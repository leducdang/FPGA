
module I2C (
	clk_clk,
	i2c_sda_in,
	i2c_scl_in,
	i2c_sda_oe,
	i2c_scl_oe,
	led1_export,
	led2_export,
	led3_export,
	led4_export,
	led5_export,
	led6_export,
	reset_reset_n,
	rs232_RXD,
	rs232_TXD);	

	input		clk_clk;
	input		i2c_sda_in;
	input		i2c_scl_in;
	output		i2c_sda_oe;
	output		i2c_scl_oe;
	output	[6:0]	led1_export;
	output	[6:0]	led2_export;
	output	[6:0]	led3_export;
	output	[6:0]	led4_export;
	output	[6:0]	led5_export;
	output	[6:0]	led6_export;
	input		reset_reset_n;
	input		rs232_RXD;
	output		rs232_TXD;
endmodule
