/*
- This module takes in the normal 50Mhz clock but to buffer the animation it only refreshes after every "refresh_tick"
- The other inputs to this module are the pixel_x and pixel_y locations used for filling the rectangualr paddle with white color.
- Other important inputs includes the left and right key presses from the N8 controller which are continuous signals of moving either left or right, never both.
- Output of this module is just a boolean expressing the area in which the paddle can be turned on.

This module utilizes a counter to slow down the animation, and this counter is present in the top-level where paddle.sv is instantiated alongside other drivers.
*/

module paddle #(parameter X_POS = 285, Y_POS = 449) (clk, reset, pixel_x, pixel_y, left, right, paddle_on, refresh_tick, paddle_x);
    input logic clk, reset;
    input logic refresh_tick;
    input logic [9:0] pixel_x, pixel_y;
    input logic left, right;
    output logic paddle_on;
    output logic signed [11:0] paddle_x;

    parameter WIDTH = 70;
    parameter HEIGHT = 12;

    parameter X_MAX = 639;
    parameter Y_MAX = 479;

    assign paddle_on = (pixel_x >= paddle_x) && (pixel_x < paddle_x + WIDTH) && (pixel_y >= Y_POS) && (pixel_y < Y_POS + HEIGHT);

    

    always_ff @(posedge clk) begin
        if(reset)
        paddle_x <= X_POS;
        else if (refresh_tick) begin 
            if(left && (paddle_x > 0) && !right)
                paddle_x <= paddle_x - 2;
            else if(right && (paddle_x < X_MAX - (WIDTH - 1)))
                paddle_x <= paddle_x + 2;
            else 
                paddle_x <= paddle_x;
        end 
    end
    
endmodule //paddle.sv


`timescale 1ns/1ps

module paddle_tb;

    // Testbench signals
    logic clk;
    logic reset;
    logic refresh_tick;
    logic [9:0]  pixel_x, pixel_y; // unused in this TB
    logic left, right;
    logic [9:0] paddle_x;
    logic paddle_on;

    //Instantiate the paddle
    paddle #(
        .X_POS(285),
        .Y_POS(449)
    ) dut (
        .clk          (clk),
        .reset        (reset),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .left         (left),
        .right        (right),
        .paddle_on    (paddle_on),
        .refresh_tick (refresh_tick),
        .paddle_x     (paddle_x)
    );


    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end


    int ctr;
    initial begin
        ctr = 0;
        refresh_tick = 0;
        forever begin
            @(posedge clk);
            if (ctr == 4) begin
                refresh_tick = 1;
                ctr = 0;
            end else begin
                refresh_tick = 0;
                ctr = ctr + 1;
            end
        end
    end

    initial begin

        reset    = 1;
        left     = 0;
        right    = 0;
        pixel_x  = 0;
        pixel_y  = 0;

        #100;      
        reset = 0;

   
        @(posedge clk);
        $display("After reset: paddle_x = %0d (expected 285)", paddle_x);

        //Move left until boundary
        left = 1;
        right = 0;
        //Keep updating refresh_tick until paddle_x reaches 0
        while (paddle_x != 0) begin
            @(posedge refresh_tick);
        end

        @(posedge refresh_tick);
        $display("At left limit: paddle_x = %0d (should stay at 0)", paddle_x);

        //Move right until rightmost boundary
        left = 0;
        right = 1;

        while (paddle_x != 570) begin
            @(posedge refresh_tick);
        end

        @(posedge refresh_tick);
        $display("At right limit: paddle_x = %0d (should stay at 570)", paddle_x);


        $display("Testbench complete.");
        $stop;
    end

endmodule //paddle_tb
