	sdram u0 (
		.phy_clk            (<connected-to-phy_clk>),            //           phy_clk.clk
		.reset_phy_clk_n    (<connected-to-reset_phy_clk_n>),    //         phy_reset.reset_n
		.status_cal_fail    (<connected-to-status_cal_fail>),    //            status.local_cal_fail
		.status_cal_success (<connected-to-status_cal_success>), //                  .local_cal_success
		.status_init_done   (<connected-to-status_init_done>),   //                  .local_init_done
		.global_reset_n     (<connected-to-global_reset_n>),     //      global_reset.reset_n
		.reset_request_n    (<connected-to-reset_request_n>),    //     reset_request.reset_n
		.local_ready        (<connected-to-local_ready>),        //               avl.waitrequest_n
		.local_write_req    (<connected-to-local_write_req>),    //                  .write
		.local_read_req     (<connected-to-local_read_req>),     //                  .read
		.local_address      (<connected-to-local_address>),      //                  .address
		.local_be           (<connected-to-local_be>),           //                  .byteenable
		.local_wdata        (<connected-to-local_wdata>),        //                  .writedata
		.local_size         (<connected-to-local_size>),         //                  .burstcount
		.local_burstbegin   (<connected-to-local_burstbegin>),   //                  .beginbursttransfer
		.local_rdata        (<connected-to-local_rdata>),        //                  .readdata
		.local_rdata_valid  (<connected-to-local_rdata_valid>),  //                  .readdatavalid
		.mem_addr           (<connected-to-mem_addr>),           //               mem.mem_a
		.mem_ba             (<connected-to-mem_ba>),             //                  .mem_ba
		.mem_cas_n          (<connected-to-mem_cas_n>),          //                  .mem_cas_n
		.mem_cke            (<connected-to-mem_cke>),            //                  .mem_cke
		.mem_clk            (<connected-to-mem_clk>),            //                  .mem_ck
		.mem_clk_n          (<connected-to-mem_clk_n>),          //                  .mem_ck_n
		.mem_cs_n           (<connected-to-mem_cs_n>),           //                  .mem_cs_n
		.mem_dm             (<connected-to-mem_dm>),             //                  .mem_dm
		.mem_dq             (<connected-to-mem_dq>),             //                  .mem_dq
		.mem_dqs            (<connected-to-mem_dqs>),            //                  .mem_dqs
		.mem_dqs_n          (<connected-to-mem_dqs_n>),          //                  .mem_dqs_n
		.mem_odt            (<connected-to-mem_odt>),            //                  .mem_odt
		.mem_ras_n          (<connected-to-mem_ras_n>),          //                  .mem_ras_n
		.mem_we_n           (<connected-to-mem_we_n>),           //                  .mem_we_n
		.aux_full_rate_clk  (<connected-to-aux_full_rate_clk>),  // aux_full_rate_clk.clk
		.aux_half_rate_clk  (<connected-to-aux_half_rate_clk>),  // aux_half_rate_clk.clk
		.pll_ref_clk        (<connected-to-pll_ref_clk>)         //       pll_ref_clk.clk
	);

