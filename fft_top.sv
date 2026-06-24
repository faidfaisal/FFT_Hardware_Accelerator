`timescale 1ns/1ps

module fft_top #(
    parameter N = 1024,
    parameter ABITS = $clog2(N),
    parameter DATA_WIDTH = 32,
    parameter QWIDTH = 16,
    parameter TWIDDLE_BITS = $clog2(N/2)
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    output logic done
);

    logic [ABITS-1:0] addrA, addrB;
    logic [TWIDDLE_BITS-1:0] twiddle_addr;
    logic valid_in, valid_out;
    logic weA, weB;

    logic signed [DATA_WIDTH-1:0] data_inA, data_inB;
    logic signed [DATA_WIDTH-1:0] data_outA, data_outB;

    logic signed [15:0] ar, ai, br, bi;
    logic signed [15:0] wr, wi;
    logic signed [15:0] ar_out, ai_out, br_out, bi_out;
    logic [ABITS-1:0] addrA_d, addrB_d;

    always_ff @(posedge clk) begin
        addrA_d <= addrA;
        addrB_d <= addrB;
    end
    assign ar = data_outA[31:16];
    assign ai = data_outA[15:0];
    assign br = data_outB[31:16];
    assign bi = data_outB[15:0];

    assign data_inA = {ar_out, ai_out};
    assign data_inB = {br_out, bi_out};

    controller #(
        .N(N),
        .ABITS(ABITS),
        .LOG2N($clog2(N)),
        .twiddle_bits(TWIDDLE_BITS)
    ) controller_inst (
        .clk(clk),
        .rst(rst),
        .valid_out(valid_out),
        .addrA(addrA),
        .addrB(addrB),
        .twiddle_addr(twiddle_addr),
        .weA(weA),
        .weB(weB),
        .valid_in(valid_in),
        .start(start),
        .done(done)
    );

        fft_bram #(
            .ABITS(ABITS),
            .WIDTH(DATA_WIDTH),
            .DEPTH(N)
        ) bram_inst (
            .clk(clk),
        
            .addrA(addrA),
            .addrB(addrB),
        
            .wAddrA(addrA_d),
            .wAddrB(addrB_d),
        
            .data_inA(data_inA),
            .data_inB(data_inB),
        
            .data_outA(data_outA),
            .data_outB(data_outB),
        
            .weA(weA),
            .weB(weB)
        );

    twiddle_rom #(
        .N(N),
        .DEPTH(N/2),
        .ABITS(TWIDDLE_BITS),
        .WIDTH(QWIDTH)
    ) twiddle_inst (
        .clk(clk),
        .addr(twiddle_addr),
        .wr(wr),
        .wi(wi)
    );

    butterfly butterfly_inst (
        .clk(clk),
        .valid_in(valid_in),
        .rst(rst),
        .ar(ar),
        .ai(ai),
        .br(br),
        .bi(bi),
        .wr(wr),
        .wi(wi),
        .valid_out(valid_out),
        .ar_out(ar_out),
        .ai_out(ai_out),
        .br_out(br_out),
        .bi_out(bi_out)
    );

endmodule
