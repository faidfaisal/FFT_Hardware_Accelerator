module butterfly (
    input logic clk,
    input logic valid_in,
    input logic rst,
    input  logic signed [15:0] ar,
    input  logic signed [15:0] ai,
    input  logic signed [15:0] br,
    input  logic signed [15:0] bi,
    input logic signed [15:0] wr,
    input logic signed [15:0] wi,

    output logic valid_out,
    output logic signed [15:0] ar_out,
    output logic signed [15:0] ai_out,
    output logic signed [15:0] br_out,
    output logic signed [15:0] bi_out
);
    logic signed [31:0] wb_real_full;
    logic signed [31:0] wb_imag_full;
    logic signed [15:0] wb_real;
    logic signed [15:0] wb_imag;
    complex_mult mult_inst(
        .a_real(br), .a_imag(bi),
        .b_real(wr), .b_imag(wi),
        .p_real(wb_real_full),
        .p_imag(wb_imag_full)
    );

    assign wb_real = wb_real_full[30:15];
    assign wb_imag = wb_imag_full[30:15];

    always_ff @(posedge clk) begin
        if(rst) begin
            ar_out <= 0;
            ai_out <= 0;
            br_out <= 0;
            bi_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            ar_out <= ar + wb_real;
            ai_out <= ai + wb_imag;
            br_out <= ar - wb_real;
            bi_out <= ai - wb_imag;
        end
    end

endmodule
