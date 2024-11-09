	led_blink u0 (
		.button_export  (<connected-to-button_export>),  //  button.export
		.clk_clk        (<connected-to-clk_clk>),        //     clk.clk
		.lcd1602_DATA   (<connected-to-lcd1602_DATA>),   // lcd1602.DATA
		.lcd1602_ON     (<connected-to-lcd1602_ON>),     //        .ON
		.lcd1602_BLON   (<connected-to-lcd1602_BLON>),   //        .BLON
		.lcd1602_EN     (<connected-to-lcd1602_EN>),     //        .EN
		.lcd1602_RS     (<connected-to-lcd1602_RS>),     //        .RS
		.lcd1602_RW     (<connected-to-lcd1602_RW>),     //        .RW
		.led_out_export (<connected-to-led_out_export>), // led_out.export
		.reset_reset_n  (<connected-to-reset_reset_n>)   //   reset.reset_n
	);

