// ed_synth.v

// Generated using ACDS version 22.1 915

`timescale 1 ps / 1 ps
module ed_synth (
		output wire        emif_status_local_cal_fail,    //  emif_status.local_cal_fail
		output wire        emif_status_local_cal_success, //             .local_cal_success
		output wire        emif_status_local_init_done,   //             .local_init_done
		input  wire        global_reset_reset_n,          // global_reset.reset_n
		output wire [12:0] mem_mem_a,                     //          mem.mem_a
		output wire [1:0]  mem_mem_ba,                    //             .mem_ba
		output wire        mem_mem_cas_n,                 //             .mem_cas_n
		output wire        mem_mem_cke,                   //             .mem_cke
		inout  wire        mem_mem_ck,                    //             .mem_ck
		inout  wire        mem_mem_ck_n,                  //             .mem_ck_n
		output wire        mem_mem_cs_n,                  //             .mem_cs_n
		output wire        mem_mem_dm,                    //             .mem_dm
		inout  wire [7:0]  mem_mem_dq,                    //             .mem_dq
		inout  wire        mem_mem_dqs,                   //             .mem_dqs
		inout  wire        mem_mem_dqs_n,                 //             .mem_dqs_n
		output wire        mem_mem_odt,                   //             .mem_odt
		output wire        mem_mem_ras_n,                 //             .mem_ras_n
		output wire        mem_mem_we_n,                  //             .mem_we_n
		output wire        phy_clk_clk,                   //      phy_clk.clk
		input  wire        pll_ref_clk_clk,               //  pll_ref_clk.clk
		output wire [15:0] tg_pnf_pnf_per_bit,            //       tg_pnf.pnf_per_bit
		output wire [15:0] tg_pnf_pnf_per_bit_persist,    //             .pnf_per_bit_persist
		output wire        tg_status_pass,                //    tg_status.pass
		output wire        tg_status_fail,                //             .fail
		output wire        tg_status_test_complete        //             .test_complete
	);

	ed_synth_ed_synth ed_synth (
		.phy_clk                 (phy_clk_clk),                   //      phy_clk.clk
		.pll_ref_clk             (pll_ref_clk_clk),               //  pll_ref_clk.clk
		.tg_status_pass          (tg_status_pass),                //    tg_status.pass
		.tg_status_fail          (tg_status_fail),                //             .fail
		.tg_status_test_complete (tg_status_test_complete),       //             .test_complete
		.status_cal_fail         (emif_status_local_cal_fail),    //  emif_status.local_cal_fail
		.status_cal_success      (emif_status_local_cal_success), //             .local_cal_success
		.status_init_done        (emif_status_local_init_done),   //             .local_init_done
		.mem_addr                (mem_mem_a),                     //          mem.mem_a
		.mem_ba                  (mem_mem_ba),                    //             .mem_ba
		.mem_cas_n               (mem_mem_cas_n),                 //             .mem_cas_n
		.mem_cke                 (mem_mem_cke),                   //             .mem_cke
		.mem_clk                 (mem_mem_ck),                    //             .mem_ck
		.mem_clk_n               (mem_mem_ck_n),                  //             .mem_ck_n
		.mem_cs_n                (mem_mem_cs_n),                  //             .mem_cs_n
		.mem_dm                  (mem_mem_dm),                    //             .mem_dm
		.mem_dq                  (mem_mem_dq),                    //             .mem_dq
		.mem_dqs                 (mem_mem_dqs),                   //             .mem_dqs
		.mem_dqs_n               (mem_mem_dqs_n),                 //             .mem_dqs_n
		.mem_odt                 (mem_mem_odt),                   //             .mem_odt
		.mem_ras_n               (mem_mem_ras_n),                 //             .mem_ras_n
		.mem_we_n                (mem_mem_we_n),                  //             .mem_we_n
		.pnf_per_bit             (tg_pnf_pnf_per_bit),            //       tg_pnf.pnf_per_bit
		.pnf_per_bit_persist     (tg_pnf_pnf_per_bit_persist),    //             .pnf_per_bit_persist
		.global_reset_n          (global_reset_reset_n)           // global_reset.reset_n
	);

endmodule
