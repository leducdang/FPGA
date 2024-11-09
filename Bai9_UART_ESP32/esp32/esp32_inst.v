	esp32 u0 (
		.clk_clk       (<connected-to-clk_clk>),       //   clk.clk
		.reset_reset_n (<connected-to-reset_reset_n>), // reset.reset_n
		.rs232_RXD     (<connected-to-rs232_RXD>),     // rs232.RXD
		.rs232_TXD     (<connected-to-rs232_TXD>),     //      .TXD
		.led1_export   (<connected-to-led1_export>),   //  led1.export
		.led2_export   (<connected-to-led2_export>),   //  led2.export
		.led3_export   (<connected-to-led3_export>)    //  led3.export
	);

