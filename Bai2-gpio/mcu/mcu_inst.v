	mcu u0 (
		.clk_clk        (<connected-to-clk_clk>),        //     clk.clk
		.reset_reset_n  (<connected-to-reset_reset_n>),  //   reset.reset_n
		.led_don_export (<connected-to-led_don_export>), // led_don.export
		.o_reg_export   (<connected-to-o_reg_export>),   //   o_reg.export
		.sw_reg_export  (<connected-to-sw_reg_export>),  //  sw_reg.export
		.bt_export      (<connected-to-bt_export>)       //      bt.export
	);

