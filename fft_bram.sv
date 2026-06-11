module bram (
    parameter ABITS = 10; // Address bits
    parameter WIDTH = 32; // Data width
    parameter DEPTH = 1024; // Depth of the BRAM
)(
    input logic clk,
    input logic [ABITS-1:0] addrA,
    input logic [ABITS-1:0] addrB,
    input logic signed [WIDTH-1:0] data_inA,
    input logic signed [WIDTH-1:0] data_inB,
    output logic signed [WIDTH-1:0] data_outA,
    output logic signed [WIDTH-1:0] data_outB,
    input logic weA,
    input logic weB
);
    logic signed [WIDTH-1:0] bram[0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (weA) begin
            bram[addrA] <= data_inA;
        end
        data_outA <= bram[addrA];
        if (weB) begin
            bram[addrB] <= data_inB;
        end
        data_outB <= bram[addrB];
    end
endmodule