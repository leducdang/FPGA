
module esp32 (
	clk_clk,
	reset_reset_n,
	rs232_RXD,
	rs232_TXD,
	led1_export,
	led2_export,
	led3_export);	

	input		clk_clk;
	input		reset_reset_n;
	input		rs232_RXD;
	output		rs232_TXD;
	output		led1_export;
	output		led2_export;
	output		led3_export;
endmodule
