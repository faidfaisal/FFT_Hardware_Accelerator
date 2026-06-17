
module controller #(
    parameter N = 1024,
    parameter DEPTH = N/2,
    parameter ABITS = $clog2(N), //address bits
    parameter WIDTH = 16,
    parameter LOG2N = $clog2(N), //stages of the FFT
    parameter twiddle_bits = $clog2(DEPTH) //bits needed to index twiddle factors
)(
    input logic clk,
    input logic rst,
    input logic valid_out,
    output logic [ABITS-1:0]  addrA,
    output logic [ABITS-1:0]  addrB,
    output logic [twiddle_bits-1:0] twiddle_addr, // 9 bits for 512 twiddle entries
    output logic weA, // write enable port A
    output logic weB, // write enable port B
    output logic valid_in, // tells butterfly when inputs are ready
    input  logic start, // tells controller to begin
    output logic done // tells top level FFT is complete
);
    logic [LOG2N-1:0]  stage_cnt; // which stage we're on (0 to 9)
    logic [ABITS-1:0]  bf_cnt; // which butterfly pair (0 to 511)
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        COMPUTE = 2'b01,
        OUTPUT  = 2'b10
    } state_t;
    logic [ABITS-1:0] span;
    logic [ABITS-1:0] j;
    logic [ABITS-1:0] group_start;
    state_t state;

    always_comb begin
        span = 10'd1 << stage_cnt; // 2^stage
        j = bf_cnt % span;
        group_start = (bf_cnt/span) * (span << 1); // (bf_cnt/span) * (2*span)
        addrA = group_start + j;
        addrB = group_start + j + span;
        twiddle_addr = j * (N/(span<<1)); // j * 512 >> stage_cnt
        weA = valid_out;
        weB = valid_out;
        valid_in = (sta
        te == COMPUTE);
    end

    always_ff @(posedge clk)begin
        if (rst) begin
            state <= IDLE;
            stage_cnt <= 0;
            bf_cnt <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= COMPUTE;
                        stage_cnt <= 0;
                        bf_cnt <= 0;
                    end
                end
                COMPUTE: begin
                    // increment butterfly counter
                    if (bf_cnt == (N/2) - 1) begin
                        bf_cnt <= 0;
                        // last stage done → go to output
                        if (stage_cnt == LOG2N - 1) begin
                            state <= OUTPUT;
                        end else begin
                            stage_cnt <= stage_cnt + 1;
                        end
                    end else begin
                        bf_cnt <= bf_cnt + 1;
                    end
                end
                OUTPUT: begin
                    // read results sequentially
                    done <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule