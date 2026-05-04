module fifo_read_test (
    input  wire        fifo_read_clk,
    input  wire        reset_n,
	 
	 input  wire [4:0]  bit_counter,
    input  wire [31:0] fifo_out_data,
    input  wire        fifo_out_valid,
    output reg         fifo_out_ready,

    output reg [31:0]  dbg_data,
	 output [15:0]		  sample_l,
	 output [15:0]		  sample_r,
    output reg [7:0]   dbg_count
);

assign sample_l = fifo_out_data[31:16];
assign sample_r = fifo_out_data[15:0];

    always @(posedge fifo_read_clk or negedge reset_n) begin
        if (!reset_n) begin
            fifo_out_ready <= 1'b0;
            dbg_data       <= 32'd0;
            dbg_count      <= 8'd0;
        end else begin
            // Luôn sẵn sàng đọc nếu có dữ liệu
            fifo_out_ready <= 1'b1;

            if (fifo_out_valid && fifo_out_ready &&(bit_counter == 0)) begin
                dbg_data  <= fifo_out_data;
                dbg_count <= dbg_count + 8'd1;
            end
        end
    end

endmodule

