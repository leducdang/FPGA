	I2C u0 (
		.clk_clk       (<connected-to-clk_clk>),       //   clk.clk
		.i2c_sda_in    (<connected-to-i2c_sda_in>),    //   i2c.sda_in
		.i2c_scl_in    (<connected-to-i2c_scl_in>),    //      .scl_in
		.i2c_sda_oe    (<connected-to-i2c_sda_oe>),    //      .sda_oe
		.i2c_scl_oe    (<connected-to-i2c_scl_oe>),    //      .scl_oe
		.reset_reset_n (<connected-to-reset_reset_n>), // reset.reset_n
		.led6_export   (<connected-to-led6_export>),   //  led6.export
		.led5_export   (<connected-to-led5_export>),   //  led5.export
		.led4_export   (<connected-to-led4_export>),   //  led4.export
		.led3_export   (<connected-to-led3_export>),   //  led3.export
		.led2_export   (<connected-to-led2_export>),   //  led2.export
		.led1_export   (<connected-to-led1_export>)    //  led1.export
	);

