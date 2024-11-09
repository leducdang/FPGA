
module uart (
	clk_clk,
	reset_reset_n,
	rs232_rxd,
	rs232_txd,
	led1_export,
	led2_export);	

	input		clk_clk;
	input		reset_reset_n;
	input		rs232_rxd;
	output		rs232_txd;
	output		led1_export;
	output		led2_export;
endmodule
