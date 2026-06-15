`timescale 1ns/1ps

module tb_complex_mult;

    // Inputs to the multiplier
    logic signed [15:0] a_real;
    logic signed [15:0] a_imag;
    logic signed [15:0] b_real;
    logic signed [15:0] b_imag;

    // Outputs from the multiplier
    logic signed [31:0] p_real;
    logic signed [31:0] p_imag;

    // Instantiate your module
    complex_mult dut (
        .a_real(a_real),
        .a_imag(a_imag),
        .b_real(b_real),
        .b_imag(b_imag),
        .p_real(p_real),
        .p_imag(p_imag)
    );

    initial begin

        // Test Case 1
        // (3 + j2) * (4 + j5)

        a_real = 3;
        a_imag = 2;

        b_real = 4;
        b_imag = 5;

        #10;

        $display("TEST 1");
        $display("A = %0d + j%0d", a_real, a_imag);
        $display("B = %0d + j%0d", b_real, b_imag);
        $display("Result = %0d + j%0d", p_real, p_imag);

        // Test Case 2
        // (1 + j0) * (7 - j3)

        a_real = 1;
        a_imag = 0;

        b_real = 7;
        b_imag = -3;

        #10;

        $display("TEST 2");
        $display("A = %0d + j%0d", a_real, a_imag);
        $display("B = %0d + j%0d", b_real, b_imag);
        $display("Result = %0d + j%0d", p_real, p_imag);

        $finish;

    end

endmodule
