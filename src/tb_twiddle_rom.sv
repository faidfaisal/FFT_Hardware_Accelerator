`timescale 1ns/1ps

module tb_twiddle_rom;

    parameter ABITS = 9;
    parameter WIDTH = 16;

    logic clk;
    logic [ABITS-1:0] addr;
    logic signed [WIDTH-1:0] wr;
    logic signed [WIDTH-1:0] wi;

    // instantiate ROM
    twiddle_rom #(
        .N(1024),
        .DEPTH(512),
        .ABITS(ABITS),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .addr(addr),
        .wr(wr),
        .wi(wi)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_twiddle_rom.vcd");
        $dumpvars(0, tb_twiddle_rom);

        clk  = 0;
        addr = 0;

        @(posedge clk);
        addr = 9'd0;
        @(posedge clk); // wait 1 cycle for registered read
        $display("Test 1 - W^0:");
        $display("  wr = %0d (expect 32767)", wr);
        $display("  wi = %0d (expect 0)",     wi);

        @(posedge clk);
        addr = 9'd256;
        @(posedge clk);
        $display("Test 2 - W^256 (should be 0 - j1.0):");
        $display("  wr = %0d (expect 0)",      wr);
        $display("  wi = %0d (expect -32768)", wi);

        @(posedge clk);
        addr = 9'd128;
        @(posedge clk);
        $display("Test 3 - W^128 (should be 0.707 - j0.707):");
        $display("  wr = %0d (expect ~23170)",  wr);
        $display("  wi = %0d (expect ~-23170)", wi);

        $display("Test 4 - address sweep:");
        for (int i = 0; i < 4; i++) begin
            @(posedge clk);
            addr = i;
            @(posedge clk);
            $display("  addr=%0d: wr=%0d wi=%0d", addr, wr, wi);
        end

        $finish;
    end

endmodule
