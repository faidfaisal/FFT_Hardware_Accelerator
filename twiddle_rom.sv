
module twiddle_rom #(
    parameter N = 1024,
    parameter DEPTH = N/2,
    parameter ABITS = 9, //address bits
    parameter WIDTH = 16 //width of the twiddle factor in bits
)(
    input logic clk,
    input logic [ABITS-1:0] addr,
    output logic signed [WIDTH-1:0] wr,
    output logic signed [WIDTH-1:0] wi
);
    logic signed [WIDTH-1:0] rom_real[0:DEPTH-1];
    logic signed [WIDTH-1:0] rom_imag[0:DEPTH-1];

    initial begin
        $readmemh("twiddle_real.hex", rom_real);
        $readmemh("twiddle_imag.hex", rom_imag);
    end

    always_ff @(posedge clk)begin
        wr<=rom_real[addr];
        wi<=rom_imag[addr];
    end

endmodule