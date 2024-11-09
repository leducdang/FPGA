
module I2C (
	clk_clk,
	i2c_sda_in,
	i2c_scl_in,
	i2c_sda_oe,
	i2c_scl_oe,
	reset_reset_n,
	led6_export,
	led5_export,
	led4_export,
	led3_export,
	led2_export,
	led1_export);	

	input		clk_clk;
	input		i2c_sda_in;
	input		i2c_scl_in;
	output		i2c_sda_oe;
	output		i2c_scl_oe;
	input		reset_reset_n;
	output	[6:0]	led6_export;
	output	[6:0]	led5_export;
	output	[6:0]	led4_export;
	output	[6:0]	led3_export;
	output	[6:0]	led2_export;
	output	[6:0]	led1_export;
endmodule
