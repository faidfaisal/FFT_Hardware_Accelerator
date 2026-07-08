`timescale 1ns/1ps

module fft_bram #(
    parameter ABITS = 10,
    parameter WIDTH = 32,
    parameter DEPTH = 1024
)(
    input  logic clk,

    input  logic [ABITS-1:0] addrA,
    input  logic [ABITS-1:0] addrB,

    input  logic [ABITS-1:0] wAddrA,
    input  logic [ABITS-1:0] wAddrB,

    input  logic signed [WIDTH-1:0] data_inA,
    input  logic signed [WIDTH-1:0] data_inB,

    output logic signed [WIDTH-1:0] data_outA,
    output logic signed [WIDTH-1:0] data_outB,

    input  logic weA,
    input  logic weB,

    input  logic [ABITS-1:0] cpu_addr,
    input  logic [WIDTH-1:0] cpu_wdata,
    input  logic cpu_we,
    output logic [WIDTH-1:0] cpu_rdata
);

    logic signed [WIDTH-1:0] bram [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (weA)
            bram[wAddrA] <= data_inA;

        if (weB)
            bram[wAddrB] <= data_inB;

        if (cpu_we)
            bram[cpu_addr] <= cpu_wdata;

        data_outA <= bram[addrA];
        data_outB <= bram[addrB];

        cpu_rdata <= bram[cpu_addr];
    end

endmodule
