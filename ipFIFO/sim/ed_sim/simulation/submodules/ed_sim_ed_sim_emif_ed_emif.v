// ed_sim_ed_sim_emif_ed_emif.v

// This file was auto-generated from alt_mem_if_civ_ddr2_emif_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 22.1 915

`timescale 1 ps / 1 ps
module ed_sim_ed_sim_emif_ed_emif (
		output wire        phy_clk,            //           phy_clk.clk
		output wire        reset_phy_clk_n,    //         phy_reset.reset_n
		output wire        status_cal_fail,    //            status.local_cal_fail
		output wire        status_cal_success, //                  .local_cal_success
		output wire        status_init_done,   //                  .local_init_done
		input  wire        global_reset_n,     //      global_reset.reset_n
		output wire        reset_request_n,    //     reset_request.reset_n
		output wire        local_ready,        //               avl.waitrequest_n
		input  wire        local_write_req,    //                  .write
		input  wire        local_read_req,     //                  .read
		input  wire [23:0] local_address,      //                  .address
		input  wire [1:0]  local_be,           //                  .byteenable
		input  wire [15:0] local_wdata,        //                  .writedata
		input  wire [2:0]  local_size,         //                  .burstcount
		input  wire        local_burstbegin,   //                  .beginbursttransfer
		output wire [15:0] local_rdata,        //                  .readdata
		output wire        local_rdata_valid,  //                  .readdatavalid
		output wire [12:0] mem_addr,           //               mem.mem_a
		output wire [1:0]  mem_ba,             //                  .mem_ba
		output wire        mem_cas_n,          //                  .mem_cas_n
		output wire        mem_cke,            //                  .mem_cke
		inout  wire        mem_clk,            //                  .mem_ck
		inout  wire        mem_clk_n,          //                  .mem_ck_n
		output wire        mem_cs_n,           //                  .mem_cs_n
		output wire        mem_dm,             //                  .mem_dm
		inout  wire [7:0]  mem_dq,             //                  .mem_dq
		inout  wire        mem_dqs,            //                  .mem_dqs
		inout  wire        mem_dqs_n,          //                  .mem_dqs_n
		output wire        mem_odt,            //                  .mem_odt
		output wire        mem_ras_n,          //                  .mem_ras_n
		output wire        mem_we_n,           //                  .mem_we_n
		output wire        aux_full_rate_clk,  // aux_full_rate_clk.clk
		output wire        aux_half_rate_clk,  // aux_half_rate_clk.clk
		input  wire        pll_ref_clk         //       pll_ref_clk.clk
	);

	wire         status_bridge_in_afi_cal_byte_lane_sel_n; // status_bridge:in_afi_cal_byte_lane_sel_n -> phy:ctl_cal_byte_lane_sel_n
	wire         status_bridge_in_afi_cal_req;             // status_bridge:in_afi_cal_req -> phy:ctl_cal_req
	wire         status_bridge_in_afi_dqs_burst;           // status_bridge:in_afi_dqs_burst -> phy:ctl_dqs_burst
	wire         status_bridge_in_afi_cas_n;               // status_bridge:in_afi_cas_n -> phy:ctl_cas_n
	wire         status_bridge_in_afi_wdata_valid;         // status_bridge:in_afi_wdata_valid -> phy:ctl_wdata_valid
	wire         status_bridge_in_afi_rdata_en;            // status_bridge:in_afi_rdata_en -> phy:ctl_doing_rd
	wire         status_bridge_in_afi_ras_n;               // status_bridge:in_afi_ras_n -> phy:ctl_ras_n
	wire         phy_afi_cal_fail;                         // phy:ctl_cal_fail -> status_bridge:in_afi_cal_fail
	wire   [1:0] status_bridge_in_afi_dm;                  // status_bridge:in_afi_dm -> phy:ctl_dm
	wire  [15:0] phy_afi_rdata;                            // phy:ctl_rdata -> status_bridge:in_afi_rdata
	wire         status_bridge_in_afi_we_n;                // status_bridge:in_afi_we_n -> phy:ctl_we_n
	wire         status_bridge_in_afi_cs_n;                // status_bridge:in_afi_cs_n -> phy:ctl_cs_n
	wire         status_bridge_in_afi_mem_clk_disable;     // status_bridge:in_afi_mem_clk_disable -> phy:ctl_mem_clk_disable
	wire   [4:0] phy_afi_rlat;                             // phy:ctl_rlat -> status_bridge:in_afi_rlat
	wire         phy_afi_cal_success;                      // phy:ctl_cal_success -> status_bridge:in_afi_cal_success
	wire         phy_afi_rdata_valid;                      // phy:ctl_rdata_valid -> status_bridge:in_afi_rdata_valid
	wire  [15:0] status_bridge_in_afi_wdata;               // status_bridge:in_afi_wdata -> phy:ctl_wdata
	wire  [12:0] status_bridge_in_afi_addr;                // status_bridge:in_afi_addr -> phy:ctl_addr
	wire         status_bridge_in_afi_cke;                 // status_bridge:in_afi_cke -> phy:ctl_cke
	wire         status_bridge_in_afi_odt;                 // status_bridge:in_afi_odt -> phy:ctl_odt
	wire         status_bridge_in_afi_rst_n;               // status_bridge:in_afi_rst_n -> phy:ctl_rst_n
	wire   [1:0] status_bridge_in_afi_ba;                  // status_bridge:in_afi_ba -> phy:ctl_ba
	wire   [4:0] phy_afi_wlat;                             // phy:ctl_wlat -> status_bridge:in_afi_wlat
	wire         ctl_local_ctrl_refresh_ack;               // ctl:local_refresh_ack -> status_bridge:local_refresh_ack
	wire         ctl_local_ctrl_init_done;                 // ctl:local_init_done -> status_bridge:local_init_done
	wire         phy_afi_clk_clk;                          // phy:ctl_clk -> ctl:clk
	wire         ctl_phy_afi_cal_req;                      // ctl:afi_cal_req -> status_bridge:out_afi_cal_req
	wire         ctl_phy_afi_cal_byte_lane_sel_n;          // ctl:afi_cal_byte_lane_sel_n -> status_bridge:out_afi_cal_byte_lane_sel_n
	wire         ctl_phy_afi_dqs_burst;                    // ctl:afi_dqs_burst -> status_bridge:out_afi_dqs_burst
	wire         ctl_phy_afi_cas_n;                        // ctl:afi_cas_n -> status_bridge:out_afi_cas_n
	wire         ctl_phy_afi_wdata_valid;                  // ctl:afi_wdata_valid -> status_bridge:out_afi_wdata_valid
	wire         ctl_phy_afi_ras_n;                        // ctl:afi_ras_n -> status_bridge:out_afi_ras_n
	wire         ctl_phy_afi_rdata_en;                     // ctl:afi_rdata_en -> status_bridge:out_afi_rdata_en
	wire   [1:0] ctl_phy_afi_dm;                           // ctl:afi_dm -> status_bridge:out_afi_dm
	wire  [15:0] status_bridge_out_afi_rdata;              // status_bridge:out_afi_rdata -> ctl:afi_rdata
	wire         status_bridge_out_afi_cal_fail;           // status_bridge:out_afi_cal_fail -> ctl:afi_cal_fail
	wire         ctl_phy_afi_we_n;                         // ctl:afi_we_n -> status_bridge:out_afi_we_n
	wire         ctl_phy_afi_cs_n;                         // ctl:afi_cs_n -> status_bridge:out_afi_cs_n
	wire         ctl_phy_afi_mem_clk_disable;              // ctl:afi_mem_clk_disable -> status_bridge:out_afi_mem_clk_disable
	wire   [4:0] status_bridge_out_afi_rlat;               // status_bridge:out_afi_rlat -> ctl:afi_rlat
	wire  [15:0] ctl_phy_afi_wdata;                        // ctl:afi_wdata -> status_bridge:out_afi_wdata
	wire         status_bridge_out_afi_rdata_valid;        // status_bridge:out_afi_rdata_valid -> ctl:afi_rdata_valid
	wire         status_bridge_out_afi_cal_success;        // status_bridge:out_afi_cal_success -> ctl:afi_cal_success
	wire         ctl_phy_afi_cke;                          // ctl:afi_cke -> status_bridge:out_afi_cke
	wire  [12:0] ctl_phy_afi_addr;                         // ctl:afi_addr -> status_bridge:out_afi_addr
	wire         ctl_phy_afi_rst_n;                        // ctl:afi_rst_n -> status_bridge:out_afi_rst_n
	wire         ctl_phy_afi_odt;                          // ctl:afi_odt -> status_bridge:out_afi_odt
	wire   [1:0] ctl_phy_afi_ba;                           // ctl:afi_ba -> status_bridge:out_afi_ba
	wire   [4:0] status_bridge_out_afi_wlat;               // status_bridge:out_afi_wlat -> ctl:afi_wlat
	wire         phy_afi_half_rate_clk_clk;                // phy:ctl_half_rate_clk -> ctl:half_clk
	wire         phy_afi_reset_reset;                      // phy:ctl_reset_n -> ctl:reset_n

	ed_sim_ed_sim_emif_ed_emif_phy #(
		.FAMILY                        ("Cyclone IV E"),
		.MEM_IF_MEMTYPE                ("DDR2"),
		.LEVELLING                     (0),
		.SPEED_GRADE                   ("C6"),
		.DLL_DELAY_BUFFER_MODE         ("LOW"),
		.DLL_DELAY_CHAIN_LENGTH        (12),
		.DQS_DELAY_CTL_WIDTH           (6),
		.DQS_OUT_MODE                  ("DELAY_CHAIN2"),
		.DQS_PHASE                     (6000),
		.DQS_PHASE_SETTING             (2),
		.DWIDTH_RATIO                  (2),
		.MEM_IF_DWIDTH                 (8),
		.MEM_IF_ADDR_WIDTH             (13),
		.MEM_IF_BANKADDR_WIDTH         (2),
		.MEM_IF_CS_WIDTH               (1),
		.MEM_IF_DM_WIDTH               (1),
		.MEM_IF_DM_PINS_EN             (1),
		.MEM_IF_DQ_PER_DQS             (8),
		.MEM_IF_DQS_WIDTH              (1),
		.MEM_IF_OCT_EN                 (0),
		.MEM_IF_CLK_PAIR_COUNT         (1),
		.MEM_IF_CLK_PS                 (7519),
		.MEM_IF_CLK_PS_STR             ("7519 ps"),
		.MEM_IF_MR_0                   (562),
		.MEM_IF_MR_1                   (1024),
		.MEM_IF_MR_2                   (0),
		.MEM_IF_MR_3                   (0),
		.MEM_IF_PRESET_RLAT            (0),
		.PLL_STEPS_PER_CYCLE           (64),
		.SCAN_CLK_DIVIDE_BY            (2),
		.REDUCE_SIM_TIME               (0),
		.CAPABILITIES                  (2048),
		.TINIT_TCK                     (200),
		.TINIT_RST                     (0),
		.DBG_A_WIDTH                   (13),
		.SEQ_STRING_ID                 ("seq_name"),
		.MEM_IF_CS_PER_RANK            (1),
		.MEM_IF_RANKS_PER_SLOT         (1),
		.MEM_IF_RDV_PER_CHIP           (0),
		.GENERATE_ADDITIONAL_DBG_RTL   (0),
		.CAPTURE_PHASE_OFFSET          (0),
		.MEM_IF_ADDR_CMD_PHASE         (90),
		.DLL_EXPORT_IMPORT             ("EXPORT"),
		.MEM_IF_DQSN_EN                (0),
		.RANK_HAS_ADDR_SWAP            (0),
		.CLOCK_INDEX_WIDTH             (3),
		.ADV_LAT_WIDTH                 (5),
		.RESYNCHRONISE_AVALON_DBG      (0),
		.RDP_ADDR_WIDTH                (4),
		.IOE_PHASES_PER_TCK            (12),
		.IOE_DELAYS_PER_PHS            (5),
		.MEM_IF_DQS_CAPTURE_EN         (0),
		.FAMILYGROUP_ID                (2),
		.SINGLE_DQS_DELAY_CONTROL_CODE (0),
		.PRESET_RLAT                   (0),
		.WRITE_DESKEW_T10              (0),
		.WRITE_DESKEW_HC_T10           (0),
		.WRITE_DESKEW_T9NI             (0),
		.WRITE_DESKEW_HC_T9NI          (0),
		.WRITE_DESKEW_T9I              (0),
		.WRITE_DESKEW_HC_T9I           (0),
		.WRITE_DESKEW_RANGE            (0),
		.IP_BUILDNUM                   (0),
		.FORCE_HC                      (0),
		.CHIP_OR_DIMM                  ("Discrete Device"),
		.RDIMM_CONFIG_BITS             (64'b0000000000000000000000000000000000000000000000000000000000000000),
		.PLL_CLK0_DIVIDE_BY            (3),
		.PLL_CLK0_MULTIPLY_BY          (2),
		.PLL_CLK0_PHASE_SHIFT_PS       ("0"),
		.PLL_CLK1_DIVIDE_BY            (100),
		.PLL_CLK1_MULTIPLY_BY          (133),
		.PLL_CLK1_PHASE_SHIFT_PS       ("0"),
		.PLL_CLK2_DIVIDE_BY            (100),
		.PLL_CLK2_MULTIPLY_BY          (133),
		.PLL_CLK2_PHASE_SHIFT_PS       ("-1880"),
		.PLL_CLK3_DIVIDE_BY            (100),
		.PLL_CLK3_MULTIPLY_BY          (133),
		.PLL_CLK3_PHASE_SHIFT_PS       ("0"),
		.PLL_CLK4_DIVIDE_BY            (100),
		.PLL_CLK4_MULTIPLY_BY          (133),
		.PLL_CLK4_PHASE_SHIFT_PS       ("0"),
		.PLL_INCLK0_PERIOD_PS          (10000),
		.PLL_INTENDED_DEVICE_FAMILY    ("Cyclone IV E"),
		.PLL_VCO_PHASE_SHIFT_STEP      (117)
	) phy (
		.pll_ref_clk             (pll_ref_clk),                              //       PLL_REF_CLK.clk
		.global_reset_n          (global_reset_n),                           //      GLOBAL_RESET.reset_n
		.reset_request_n         (reset_request_n),                          //     RESET_REQUEST.reset_n
		.ctl_clk                 (phy_afi_clk_clk),                          //           AFI_CLK.clk
		.ctl_half_rate_clk       (phy_afi_half_rate_clk_clk),                // AFI_HALF_RATE_CLK.clk
		.ctl_reset_n             (phy_afi_reset_reset),                      //         AFI_RESET.reset_n
		.ctl_addr                (status_bridge_in_afi_addr),                //               AFI.addr
		.ctl_ba                  (status_bridge_in_afi_ba),                  //                  .ba
		.ctl_cal_byte_lane_sel_n (status_bridge_in_afi_cal_byte_lane_sel_n), //                  .cal_byte_lane_sel_n
		.ctl_cal_fail            (phy_afi_cal_fail),                         //                  .cal_fail
		.ctl_cal_req             (status_bridge_in_afi_cal_req),             //                  .cal_req
		.ctl_cal_success         (phy_afi_cal_success),                      //                  .cal_success
		.ctl_cas_n               (status_bridge_in_afi_cas_n),               //                  .cas_n
		.ctl_cke                 (status_bridge_in_afi_cke),                 //                  .cke
		.ctl_cs_n                (status_bridge_in_afi_cs_n),                //                  .cs_n
		.ctl_doing_rd            (status_bridge_in_afi_rdata_en),            //                  .rdata_en
		.ctl_dm                  (status_bridge_in_afi_dm),                  //                  .dm
		.ctl_dqs_burst           (status_bridge_in_afi_dqs_burst),           //                  .dqs_burst
		.ctl_mem_clk_disable     (status_bridge_in_afi_mem_clk_disable),     //                  .mem_clk_disable
		.ctl_odt                 (status_bridge_in_afi_odt),                 //                  .odt
		.ctl_ras_n               (status_bridge_in_afi_ras_n),               //                  .ras_n
		.ctl_rdata               (phy_afi_rdata),                            //                  .rdata
		.ctl_rdata_valid         (phy_afi_rdata_valid),                      //                  .rdata_valid
		.ctl_rlat                (phy_afi_rlat),                             //                  .rlat
		.ctl_rst_n               (status_bridge_in_afi_rst_n),               //                  .rst_n
		.ctl_wdata               (status_bridge_in_afi_wdata),               //                  .wdata
		.ctl_wdata_valid         (status_bridge_in_afi_wdata_valid),         //                  .wdata_valid
		.ctl_we_n                (status_bridge_in_afi_we_n),                //                  .we_n
		.ctl_wlat                (phy_afi_wlat),                             //                  .wlat
		.phy_clk                 (phy_clk),                                  //           PHY_CLK.clk
		.reset_phy_clk_n         (reset_phy_clk_n),                          //         PHY_RESET.reset_n
		.mem_addr                (mem_addr),                                 //               MEM.mem_a
		.mem_ba                  (mem_ba),                                   //                  .mem_ba
		.mem_cas_n               (mem_cas_n),                                //                  .mem_cas_n
		.mem_cke                 (mem_cke),                                  //                  .mem_cke
		.mem_clk                 (mem_clk),                                  //                  .mem_ck
		.mem_clk_n               (mem_clk_n),                                //                  .mem_ck_n
		.mem_cs_n                (mem_cs_n),                                 //                  .mem_cs_n
		.mem_dm                  (mem_dm),                                   //                  .mem_dm
		.mem_dq                  (mem_dq),                                   //                  .mem_dq
		.mem_dqs                 (mem_dqs),                                  //                  .mem_dqs
		.mem_dqs_n               (mem_dqs_n),                                //                  .mem_dqs_n
		.mem_odt                 (mem_odt),                                  //                  .mem_odt
		.mem_ras_n               (mem_ras_n),                                //                  .mem_ras_n
		.mem_we_n                (mem_we_n),                                 //                  .mem_we_n
		.aux_full_rate_clk       (aux_full_rate_clk),                        //           AUX_CLK.clk
		.aux_half_rate_clk       (aux_half_rate_clk),                        // AUX_HALF_RATE_CLK.clk
		.mem_reset_n             (),                                         //       (terminated)
		.soft_reset_n            (1'b1),                                     //       (terminated)
		.dbg_addr                (13'b0000000000000),                        //       (terminated)
		.dbg_cs                  (1'b0),                                     //       (terminated)
		.dbg_rd                  (1'b0),                                     //       (terminated)
		.dbg_rd_data             (),                                         //       (terminated)
		.dbg_waitrequest         (),                                         //       (terminated)
		.dbg_wr                  (1'b0),                                     //       (terminated)
		.dbg_wr_data             (32'b00000000000000000000000000000000)      //       (terminated)
	);

	ed_sim_ed_sim_emif_ed_emif_ctl #(
		.LOCAL_SIZE_WIDTH                 (3),
		.LOCAL_ADDR_WIDTH                 (24),
		.LOCAL_DATA_WIDTH                 (16),
		.LOCAL_BE_WIDTH                   (2),
		.LOCAL_ID_WIDTH                   (8),
		.LOCAL_CS_WIDTH                   (0),
		.MEM_IF_ADDR_WIDTH                (13),
		.MEM_IF_CLK_PAIR_COUNT            (1),
		.LOCAL_IF_TYPE                    ("AVALON"),
		.DWIDTH_RATIO                     (2),
		.CTL_ODT_ENABLED                  (0),
		.CTL_OUTPUT_REGD                  (0),
		.CTL_TBP_NUM                      (4),
		.WRBUFFER_ADDR_WIDTH              (6),
		.RDBUFFER_ADDR_WIDTH              (8),
		.MEM_IF_CS_WIDTH                  (1),
		.MEM_IF_CHIP                      (1),
		.MEM_IF_BANKADDR_WIDTH            (2),
		.MEM_IF_ROW_WIDTH                 (13),
		.MEM_IF_COL_WIDTH                 (10),
		.MEM_IF_ODT_WIDTH                 (1),
		.MEM_IF_DQS_WIDTH                 (1),
		.MEM_IF_DWIDTH                    (8),
		.MEM_IF_DM_WIDTH                  (1),
		.MAX_MEM_IF_CS_WIDTH              (30),
		.MAX_MEM_IF_CHIP                  (4),
		.MAX_MEM_IF_BANKADDR_WIDTH        (3),
		.MAX_MEM_IF_ROWADDR_WIDTH         (16),
		.MAX_MEM_IF_COLADDR_WIDTH         (12),
		.MAX_MEM_IF_ODT_WIDTH             (1),
		.MAX_MEM_IF_DQS_WIDTH             (5),
		.MAX_MEM_IF_DQ_WIDTH              (40),
		.MAX_MEM_IF_MASK_WIDTH            (5),
		.MAX_LOCAL_DATA_WIDTH             (80),
		.CFG_TYPE                         (3'b001),
		.CFG_INTERFACE_WIDTH              (8),
		.CFG_BURST_LENGTH                 (5'b00100),
		.CFG_DEVICE_WIDTH                 (1),
		.CFG_REORDER_DATA                 (1),
		.CFG_DATA_REORDERING_TYPE         ("INTER_BANK"),
		.CFG_STARVE_LIMIT                 (10),
		.CFG_ADDR_ORDER                   (2'b00),
		.MEM_CAS_WR_LAT                   (5),
		.MEM_ADD_LAT                      (0),
		.MEM_TCL                          (3),
		.MEM_TRRD                         (2),
		.MEM_TFAW                         (5),
		.MEM_TRFC                         (12),
		.MEM_TREFI                        (931),
		.MEM_TRCD                         (2),
		.MEM_TRP                          (2),
		.MEM_TWR                          (2),
		.MEM_TWTR                         (2),
		.MEM_TRTP                         (2),
		.MEM_TRAS                         (6),
		.MEM_TRC                          (8),
		.CFG_TCCD                         (2),
		.MEM_AUTO_PD_CYCLES               (0),
		.CFG_SELF_RFSH_EXIT_CYCLES        (200),
		.CFG_PDN_EXIT_CYCLES              (3),
		.CFG_POWER_SAVING_EXIT_CYCLES     (5),
		.CFG_MEM_CLK_ENTRY_CYCLES         (10),
		.MEM_TMRD_CK                      (10),
		.CTL_ECC_ENABLED                  (0),
		.CTL_ECC_RMW_ENABLED              (0),
		.CTL_ECC_MULTIPLES_16_24_40_72    (1),
		.CFG_GEN_SBE                      (0),
		.CFG_GEN_DBE                      (0),
		.CFG_ENABLE_INTR                  (0),
		.CFG_MASK_SBE_INTR                (0),
		.CFG_MASK_DBE_INTR                (0),
		.CFG_MASK_CORRDROP_INTR           (0),
		.CFG_CLR_INTR                     (0),
		.CTL_USR_REFRESH                  (0),
		.CTL_REGDIMM_ENABLED              (0),
		.CFG_WRITE_ODT_CHIP               (64'b0000000000000000000000000000000000000000000000000000000000000001),
		.CFG_READ_ODT_CHIP                (64'b0000000000000000000000000000000000000000000000000000000000000000),
		.CFG_PORT_WIDTH_WRITE_ODT_CHIP    (1),
		.CFG_PORT_WIDTH_READ_ODT_CHIP     (1),
		.MEM_IF_CKE_WIDTH                 (1),
		.CTL_CSR_ENABLED                  (0),
		.CFG_ENABLE_NO_DM                 (0),
		.CSR_ADDR_WIDTH                   (16),
		.CSR_DATA_WIDTH                   (32),
		.CSR_BE_WIDTH                     (4),
		.MEM_IF_RD_TO_WR_TURNAROUND_OCT   (3),
		.MEM_IF_WR_TO_RD_TURNAROUND_OCT   (0),
		.CTL_RD_TO_PCH_EXTRA_CLK          (0),
		.CTL_RD_TO_RD_DIFF_CHIP_EXTRA_CLK (0),
		.CTL_WR_TO_WR_DIFF_CHIP_EXTRA_CLK (0)
	) ctl (
		.afi_rst_n               (ctl_phy_afi_rst_n),                    //           PHY_AFI.rst_n
		.afi_cs_n                (ctl_phy_afi_cs_n),                     //                  .cs_n
		.afi_cke                 (ctl_phy_afi_cke),                      //                  .cke
		.afi_odt                 (ctl_phy_afi_odt),                      //                  .odt
		.afi_addr                (ctl_phy_afi_addr),                     //                  .addr
		.afi_ba                  (ctl_phy_afi_ba),                       //                  .ba
		.afi_ras_n               (ctl_phy_afi_ras_n),                    //                  .ras_n
		.afi_cas_n               (ctl_phy_afi_cas_n),                    //                  .cas_n
		.afi_we_n                (ctl_phy_afi_we_n),                     //                  .we_n
		.afi_dqs_burst           (ctl_phy_afi_dqs_burst),                //                  .dqs_burst
		.afi_wdata_valid         (ctl_phy_afi_wdata_valid),              //                  .wdata_valid
		.afi_wdata               (ctl_phy_afi_wdata),                    //                  .wdata
		.afi_dm                  (ctl_phy_afi_dm),                       //                  .dm
		.afi_wlat                (status_bridge_out_afi_wlat),           //                  .wlat
		.afi_rdata_en            (ctl_phy_afi_rdata_en),                 //                  .rdata_en
		.afi_rdata               (status_bridge_out_afi_rdata),          //                  .rdata
		.afi_rdata_valid         (status_bridge_out_afi_rdata_valid),    //                  .rdata_valid
		.afi_rlat                (status_bridge_out_afi_rlat),           //                  .rlat
		.afi_cal_success         (status_bridge_out_afi_cal_success),    //                  .cal_success
		.afi_cal_fail            (status_bridge_out_afi_cal_fail),       //                  .cal_fail
		.afi_cal_req             (ctl_phy_afi_cal_req),                  //                  .cal_req
		.afi_mem_clk_disable     (ctl_phy_afi_mem_clk_disable),          //                  .mem_clk_disable
		.afi_cal_byte_lane_sel_n (ctl_phy_afi_cal_byte_lane_sel_n),      //                  .cal_byte_lane_sel_n
		.clk                     (phy_afi_clk_clk),                      //           AFI_CLK.clk
		.half_clk                (phy_afi_half_rate_clk_clk),            // AFI_HALF_RATE_CLK.clk
		.reset_n                 (phy_afi_reset_reset),                  //         AFI_RESET.reset_n
		.local_ready             (local_ready),                          //         LOCAL_AVL.waitrequest_n
		.local_write_req         (local_write_req),                      //                  .write
		.local_read_req          (local_read_req),                       //                  .read
		.local_address           (local_address),                        //                  .address
		.local_be                (local_be),                             //                  .byteenable
		.local_wdata             (local_wdata),                          //                  .writedata
		.local_size              (local_size),                           //                  .burstcount
		.local_burstbegin        (local_burstbegin),                     //                  .beginbursttransfer
		.local_rdata             (local_rdata),                          //                  .readdata
		.local_rdata_valid       (local_rdata_valid),                    //                  .readdatavalid
		.local_init_done         (ctl_local_ctrl_init_done),             //        LOCAL_CTRL.init_done
		.local_refresh_ack       (ctl_local_ctrl_refresh_ack),           //                  .refresh_ack
		.local_self_rfsh_req     (1'b0),                                 //       (terminated)
		.local_self_rfsh_chip    (1'b0),                                 //       (terminated)
		.local_self_rfsh_ack     (),                                     //       (terminated)
		.local_refresh_req       (1'b0),                                 //       (terminated)
		.local_refresh_chip      (1'b0),                                 //       (terminated)
		.local_powerdn_ack       (),                                     //       (terminated)
		.local_autopch_req       (1'b0),                                 //       (terminated)
		.csr_read_req            (1'b0),                                 //       (terminated)
		.csr_write_req           (1'b0),                                 //       (terminated)
		.csr_burst_count         (1'b0),                                 //       (terminated)
		.csr_beginbursttransfer  (1'b0),                                 //       (terminated)
		.csr_addr                (16'b0000000000000000),                 //       (terminated)
		.csr_wdata               (32'b00000000000000000000000000000000), //       (terminated)
		.csr_rdata               (),                                     //       (terminated)
		.csr_be                  (4'b0000),                              //       (terminated)
		.csr_rdata_valid         (),                                     //       (terminated)
		.csr_waitrequest         ()                                      //       (terminated)
	);

	ed_sim_ed_sim_emif_ed_emif_status_bridge #(
		.LOCAL_SIZE_WIDTH                 (3),
		.LOCAL_ADDR_WIDTH                 (24),
		.LOCAL_DATA_WIDTH                 (16),
		.LOCAL_BE_WIDTH                   (2),
		.LOCAL_ID_WIDTH                   (8),
		.LOCAL_CS_WIDTH                   (0),
		.MEM_IF_ADDR_WIDTH                (13),
		.MEM_IF_CLK_PAIR_COUNT            (1),
		.LOCAL_IF_TYPE                    ("AVALON"),
		.DWIDTH_RATIO                     (2),
		.CTL_ODT_ENABLED                  (0),
		.CTL_OUTPUT_REGD                  (0),
		.CTL_TBP_NUM                      (4),
		.WRBUFFER_ADDR_WIDTH              (6),
		.RDBUFFER_ADDR_WIDTH              (8),
		.MEM_IF_CS_WIDTH                  (1),
		.MEM_IF_CHIP                      (1),
		.MEM_IF_BANKADDR_WIDTH            (2),
		.MEM_IF_ROW_WIDTH                 (13),
		.MEM_IF_COL_WIDTH                 (10),
		.MEM_IF_ODT_WIDTH                 (1),
		.MEM_IF_DQS_WIDTH                 (1),
		.MEM_IF_DWIDTH                    (8),
		.MEM_IF_DM_WIDTH                  (1),
		.MAX_MEM_IF_CS_WIDTH              (30),
		.MAX_MEM_IF_CHIP                  (4),
		.MAX_MEM_IF_BANKADDR_WIDTH        (3),
		.MAX_MEM_IF_ROWADDR_WIDTH         (16),
		.MAX_MEM_IF_COLADDR_WIDTH         (12),
		.MAX_MEM_IF_ODT_WIDTH             (1),
		.MAX_MEM_IF_DQS_WIDTH             (5),
		.MAX_MEM_IF_DQ_WIDTH              (40),
		.MAX_MEM_IF_MASK_WIDTH            (5),
		.MAX_LOCAL_DATA_WIDTH             (80),
		.CFG_TYPE                         (3'b001),
		.CFG_INTERFACE_WIDTH              (8),
		.CFG_BURST_LENGTH                 (5'b00100),
		.CFG_DEVICE_WIDTH                 (1),
		.CFG_REORDER_DATA                 (1),
		.CFG_DATA_REORDERING_TYPE         ("INTER_BANK"),
		.CFG_STARVE_LIMIT                 (10),
		.CFG_ADDR_ORDER                   (2'b00),
		.MEM_CAS_WR_LAT                   (5),
		.MEM_ADD_LAT                      (0),
		.MEM_TCL                          (3),
		.MEM_TRRD                         (2),
		.MEM_TFAW                         (5),
		.MEM_TRFC                         (12),
		.MEM_TREFI                        (931),
		.MEM_TRCD                         (2),
		.MEM_TRP                          (2),
		.MEM_TWR                          (2),
		.MEM_TWTR                         (2),
		.MEM_TRTP                         (2),
		.MEM_TRAS                         (6),
		.MEM_TRC                          (8),
		.CFG_TCCD                         (2),
		.MEM_AUTO_PD_CYCLES               (0),
		.CFG_SELF_RFSH_EXIT_CYCLES        (200),
		.CFG_PDN_EXIT_CYCLES              (3),
		.CFG_POWER_SAVING_EXIT_CYCLES     (5),
		.CFG_MEM_CLK_ENTRY_CYCLES         (10),
		.MEM_TMRD_CK                      (10),
		.CTL_ECC_ENABLED                  (0),
		.CTL_ECC_RMW_ENABLED              (0),
		.CTL_ECC_MULTIPLES_16_24_40_72    (1),
		.CFG_GEN_SBE                      (0),
		.CFG_GEN_DBE                      (0),
		.CFG_ENABLE_INTR                  (0),
		.CFG_MASK_SBE_INTR                (0),
		.CFG_MASK_DBE_INTR                (0),
		.CFG_MASK_CORRDROP_INTR           (0),
		.CFG_CLR_INTR                     (0),
		.CTL_USR_REFRESH                  (0),
		.CTL_REGDIMM_ENABLED              (0),
		.CFG_WRITE_ODT_CHIP               (64'b0000000000000000000000000000000000000000000000000000000000000001),
		.CFG_READ_ODT_CHIP                (64'b0000000000000000000000000000000000000000000000000000000000000000),
		.CFG_PORT_WIDTH_WRITE_ODT_CHIP    (1),
		.CFG_PORT_WIDTH_READ_ODT_CHIP     (1),
		.MEM_IF_CKE_WIDTH                 (1),
		.CTL_CSR_ENABLED                  (0),
		.CFG_ENABLE_NO_DM                 (0),
		.CSR_ADDR_WIDTH                   (16),
		.CSR_DATA_WIDTH                   (32),
		.CSR_BE_WIDTH                     (4),
		.MEM_IF_RD_TO_WR_TURNAROUND_OCT   (3),
		.MEM_IF_WR_TO_RD_TURNAROUND_OCT   (0),
		.CTL_RD_TO_PCH_EXTRA_CLK          (0),
		.CTL_RD_TO_RD_DIFF_CHIP_EXTRA_CLK (0),
		.CTL_WR_TO_WR_DIFF_CHIP_EXTRA_CLK (0)
	) status_bridge (
		.in_afi_rst_n                (status_bridge_in_afi_rst_n),               //   in_afi.rst_n
		.in_afi_cs_n                 (status_bridge_in_afi_cs_n),                //         .cs_n
		.in_afi_cke                  (status_bridge_in_afi_cke),                 //         .cke
		.in_afi_odt                  (status_bridge_in_afi_odt),                 //         .odt
		.in_afi_addr                 (status_bridge_in_afi_addr),                //         .addr
		.in_afi_ba                   (status_bridge_in_afi_ba),                  //         .ba
		.in_afi_ras_n                (status_bridge_in_afi_ras_n),               //         .ras_n
		.in_afi_cas_n                (status_bridge_in_afi_cas_n),               //         .cas_n
		.in_afi_we_n                 (status_bridge_in_afi_we_n),                //         .we_n
		.in_afi_dqs_burst            (status_bridge_in_afi_dqs_burst),           //         .dqs_burst
		.in_afi_wdata_valid          (status_bridge_in_afi_wdata_valid),         //         .wdata_valid
		.in_afi_wdata                (status_bridge_in_afi_wdata),               //         .wdata
		.in_afi_dm                   (status_bridge_in_afi_dm),                  //         .dm
		.in_afi_wlat                 (phy_afi_wlat),                             //         .wlat
		.in_afi_rdata_en             (status_bridge_in_afi_rdata_en),            //         .rdata_en
		.in_afi_rdata                (phy_afi_rdata),                            //         .rdata
		.in_afi_rdata_valid          (phy_afi_rdata_valid),                      //         .rdata_valid
		.in_afi_rlat                 (phy_afi_rlat),                             //         .rlat
		.in_afi_cal_success          (phy_afi_cal_success),                      //         .cal_success
		.in_afi_cal_fail             (phy_afi_cal_fail),                         //         .cal_fail
		.in_afi_cal_req              (status_bridge_in_afi_cal_req),             //         .cal_req
		.in_afi_mem_clk_disable      (status_bridge_in_afi_mem_clk_disable),     //         .mem_clk_disable
		.in_afi_cal_byte_lane_sel_n  (status_bridge_in_afi_cal_byte_lane_sel_n), //         .cal_byte_lane_sel_n
		.local_init_done             (ctl_local_ctrl_init_done),                 // in_local.init_done
		.local_refresh_ack           (ctl_local_ctrl_refresh_ack),               //         .refresh_ack
		.out_afi_rst_n               (ctl_phy_afi_rst_n),                        //  out_afi.rst_n
		.out_afi_cs_n                (ctl_phy_afi_cs_n),                         //         .cs_n
		.out_afi_cke                 (ctl_phy_afi_cke),                          //         .cke
		.out_afi_odt                 (ctl_phy_afi_odt),                          //         .odt
		.out_afi_addr                (ctl_phy_afi_addr),                         //         .addr
		.out_afi_ba                  (ctl_phy_afi_ba),                           //         .ba
		.out_afi_ras_n               (ctl_phy_afi_ras_n),                        //         .ras_n
		.out_afi_cas_n               (ctl_phy_afi_cas_n),                        //         .cas_n
		.out_afi_we_n                (ctl_phy_afi_we_n),                         //         .we_n
		.out_afi_dqs_burst           (ctl_phy_afi_dqs_burst),                    //         .dqs_burst
		.out_afi_wdata_valid         (ctl_phy_afi_wdata_valid),                  //         .wdata_valid
		.out_afi_wdata               (ctl_phy_afi_wdata),                        //         .wdata
		.out_afi_dm                  (ctl_phy_afi_dm),                           //         .dm
		.out_afi_wlat                (status_bridge_out_afi_wlat),               //         .wlat
		.out_afi_rdata_en            (ctl_phy_afi_rdata_en),                     //         .rdata_en
		.out_afi_rdata               (status_bridge_out_afi_rdata),              //         .rdata
		.out_afi_rdata_valid         (status_bridge_out_afi_rdata_valid),        //         .rdata_valid
		.out_afi_rlat                (status_bridge_out_afi_rlat),               //         .rlat
		.out_afi_cal_success         (status_bridge_out_afi_cal_success),        //         .cal_success
		.out_afi_cal_fail            (status_bridge_out_afi_cal_fail),           //         .cal_fail
		.out_afi_cal_req             (ctl_phy_afi_cal_req),                      //         .cal_req
		.out_afi_mem_clk_disable     (ctl_phy_afi_mem_clk_disable),              //         .mem_clk_disable
		.out_afi_cal_byte_lane_sel_n (ctl_phy_afi_cal_byte_lane_sel_n),          //         .cal_byte_lane_sel_n
		.status_cal_fail             (status_cal_fail),                          //   status.local_cal_fail
		.status_cal_success          (status_cal_success),                       //         .local_cal_success
		.status_init_done            (status_init_done),                         //         .local_init_done
		.local_self_rfsh_req         (),                                         // (terminated)
		.local_self_rfsh_chip        (),                                         // (terminated)
		.local_self_rfsh_ack         (1'b0),                                     // (terminated)
		.local_refresh_req           (),                                         // (terminated)
		.local_refresh_chip          (),                                         // (terminated)
		.local_powerdn_ack           (1'b0),                                     // (terminated)
		.local_autopch_req           ()                                          // (terminated)
	);

endmodule
