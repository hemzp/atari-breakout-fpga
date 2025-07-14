/* Ball physics module that handles ball movement, collision detection, and lives management.
   Controls ball bouncing off walls/paddle/bricks and tracks when player loses lives. */
   
module ball (
    input  logic             clk,
    input  logic             reset,
    input  logic signed [11:0] paddle_x,
    input  logic             up_press,
    input  logic             refresh_tick,
    input  logic             brick_h_hit,
    input  logic             brick_v_hit,

    output logic             ball_hit,
    output logic [10:0]      ball_x,
    output logic [9:0]       ball_y,
    output logic             ball_died,      //  Signal when ball dies
    output logic [1:0]       lives_remaining //  Lives counter (0-3)
);

    parameter int BALL_W = 8;
    parameter int BALL_H = 7;
    parameter int SCREEN_W = 640;
    parameter int SCREEN_H = 480;

    parameter int PADDLE_W = 70;
    parameter int PADDLE_H = 12;
    parameter int PADDLE_Y = SCREEN_H - PADDLE_H;

    parameter BRICK_ROWS       = 4;
    parameter BRICK_COLS       = 7;
    parameter BRICK_WIDTH      = 77;
    parameter BRICK_HEIGHT     = 20;
    parameter BRICK_SPACING_X  = 6;
    parameter BRICK_SPACING_Y  = 10;
    parameter BRICK_START_X    = 32;
    parameter BRICK_START_Y    = 60;

    logic signed [10:0] x_reg, next_x, rel_x;
    logic signed [9:0]  y_reg, next_y, rel_y;
    logic signed [3:0]  dx, dy;
    logic signed [3:0]  next_dx, next_dy;
    
    integer overlap_x;
    integer overlap_y;

    logic [2:0] hit_col;
    logic [1:0] hit_row;
    logic signed [10:0] BX, BR;
    logic signed [9:0]  BY, BB;

    logic geometric_hit;

    enum logic {REST, MOVING} ps;

    always_ff @(posedge clk) begin
        if (reset) begin
            ps <= REST;
            dx <=  0;
            dy <=  0;
            lives_remaining <= 2'd3;  //  Start with 3 lives
            ball_died <= 1'b0;
        end else begin
            ball_died <= 1'b0;  // Default: no death this cycle
            
            if (ps == REST && up_press) begin
                ps <= MOVING;
                dx <= -1;
                dy <= -1;
            end

            if (ps == MOVING && refresh_tick) begin
                next_x = x_reg + dx;
                next_y = y_reg + dy;

                // Wall bounce
                if ((dx < 0 && next_x < 0) || (dx > 0 && next_x > SCREEN_W - BALL_W))
                    dx <= -dx;
                if (dy < 0 && next_y < 0)
                    dy <= -dy;

                if (brick_h_hit && !brick_v_hit) begin
                    dx <= -dx;      // left/right face
                end else if (brick_v_hit && !brick_h_hit) begin
                    dy <= -dy;      // top/bottom face
                end else if (brick_h_hit && brick_v_hit) begin
                    dx <= -dx; dy <= -dy;  // perfect corner
                end

                // Paddle bounce
                if ((dy > 0) &&
                    (next_y + BALL_H - 1 >= PADDLE_Y) &&
                    (next_x + BALL_W - 1 >= paddle_x) &&
                    (next_x <= paddle_x + PADDLE_W - 1)) begin
                    dy <= -dy;
                end else if ((dy > 0) && (next_y + BALL_H - 1 > SCREEN_H - 1)) begin
                    //  Ball died - lose a life
                    ball_died <= 1'b1;
                    ps <= REST;
                    dx <= 0;
                    dy <= 0;
                    
                    if (lives_remaining > 0) begin
                        lives_remaining <= lives_remaining - 1;
                    end
                end
            end
        end
    end
    
    always_ff @(posedge clk) begin
    //always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_reg    <= paddle_x + 31;
            y_reg    <= 429;
            ball_hit <= 1'b0;
        end else if (refresh_tick) begin
            ball_hit <= geometric_hit;

            if (ps == REST) begin
                x_reg <= paddle_x + 31;
                y_reg <= 429;
            end else begin
                x_reg <= x_reg + dx;
                y_reg <= y_reg + dy;
            end
        end
    end

    assign ball_x = x_reg;
    assign ball_y = y_reg;

endmodule //ball

`timescale 1ns / 1ps

module ball_tb;


    parameter CLK_PERIOD     = 10; 
    parameter REFRESH_PERIOD = 200;  
    parameter int BALL_W    =  8;    
    parameter int BALL_H    =  7;    
    parameter int SCREEN_W  = 640;   
    parameter int SCREEN_H  = 480;   
    parameter int PADDLE_W  = 70;
    parameter int PADDLE_H  = 12;
    parameter int PADDLE_Y  = SCREEN_H - PADDLE_H; 


    logic clk;
    logic reset;
    logic signed [11:0] paddle_x;       
    logic up_press;
    logic refresh_tick;


    logic [9:0]  ball_x;
    logic [8:0]  ball_y;


    // Instantiate the ball module under test:
    ball dut (
        .clk (clk),
        .reset (reset),
        .paddle_x (paddle_x),
        .up_press (up_press),
        .refresh_tick (refresh_tick),
        .ball_x (ball_x),
        .ball_y (ball_y)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        refresh_tick = 1'b0;
        #REFRESH_PERIOD;
        forever begin
            refresh_tick = 1'b1;
            #CLK_PERIOD;              
            refresh_tick = 1'b0;
            # (REFRESH_PERIOD - CLK_PERIOD);
        end
    end

    initial begin
        reset    = 1'b1;
        paddle_x = 10'sd300;   
        up_press = 1'b0;
        #(CLK_PERIOD * 5);    
        reset = 1'b0;          
        #(CLK_PERIOD * 5);    
        up_press = 1'b1;
        # (CLK_PERIOD * 3);
        up_press = 1'b0;
        #(REFRESH_PERIOD * 100);
        $finish;
    end


    logic [9:0] prev_x;
    logic prev_moving_right;

    initial begin
        prev_x           = 10'd0;
        prev_moving_right = 1'b0;
    end

    always @(posedge clk) begin
        if (refresh_tick) begin
            // Check if previously we were moving right (x increasing)
            // and the current position is exactly at 632:
            if ((prev_x < ball_x) && (ball_x == (SCREEN_W - BALL_W))) begin
 
                $display(" Right‐wall collision predicted at time %0t: ball_x = %0d ",
                          $time, ball_x);
            end

            if ((prev_x == (SCREEN_W - BALL_W)) && (ball_x < prev_x)) begin
                $display(" Confirmed bounce at time %0t: ball_x went from %0d → %0d ",
                          $time, prev_x, ball_x);
            end

            prev_x = ball_x; 
        end
    end

endmodule //ball_tb
