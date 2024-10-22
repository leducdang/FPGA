	sdram u0 (
		.wire_addr             (<connected-to-wire_addr>),             //      wire.addr
		.wire_ba               (<connected-to-wire_ba>),               //          .ba
		.wire_cas_n            (<connected-to-wire_cas_n>),            //          .cas_n
		.wire_cke              (<connected-to-wire_cke>),              //          .cke
		.wire_cs_n             (<connected-to-wire_cs_n>),             //          .cs_n
		.wire_dq               (<connected-to-wire_dq>),               //          .dq
		.wire_dqm              (<connected-to-wire_dqm>),              //          .dqm
		.wire_ras_n            (<connected-to-wire_ras_n>),            //          .ras_n
		.wire_we_n             (<connected-to-wire_we_n>),             //          .we_n
		.sdram_clk_clk         (<connected-to-sdram_clk_clk>),         // sdram_clk.clk
		.clk_clk               (<connected-to-clk_clk>),               //       clk.clk
		.reset_reset           (<connected-to-reset_reset>),           //     reset.reset
		.sdram_1_address       (<connected-to-sdram_1_address>),       //   sdram_1.address
		.sdram_1_byteenable_n  (<connected-to-sdram_1_byteenable_n>),  //          .byteenable_n
		.sdram_1_chipselect    (<connected-to-sdram_1_chipselect>),    //          .chipselect
		.sdram_1_writedata     (<connected-to-sdram_1_writedata>),     //          .writedata
		.sdram_1_read_n        (<connected-to-sdram_1_read_n>),        //          .read_n
		.sdram_1_write_n       (<connected-to-sdram_1_write_n>),       //          .write_n
		.sdram_1_readdata      (<connected-to-sdram_1_readdata>),      //          .readdata
		.sdram_1_readdatavalid (<connected-to-sdram_1_readdatavalid>), //          .readdatavalid
		.sdram_1_waitrequest   (<connected-to-sdram_1_waitrequest>)    //          .waitrequest
	);

