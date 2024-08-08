// ed_sim_ed_sim.v

// This file was auto-generated from alt_mem_if_civ_ddr2_tg_eds_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 22.1 915

`timescale 1 ps / 1 ps
module ed_sim_ed_sim (
		output wire [15:0] tg_pnf_pnf_per_bit,         // tg_pnf.pnf_per_bit
		output wire [15:0] tg_pnf_pnf_per_bit_persist  //       .pnf_per_bit_persist
	);

	wire         ref_clk_clk_clk;                       // ref_clk:clk -> [emif_ed:pll_ref_clk, global_reset:clk]
	wire         global_reset_reset_reset;              // global_reset:reset -> [emif_ed:global_reset_n, sim_checker:reset_n]
	wire         emif_ed_phy_clk_clk;                   // emif_ed:phy_clk -> sim_checker:clk
	wire         emif_ed_tg_status_fail;                // emif_ed:tg_status_fail -> sim_checker:fail
	wire         emif_ed_tg_status_pass;                // emif_ed:tg_status_pass -> sim_checker:pass
	wire         emif_ed_tg_status_test_complete;       // emif_ed:tg_status_test_complete -> sim_checker:test_complete
	wire         emif_ed_emif_status_local_cal_fail;    // emif_ed:status_cal_fail -> sim_checker:local_cal_fail
	wire         emif_ed_emif_status_local_init_done;   // emif_ed:status_init_done -> sim_checker:local_init_done
	wire         emif_ed_emif_status_local_cal_success; // emif_ed:status_cal_success -> sim_checker:local_cal_success
	wire         emif_ed_mem_mem_cas_n;                 // emif_ed:mem_cas_n -> mem_model:mem_cas_n
	wire   [1:0] emif_ed_mem_mem_ba;                    // emif_ed:mem_ba -> mem_model:mem_ba
	wire         emif_ed_mem_mem_we_n;                  // emif_ed:mem_we_n -> mem_model:mem_we_n
	wire         emif_ed_mem_mem_ck;                    // [] -> [emif_ed:mem_clk, mem_model:mem_ck]
	wire         emif_ed_mem_mem_dm;                    // emif_ed:mem_dm -> mem_model:mem_dm
	wire         emif_ed_mem_mem_dqs;                   // [] -> [emif_ed:mem_dqs, mem_model:mem_dqs]
	wire   [7:0] emif_ed_mem_mem_dq;                    // [] -> [emif_ed:mem_dq, mem_model:mem_dq]
	wire         emif_ed_mem_mem_cs_n;                  // emif_ed:mem_cs_n -> mem_model:mem_cs_n
	wire  [12:0] emif_ed_mem_mem_a;                     // emif_ed:mem_addr -> mem_model:mem_a
	wire         emif_ed_mem_mem_odt;                   // emif_ed:mem_odt -> mem_model:mem_odt
	wire         emif_ed_mem_mem_ras_n;                 // emif_ed:mem_ras_n -> mem_model:mem_ras_n
	wire         emif_ed_mem_mem_cke;                   // emif_ed:mem_cke -> mem_model:mem_cke
	wire         emif_ed_mem_mem_ck_n;                  // [] -> [emif_ed:mem_clk_n, mem_model:mem_ck_n]

	ed_sim_ed_sim_emif_ed emif_ed (
		.phy_clk                 (emif_ed_phy_clk_clk),                   //      phy_clk.clk
		.pll_ref_clk             (ref_clk_clk_clk),                       //  pll_ref_clk.clk
		.tg_status_pass          (emif_ed_tg_status_pass),                //    tg_status.pass
		.tg_status_fail          (emif_ed_tg_status_fail),                //             .fail
		.tg_status_test_complete (emif_ed_tg_status_test_complete),       //             .test_complete
		.status_cal_fail         (emif_ed_emif_status_local_cal_fail),    //  emif_status.local_cal_fail
		.status_cal_success      (emif_ed_emif_status_local_cal_success), //             .local_cal_success
		.status_init_done        (emif_ed_emif_status_local_init_done),   //             .local_init_done
		.mem_addr                (emif_ed_mem_mem_a),                     //          mem.mem_a
		.mem_ba                  (emif_ed_mem_mem_ba),                    //             .mem_ba
		.mem_cas_n               (emif_ed_mem_mem_cas_n),                 //             .mem_cas_n
		.mem_cke                 (emif_ed_mem_mem_cke),                   //             .mem_cke
		.mem_clk                 (emif_ed_mem_mem_ck),                    //             .mem_ck
		.mem_clk_n               (emif_ed_mem_mem_ck_n),                  //             .mem_ck_n
		.mem_cs_n                (emif_ed_mem_mem_cs_n),                  //             .mem_cs_n
		.mem_dm                  (emif_ed_mem_mem_dm),                    //             .mem_dm
		.mem_dq                  (emif_ed_mem_mem_dq),                    //             .mem_dq
		.mem_dqs                 (emif_ed_mem_mem_dqs),                   //             .mem_dqs
		.mem_dqs_n               (),                                      //             .mem_dqs_n
		.mem_odt                 (emif_ed_mem_mem_odt),                   //             .mem_odt
		.mem_ras_n               (emif_ed_mem_mem_ras_n),                 //             .mem_ras_n
		.mem_we_n                (emif_ed_mem_mem_we_n),                  //             .mem_we_n
		.pnf_per_bit             (tg_pnf_pnf_per_bit),                    //       tg_pnf.pnf_per_bit
		.pnf_per_bit_persist     (tg_pnf_pnf_per_bit_persist),            //             .pnf_per_bit_persist
		.global_reset_n          (global_reset_reset_reset)               // global_reset.reset_n
	);

	altera_mem_if_checker_no_ifdef_params #(
		.ENABLE_VCDPLUS          (0),
		.CONTINUE_AFTER_CAL_FAIL (0)
	) sim_checker (
		.clk                  (emif_ed_phy_clk_clk),                   //   avl_clock.clk
		.reset_n              (global_reset_reset_reset),              //   avl_reset.reset_n
		.test_complete        (emif_ed_tg_status_test_complete),       //  drv_status.test_complete
		.fail                 (emif_ed_tg_status_fail),                //            .fail
		.pass                 (emif_ed_tg_status_pass),                //            .pass
		.local_init_done      (emif_ed_emif_status_local_init_done),   // emif_status.local_init_done
		.local_cal_success    (emif_ed_emif_status_local_cal_success), //            .local_cal_success
		.local_cal_fail       (emif_ed_emif_status_local_cal_fail),    //            .local_cal_fail
		.test_complete_1      (1'b1),                                  // (terminated)
		.fail_1               (1'b0),                                  // (terminated)
		.pass_1               (1'b1),                                  // (terminated)
		.local_init_done_1    (1'b1),                                  // (terminated)
		.local_cal_success_1  (1'b1),                                  // (terminated)
		.local_cal_fail_1     (1'b0),                                  // (terminated)
		.test_complete_2      (1'b1),                                  // (terminated)
		.fail_2               (1'b0),                                  // (terminated)
		.pass_2               (1'b1),                                  // (terminated)
		.local_init_done_2    (1'b1),                                  // (terminated)
		.local_cal_success_2  (1'b1),                                  // (terminated)
		.local_cal_fail_2     (1'b0),                                  // (terminated)
		.test_complete_3      (1'b1),                                  // (terminated)
		.fail_3               (1'b0),                                  // (terminated)
		.pass_3               (1'b1),                                  // (terminated)
		.local_init_done_3    (1'b1),                                  // (terminated)
		.local_cal_success_3  (1'b1),                                  // (terminated)
		.local_cal_fail_3     (1'b0),                                  // (terminated)
		.test_complete_4      (1'b1),                                  // (terminated)
		.fail_4               (1'b0),                                  // (terminated)
		.pass_4               (1'b1),                                  // (terminated)
		.local_init_done_4    (1'b1),                                  // (terminated)
		.local_cal_success_4  (1'b1),                                  // (terminated)
		.local_cal_fail_4     (1'b0),                                  // (terminated)
		.test_complete_5      (1'b1),                                  // (terminated)
		.fail_5               (1'b0),                                  // (terminated)
		.pass_5               (1'b1),                                  // (terminated)
		.local_init_done_5    (1'b1),                                  // (terminated)
		.local_cal_success_5  (1'b1),                                  // (terminated)
		.local_cal_fail_5     (1'b0),                                  // (terminated)
		.test_complete_6      (1'b1),                                  // (terminated)
		.fail_6               (1'b0),                                  // (terminated)
		.pass_6               (1'b1),                                  // (terminated)
		.local_init_done_6    (1'b1),                                  // (terminated)
		.local_cal_success_6  (1'b1),                                  // (terminated)
		.local_cal_fail_6     (1'b0),                                  // (terminated)
		.test_complete_7      (1'b1),                                  // (terminated)
		.fail_7               (1'b0),                                  // (terminated)
		.pass_7               (1'b1),                                  // (terminated)
		.local_init_done_7    (1'b1),                                  // (terminated)
		.local_cal_success_7  (1'b1),                                  // (terminated)
		.local_cal_fail_7     (1'b0),                                  // (terminated)
		.test_complete_8      (1'b1),                                  // (terminated)
		.fail_8               (1'b0),                                  // (terminated)
		.pass_8               (1'b1),                                  // (terminated)
		.local_init_done_8    (1'b1),                                  // (terminated)
		.local_cal_success_8  (1'b1),                                  // (terminated)
		.local_cal_fail_8     (1'b0),                                  // (terminated)
		.test_complete_9      (1'b1),                                  // (terminated)
		.fail_9               (1'b0),                                  // (terminated)
		.pass_9               (1'b1),                                  // (terminated)
		.local_init_done_9    (1'b1),                                  // (terminated)
		.local_cal_success_9  (1'b1),                                  // (terminated)
		.local_cal_fail_9     (1'b0),                                  // (terminated)
		.test_complete_10     (1'b1),                                  // (terminated)
		.fail_10              (1'b0),                                  // (terminated)
		.pass_10              (1'b1),                                  // (terminated)
		.local_init_done_10   (1'b1),                                  // (terminated)
		.local_cal_success_10 (1'b1),                                  // (terminated)
		.local_cal_fail_10    (1'b0),                                  // (terminated)
		.test_complete_11     (1'b1),                                  // (terminated)
		.fail_11              (1'b0),                                  // (terminated)
		.pass_11              (1'b1),                                  // (terminated)
		.local_init_done_11   (1'b1),                                  // (terminated)
		.local_cal_success_11 (1'b1),                                  // (terminated)
		.local_cal_fail_11    (1'b0)                                   // (terminated)
	);

	alt_mem_if_ddr2_mem_model_top_mem_if_dm_pins_en #(
		.MEM_IF_ADDR_WIDTH            (13),
		.MEM_IF_ROW_ADDR_WIDTH        (13),
		.MEM_IF_COL_ADDR_WIDTH        (10),
		.MEM_IF_CS_PER_RANK           (1),
		.MEM_IF_CONTROL_WIDTH         (1),
		.MEM_IF_DQS_WIDTH             (1),
		.MEM_IF_CS_WIDTH              (1),
		.MEM_IF_BANKADDR_WIDTH        (2),
		.MEM_IF_DQ_WIDTH              (8),
		.MEM_IF_CK_WIDTH              (1),
		.MEM_IF_CLK_EN_WIDTH          (1),
		.MEM_TRCD                     (2),
		.MEM_TRTP                     (2),
		.MEM_DQS_TO_CLK_CAPTURE_DELAY (450),
		.MEM_CLK_TO_DQS_CAPTURE_DELAY (100000),
		.MEM_IF_ODT_WIDTH             (1),
		.MEM_MIRROR_ADDRESSING_DEC    (0),
		.MEM_REGDIMM_ENABLED          (0),
		.DEVICE_DEPTH                 (1),
		.MEM_GUARANTEED_WRITE_INIT    (0),
		.MEM_VERBOSE                  (0),
		.MEM_INIT_EN                  (0),
		.MEM_INIT_FILE                (""),
		.DAT_DATA_WIDTH               (32)
	) mem_model (
		.mem_a     (emif_ed_mem_mem_a),     // memory.mem_a
		.mem_ba    (emif_ed_mem_mem_ba),    //       .mem_ba
		.mem_ck    (emif_ed_mem_mem_ck),    //       .mem_ck
		.mem_ck_n  (emif_ed_mem_mem_ck_n),  //       .mem_ck_n
		.mem_cke   (emif_ed_mem_mem_cke),   //       .mem_cke
		.mem_cs_n  (emif_ed_mem_mem_cs_n),  //       .mem_cs_n
		.mem_dm    (emif_ed_mem_mem_dm),    //       .mem_dm
		.mem_ras_n (emif_ed_mem_mem_ras_n), //       .mem_ras_n
		.mem_cas_n (emif_ed_mem_mem_cas_n), //       .mem_cas_n
		.mem_we_n  (emif_ed_mem_mem_we_n),  //       .mem_we_n
		.mem_dq    (emif_ed_mem_mem_dq),    //       .mem_dq
		.mem_dqs   (emif_ed_mem_mem_dqs),   //       .mem_dqs
		.mem_odt   (emif_ed_mem_mem_odt)    //       .mem_odt
	);

	altera_avalon_clock_source #(
		.CLOCK_RATE (50000000),
		.CLOCK_UNIT (1)
	) ref_clk (
		.clk (ref_clk_clk_clk)  // clk.clk
	);

	altera_avalon_reset_source #(
		.ASSERT_HIGH_RESET    (0),
		.INITIAL_RESET_CYCLES (5)
	) global_reset (
		.reset (global_reset_reset_reset), // reset.reset_n
		.clk   (ref_clk_clk_clk)           //   clk.clk
	);

endmodule
