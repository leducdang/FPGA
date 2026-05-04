module fifo_reader (
    input  wire        clk_read,       // clock phía đọc FIFO
    input  wire        reset_n,

    // tick lấy mẫu, ví dụ 16kHz hoặc 48kHz
    input  wire        sample_clk,

    // Avalon-ST source từ FIFO
    input  wire [31:0] fifo_out_data,
    input  wire        fifo_out_valid,
    output reg         fifo_out_ready,

    // dữ liệu đã đọc ra
    output reg [31:0]  sample_reg,
	 output  [15:0]  sample_l,
	 output  [15:0]  sample_r,
    output reg         sample_valid
);


	assign sample_l = sample_reg[15:0];
	assign sample_r = sample_reg[31:16];
	
	
    reg sample_clk_d;

    wire sample_rise;
    assign sample_rise = (~sample_clk_d) & sample_clk;

    always @(posedge clk_read or negedge reset_n) begin
        if (!reset_n) begin
            sample_clk_d   <= 1'b0;
            fifo_out_ready <= 1'b0;
            sample_reg     <= 32'd0;
            sample_valid   <= 1'b0;
        end
        else begin
            sample_clk_d   <= sample_clk;
            fifo_out_ready <= 1'b0;
            sample_valid   <= 1'b0;

            // tới thời điểm cần lấy mẫu mới
            if (sample_rise) begin
                if (fifo_out_valid) begin
                    fifo_out_ready <= 1'b1;
                    sample_reg     <= fifo_out_data;
                    sample_valid   <= 1'b1;
                end
            end
        end
    end

endmodule