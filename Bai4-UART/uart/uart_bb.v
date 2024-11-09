
module uart (
	clk_clk,
	led_export,
	reset_reset_n,
	rs232_rxd,
	rs232_txd);	

	input		clk_clk;
	output		led_export;
	input		reset_reset_n;
	input		rs232_rxd;
	output		rs232_txd;
endmodule
