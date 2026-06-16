`timescale 1ns/1ps

module tb_butterfly;

    logic clk;
    logic rst;
    logic valid_in;
    logic valid_out;

    logic signed [15:0] ar, ai, br, bi, wr, wi;
    logic signed [15:0] ar_out, ai_out, br_out, bi_out;

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

    always #5 clk = ~clk;

    // Convert real -> Q1.15
    function automatic signed [15:0] q15(input real x);
        q15 = $rtoi(x * 32768.0);
    endfunction

    // Convert Q1.15 -> real
    function automatic real q15_to_real(input signed [15:0] x);
        q15_to_real = x / 32768.0;
    endfunction

    // Print inputs and outputs
    task automatic print_results(input string name);
        begin
            $display("%s", name);

            $display("INPUTS:");
            $display("A = %0d + j%0d   (%f + j%f)",
                     ar, ai,
                     q15_to_real(ar), q15_to_real(ai));

            $display("B = %0d + j%0d   (%f + j%f)",
                     br, bi,
                     q15_to_real(br), q15_to_real(bi));

            $display("W = %0d + j%0d   (%f + j%f)",
                     wr, wi,
                     q15_to_real(wr), q15_to_real(wi));

            $display("");

            $display("OUTPUTS:");
            $display("Y0 = %0d + j%0d   (%f + j%f)",
                     ar_out, ai_out,
                     q15_to_real(ar_out), q15_to_real(ai_out));

            $display("Y1 = %0d + j%0d   (%f + j%f)",
                     br_out, bi_out,
                     q15_to_real(br_out), q15_to_real(bi_out));

            $display("valid_out = %0d", valid_out);
        end
    endtask

    initial begin

        clk = 0;
        rst = 1;
        valid_in = 0;

        ar = 0;
        ai = 0;
        br = 0;
        bi = 0;
        wr = 0;
        wi = 0;

        #20;
        rst = 0;

        //--------------------------------------------------
        // TEST 1
        //--------------------------------------------------
        @(negedge clk);

        ar = q15(0.5);
        ai = q15(0.25);

        br = q15(0.25);
        bi = q15(0.125);

        wr = 16'sh7FFF;     // ~1.0
        wi = q15(0.0);

        valid_in = 1;

        @(posedge valid_out);
        #1;
        print_results("TEST 1");

        //--------------------------------------------------
        // TEST 2
        //--------------------------------------------------
        @(negedge clk);

        ar = q15(0.75);
        ai = q15(0.25);

        br = q15(0.125);
        bi = q15(0.0625);

        wr = 16'sh7FFF;
        wi = q15(0.0);

        valid_in = 1;

        @(posedge valid_out);
        #1;
        print_results("TEST 2");

        @(negedge clk);
        valid_in = 0;

        #50;
        $finish;
    end

endmodule
