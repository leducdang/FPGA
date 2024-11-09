	uart u0 (
		.clk_clk       (<connected-to-clk_clk>),       //   clk.clk
		.reset_reset_n (<connected-to-reset_reset_n>), // reset.reset_n
		.rs232_rxd     (<connected-to-rs232_rxd>),     // rs232.rxd
		.rs232_txd     (<connected-to-rs232_txd>),     //      .txd
		.led1_export   (<connected-to-led1_export>),   //  led1.export
		.led2_export   (<connected-to-led2_export>)    //  led2.export
	);

