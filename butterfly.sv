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
    logic signed [15:0] wb_real;
    logic signed [15:0] wb_imag;
    complex_multi mult_inst(
        .ar(ar), .ai(ai),
        .br(br), .bi(bi),
        .wr(wr), .wi(wi),
        .wb_real(wb_real),
        .wb_imag(wb_imag)
    );
    always_ff @(posedge clk) begin
        if(rst) begin
            ar_out <= 0;
            ai_out <= 0;
            br_out <= 0;
            bi_out <= 0;
            valid_out <= 1;
        end else begin
            valid_out <= valid_in;
            ar_out <= ar + wb_real;
            ai_out <= ai + wb_imag;
            br_out <= ar - wb_real;
            bi_out <= ai - wb_imag;
        end
    end

endmodule