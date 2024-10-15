// (C) 2001-2022 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


///////////////////////////////////////////////////////////////////////////////////////////////
// Multiplexes some signals that are useful.
//

`timescale 1 ps / 1 ps

`define MMR_TYPE_DDR1    3'b000
`define MMR_TYPE_DDR2    3'b001
`define MMR_TYPE_DDR3    3'b010
`define MMR_TYPE_LPDDR1  3'b011
`define MMR_TYPE_LPDDR2  3'b100 
`define MMR_ADDR_ORDER_CS_ROW_BA_COL    2'b00
`define MMR_ADDR_ORDER_CS_BA_ROW_COL    2'b01
`define MMR_ADDR_ORDER_ROW_CS_BA_COL    2'b10

module sdram_alt_mem_if_civ_ddr2_emif_0_status_bridge (
    in_afi_rst_n,
    in_afi_cs_n,
    in_afi_cke,
    in_afi_odt,
    in_afi_addr,
    in_afi_ba,
    in_afi_ras_n,
    in_afi_cas_n,
    in_afi_we_n,
    in_afi_dqs_burst,
    in_afi_wdata_valid,
    in_afi_wdata,
    in_afi_dm,
    in_afi_wlat,
    in_afi_rdata_en,
    in_afi_rdata,
    in_afi_rdata_valid,
    in_afi_rlat,
    in_afi_cal_success,
    in_afi_cal_fail,
    in_afi_cal_req,
    in_afi_mem_clk_disable,
    in_afi_cal_byte_lane_sel_n,
    local_init_done,
    local_refresh_ack,
    local_powerdn_ack,
    local_self_rfsh_ack,
    local_autopch_req,
    local_refresh_req,
    local_refresh_chip,
    local_self_rfsh_req,
    local_self_rfsh_chip,
    out_afi_rst_n,
    out_afi_cs_n,
    out_afi_cke,
    out_afi_odt,
    out_afi_addr,
    out_afi_ba,
    out_afi_ras_n,
    out_afi_cas_n,
    out_afi_we_n,
    out_afi_dqs_burst,
    out_afi_wdata_valid,
    out_afi_wdata,
    out_afi_dm,
    out_afi_wlat,
    out_afi_rdata_en,
    out_afi_rdata,
    out_afi_rdata_valid,
    out_afi_rlat,
    out_afi_cal_success,
    out_afi_cal_fail,
    out_afi_cal_req,
    out_afi_mem_clk_disable,
    out_afi_cal_byte_lane_sel_n,
    status_cal_fail,
    status_cal_success,
    status_init_done
);

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Parameters
//
parameter LOCAL_SIZE_WIDTH                          = "";
parameter LOCAL_ADDR_WIDTH                          = "";
parameter LOCAL_DATA_WIDTH                          = "";
parameter LOCAL_BE_WIDTH                            = "";
parameter LOCAL_ID_WIDTH                            = "";
parameter LOCAL_CS_WIDTH                            = "";
parameter MEM_IF_ADDR_WIDTH                         = "";
parameter MEM_IF_CLK_PAIR_COUNT                     = "";
parameter LOCAL_IF_TYPE                             = "";
parameter DWIDTH_RATIO                              = "";
parameter CTL_ODT_ENABLED                           = "";
parameter CTL_OUTPUT_REGD                           = "";
parameter CTL_TBP_NUM                               = "";
parameter WRBUFFER_ADDR_WIDTH                       = "";
parameter RDBUFFER_ADDR_WIDTH                       = "";
parameter MEM_IF_CS_WIDTH                           = "";
parameter MEM_IF_CHIP                               = "";
parameter MEM_IF_BANKADDR_WIDTH                     = "";
parameter MEM_IF_ROW_WIDTH                          = "";
parameter MEM_IF_COL_WIDTH                          = "";
parameter MEM_IF_ODT_WIDTH                          = "";
parameter MEM_IF_DQS_WIDTH                          = "";
parameter MEM_IF_DWIDTH                             = "";
parameter MEM_IF_DM_WIDTH                           = "";
parameter MAX_MEM_IF_CS_WIDTH                       = "";
parameter MAX_MEM_IF_CHIP                           = "";
parameter MAX_MEM_IF_BANKADDR_WIDTH                 = "";
parameter MAX_MEM_IF_ROWADDR_WIDTH                  = "";
parameter MAX_MEM_IF_COLADDR_WIDTH                  = "";
parameter MAX_MEM_IF_ODT_WIDTH                      = "";
parameter MAX_MEM_IF_DQS_WIDTH                      = "";
parameter MAX_MEM_IF_DQ_WIDTH                       = "";
parameter MAX_MEM_IF_MASK_WIDTH                     = "";
parameter MAX_LOCAL_DATA_WIDTH                      = "";
parameter CFG_TYPE                                  = "";
parameter CFG_INTERFACE_WIDTH                       = "";
parameter CFG_BURST_LENGTH                          = "";
parameter CFG_DEVICE_WIDTH                          = "";
parameter CFG_REORDER_DATA                          = "";
parameter CFG_DATA_REORDERING_TYPE                  = "";
parameter CFG_STARVE_LIMIT                          = "";
parameter CFG_ADDR_ORDER                            = "";
parameter MEM_CAS_WR_LAT                            = "";
parameter MEM_ADD_LAT                               = "";
parameter MEM_TCL                                   = "";
parameter MEM_TRRD                                  = "";
parameter MEM_TFAW                                  = "";
parameter MEM_TRFC                                  = "";
parameter MEM_TREFI                                 = "";
parameter MEM_TRCD                                  = "";
parameter MEM_TRP                                   = "";
parameter MEM_TWR                                   = "";
parameter MEM_TWTR                                  = "";
parameter MEM_TRTP                                  = "";
parameter MEM_TRAS                                  = "";
parameter MEM_TRC                                   = "";
parameter CFG_TCCD                                  = "";
parameter MEM_AUTO_PD_CYCLES                        = "";
parameter CFG_SELF_RFSH_EXIT_CYCLES                 = "";
parameter CFG_PDN_EXIT_CYCLES                       = "";
parameter CFG_POWER_SAVING_EXIT_CYCLES              = "";
parameter CFG_MEM_CLK_ENTRY_CYCLES                  = "";
parameter MEM_TMRD_CK                               = "";
parameter CTL_ECC_ENABLED                           = "";
parameter CTL_ECC_RMW_ENABLED                       = "";
parameter CTL_ECC_MULTIPLES_16_24_40_72             = "";
parameter CFG_GEN_SBE                               = "";
parameter CFG_GEN_DBE                               = "";
parameter CFG_ENABLE_INTR                           = "";
parameter CFG_MASK_SBE_INTR                         = "";
parameter CFG_MASK_DBE_INTR                         = "";
parameter CFG_MASK_CORRDROP_INTR                    = 0;
parameter CFG_CLR_INTR                              = "";
parameter CTL_USR_REFRESH                           = "";
parameter CTL_REGDIMM_ENABLED                       = "";
parameter CFG_WRITE_ODT_CHIP                        = "";
parameter CFG_READ_ODT_CHIP                         = "";
parameter CFG_PORT_WIDTH_WRITE_ODT_CHIP             = "";
parameter CFG_PORT_WIDTH_READ_ODT_CHIP              = "";
parameter MEM_IF_CKE_WIDTH                          = "";//check
parameter CTL_CSR_ENABLED                           = "";
parameter CFG_ENABLE_NO_DM                          = "";
parameter CSR_ADDR_WIDTH                            = "";
parameter CSR_DATA_WIDTH                            = "";
parameter CSR_BE_WIDTH                              = "";
parameter MEM_IF_RD_TO_WR_TURNAROUND_OCT            = "";
parameter MEM_IF_WR_TO_RD_TURNAROUND_OCT            = "";
parameter CTL_RD_TO_PCH_EXTRA_CLK                   = 0;
parameter CTL_RD_TO_RD_DIFF_CHIP_EXTRA_CLK          = 0;
parameter CTL_WR_TO_WR_DIFF_CHIP_EXTRA_CLK          = 0;


////////////////////////////////////////////////////////////////////////////////////////////////////////
// Local Parameters
//
localparam CFG_LOCAL_SIZE_WIDTH                                 = LOCAL_SIZE_WIDTH;
localparam CFG_LOCAL_ADDR_WIDTH                                 = LOCAL_ADDR_WIDTH;
localparam CFG_LOCAL_DATA_WIDTH                                 = LOCAL_DATA_WIDTH;
localparam CFG_LOCAL_BE_WIDTH                                   = LOCAL_BE_WIDTH;
localparam CFG_LOCAL_ID_WIDTH                                   = LOCAL_ID_WIDTH;
localparam CFG_LOCAL_IF_TYPE                                    = LOCAL_IF_TYPE;
localparam CFG_MEM_IF_ADDR_WIDTH                                = MEM_IF_ADDR_WIDTH;
localparam CFG_MEM_IF_CLK_PAIR_COUNT                            = MEM_IF_CLK_PAIR_COUNT;
localparam CFG_DWIDTH_RATIO                                     = DWIDTH_RATIO;
localparam CFG_ODT_ENABLED                                      = CTL_ODT_ENABLED;
localparam CFG_CTL_TBP_NUM                                      = CTL_TBP_NUM;
localparam CFG_WRBUFFER_ADDR_WIDTH                              = WRBUFFER_ADDR_WIDTH;
localparam CFG_RDBUFFER_ADDR_WIDTH                              = RDBUFFER_ADDR_WIDTH;
localparam CFG_MEM_IF_CS_WIDTH                                  = MEM_IF_CS_WIDTH;
localparam CFG_MEM_IF_CHIP                                      = MEM_IF_CHIP;
localparam CFG_MEM_IF_BA_WIDTH                                  = MEM_IF_BANKADDR_WIDTH;
localparam CFG_MEM_IF_ROW_WIDTH                                 = MEM_IF_ROW_WIDTH;
localparam CFG_MEM_IF_COL_WIDTH                                 = MEM_IF_COL_WIDTH;
localparam CFG_MEM_IF_CKE_WIDTH                                 = MEM_IF_CKE_WIDTH;
localparam CFG_MEM_IF_ODT_WIDTH                                 = MEM_IF_ODT_WIDTH;
localparam CFG_MEM_IF_DQS_WIDTH                                 = MEM_IF_DQS_WIDTH;
localparam CFG_MEM_IF_DQ_WIDTH                                  = MEM_IF_DWIDTH;
localparam CFG_MEM_IF_DM_WIDTH                                  = MEM_IF_DM_WIDTH;
localparam CFG_COL_ADDR_WIDTH                                   = MEM_IF_COL_WIDTH;
localparam CFG_ROW_ADDR_WIDTH                                   = MEM_IF_ROW_WIDTH;
localparam CFG_BANK_ADDR_WIDTH                                  = MEM_IF_BANKADDR_WIDTH;
localparam CFG_CS_ADDR_WIDTH                                    = LOCAL_CS_WIDTH;
localparam CFG_CAS_WR_LAT                                       = MEM_CAS_WR_LAT;
localparam CFG_ADD_LAT                                          = MEM_ADD_LAT;
localparam CFG_TCL                                              = MEM_TCL;
localparam CFG_TRRD                                             = MEM_TRRD;
localparam CFG_TFAW                                             = MEM_TFAW;
localparam CFG_TRFC                                             = MEM_TRFC;
localparam CFG_TREFI                                            = MEM_TREFI;
localparam CFG_TRCD                                             = MEM_TRCD;
localparam CFG_TRP                                              = MEM_TRP;
localparam CFG_TWR                                              = MEM_TWR;
localparam CFG_TWTR                                             = MEM_TWTR;
localparam CFG_TRTP                                             = MEM_TRTP;
localparam CFG_TRAS                                             = MEM_TRAS;
localparam CFG_TRC                                              = MEM_TRC;
localparam CFG_AUTO_PD_CYCLES                                   = MEM_AUTO_PD_CYCLES;
localparam CFG_TMRD                                             = MEM_TMRD_CK;
localparam CFG_ENABLE_ECC                                       = CTL_ECC_ENABLED;
localparam CFG_ENABLE_AUTO_CORR                                 = CTL_ECC_RMW_ENABLED;
localparam CFG_ECC_MULTIPLES_16_24_40_72                        = CTL_ECC_MULTIPLES_16_24_40_72;
localparam CFG_ENABLE_ECC_CODE_OVERWRITES                       = 1'b1;
localparam CFG_CAL_REQ                                          = 0;
localparam CFG_EXTRA_CTL_CLK_ACT_TO_RDWR                        = 0;
localparam CFG_EXTRA_CTL_CLK_ACT_TO_PCH                         = 0;
localparam CFG_EXTRA_CTL_CLK_ACT_TO_ACT                         = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_RD                           = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_RD_DIFF_CHIP                 = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_WR                           = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_WR_BC                        = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_WR_DIFF_CHIP                 = 0;
localparam CFG_EXTRA_CTL_CLK_RD_TO_PCH                          = 0;
localparam CFG_EXTRA_CTL_CLK_RD_AP_TO_VALID                     = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_WR                           = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_WR_DIFF_CHIP                 = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_RD                           = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_RD_BC                        = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_RD_DIFF_CHIP                 = 0;
localparam CFG_EXTRA_CTL_CLK_WR_TO_PCH                          = 0;
localparam CFG_EXTRA_CTL_CLK_WR_AP_TO_VALID                     = 0;
localparam CFG_EXTRA_CTL_CLK_PCH_TO_VALID                       = 0;
localparam CFG_EXTRA_CTL_CLK_PCH_ALL_TO_VALID                   = 0;
localparam CFG_EXTRA_CTL_CLK_ACT_TO_ACT_DIFF_BANK               = 0;
localparam CFG_EXTRA_CTL_CLK_FOUR_ACT_TO_ACT                    = 0;
localparam CFG_EXTRA_CTL_CLK_ARF_TO_VALID                       = 0;
localparam CFG_EXTRA_CTL_CLK_PDN_TO_VALID                       = 0;
localparam CFG_EXTRA_CTL_CLK_SRF_TO_VALID                       = 0;
localparam CFG_EXTRA_CTL_CLK_SRF_TO_ZQ_CAL                      = 0;
localparam CFG_EXTRA_CTL_CLK_ARF_PERIOD                         = 0;
localparam CFG_EXTRA_CTL_CLK_PDN_PERIOD                         = 0;
localparam CFG_ENABLE_DQS_TRACKING                              = 0;
localparam CFG_OUTPUT_REGD                                      = CTL_OUTPUT_REGD;
localparam CFG_MASK_CORR_DROPPED_INTR                           = 0;
localparam CFG_USER_RFSH                                        = CTL_USR_REFRESH;
localparam CFG_REGDIMM_ENABLE                                   = CTL_REGDIMM_ENABLED;
localparam CFG_PORT_WIDTH_TYPE                                  = 3;
localparam CFG_PORT_WIDTH_INTERFACE_WIDTH                       = 8;
localparam CFG_PORT_WIDTH_BURST_LENGTH                          = 5;
localparam CFG_PORT_WIDTH_DEVICE_WIDTH                          = 4;
localparam CFG_PORT_WIDTH_REORDER_DATA                          = 1;
localparam CFG_PORT_WIDTH_STARVE_LIMIT                          = 6;
localparam CFG_PORT_WIDTH_OUTPUT_REGD                           = 2;
localparam CFG_PORT_WIDTH_ADDR_ORDER                            = 2;
localparam CFG_PORT_WIDTH_COL_ADDR_WIDTH                        = 5;
localparam CFG_PORT_WIDTH_ROW_ADDR_WIDTH                        = 5;
localparam CFG_PORT_WIDTH_BANK_ADDR_WIDTH                       = 3;
localparam CFG_PORT_WIDTH_CS_ADDR_WIDTH                         = 3;
localparam CFG_PORT_WIDTH_CAS_WR_LAT                            = 4;
localparam CFG_PORT_WIDTH_ADD_LAT                               = 4;
localparam CFG_PORT_WIDTH_TCL                                   = 4;
localparam CFG_PORT_WIDTH_TRRD                                  = 4;
localparam CFG_PORT_WIDTH_TFAW                                  = 6;
localparam CFG_PORT_WIDTH_TRFC                                  = 9; //case:234203
localparam CFG_PORT_WIDTH_TREFI                                 = 14; //case:234203
localparam CFG_PORT_WIDTH_TRCD                                  = 4;
localparam CFG_PORT_WIDTH_TRP                                   = 4;
localparam CFG_PORT_WIDTH_TWR                                   = 5; //case:234203
localparam CFG_PORT_WIDTH_TWTR                                  = 4;
localparam CFG_PORT_WIDTH_TRTP                                  = 4;
localparam CFG_PORT_WIDTH_TRAS                                  = 6; //case:234203
localparam CFG_PORT_WIDTH_TRC                                   = 6;
localparam CFG_PORT_WIDTH_TCCD                                  = 4;
localparam CFG_PORT_WIDTH_TMRD                                  = 3;
localparam CFG_PORT_WIDTH_SELF_RFSH_EXIT_CYCLES                 = 10;
localparam CFG_PORT_WIDTH_PDN_EXIT_CYCLES                       = 4;
localparam CFG_PORT_WIDTH_AUTO_PD_CYCLES                        = 16;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ACT_TO_RDWR             = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ACT_TO_PCH              = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ACT_TO_ACT              = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_RD                = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_RD_DIFF_CHIP      = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_WR                = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_WR_BC             = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_WR_DIFF_CHIP      = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_TO_PCH               = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_RD_AP_TO_VALID          = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_WR                = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_WR_DIFF_CHIP      = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_RD                = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_RD_BC             = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_RD_DIFF_CHIP      = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_TO_PCH               = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_WR_AP_TO_VALID          = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_PCH_TO_VALID            = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_PCH_ALL_TO_VALID        = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ACT_TO_ACT_DIFF_BANK    = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_FOUR_ACT_TO_ACT         = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ARF_TO_VALID            = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_PDN_TO_VALID            = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_SRF_TO_VALID            = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_SRF_TO_ZQ_CAL           = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_ARF_PERIOD              = 4;
localparam CFG_PORT_WIDTH_EXTRA_CTL_CLK_PDN_PERIOD              = 4;
localparam CFG_PORT_WIDTH_ENABLE_ECC                            = 1;
localparam CFG_PORT_WIDTH_ENABLE_AUTO_CORR                      = 1;
localparam CFG_PORT_WIDTH_GEN_SBE                               = 1;
localparam CFG_PORT_WIDTH_GEN_DBE                               = 1;
localparam CFG_PORT_WIDTH_ENABLE_INTR                           = 1;
localparam CFG_PORT_WIDTH_MASK_SBE_INTR                         = 1;
localparam CFG_PORT_WIDTH_MASK_DBE_INTR                         = 1;
localparam CFG_PORT_WIDTH_CLR_INTR                              = 1;
localparam CFG_PORT_WIDTH_USER_RFSH                             = 1;
localparam CFG_PORT_WIDTH_SELF_RFSH                             = 1;
localparam CFG_PORT_WIDTH_REGDIMM_ENABLE                        = 1;
localparam CFG_WLAT_BUS_WIDTH                                   = 5;
localparam CFG_RDATA_RETURN_MODE                                = (CFG_REORDER_DATA == 1) ? "INORDER" : "PASSTHROUGH";
localparam CFG_LPDDR2_ENABLED                                   = (CFG_TYPE == `MMR_TYPE_LPDDR2) ? 1 : 0;
localparam CFG_ADDR_RATE_RATIO                                  = (CFG_LPDDR2_ENABLED == 1) ? 2 : 1;
localparam CFG_AFI_IF_FR_ADDR_WIDTH                             = (CFG_ADDR_RATE_RATIO * CFG_MEM_IF_ADDR_WIDTH);
localparam STS_PORT_WIDTH_SBE_ERROR                             = 1;
localparam STS_PORT_WIDTH_DBE_ERROR                             = 1;
localparam STS_PORT_WIDTH_CORR_DROP_ERROR                       = 1;
localparam STS_PORT_WIDTH_SBE_COUNT                             = 8;
localparam STS_PORT_WIDTH_DBE_COUNT                             = 8;
localparam STS_PORT_WIDTH_CORR_DROP_COUNT                       = 8;
localparam AFI_CS_WIDTH                                         = (CFG_MEM_IF_CHIP * (CFG_DWIDTH_RATIO / 2));
localparam AFI_CKE_WIDTH                                        = (CFG_MEM_IF_CKE_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_ODT_WIDTH                                        = (CFG_MEM_IF_ODT_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_ADDR_WIDTH                                       = (CFG_AFI_IF_FR_ADDR_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_BA_WIDTH                                         = (CFG_MEM_IF_BA_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_CAL_BYTE_LANE_SEL_N_WIDTH                        = (CFG_MEM_IF_DQS_WIDTH * CFG_MEM_IF_CHIP);
localparam AFI_CMD_WIDTH                                        = (CFG_DWIDTH_RATIO / 2);
localparam AFI_DQS_BURST_WIDTH                                  = (CFG_MEM_IF_DQS_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_WDATA_VALID_WIDTH                                = (CFG_MEM_IF_DQS_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_WDATA_WIDTH                                      = (CFG_MEM_IF_DQ_WIDTH * CFG_DWIDTH_RATIO);
localparam AFI_DM_WIDTH                                         = (CFG_MEM_IF_DM_WIDTH * CFG_DWIDTH_RATIO);
localparam AFI_WLAT_WIDTH                                       = CFG_WLAT_BUS_WIDTH;
localparam AFI_RDATA_EN_WIDTH                                   = (CFG_MEM_IF_DQS_WIDTH * (CFG_DWIDTH_RATIO / 2));
localparam AFI_RDATA_WIDTH                                      = (CFG_MEM_IF_DQ_WIDTH * CFG_DWIDTH_RATIO);
localparam AFI_RDATA_VALID_WIDTH                                = (CFG_DWIDTH_RATIO / 2);
localparam AFI_RLAT_WIDTH                                       = 5;
localparam AFI_OTF_BITNUM                                       = 12;
localparam AFI_AUTO_PRECHARGE_BITNUM                            = 10;
localparam AFI_MEM_CLK_DISABLE_WIDTH                            = CFG_MEM_IF_CLK_PAIR_COUNT;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Port Declarations
//
// in_afi
output  [AFI_CMD_WIDTH                                     - 1 : 0]    in_afi_rst_n;
output  [AFI_CS_WIDTH                                      - 1 : 0]    in_afi_cs_n;
output  [AFI_CKE_WIDTH                                     - 1 : 0]    in_afi_cke;
output  [AFI_ODT_WIDTH                                     - 1 : 0]    in_afi_odt;
output  [AFI_ADDR_WIDTH                                    - 1 : 0]    in_afi_addr;
output  [AFI_BA_WIDTH                                      - 1 : 0]    in_afi_ba;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    in_afi_ras_n;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    in_afi_cas_n;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    in_afi_we_n;
output  [AFI_DQS_BURST_WIDTH                               - 1 : 0]    in_afi_dqs_burst;
output  [AFI_WDATA_VALID_WIDTH                             - 1 : 0]    in_afi_wdata_valid;
output  [AFI_WDATA_WIDTH                                   - 1 : 0]    in_afi_wdata;
output  [AFI_DM_WIDTH                                      - 1 : 0]    in_afi_dm;
input   [AFI_WLAT_WIDTH                                    - 1 : 0]    in_afi_wlat;
output  [AFI_RDATA_EN_WIDTH                                - 1 : 0]    in_afi_rdata_en;
input   [AFI_RDATA_WIDTH                                   - 1 : 0]    in_afi_rdata;
input   [AFI_RDATA_VALID_WIDTH                             - 1 : 0]    in_afi_rdata_valid;
input   [AFI_RLAT_WIDTH                                    - 1 : 0]    in_afi_rlat;
input                                                                  in_afi_cal_success;
input                                                                  in_afi_cal_fail;
output                                                                 in_afi_cal_req;
output  [AFI_MEM_CLK_DISABLE_WIDTH                         - 1 : 0]    in_afi_mem_clk_disable;
output  [AFI_CAL_BYTE_LANE_SEL_N_WIDTH                     - 1 : 0]    in_afi_cal_byte_lane_sel_n;

// local
input                                                                  local_init_done;
input                                                                  local_refresh_ack;
input                                                                  local_powerdn_ack;
input                                                                  local_self_rfsh_ack;
output                                                                 local_autopch_req;
output                                                                 local_refresh_req;
output  [CFG_MEM_IF_CHIP                                   - 1 : 0]    local_refresh_chip;
output                                                                 local_self_rfsh_req;
output  [CFG_MEM_IF_CHIP                                   - 1 : 0]    local_self_rfsh_chip;

// out_afi
input  [AFI_CMD_WIDTH                                     - 1 : 0]     out_afi_rst_n;
input  [AFI_CS_WIDTH                                      - 1 : 0]     out_afi_cs_n;
input  [AFI_CKE_WIDTH                                     - 1 : 0]     out_afi_cke;
input  [AFI_ODT_WIDTH                                     - 1 : 0]     out_afi_odt;
input  [AFI_ADDR_WIDTH                                    - 1 : 0]     out_afi_addr;
input  [AFI_BA_WIDTH                                      - 1 : 0]     out_afi_ba;
input  [AFI_CMD_WIDTH                                     - 1 : 0]     out_afi_ras_n;
input  [AFI_CMD_WIDTH                                     - 1 : 0]     out_afi_cas_n;
input  [AFI_CMD_WIDTH                                     - 1 : 0]     out_afi_we_n;
input  [AFI_DQS_BURST_WIDTH                               - 1 : 0]     out_afi_dqs_burst;
input  [AFI_WDATA_VALID_WIDTH                             - 1 : 0]     out_afi_wdata_valid;
input  [AFI_WDATA_WIDTH                                   - 1 : 0]     out_afi_wdata;
input  [AFI_DM_WIDTH                                      - 1 : 0]     out_afi_dm;
output [AFI_WLAT_WIDTH                                    - 1 : 0]     out_afi_wlat;
input  [AFI_RDATA_EN_WIDTH                                - 1 : 0]     out_afi_rdata_en;
output [AFI_RDATA_WIDTH                                   - 1 : 0]     out_afi_rdata;
output [AFI_RDATA_VALID_WIDTH                             - 1 : 0]     out_afi_rdata_valid;
output [AFI_RLAT_WIDTH                                    - 1 : 0]     out_afi_rlat;
output                                                                 out_afi_cal_success;
output                                                                 out_afi_cal_fail;
input                                                                  out_afi_cal_req;
input  [AFI_MEM_CLK_DISABLE_WIDTH                         - 1 : 0]     out_afi_mem_clk_disable;
input  [AFI_CAL_BYTE_LANE_SEL_N_WIDTH                     - 1 : 0]     out_afi_cal_byte_lane_sel_n;

// status
output                                                                 status_cal_fail;
output                                                                 status_cal_success;
output                                                                 status_init_done;


//////////////////////////////////////////////////////////////////////////////////////////////////////
// Create the output assignments. Acts as a "bridge".
//
assign    in_afi_rst_n                    = out_afi_rst_n;
assign    in_afi_cs_n                     = out_afi_cs_n;
assign    in_afi_cke                      = out_afi_cke;
assign    in_afi_odt                      = out_afi_odt;
assign    in_afi_addr                     = out_afi_addr;
assign    in_afi_ba                       = out_afi_ba;
assign    in_afi_ras_n                    = out_afi_ras_n;
assign    in_afi_cas_n                    = out_afi_cas_n;
assign    in_afi_we_n                     = out_afi_we_n; 
assign    in_afi_dqs_burst                = out_afi_dqs_burst;
assign    in_afi_wdata_valid              = out_afi_wdata_valid;
assign    in_afi_wdata                    = out_afi_wdata;
assign    in_afi_dm                       = out_afi_dm;
assign    out_afi_wlat                    = in_afi_wlat;
assign    in_afi_rdata_en                 = out_afi_rdata_en;
assign    out_afi_rdata                   = in_afi_rdata;
assign    out_afi_rdata_valid             = in_afi_rdata_valid;
assign    out_afi_rlat                    = in_afi_rlat;
assign    out_afi_cal_success             = in_afi_cal_success;
assign    out_afi_cal_fail                = in_afi_cal_fail;
assign    in_afi_cal_req                  = out_afi_cal_req;
assign    in_afi_mem_clk_disable          = out_afi_mem_clk_disable;
assign    in_afi_cal_byte_lane_sel_n      = out_afi_cal_byte_lane_sel_n;

assign    status_cal_fail                 = in_afi_cal_fail;
assign    status_cal_success              = in_afi_cal_success;
assign    status_init_done                = local_init_done;

// Done
endmodule


