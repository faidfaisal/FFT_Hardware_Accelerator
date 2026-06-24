`timescale 1ns/1ps

module tb_fft_top;

    parameter N = 8;

    logic clk;
    logic rst;
    logic start;
    logic done;

    fft_top #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );

    always #5 clk = ~clk;

    function automatic signed [15:0] q15(input real x);
        q15 = $rtoi(x * 32768.0);
    endfunction

    function automatic real q15_to_real(input signed [15:0] x);
        q15_to_real = x / 32768.0;
    endfunction

    function automatic [31:0] pack_complex(
        input signed [15:0] real_part,
        input signed [15:0] imag_part
    );
        pack_complex = {real_part, imag_part};
    endfunction

    integer i;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        #20;
        rst = 0;

    dut.bram_inst.bram[0] = pack_complex(q15( 0.125),  q15(0.0)); // x[0]
    dut.bram_inst.bram[4] = pack_complex(q15(-0.0625), q15(0.0)); // x[1]
    dut.bram_inst.bram[2] = pack_complex(q15( 0.25),   q15(0.0)); // x[2]
    dut.bram_inst.bram[6] = pack_complex(q15( 0.0),    q15(0.0)); // x[3]
    dut.bram_inst.bram[1] = pack_complex(q15(-0.125),  q15(0.0)); // x[4]
    dut.bram_inst.bram[5] = pack_complex(q15( 0.1875), q15(0.0)); // x[5]
    dut.bram_inst.bram[3] = pack_complex(q15(-0.25),   q15(0.0)); // x[6]
    dut.bram_inst.bram[7] = pack_complex(q15( 0.0625), q15(0.0)); // x[7]

        @(posedge clk);
        start = 1;

        @(posedge clk);
        start = 0;

        #20;
        @(posedge done);
        $display("\nFFT DONE\n");

        for (i = 0; i < N; i = i + 1) begin
            $display("mem[%0d] = %f + j%f",
                i,
                q15_to_real(dut.bram_inst.bram[i][31:16]),
                q15_to_real(dut.bram_inst.bram[i][15:0])
            );
        end

        #20;
        $finish;
    end

    always @(posedge clk) begin
        $display(
            "t=%0t state=%0d stage=%0d bf=%0d start=%0d done=%0d vin=%0d vout=%0d addrA=%0d addrB=%0d tw=%0d weA=%0d weB=%0d",
            $time,
            dut.controller_inst.state,
            dut.controller_inst.stage_cnt,
            dut.controller_inst.bf_cnt,
            start,
            done,
            dut.valid_in,
            dut.valid_out,
            dut.addrA,
            dut.addrB,
            dut.twiddle_addr,
            dut.weA,
            dut.weB
        );
        $display("wr=%0d wi=%0d", dut.wr, dut.wi);
        $display("t=%0t weA=%0d dataA=%f+j%f dataB=%f+j%f",
            $time, dut.weA,
            q15_to_real(dut.data_inA[31:16]),
            q15_to_real(dut.data_inA[15:0]),
            q15_to_real(dut.data_inB[31:16]),
            q15_to_real(dut.data_inB[15:0])
        );
        $display("addrA_bram=%0d addrB_bram=%0d", 
            dut.bram_inst.addrA, 
            dut.bram_inst.addrB
        );
        $display("ar=%f ai=%f br=%f bi=%f wb_real=%f ar_out=%f br_out=%f",
            q15_to_real(dut.ar),
            q15_to_real(dut.ai),
            q15_to_real(dut.br),
            q15_to_real(dut.bi),
            q15_to_real(dut.butterfly_inst.wb_real),
            q15_to_real(dut.ar_out),
            q15_to_real(dut.br_out)
        );
    end

endmodule
