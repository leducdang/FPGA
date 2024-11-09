	uart u0 (
		.clk_clk       (<connected-to-clk_clk>),       //   clk.clk
		.led_export    (<connected-to-led_export>),    //   led.export
		.reset_reset_n (<connected-to-reset_reset_n>), // reset.reset_n
		.rs232_rxd     (<connected-to-rs232_rxd>),     // rs232.rxd
		.rs232_txd     (<connected-to-rs232_txd>)      //      .txd
	);

