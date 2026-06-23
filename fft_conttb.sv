`timescale 1ns/1ps

module tb_controller;

    parameter N            = 1024;
    parameter ABITS        = $clog2(N);
    parameter LOG2N        = $clog2(N);
    parameter twiddle_bits = $clog2(N/2);

    // DUT signals
    logic clk;
    logic rst;
    logic start;
    logic valid_out;
    logic [ABITS-1:0] addrA;
    logic [ABITS-1:0] addrB;
    logic [twiddle_bits-1:0] twiddle_addr;
    logic weA;
    logic weB;
    logic valid_in;
    logic valid_in_d1, valid_in_d2;
    logic done;

    // instantiate controller
    controller #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .valid_out(valid_out),
        .addrA(addrA),
        .addrB(addrB),
        .twiddle_addr(twiddle_addr),
        .weA(weA),
        .weB(weB),
        .valid_in(valid_in),
        .done(done)
    );

    // clock generation
    always #5 clk = ~clk;

    // simulate butterfly latency — valid_out goes high 2 cycles after valid_in
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_in_d1 <= 0;
            valid_in_d2 <= 0;
        end else begin
            valid_in_d1 <= valid_in;
            valid_in_d2 <= valid_in_d1;
        end
    end
    assign valid_out = valid_in_d2;

    // track expected addresses from Python model
    // for N=8 equivalent check first few values manually
    int expected_addrA, expected_addrB, expected_k;

    // monitor — print every butterfly operation
    always @(posedge clk) begin
        if (valid_in) begin
            $display("stage=%0d bf=%0d | addrA=%0d addrB=%0d twiddle=%0d | weA=%0d weB=%0d",
                dut.stage_cnt,
                dut.bf_cnt,
                addrA,
                addrB,
                twiddle_addr,
                weA,
                weB
            );
        end
    end

    initial begin
        $dumpfile("tb_controller.vcd");
        $dumpvars(0, tb_controller);
        clk = 0;
        rst = 1;
        start = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // check idle
        @(posedge clk);
        $display("Test 1");
        $display("valid_in=%0d (expect 0)", valid_in);
        $display("done=%0d (expect 0)", done);
        $display("weA=%0d weB=%0d (expect 0 0)", weA, weB);

        // check start and transition to compute state
        @(posedge clk);
        start = 1;
        @(posedge clk);
        @(posedge clk);
        start = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $display("Test 2");
        $display("valid_in=%0d (expect 1)", valid_in);
        $display("stage_cnt=%0d (expect 0)", dut.stage_cnt);
        $display("bf_cnt=%0d (expect 0)", dut.bf_cnt);
        $display("valid_in_d1=%0d valid_in_d2=%0d", valid_in_d1, valid_in_d2);

        // address pair check
        $display("Test 3");
        repeat(4) begin
            @(posedge clk);
            $display("  bf=%0d addrA=%0d addrB=%0d k=%0d",
                dut.bf_cnt, addrA, addrB, twiddle_addr);
        end

        // done check
        $display("Test 4");
        wait(done == 1);
        $display("done=1 received");
        $display("stage_cnt=%0d (expect 0, reset after done)", dut.stage_cnt);
        $display("bf_cnt=%0d (expect 0, reset after done)", dut.bf_cnt);

        // idle return check
        @(posedge clk);
        $display("Test 5");
        $display("valid_in=%0d (expect 0)", valid_in);
        $display("done=%0d (expect 0)", done);

        $finish;
    end
    initial begin
        #500000;  // timeout after 500000ns
        $display("TIMEOUT");
        $finish;
    end

endmodule