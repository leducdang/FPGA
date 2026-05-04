	cpu u0 (
		.clk_clk            (<connected-to-clk_clk>),            //           clk.clk
		.reset_reset_n      (<connected-to-reset_reset_n>),      //         reset.reset_n
		.fifo_out_valid     (<connected-to-fifo_out_valid>),     //      fifo_out.valid
		.fifo_out_data      (<connected-to-fifo_out_data>),      //              .data
		.fifo_out_channel   (<connected-to-fifo_out_channel>),   //              .channel
		.fifo_out_error     (<connected-to-fifo_out_error>),     //              .error
		.fifo_out_ready     (<connected-to-fifo_out_ready>),     //              .ready
		.fifo_read_clk_clk  (<connected-to-fifo_read_clk_clk>),  // fifo_read_clk.clk
		.sd_card_b_SD_cmd   (<connected-to-sd_card_b_SD_cmd>),   //       sd_card.b_SD_cmd
		.sd_card_b_SD_dat   (<connected-to-sd_card_b_SD_dat>),   //              .b_SD_dat
		.sd_card_b_SD_dat3  (<connected-to-sd_card_b_SD_dat3>),  //              .b_SD_dat3
		.sd_card_o_SD_clock (<connected-to-sd_card_o_SD_clock>)  //              .o_SD_clock
	);

