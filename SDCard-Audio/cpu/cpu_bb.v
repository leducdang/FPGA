
module cpu (
	clk_clk,
	reset_reset_n,
	fifo_out_valid,
	fifo_out_data,
	fifo_out_channel,
	fifo_out_error,
	fifo_out_ready,
	fifo_read_clk_clk,
	sd_card_b_SD_cmd,
	sd_card_b_SD_dat,
	sd_card_b_SD_dat3,
	sd_card_o_SD_clock);	

	input		clk_clk;
	input		reset_reset_n;
	output		fifo_out_valid;
	output	[31:0]	fifo_out_data;
	output	[7:0]	fifo_out_channel;
	output	[7:0]	fifo_out_error;
	input		fifo_out_ready;
	input		fifo_read_clk_clk;
	inout		sd_card_b_SD_cmd;
	inout		sd_card_b_SD_dat;
	inout		sd_card_b_SD_dat3;
	output		sd_card_o_SD_clock;
endmodule
