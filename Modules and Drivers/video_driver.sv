/* VGA video driver that converts game graphics to proper VGA timing and color signals.
   Handles pixel scaling, timing coordination, and interfaces with VGA timing controller. */

module video_driver
	#(parameter WIDTH = 640, parameter HEIGHT = 480)
	(CLOCK_50, reset, x, y, r, g, b, VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS); 
	input  logic CLOCK_50;
	input  logic reset;
	output logic [9:0] x;
	output logic [8:0] y;
	input  logic [7:0] r, g, b;
	output logic [7:0] VGA_R, VGA_G, VGA_B;
	output logic VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS;
	
	localparam integer X_BLOCK = 640 / WIDTH;
	localparam integer Y_BLOCK = 480 / HEIGHT;
	localparam integer BLOCK = X_BLOCK < Y_BLOCK ? X_BLOCK : Y_BLOCK;
	localparam integer X_SPAN = WIDTH * BLOCK;
	localparam integer Y_SPAN = HEIGHT * BLOCK;
	localparam integer X_START = (640 - X_SPAN) / 2;
	localparam integer Y_START = (480 - Y_SPAN) / 2;
	localparam integer X_STOP = X_START + X_SPAN;
	localparam integer Y_STOP = Y_START + Y_SPAN;
	localparam integer BLOCK_STOP = BLOCK - 1;
	
	logic read_enable;
	logic end_of_active_frame;
	logic end_of_frame;
	logic vga_blank;
	logic vga_c_sync;
	logic vga_h_sync;
	logic vga_v_sync;
	logic vga_data_enable;
	
	logic read_enable_last;
	logic CLOCK_25;
	logic locked; // ignore - is PLL locked?
	logic [9:0] xt;
	logic [8:0] yt;
	logic [9:0] xd;
	logic [8:0] yd;
	
	// Simple clock divider to generate 25MHz from 50MHz
	always_ff @(posedge CLOCK_50) begin
		if (reset)
			CLOCK_25 <= 0;
		else
			CLOCK_25 <= ~CLOCK_25;
	end
	
	always @(posedge CLOCK_25) begin
		if(reset) begin
			xt <= 0;
			yt <= 0;
			xd <= 0;
			yd <= 0;
			x <= 0;
			y <= 0;
		end else begin
			read_enable_last <= read_enable;
			if(read_enable) begin
				xt <= xt + 1'b1;
				if(xt >= X_START && xt < X_STOP) begin
					if(xd == BLOCK_STOP) begin
						xd <= 10'b0;
						x <= x + 1'b1;
					end else begin
						xd <= xd + 1'b1;
					end
				end else begin
					xd <= 10'b0;
					x <= 10'b0;
				end
			end else begin
				xt <= 10'b0;
				xd <= 10'b0;
				x <= 10'b0;
			end
			if(end_of_active_frame) begin
				yt <= 9'b111111111;
				yd <= 9'b0;
				y <= 9'b0;
			end else begin
				if(read_enable_last & ~read_enable) begin
					yt <= yt + 1'b1;
					if(yt >= Y_START && yt < Y_STOP) begin
						if(yd == BLOCK_STOP) begin
							yd <= 9'b0;
							y <= y + 1'b1;
						end else begin
							yd <= yd + 1'b1;
						end
					end else begin
						yd <= 9'b0;
						y <= 9'b0;
					end
				end
			end
		end
	end
	
	assign VGA_BLANK_N = vga_blank;
	assign VGA_CLK = CLOCK_25;
	assign VGA_HS = vga_h_sync;
	assign VGA_SYNC_N = 1'b0;
	assign VGA_VS = vga_v_sync;
	
	logic [7:0] rout, gout, bout;
	
	always @(posedge CLOCK_25) begin
		if(xt >= X_START && xt < X_STOP && yt >= Y_START && yt < Y_STOP) begin
			rout <= r;
			gout <= g;
			bout <= b;
		end else begin
			rout <= 8'b0;
			gout <= 8'b0;
			bout <= 8'b0;
		end
	end
	
	altera_up_avalon_video_vga_timing video (
		// inputs
		.clk(CLOCK_25),
		.reset,

		.red_to_vga_display({2'b00,rout}),
		.green_to_vga_display({2'b00,gout}),
		.blue_to_vga_display({2'b00,bout}),
		.color_select(4'b1111),
		
		// outputs
		.read_enable,
		.end_of_active_frame,
		.end_of_frame,

		// dac pins
		.vga_blank,					//	VGA BLANK
		.vga_c_sync,				//	VGA COMPOSITE SYNC
		.vga_h_sync,				//	VGA H_SYNC
		.vga_v_sync,				//	VGA V_SYNC
		.vga_data_enable,			// VGA DEN
		.vga_red(VGA_R),			//	VGA Red[9:0]
		.vga_green(VGA_G),	 	//	VGA Green[9:0]
		.vga_blue(VGA_B),	   	//	VGA Blue[9:0]
		.vga_color_data()	   	//	VGA Color[9:0] for TRDB_LCM
	);
endmodule //video_driver