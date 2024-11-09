
module mcu (
	clk_clk,
	reset_reset_n,
	led_don_export,
	o_reg_export,
	sw_reg_export,
	bt_export);	

	input		clk_clk;
	input		reset_reset_n;
	output		led_don_export;
	output	[7:0]	o_reg_export;
	input	[2:0]	sw_reg_export;
	input		bt_export;
endmodule
