
module led_blink (
	button_export,
	clk_clk,
	lcd1602_DATA,
	lcd1602_ON,
	lcd1602_BLON,
	lcd1602_EN,
	lcd1602_RS,
	lcd1602_RW,
	led_out_export,
	reset_reset_n);	

	input		button_export;
	input		clk_clk;
	inout	[7:0]	lcd1602_DATA;
	output		lcd1602_ON;
	output		lcd1602_BLON;
	output		lcd1602_EN;
	output		lcd1602_RS;
	output		lcd1602_RW;
	output	[7:0]	led_out_export;
	input		reset_reset_n;
endmodule
