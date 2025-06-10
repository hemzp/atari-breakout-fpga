module n8_driver
(
    input clk,
    input data_in,
    output reg latch,
    output reg pulse,
    output reg up,
    output reg down,
    output reg left,
    output reg right,
    output reg select,
    output reg start,
    output reg a,
    output reg b
);

    reg[7:0] data_out;
    

    serial_driver #(.BITS(8)) driver (
        .clk(clk),
        .data_in(data_in),
        .latch(latch),
        .pulse(pulse),
        .data_out(data_out)
    );
    
    assign right  = ~data_out[0];
    assign left   = ~data_out[1];
    assign down   = ~data_out[2];
    assign up     = ~data_out[3];
    assign start  = ~data_out[4];
    assign select = ~data_out[5];
    assign b      = ~data_out[6];
    assign a      = ~data_out[7];
    
endmodule //n8_driver