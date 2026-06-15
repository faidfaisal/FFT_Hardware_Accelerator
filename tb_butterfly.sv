`timescale 1ns/1ps

module tb_butterfly;

    // Clock and control
    logic clk;
    logic rst;
    logic valid_in;
    logic valid_out;

    // Butterfly inputs
    logic signed [15:0] ar;
    logic signed [15:0] ai;
    logic signed [15:0] br;
    logic signed [15:0] bi;
    logic signed [15:0] wr;
    logic signed [15:0] wi;

    // Butterfly outputs
    logic signed [15:0] ar_out;
    logic signed [15:0] ai_out;
    logic signed [15:0] br_out;
    logic signed [15:0] bi_out;

    // Instantiate DUT (Device Under Test)
    butterfly dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),

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

    // Generate clock
    always #5 clk = ~clk;

    initial begin

        // Initialize signals
        clk = 0;
        rst = 1;
        valid_in = 0;

        ar = 0;
        ai = 0;
        br = 0;
        bi = 0;
        wr = 0;
        wi = 0;

        // Hold reset
        #20;
        rst = 0;

        // A = 5 + j2
        // B = 3 + j1
        // W = 1 + j0

        ar = 5;
        ai = 2;

        br = 3;
        bi = 1;

        wr = 32767;  // Q1.15 representation of 1.0
        wi = 0;

        valid_in = 1;

        #20;

        $display("TEST 1");
        $display("A = %0d + j%0d", ar, ai);
        $display("B = %0d + j%0d", br, bi);

        $display("Output 1 = %0d + j%0d",
                 ar_out, ai_out);

        $display("Output 2 = %0d + j%0d",
                 br_out, bi_out);

        // A = 10 + j4
        // B = 2 + j1
        // W = 1 + j0

        ar = 10;
        ai = 4;

        br = 2;
        bi = 1;

        wr = 32767;
        wi = 0;

        #20;

        $display("TEST 2");

        $display("Output 1 = %0d + j%0d",
                 ar_out, ai_out);

        $display("Output 2 = %0d + j%0d",
                 br_out, bi_out);

        #20;

        $finish;
    end

endmodule
