/* Game over screen controller that displays red "GAME OVER" text for 5 seconds when player loses.
   Uses ROM-based bitmap graphics with 8x scaling and automatic reset after display timeout. */

module game_over_display (
    input  logic        clk,
    input  logic        reset,
    input  logic        trigger_game_over,  //Start game over sequence
    input  logic [9:0]  pixel_x,
    input  logic [8:0]  pixel_y,
    output logic        game_over_on,       //High when displaying game over
    output logic        game_over_complete  //High when 5 seconds elapsed
);

    // Game over text position (scaled up 8x)
    parameter TEXT_START_X = 230;  // Center the larger text
    parameter TEXT_START_Y = 160;  // Center vertically  
    parameter TEXT_WIDTH = 256;    // 32 * 8 scale
    parameter TEXT_HEIGHT = 128;   // 16 * 8 scale
    parameter SCALE_FACTOR = 8;    // Scale up by 8x
    
    // Timer for 5 second display (at 50MHz)
    parameter DISPLAY_TIME = 50000000 * 5; // 5 seconds
    logic [28:0] timer_counter;
    
    // State machine
    enum logic [1:0] {IDLE, DISPLAYING, COMPLETE} state;
    
    //ROM signals
    logic [3:0] rom_addr;  //4 bits for 16 rows
    logic [31:0] rom_data; //32 bits per row
    logic rom_pixel;
    
    //Calculate ROM address and pixel within row (with scaling)
    logic [7:0] rel_x, rel_y;
    logic [4:0] scaled_x, scaled_y;
    assign rel_x = pixel_x - TEXT_START_X;
    assign rel_y = pixel_y - TEXT_START_Y;
    
    //scake down to get original coordinates
    assign scaled_x = rel_x / SCALE_FACTOR;  //ivide by 8
    assign scaled_y = rel_y / SCALE_FACTOR;  //Divide by 8
    
    assign rom_addr = scaled_y[3:0];  // Row selection
    assign rom_pixel = rom_data[31 - scaled_x[4:0]]; // Pixel selection (MSB first)
    
    //Instantiate  ROM
    game_over_rom rom_inst (
        .clock(clk),
        .address(rom_addr),
        .q(rom_data)
    );
    
    //State machine and timer
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            timer_counter <= 0;
            game_over_complete <= 0;
        end else begin
            case (state)
                IDLE: begin
                    timer_counter <= 0;
                    game_over_complete <= 0;
                    if (trigger_game_over) begin
                        state <= DISPLAYING;
                    end
                end
                
                DISPLAYING: begin
                    timer_counter <= timer_counter + 1;
                    if (timer_counter >= DISPLAY_TIME - 1) begin
                        state <= COMPLETE;
                        game_over_complete <= 1;
                    end
                end
                
                COMPLETE: begin
                    // Stay in complete state until reset
                    game_over_complete <= 1;
                end
            endcase
        end
    end
    
    //Output logic
    always_comb begin
        game_over_on = 0;
        
        if (state == DISPLAYING) begin
            
            if (pixel_x >= TEXT_START_X && 
                pixel_x < TEXT_START_X + TEXT_WIDTH &&
                pixel_y >= TEXT_START_Y && 
                pixel_y < TEXT_START_Y + TEXT_HEIGHT) begin
                
                game_over_on = rom_pixel;  // Show pixel if ROM bit is set
            end
        end
    end

endmodule //game_over_display