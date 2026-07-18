
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
        case (N)
8:       begin
            $readmemh(
                "D:/FFT_Accelerator/FFT_Accelerator/FFT_Accelerator.srcs/sources_1/new/twiddle_real8.hex",
                rom_real
            );
        
            $readmemh(
                "D:/FFT_Accelerator/FFT_Accelerator/FFT_Accelerator.srcs/sources_1/new/twiddle_imag8.hex",
                rom_imag
            );
            end
            16: begin
                $readmemh("twiddle_real16.hex",   rom_real);
                $readmemh("twiddle_imag16.hex",   rom_imag);
            end
            32: begin
                $readmemh("twiddle_real32.hex",   rom_real);
                $readmemh("twiddle_imag32.hex",   rom_imag);
            end
            64: begin
                $readmemh("twiddle_real64.hex",   rom_real);
                $readmemh("twiddle_imag64.hex",   rom_imag);
            end
            128: begin
                $readmemh("twiddle_real128.hex",  rom_real);
                $readmemh("twiddle_imag128.hex",  rom_imag);
            end
            256: begin
                $readmemh("twiddle_real256.hex",  rom_real);
                $readmemh("twiddle_imag256.hex",  rom_imag);
            end
            512: begin
                $readmemh("twiddle_real512.hex",  rom_real);
                $readmemh("twiddle_imag512.hex",  rom_imag);
            end
        1024: begin
                $readmemh(
                    "D:/FFT_Accelerator/FFT_Accelerator/FFT_Accelerator.srcs/sources_1/new/twiddle_real1024.hex",
                    rom_real
                );
            
                $readmemh(
                    "D:/FFT_Accelerator/FFT_Accelerator/FFT_Accelerator.srcs/sources_1/new/twiddle_imag1024.hex",
                    rom_imag
                );
            end
            default: $display("ERROR: unsupported N=%0d", N);
        endcase
    end

    always_ff @(posedge clk)begin
        wr<=rom_real[addr];
        wi<=rom_imag[addr];
    end

endmodule
