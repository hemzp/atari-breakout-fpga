/* 4x7 brick array that manages brick visibility, collision detection, and destruction.
   Handles VGA rendering of colored bricks and decrements brick count when hit by ball. */

module brick_array (
    input  logic         clk,
    input  logic         reset,
    input  logic [9:0]   pixel_x,
    input  logic [8:0]   pixel_y,
    input  logic [9:0]   ball_x,
    input  logic [8:0]   ball_y,
    input  logic         ball_hit,
    output logic         brick_on,
    output logic [7:0]   brick_r,
    output logic [7:0]   brick_g,
    output logic [7:0]   brick_b,
    output logic [4:0]   bricks_remaining
);

    // Parameters
    parameter int BRICK_ROWS      = 4;
    parameter int BRICK_COLS      = 7;
    parameter int BRICK_WIDTH     = 77;
    parameter int BRICK_HEIGHT    = 20;
    parameter int BRICK_SPACING_X = 6;
    parameter int BRICK_SPACING_Y = 10;
    parameter int BRICK_START_X   = 32;
    parameter int BRICK_START_Y   = 60;
    localparam int TOTAL_BRICKS   = BRICK_ROWS * BRICK_COLS;

    // Alive registers
    logic alive [0:BRICK_ROWS-1][0:BRICK_COLS-1];

    // VGA pipeline signals
    logic         in_area;
    logic         in_area_d;
    logic [2:0]   col;
    logic [1:0]   row;
    logic [2:0]   col_d;
    logic [1:0]   row_d;
    logic signed [10:0] rx_comb;
    logic signed [9:0]  ry_comb;

    // Hit computation signals
    logic signed [10:0] rx_hit;
    logic signed [9:0]  ry_hit;
    logic [2:0]         hit_col;
    logic [1:0]         hit_row;
    logic               hit_zone;

    // Combined reset + collision and pipeline update
    always_ff @(posedge clk) begin
        integer i, j;
        if (reset) begin
            // Initialize bricks
            bricks_remaining  <= TOTAL_BRICKS;
            for (i = 0; i < BRICK_ROWS; i = i + 1)
                for (j = 0; j < BRICK_COLS; j = j + 1)
                    alive[i][j] <= 1'b1;
            // Pipeline regs reset
            in_area_d <= 1'b0;
            col_d     <= 3'd0;
            row_d     <= 2'd0;
        end else begin
            // Pipeline VGA signals
            in_area_d <= in_area;
            col_d     <= col;
            row_d     <= row;
            //Collision and brick kill
            if (ball_hit) begin
                //Compute hit-relative coords
                rx_hit = ball_x - BRICK_START_X;
                ry_hit = ball_y - BRICK_START_Y;
                // Check valid hit area
                hit_zone = (rx_hit >= 0) && (rx_hit < BRICK_COLS*(BRICK_WIDTH+BRICK_SPACING_X)) &&
                           (ry_hit >= 0) && (ry_hit < BRICK_ROWS*(BRICK_HEIGHT+BRICK_SPACING_Y)) &&
                           ((rx_hit % (BRICK_WIDTH+BRICK_SPACING_X)) < BRICK_WIDTH) &&
                           ((ry_hit % (BRICK_HEIGHT+BRICK_SPACING_Y)) < BRICK_HEIGHT);
                if (hit_zone) begin
                    hit_col = rx_hit / (BRICK_WIDTH + BRICK_SPACING_X);
                    hit_row = ry_hit / (BRICK_HEIGHT + BRICK_SPACING_Y);
                    if (alive[hit_row][hit_col]) begin
                        alive[hit_row][hit_col]   <= 1'b0;
                        bricks_remaining <= bricks_remaining - 1;
                    end
                end
            end
        end
    end

    // VGA combinational address decode
    always_comb begin
        // Default
        in_area  = 1'b0;
        rx_comb  = pixel_x - BRICK_START_X;
        ry_comb  = pixel_y - BRICK_START_Y;
        col      = 3'd0;
        row      = 2'd0;
        // Within brick grid region?
        if (pixel_x >= BRICK_START_X && pixel_x <  BRICK_START_X + BRICK_COLS*(BRICK_WIDTH+BRICK_SPACING_X) &&
            pixel_y >= BRICK_START_Y && pixel_y <  BRICK_START_Y + BRICK_ROWS*(BRICK_HEIGHT+BRICK_SPACING_Y)) begin
            if ((rx_comb % (BRICK_WIDTH+BRICK_SPACING_X)) < BRICK_WIDTH &&
                (ry_comb % (BRICK_HEIGHT+BRICK_SPACING_Y)) < BRICK_HEIGHT) begin
                in_area = 1'b1;
                col     = rx_comb / (BRICK_WIDTH + BRICK_SPACING_X);
                row     = ry_comb / (BRICK_HEIGHT + BRICK_SPACING_Y);
            end
        end
    end

    // VGA output assignment
    always_ff @(posedge clk) begin
        brick_on <= in_area_d && alive[row_d][col_d];
        if (brick_on) begin
            case (row_d)
                2'd0: begin brick_r <= 8'h00; brick_g <= 8'hFF; brick_b <= 8'h00; end
                2'd1: begin brick_r <= 8'hFF; brick_g <= 8'hFF; brick_b <= 8'h00; end
                2'd2: begin brick_r <= 8'hFF; brick_g <= 8'h00; brick_b <= 8'h00; end
                2'd3: begin brick_r <= 8'h00; brick_g <= 8'h00; brick_b <= 8'hFF; end
            endcase
        end else begin
            brick_r <= 8'h00;
            brick_g <= 8'h00;
            brick_b <= 8'h00;
        end
    end

endmodule // brick_array