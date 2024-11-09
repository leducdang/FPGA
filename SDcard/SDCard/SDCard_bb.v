
module SDCard (
	clk_clk,
	reset_reset_n,
	sdcard_b_SD_cmd,
	sdcard_b_SD_dat,
	sdcard_b_SD_dat3,
	sdcard_o_SD_clock);	

	input		clk_clk;
	input		reset_reset_n;
	inout		sdcard_b_SD_cmd;
	inout		sdcard_b_SD_dat;
	inout		sdcard_b_SD_dat3;
	output		sdcard_o_SD_clock;
endmodule
