`timescale 1ns/1ps

module tb_bram;

    parameter ABITS = 10;
    parameter WIDTH = 32;
    parameter DEPTH = 1024;

    logic clk;
    logic [ABITS-1:0] addrA, addrB;
    logic signed [WIDTH-1:0] data_inA, data_inB;
    logic signed [WIDTH-1:0] data_outA, data_outB;
    logic weA, weB;

    bram #(
        .ABITS(ABITS),
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .addrA(addrA),
        .addrB(addrB),
        .data_inA(data_inA),
        .data_inB(data_inB),
        .data_outA(data_outA),
        .data_outB(data_outB),
        .weA(weA),
        .weB(weB)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_bram.vcd");
        $dumpvars(0, tb_bram);

        clk = 0;
        weA = 0; weB = 0;
        addrA = 0; addrB = 0;
        data_inA = 0; data_inB = 0;

        @(posedge clk);
        addrA = 10'd5;
        data_inA = 32'hDEADBEEF;
        weA = 1;
        @(posedge clk);
        weA = 0;
        @(posedge clk);
        $display("Test 1: data_outA = %h (expect deadbeef)", data_outA);

        addrB = 10'd5;
        @(posedge clk);
        $display("Test 2: data_outB = %h (expect deadbeef)", data_outB);

        addrA = 10'd10;
        addrB = 10'd20;
        data_inA = 32'h11111111;
        data_inB = 32'h22222222;
        weA = 1;
        weB = 1;
        @(posedge clk);
        weA = 0;
        weB = 0;
        @(posedge clk);
        $display("Test 3: data_outA = %h (expect 11111111)", data_outA);
        $display("Test 3: data_outB = %h (expect 22222222)", data_outB);

        addrA = 10'd10;
        addrB = 10'd20;
        @(posedge clk);
        $display("Test 4: data_outA = %h (expect 11111111)", data_outA);
        $display("Test 4: data_outB = %h (expect 22222222)", data_outB);

        $finish;
    end

endmodule