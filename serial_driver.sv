module serial_driver #(int BITS)
(
    input clk,
    input data_in,
    output reg latch,
    output reg pulse,
    output reg [BITS-1:0] data_out
);

    localparam SPEED = 14; // Very fast (some bits lost)
    // localparam SPEED = 14; // Very fast (some bits lost)
    // localparam SPEED = 15; // Fast 
    // localparam SPEED = 20; // Slow (and visible)
    // with 26, each step is 1 second
    localparam MAX_STEPS = 4 + BITS * 2; // e.g., with 8 bits we need 20 phases
    localparam MAX_COUNT = 10; // 10 additional steps after the 20 or whatever before requesting again
    reg[BITS-1:0] temp; // The register to be saved. 
                   
    reg save; // Either 1 (saving temp[7:0] to LED's 0:7) or 0 (not saving)


    //pulse and latch generation
    always@* begin
    
        // For the first 20 options:
        if (count < MAX_STEPS) begin
            //count 0
            if(count == 0) begin 
                latch = 0; pulse = 0; save = 0; 
            end
            //count 1, 2
            else if ((count == 1) | (count == 2)) begin
                latch = 1; pulse = 0; save = 0; 
            end
            //count 19
            else if (count == MAX_STEPS-1) begin 
                latch = 0; pulse = 0; save = 1; 
            end
            //count 3, 5, 7, 9, 11, 13, 15, 17
            else if (count[0]) begin 
                latch = 0; pulse = 0; save = 0; 
            end
            //count 4, 6, 8, 10, 12, 14, 16, 18
            else /* (~count[0])*/ begin 
                latch = 0; pulse = 1; save = 0; 
            end
            //count >18
        end
        else begin 
            latch = 0; pulse = 0; save = 0;
        end
    end

    // Whenever either N8_PULSE or N8_LATCH become negative from positive
    // then do the left shifting of one bit. The reason for doing it
    // in negedge and not in posedge is because doing it in posedge assumes
    // that the request by the Raspberry Pico must be extremely fast.
    // My understanding is that the answer by the Raspberry Pico must be
    // at least 1/50M seconds, as once the previous block changes from
    // N8_PULSE 0 to 1, immediately this code is triggered. However,
    // if we do negedge (as we do here), thanks to the counter it will
    // process it in a longer time (depending on "SPEED"), which gives
    // room to the Raspberry Pico to process it in a millisecond or similar
    always @(negedge latch | pulse)
    begin
        temp[BITS-1:1] <= temp[BITS-2:0];
        temp[0] <= data_in;
    end

    // When save is true, then save it
    always @(posedge save) 
    begin
        data_out = temp;
    end
    
    reg [SPEED:0] counter;
    always@(posedge clk) counter <= counter + 1;

    reg [BITS:0] count; // counter... 30 low number of positions (e.g. 0..30)
    always@(posedge counter[SPEED]) begin
        if (count == MAX_STEPS+MAX_COUNT)
            count <= 0;
        else
            count <= count + 1;
    end
    
endmodule //serial_driver
