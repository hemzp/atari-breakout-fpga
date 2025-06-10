/* Top-level module that connects all game components and handles I/O for the DE1-SoC board.
   Manages game logic, VGA output, controller input, score display, and victory/game over screens. */

module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
					 CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS, V_GPIO);
	inout [35:0] V_GPIO;
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input CLOCK_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_BLANK_N;
	output VGA_CLK;
	output VGA_HS;
	output VGA_SYNC_N;
	output VGA_VS;
	parameter int TICK = 50000000/180; 
	parameter int BALL_W = 8;
	parameter int BALL_H = 7;

	logic [19:0] move_counter;
	logic refresh_tick;
	logic reset;
	logic [9:0] x;
	logic [8:0] y;
	logic [7:0] r, g, b;
	logic raw_up, raw_down, raw_left, raw_right, raw_select, raw_start, raw_a, raw_b;
	logic latch, pulse;
	logic signed [11:0] paddle_x;
	logic [10:0] ball_x;
    logic [9:0] ball_y;
	logic ball_on;
	logic ball_hit;

	//  Lives system signals
	logic ball_died;
	logic [1:0] lives_remaining;
	logic game_over;
	logic game_over_triggered;
	logic game_over_complete;
	logic game_over_displaying;

	//  Victory system signals
	logic victory_condition;
	logic victory_triggered;
	logic victory_complete;
	logic victory_displaying;

	wire data_in = V_GPIO[28];
	assign V_GPIO[26] = latch;       
	assign V_GPIO[27] = pulse;
	n8_driver n8 (
		.clk      (CLOCK_50),
		.data_in  (data_in),
		.latch    (latch),
		.pulse    (pulse),
		.up       (raw_up),
		.down     (raw_down),
		.left     (raw_left),
		.right    (raw_right),
		.select   (raw_select),
		.start    (raw_start),
		.a        (raw_a),
		.b        (raw_b)
	);
	
	logic dff1Q, dff2Q, dff1Q_1, dff2Q_2;
	logic dff3, dff4;
	logic dff5, dff6;
	logic filteredLeft;  
	logic filteredRight; 
	logic filteredUp;
	logic filteredReset;

	   //collision‐by‐raster signals
	logic        drawing_ball, drawing_brick;
	logic        pixel_collision;
	logic [9:0]  collision_x;
	logic [8:0]  collision_y;
	logic        brick_h_hit, brick_v_hit;
	logic brick_h_acc, brick_v_acc;

	always_ff @(posedge CLOCK_50) begin
		dff1Q <= raw_left;
		dff2Q <= dff1Q;
		dff1Q_1 <= raw_right;
		dff2Q_2 <= dff1Q_1;
		dff3 <= raw_start;
		dff4 <= dff3;
		dff5 <= raw_up;
		dff6 <= dff5;
	end
	assign filteredLeft = dff2Q;
	assign filteredRight = dff2Q_2; 
	assign filteredUp = dff6;
	assign filteredReset = dff4;

	//Game over logic - only trigger when ball dies AND no lives left
	assign game_over = (lives_remaining == 0) && ball_died;
	
	//Victory logic - trigger when all bricks destroyed
	assign victory_condition = (bricks_remaining == 0);
	
	// Game over trigger and timer system
	always_ff @(posedge CLOCK_50) begin
		if (filteredReset) begin
			game_over_triggered <= 1'b0;
		end else if (game_over && !game_over_triggered) begin
			game_over_triggered <= 1'b1;  // Trigger game over display
		end else if (game_over_complete) begin
			game_over_triggered <= 1'b0;  // Clear after display complete
		end
	end
	
	//Victory trigger logic
	always_ff @(posedge CLOCK_50) begin
		if (filteredReset) begin
			victory_triggered <= 1'b0;
		end else if (victory_condition && !victory_triggered) begin
			victory_triggered <= 1'b1;  // Trigger victory display
		end else if (victory_complete) begin
			victory_triggered <= 1'b0;  // Clear after display complete
		end
	end
	
	//Auto-reset when game over OR victory display completes
	logic auto_reset;
	always_ff @(posedge CLOCK_50) begin
		if (filteredReset) begin
			auto_reset <= 1'b0;
		end else if (game_over_complete || victory_complete) begin
			auto_reset <= 1'b1;  // Auto-reset when either display completes
		end else if (auto_reset) begin
			auto_reset <= 1'b0;  // Clear after one cycle
		end
	end
	
	//Combine manual and auto reset
	logic combined_reset;
	assign combined_reset = filteredReset || auto_reset;

	//Game Over Display Module
	game_over_display game_over_inst (
		.clk(CLOCK_50),
		.reset(combined_reset),
		.trigger_game_over(game_over_triggered),
		.pixel_x(x),
		.pixel_y(y),
		.game_over_on(game_over_displaying),
		.game_over_complete(game_over_complete)
	);

	//Victory Display Module
	victory_display victory_inst (
		.clk(CLOCK_50),
		.reset(combined_reset),
		.trigger_victory(victory_triggered),
		.pixel_x(x),
		.pixel_y(y),
		.victory_on(victory_displaying),
		.victory_complete(victory_complete)
	);

	video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50(CLOCK_50), .reset(combined_reset), .x(x), .y(y), .r(r), .g(g), .b(b),
			 .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_BLANK_N(VGA_BLANK_N),
			 .VGA_CLK(VGA_CLK), .VGA_HS(VGA_HS), .VGA_SYNC_N(VGA_SYNC_N), .VGA_VS(VGA_VS));
	always_ff @(posedge CLOCK_50) begin
		if(combined_reset)
			move_counter <= 0;
		else if (move_counter == TICK - 1)
			move_counter <= 0;
		else
			move_counter <= move_counter + 1;
	end

	assign refresh_tick = (move_counter == TICK - 1); 
	logic paddle_on;
	paddle #(.X_POS(285), .Y_POS(449)) pad 
	(.clk(CLOCK_50), 
	.reset(combined_reset), 
	.pixel_x(x), 
	.pixel_y(y),
	.refresh_tick(refresh_tick), 
	.left(filteredLeft), 
	.right(filteredRight), 
	.paddle_on(paddle_on),
	.paddle_x(paddle_x));

	ball balling 
	(.clk(CLOCK_50), 
	.reset(combined_reset), 
	.paddle_x(paddle_x),
	.up_press(filteredUp), 
	.refresh_tick(refresh_tick), 
	.ball_x(ball_x), 
	.ball_y(ball_y),
	.ball_hit(ball_hit),
	.brick_h_hit(brick_h_acc),
	.brick_v_hit(brick_v_acc),
	.ball_died(ball_died),          //  Ball death signal
	.lives_remaining(lives_remaining) //  Lives counter
	);
	
	assign ball_on = (x >= ball_x) &&
					(x <  ball_x + 7) &&
					(y >= ball_y) &&
					(y <  ball_y + 8);

	// Brick array signals
	logic brick_on;
	logic [7:0] brick_r, brick_g, brick_b;
	logic [4:0] bricks_remaining;

	brick_array #(
		.BRICK_ROWS      (4),
		.BRICK_COLS      (7),
		.BRICK_WIDTH     (77),
		.BRICK_HEIGHT    (20),
		.BRICK_SPACING_X (6),
		.BRICK_SPACING_Y (10),
		.BRICK_START_X   (32),
		.BRICK_START_Y   (60)
	) bricks (
		.clk               (CLOCK_50),
		.reset             (combined_reset),
		.pixel_x           (x),
		.pixel_y           (y),
		.ball_x            (collision_x),    
		.ball_y            (collision_y),    
		.ball_hit          (pixel_collision),
		.brick_on          (brick_on),
		.brick_r           (brick_r),
		.brick_g           (brick_g),
		.brick_b           (brick_b),
		.bricks_remaining  (bricks_remaining)
	);

	// combinational strobes
	always_comb begin
		drawing_ball  = VGA_BLANK_N && ball_on;
		drawing_brick = VGA_BLANK_N && brick_on;
	end

	// snapshot on every pixel clock
	always_ff @(posedge CLOCK_50) begin
	// 1-cycle pulse when both ball and brick would draw
	pixel_collision <= drawing_ball && drawing_brick;

	// remember which pixel it was
	if (pixel_collision) begin
		collision_x <= x;
		collision_y <= y;
	end

	// which edge of the ball did we hit?
	brick_h_hit <= pixel_collision &&
					((x == ball_x) ||
					(x == ball_x + BALL_W - 1));

	brick_v_hit <= pixel_collision &&
					((y == ball_y) ||
					(y == ball_y + BALL_H - 1));
	end

	always_ff @(posedge CLOCK_50) begin
		if (combined_reset) begin
			brick_h_acc <= 0;
			brick_v_acc <= 0;
		end else begin
			// accumulate any hit pulses
			if (brick_h_hit) brick_h_acc <= 1;
			if (brick_v_hit) brick_v_acc <= 1;

			// on each ball move, clear the accumulators
			if (refresh_tick) begin
			brick_h_acc <= 0;
			brick_v_acc <= 0;
			end
		end
	end

	// Priority-based color selection with VICTORY and GAME OVER overlays
	always_comb begin
		if (victory_displaying) begin
			// Victory text in green
			r = 8'h00;
			g = 8'hFF;
			b = 8'h00;
		end else if (game_over_displaying) begin
			// Game over text in red
			r = 8'hFF;
			g = 8'h00;
			b = 8'h00;
		end else if (paddle_on) begin
			r = 8'hFF;
			g = 8'hFF;
			b = 8'hFF; //white
		end else if(ball_on) begin
			r = 8'hFF;
			g = 8'hFF;
			b = 8'hFF; //white
		end else if (brick_on) begin
			// Use brick colors
			r = brick_r;
			g = brick_g;
			b = brick_b;
		end else begin
			r = 8'h00;
			g = 8'h00;
			b = 8'h00; //black background
		end
	end
	
	// Display score on HEX displays (counts UP from 00 to 28)
	logic [4:0] score;
	assign score = 28 - bricks_remaining;  // Count up as bricks are destroyed
	
	logic [3:0] ones, tens;
	assign ones = score % 10;
	assign tens = score / 10;
	
	// Simple 7-segment decoder for digits 0-9
	function logic [6:0] digit_to_seg(input logic [3:0] digit);
		case (digit)
			4'd0: digit_to_seg = 7'b1000000;
			4'd1: digit_to_seg = 7'b1111001;
			4'd2: digit_to_seg = 7'b0100100;
			4'd3: digit_to_seg = 7'b0110000;
			4'd4: digit_to_seg = 7'b0011001;
			4'd5: digit_to_seg = 7'b0010010;
			4'd6: digit_to_seg = 7'b0000010;
			4'd7: digit_to_seg = 7'b1111000;
			4'd8: digit_to_seg = 7'b0000000;
			4'd9: digit_to_seg = 7'b0010000;
			default: digit_to_seg = 7'b1111111;
		endcase
	endfunction
	
	//  Display lives on HEX5 (leftmost), score on HEX1/HEX0
	assign HEX0 = digit_to_seg(ones);          // Score ones
	assign HEX1 = digit_to_seg(tens);          // Score tens
	assign HEX2 = 7'b1111111;                  // Off
	assign HEX3 = 7'b1111111;                  // Off
	assign HEX4 = 7'b1111111;                  // Off
	assign HEX5 = digit_to_seg(lives_remaining[1:0]); //  Lives display

	//  Debug LEDs for lives and victory system
	assign LEDR[0] = ball_died;           // LED0: Ball died this cycle
	assign LEDR[1] = game_over;           // LED1: Game over condition
	assign LEDR[2] = game_over_displaying; // LED2: Game over text showing
	assign LEDR[3] = game_over_complete;   // LED3: Game over display complete
	assign LEDR[4] = victory_condition;    // LED4: Victory condition (all bricks destroyed)
	assign LEDR[5] = victory_displaying;   // LED5: Victory text showing
	assign LEDR[6] = victory_complete;     // LED6: Victory display complete
	assign LEDR[7] = 1'b0;                 // LED7: Unused
	assign LEDR[9:8] = lives_remaining;    // LED9-8: Lives remaining
	
endmodule  // DE1_SoC