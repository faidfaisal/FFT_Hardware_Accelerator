`timescale 1ns/1ps

module controller #(
    parameter N = 1024,
    parameter ABITS = $clog2(N),
    parameter LOG2N = $clog2(N),
    parameter twiddle_bits = $clog2(N/2)
)(
    input  logic clk,
    input  logic rst,
    input  logic valid_out,

    output logic [ABITS-1:0] addrA,
    output logic [ABITS-1:0] addrB,
    output logic [twiddle_bits-1:0] twiddle_addr,

    output logic weA,
    output logic weB,
    output logic valid_in,

    input  logic start,
    output logic done
);

    typedef enum logic [2:0] {
        IDLE,
        SETUP,
        EXEC,
        WRITE,
        FINISH
    } state_t;

    state_t state;

    logic [LOG2N-1:0] stage_cnt;
    logic [ABITS-1:0] bf_cnt;

    int span;
    int j;
    int group_start;
    int tw;

    always_comb begin
        span = 1 << stage_cnt;
        j = bf_cnt % span;
        group_start = (bf_cnt / span) * (span * 2);
        tw = j * (N / (span * 2));
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            stage_cnt <= 0;
            bf_cnt <= 0;
            addrA <= 0;
            addrB <= 1;
            twiddle_addr <= 0;
            valid_in <= 0;
            weA <= 0;
            weB <= 0;
            done <= 0;
        end else begin
            valid_in <= 0;
            weA <= 0;
            weB <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        done <= 0;
                        stage_cnt <= 0;
                        bf_cnt <= 0;
                        state <= SETUP;
                    end
                end

                SETUP: begin
                    addrA <= group_start + j;
                    addrB <= group_start + j + span;
                    twiddle_addr <= tw[twiddle_bits-1:0];
                    state <= EXEC;
                end

                EXEC: begin
                    valid_in <= 1;
                    state <= WRITE;
                end

                WRITE: begin
                    weA <= 1;
                    weB <= 1;

                    if (bf_cnt == (N/2)-1) begin
                        bf_cnt <= 0;

                        if (stage_cnt == LOG2N-1) begin
                            state <= FINISH;
                        end else begin
                            stage_cnt <= stage_cnt + 1;
                            state <= SETUP;
                        end
                    end else begin
                        bf_cnt <= bf_cnt + 1;
                        state <= SETUP;
                    end
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
