module complex_mult (
    input  logic signed [15:0] a_real,
    input  logic signed [15:0] a_imag,

    input  logic signed [15:0] b_real,
    input  logic signed [15:0] b_imag,

    output logic signed [31:0] p_real,
    output logic signed [31:0] p_imag
);

    logic signed [31:0] ac;
    logic signed [31:0] bd;
    logic signed [31:0] ad;
    logic signed [31:0] bc;

    always_comb begin
        ac = a_real * b_real;
        bd = a_imag * b_imag;
        ad = a_real * b_imag;
        bc = a_imag * b_real;

        p_real = ac - bd;
        p_imag = ad + bc;
    end

endmodule