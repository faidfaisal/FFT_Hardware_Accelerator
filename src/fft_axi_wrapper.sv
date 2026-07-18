`timescale 1ns/1ps

module fft_axi_wrapper #(
    parameter N = 1024,
    parameter ABITS = $clog2(N),
    parameter DATA_WIDTH = 32
)(
    input  logic S_AXI_ACLK,
    input  logic S_AXI_ARESETN,

    input  logic [3:0]  S_AXI_AWADDR,
    input  logic        S_AXI_AWVALID,
    output logic        S_AXI_AWREADY,

    input  logic [31:0] S_AXI_WDATA,
    input  logic [3:0]  S_AXI_WSTRB,
    input  logic        S_AXI_WVALID,
    output logic        S_AXI_WREADY,

    output logic [1:0]  S_AXI_BRESP,
    output logic        S_AXI_BVALID,
    input  logic        S_AXI_BREADY,

    input  logic [3:0]  S_AXI_ARADDR,
    input  logic        S_AXI_ARVALID,
    output logic        S_AXI_ARREADY,

    output logic [31:0] S_AXI_RDATA,
    output logic [1:0]  S_AXI_RRESP,
    output logic        S_AXI_RVALID,
    input  logic        S_AXI_RREADY
);

    logic rst;
    logic start;
    logic done;

    logic [ABITS-1:0] cpu_addr;
    logic [DATA_WIDTH-1:0] cpu_wdata;
    logic [DATA_WIDTH-1:0] cpu_rdata;
    logic cpu_we;

    assign rst = ~S_AXI_ARESETN;

    fft_top #(
        .N(N)
    ) fft_inst (
        .clk(S_AXI_ACLK),
        .rst(rst),
        .start(start),
        .done(done),

        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_we(cpu_we),
        .cpu_rdata(cpu_rdata)
    );

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY  <= 0;
            S_AXI_BVALID  <= 0;
            S_AXI_BRESP   <= 2'b00;

            S_AXI_ARREADY <= 0;
            S_AXI_RVALID  <= 0;
            S_AXI_RRESP   <= 2'b00;
            S_AXI_RDATA   <= 0;

            start <= 0;
            cpu_addr <= 0;
            cpu_wdata <= 0;
            cpu_we <= 0;
        end else begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY  <= 0;
            S_AXI_ARREADY <= 0;

            start <= 0;
            cpu_we <= 0;

            if (S_AXI_AWVALID && S_AXI_WVALID && !S_AXI_BVALID) begin
                S_AXI_AWREADY <= 1;
                S_AXI_WREADY  <= 1;
                S_AXI_BVALID  <= 1;
                S_AXI_BRESP   <= 2'b00;

                case (S_AXI_AWADDR)
                    4'h0: begin
                        start <= S_AXI_WDATA[0];
                    end

                    4'h4: begin
                        cpu_addr <= S_AXI_WDATA[ABITS-1:0];
                    end

                    4'h8: begin
                        cpu_wdata <= S_AXI_WDATA;
                        cpu_we <= 1;
                    end

                    default: begin
                    end
                endcase
            end

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 0;
            end

            if (S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_ARREADY <= 1;
                S_AXI_RVALID  <= 1;
                S_AXI_RRESP   <= 2'b00;

                case (S_AXI_ARADDR)
                    4'h0: S_AXI_RDATA <= {30'd0, done, 1'b0};
                    4'h4: S_AXI_RDATA <= {{(32-ABITS){1'b0}}, cpu_addr};
                    4'h8: S_AXI_RDATA <= cpu_wdata;
                    4'hC: S_AXI_RDATA <= cpu_rdata;
                    default: S_AXI_RDATA <= 32'd0;
                endcase
            end

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 0;
            end
        end
    end

endmodule
