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


//////////////////////////////////////////////////////////////////////////////
// This module is a wrapper for the soft IP NextGen controller and the MMR
// This file is only used for the ALTMEMPHY flow
//////////////////////////////////////////////////////////////////////////////

//altera message_off 10230

`include "alt_mem_ddrx_define.iv"

`timescale 1 ps / 1 ps

//#mw_prefix("alt_mem_ddrx_controller_top")
module ed_sim_ed_sim_emif_ed_emif_ctl(
//#end
    clk,
    half_clk,
    reset_n,
    local_ready,
    local_write_req,
    local_read_req,
    local_address,
    local_be,
    local_wdata,
    local_size,
    local_burstbegin,
    local_rdata,
    local_rdata_valid,
    afi_rst_n,
    afi_cs_n,
    afi_cke,
    afi_odt,
    afi_addr,
    afi_ba,
    afi_ras_n,
    afi_cas_n,
    afi_we_n,
    afi_dqs_burst,
    afi_wdata_valid,
    afi_wdata,
    afi_dm,
    afi_wlat,
    afi_rdata_en,
    afi_rdata_en_full,
    afi_rdata,
    afi_rdata_valid,
    afi_rlat,
    afi_cal_success,
    afi_cal_fail,
    afi_cal_req,
    afi_mem_clk_disable,
    afi_cal_byte_lane_sel_n,
    afi_ctl_refresh_done,
    afi_seq_busy,
    afi_ctl_long_idle,
    local_init_done,
    local_refresh_ack,
    local_powerdn_ack,
    local_self_rfsh_ack,
    local_autopch_req,
    local_refresh_req,
    local_refresh_chip,
    local_powerdn_req,
    local_self_rfsh_req,
    local_self_rfsh_chip,
    local_multicast,
    local_priority,
    ecc_interrupt,
    csr_read_req,
    csr_write_req,
    csr_burst_count,
    csr_beginbursttransfer,
    csr_addr,
    csr_wdata,
    csr_rdata,
    csr_be,
    csr_rdata_valid,
    csr_waitrequest
);

//////////////////////////////////////////////////////////////////////////////
// << START MEGAWIZARD INSERT GENERICS
// #mw_generic_list("controller_generics")
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

//#end
// << END MEGAWIZARD INSERT GENERICS
//////////////////////////////////////////////////////////////////////////////

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

// KALEN HACK: We are supposed to use these parameters when the CSR is enabled
// but the MAX_ parameters are not defined
//localparam AFI_CS_WIDTH                                         = (MAX_MEM_IF_CHIP * (CFG_DWIDTH_RATIO / 2));
//localparam AFI_CKE_WIDTH                                        = (MAX_CFG_MEM_IF_CHIP * (CFG_DWIDTH_RATIO / 2));
//localparam AFI_ODT_WIDTH                                        = (MAX_CFG_MEM_IF_CHIP * (CFG_DWIDTH_RATIO / 2));
//localparam AFI_ADDR_WIDTH                                       = (MAX_CFG_MEM_IF_ADDR_WIDTH * (CFG_DWIDTH_RATIO / 2));
//localparam AFI_BA_WIDTH                                         = (MAX_CFG_MEM_IF_BA_WIDTH * (CFG_DWIDTH_RATIO / 2));
//localparam AFI_CAL_BYTE_LANE_SEL_N_WIDTH                        = (CFG_MEM_IF_DQS_WIDTH * MAX_CFG_MEM_IF_CHIP);

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

localparam CFG_MM_ST_CONV_REG									= 0;
localparam CFG_ECC_DECODER_REG									= 0;
localparam CFG_ERRCMD_FIFO_REG									= 0;

//////////////////////////////////////////////////////////////////////////////
// BEGIN PORT SECTION

// Clk and reset signals
input                                                                  clk;
input                                                                  half_clk;
input                                                                  reset_n;

// Avalon signals
output                                                                 local_ready;
input                                                                  local_write_req;
input                                                                  local_read_req;
input   [LOCAL_ADDR_WIDTH                                  - 1 : 0]    local_address;
input   [LOCAL_BE_WIDTH                                    - 1 : 0]    local_be;
input   [LOCAL_DATA_WIDTH                                  - 1 : 0]    local_wdata;
input   [LOCAL_SIZE_WIDTH                                  - 1 : 0]    local_size;
input                                                                  local_burstbegin;
output  [LOCAL_DATA_WIDTH                                  - 1 : 0]    local_rdata;
output                                                                 local_rdata_valid;

// AFI signals
output  [AFI_CMD_WIDTH                                     - 1 : 0]    afi_rst_n;
output  [AFI_CS_WIDTH                                      - 1 : 0]    afi_cs_n;
output  [AFI_CKE_WIDTH                                     - 1 : 0]    afi_cke;
output  [AFI_ODT_WIDTH                                     - 1 : 0]    afi_odt;
output  [AFI_ADDR_WIDTH                                    - 1 : 0]    afi_addr;
output  [AFI_BA_WIDTH                                      - 1 : 0]    afi_ba;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    afi_ras_n;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    afi_cas_n;
output  [AFI_CMD_WIDTH                                     - 1 : 0]    afi_we_n;
output  [AFI_DQS_BURST_WIDTH                               - 1 : 0]    afi_dqs_burst;
output  [AFI_WDATA_VALID_WIDTH                             - 1 : 0]    afi_wdata_valid;
output  [AFI_WDATA_WIDTH                                   - 1 : 0]    afi_wdata;
output  [AFI_DM_WIDTH                                      - 1 : 0]    afi_dm;
input   [AFI_WLAT_WIDTH                                    - 1 : 0]    afi_wlat;
output  [AFI_RDATA_EN_WIDTH                                - 1 : 0]    afi_rdata_en;
output  [AFI_RDATA_EN_WIDTH                                - 1 : 0]    afi_rdata_en_full;
input   [AFI_RDATA_WIDTH                                   - 1 : 0]    afi_rdata;
input   [AFI_RDATA_VALID_WIDTH                             - 1 : 0]    afi_rdata_valid;
input   [AFI_RLAT_WIDTH                                    - 1 : 0]    afi_rlat;
input                                                                  afi_cal_success;
input                                                                  afi_cal_fail;
output                                                                 afi_cal_req;
output  [AFI_MEM_CLK_DISABLE_WIDTH                         - 1 : 0]    afi_mem_clk_disable;
output  [AFI_CAL_BYTE_LANE_SEL_N_WIDTH                     - 1 : 0]    afi_cal_byte_lane_sel_n;
output  [CFG_MEM_IF_CHIP                                   - 1 : 0]    afi_ctl_refresh_done;
input   [CFG_MEM_IF_CHIP                                   - 1 : 0]    afi_seq_busy;
output  [CFG_MEM_IF_CHIP                                   - 1 : 0]    afi_ctl_long_idle;

// Sideband signals
output                                                                 local_init_done;
output                                                                 local_refresh_ack;
output                                                                 local_powerdn_ack;
output                                                                 local_self_rfsh_ack;
input                                                                  local_autopch_req;
input                                                                  local_refresh_req;
input   [CFG_MEM_IF_CHIP                                   - 1 : 0]    local_refresh_chip;
input                                                                  local_powerdn_req;
input                                                                  local_self_rfsh_req;
input   [CFG_MEM_IF_CHIP                                   - 1 : 0]    local_self_rfsh_chip;
input                                                                  local_multicast;
input                                                                  local_priority;

// Csr & ecc signals
output                                                                 ecc_interrupt;
input                                                                  csr_read_req;
input                                                                  csr_write_req;
input   [1                                                 - 1 : 0]    csr_burst_count;
input                                                                  csr_beginbursttransfer;
input   [CSR_ADDR_WIDTH                                    - 1 : 0]    csr_addr;
input   [CSR_DATA_WIDTH                                    - 1 : 0]    csr_wdata;
output  [CSR_DATA_WIDTH                                    - 1 : 0]    csr_rdata;
input   [CSR_BE_WIDTH                                      - 1 : 0]    csr_be;
output                                                                 csr_rdata_valid;
output                                                                 csr_waitrequest;

// END PORT SECTION
//////////////////////////////////////////////////////////////////////////////

wire                                                                   itf_cmd_ready;
wire                                                                   itf_cmd_valid;
wire                                                                   itf_cmd;
wire    [LOCAL_ADDR_WIDTH                                  - 1 : 0]    itf_cmd_address;
wire    [LOCAL_SIZE_WIDTH                                  - 1 : 0]    itf_cmd_burstlen;
wire                                                                   itf_cmd_id;
wire                                                                   itf_cmd_priority;
wire                                                                   itf_cmd_autopercharge;
wire                                                                   itf_cmd_multicast;
wire                                                                   itf_wr_data_ready;
wire                                                                   itf_wr_data_valid;
wire    [LOCAL_DATA_WIDTH                                  - 1 : 0]    itf_wr_data;
wire    [LOCAL_BE_WIDTH                                    - 1 : 0]    itf_wr_data_byte_en;
wire                                                                   itf_wr_data_begin;
wire                                                                   itf_wr_data_last;
wire    [CFG_LOCAL_ID_WIDTH                                - 1 : 0]    itf_wr_data_id;
wire                                                                   itf_rd_data_ready;
wire                                                                   itf_rd_data_valid;
wire    [LOCAL_DATA_WIDTH                                  - 1 : 0]    itf_rd_data;
wire    [2                                                 - 1 : 0]    itf_rd_data_error;
wire                                                                   itf_rd_data_begin;
wire                                                                   itf_rd_data_last;
wire    [CFG_LOCAL_ID_WIDTH                                - 1 : 0]    itf_rd_data_id;

// Converter
alt_mem_ddrx_mm_st_converter # (
    .AVL_SIZE_WIDTH                                   ( LOCAL_SIZE_WIDTH                               ),
    .AVL_ADDR_WIDTH                                   ( LOCAL_ADDR_WIDTH                               ),
    .AVL_DATA_WIDTH                                   ( LOCAL_DATA_WIDTH                               ),
	.CFG_MM_ST_CONV_REG								  ( CFG_MM_ST_CONV_REG							   )
) mm_st_converter_inst (
    .ctl_clk                                            ( clk                                                ),
    .ctl_reset_n                                        ( reset_n                                            ),
    .ctl_half_clk                                       ( half_clk                                           ),
    .ctl_half_clk_reset_n                               ( reset_n                                            ),
    .avl_ready                                          ( local_ready                                        ),
    .avl_read_req                                       ( local_read_req                                     ),
    .avl_write_req                                      ( local_write_req                                    ),
    .avl_size                                           ( local_size                                         ),
    .avl_burstbegin                                     ( local_burstbegin                                   ),
    .avl_addr                                           ( local_address                                      ),
    .avl_rdata_valid                                    ( local_rdata_valid                                  ),
    .local_rdata_error                                  (                                                    ),
    .avl_rdata                                          ( local_rdata                                        ),
    .avl_wdata                                          ( local_wdata                                        ),
    .avl_be                                             ( local_be                                           ),
    .local_multicast                                    ( local_multicast                                    ),
    .local_autopch_req                                  ( local_autopch_req                                  ),
    .local_priority                                     ( local_priority                                     ),

    .itf_cmd_ready                                      ( itf_cmd_ready                                      ),
    .itf_cmd_valid                                      ( itf_cmd_valid                                      ),
    .itf_cmd                                            ( itf_cmd                                            ),
    .itf_cmd_address                                    ( itf_cmd_address                                    ),
    .itf_cmd_burstlen                                   ( itf_cmd_burstlen                                   ),
    .itf_cmd_id                                         ( itf_cmd_id                                         ),
    .itf_cmd_priority                                   ( itf_cmd_priority                                   ),
    .itf_cmd_autopercharge                              ( itf_cmd_autopercharge                              ),
    .itf_cmd_multicast                                  ( itf_cmd_multicast                                  ),

    .itf_wr_data_ready                                  ( itf_wr_data_ready                                  ),
    .itf_wr_data_valid                                  ( itf_wr_data_valid                                  ),
    .itf_wr_data                                        ( itf_wr_data                                        ),
    .itf_wr_data_byte_en                                ( itf_wr_data_byte_en                                ),
    .itf_wr_data_begin                                  ( itf_wr_data_begin                                  ),
    .itf_wr_data_last                                   ( itf_wr_data_last                                   ),
    .itf_wr_data_id                                     ( itf_wr_data_id                                     ),

    .itf_rd_data_ready                                  ( itf_rd_data_ready                                  ),
    .itf_rd_data_valid                                  ( itf_rd_data_valid                                  ),
    .itf_rd_data                                        ( itf_rd_data                                        ),
    .itf_rd_data_error                                  ( itf_rd_data_error                                  ),
    .itf_rd_data_begin                                  ( itf_rd_data_begin                                  ),
    .itf_rd_data_last                                   ( itf_rd_data_last                                   ),
    .itf_rd_data_id                                     ( itf_rd_data_id                                     )
);


// Next Gen Controller
//////////////////////////////////////////////////////////////////////////////

alt_mem_ddrx_controller_st_top #(
	.LOCAL_SIZE_WIDTH(LOCAL_SIZE_WIDTH),
	.LOCAL_ADDR_WIDTH(LOCAL_ADDR_WIDTH),
	.LOCAL_DATA_WIDTH(LOCAL_DATA_WIDTH),
	.LOCAL_BE_WIDTH(LOCAL_BE_WIDTH),
	.LOCAL_ID_WIDTH(LOCAL_ID_WIDTH),
	.LOCAL_CS_WIDTH(LOCAL_CS_WIDTH),
	.MEM_IF_ADDR_WIDTH(MEM_IF_ADDR_WIDTH),
	.MEM_IF_CLK_PAIR_COUNT(MEM_IF_CLK_PAIR_COUNT),
	.LOCAL_IF_TYPE(LOCAL_IF_TYPE),
	.DWIDTH_RATIO(DWIDTH_RATIO),
	.CTL_ODT_ENABLED(CTL_ODT_ENABLED),
	.CTL_OUTPUT_REGD(CTL_OUTPUT_REGD),
	.CTL_TBP_NUM(CTL_TBP_NUM),
	.WRBUFFER_ADDR_WIDTH(WRBUFFER_ADDR_WIDTH),
	.RDBUFFER_ADDR_WIDTH(RDBUFFER_ADDR_WIDTH),
	.MEM_IF_CS_WIDTH(MEM_IF_CS_WIDTH),
	.MEM_IF_CHIP(MEM_IF_CHIP),
	.MEM_IF_BANKADDR_WIDTH(MEM_IF_BANKADDR_WIDTH),
	.MEM_IF_ROW_WIDTH(MEM_IF_ROW_WIDTH),
	.MEM_IF_COL_WIDTH(MEM_IF_COL_WIDTH),
	.MEM_IF_ODT_WIDTH(MEM_IF_ODT_WIDTH),
	.MEM_IF_DQS_WIDTH(MEM_IF_DQS_WIDTH),
	.MEM_IF_DWIDTH(MEM_IF_DWIDTH),
	.MEM_IF_DM_WIDTH(MEM_IF_DM_WIDTH),
	.MAX_MEM_IF_CS_WIDTH(MAX_MEM_IF_CS_WIDTH),
	.MAX_MEM_IF_CHIP(MAX_MEM_IF_CHIP),
	.MAX_MEM_IF_BANKADDR_WIDTH(MAX_MEM_IF_BANKADDR_WIDTH),
	.MAX_MEM_IF_ROWADDR_WIDTH(MAX_MEM_IF_ROWADDR_WIDTH),
	.MAX_MEM_IF_COLADDR_WIDTH(MAX_MEM_IF_COLADDR_WIDTH),
	.MAX_MEM_IF_ODT_WIDTH(MAX_MEM_IF_ODT_WIDTH),
	.MAX_MEM_IF_DQS_WIDTH(MAX_MEM_IF_DQS_WIDTH),
	.MAX_MEM_IF_DQ_WIDTH(MAX_MEM_IF_DQ_WIDTH),
	.MAX_MEM_IF_MASK_WIDTH(MAX_MEM_IF_MASK_WIDTH),
	.MAX_LOCAL_DATA_WIDTH(MAX_LOCAL_DATA_WIDTH),
	.CFG_TYPE(CFG_TYPE),
	.CFG_INTERFACE_WIDTH(CFG_INTERFACE_WIDTH),
	.CFG_BURST_LENGTH(CFG_BURST_LENGTH),
	.CFG_DEVICE_WIDTH(CFG_DEVICE_WIDTH),
	.CFG_REORDER_DATA(CFG_REORDER_DATA),
	.CFG_DATA_REORDERING_TYPE(CFG_DATA_REORDERING_TYPE),
	.CFG_STARVE_LIMIT(CFG_STARVE_LIMIT),
	.CFG_ADDR_ORDER(CFG_ADDR_ORDER),
	.MEM_CAS_WR_LAT(MEM_CAS_WR_LAT),
	.MEM_ADD_LAT(MEM_ADD_LAT),
	.MEM_TCL(MEM_TCL),
	.MEM_TRRD(MEM_TRRD),
	.MEM_TFAW(MEM_TFAW),
	.MEM_TRFC(MEM_TRFC),
	.MEM_TREFI(MEM_TREFI),
	.MEM_TRCD(MEM_TRCD),
	.MEM_TRP(MEM_TRP),
	.MEM_TWR(MEM_TWR),
	.MEM_TWTR(MEM_TWTR),
	.MEM_TRTP(MEM_TRTP),
	.MEM_TRAS(MEM_TRAS),
	.MEM_TRC(MEM_TRC),
	.CFG_TCCD(CFG_TCCD),
	.MEM_AUTO_PD_CYCLES(MEM_AUTO_PD_CYCLES),
	.CFG_SELF_RFSH_EXIT_CYCLES(CFG_SELF_RFSH_EXIT_CYCLES),
	.CFG_PDN_EXIT_CYCLES(CFG_PDN_EXIT_CYCLES),
	.CFG_POWER_SAVING_EXIT_CYCLES(CFG_POWER_SAVING_EXIT_CYCLES),
	.CFG_MEM_CLK_ENTRY_CYCLES(CFG_MEM_CLK_ENTRY_CYCLES),
	.MEM_TMRD_CK(MEM_TMRD_CK),
	.CTL_ECC_ENABLED(CTL_ECC_ENABLED),
	.CTL_ECC_RMW_ENABLED(CTL_ECC_RMW_ENABLED),
	.CTL_ECC_MULTIPLES_16_24_40_72(CTL_ECC_MULTIPLES_16_24_40_72),
	.CFG_GEN_SBE(CFG_GEN_SBE),
	.CFG_GEN_DBE(CFG_GEN_DBE),
	.CFG_ENABLE_INTR(CFG_ENABLE_INTR),
	.CFG_MASK_SBE_INTR(CFG_MASK_SBE_INTR),
	.CFG_MASK_DBE_INTR(CFG_MASK_DBE_INTR),
	.CFG_MASK_CORRDROP_INTR(CFG_MASK_CORRDROP_INTR),
	.CFG_CLR_INTR(CFG_CLR_INTR),
	.CTL_USR_REFRESH(CTL_USR_REFRESH),
	.CTL_REGDIMM_ENABLED(CTL_REGDIMM_ENABLED),
	.CFG_WRITE_ODT_CHIP(CFG_WRITE_ODT_CHIP),
	.CFG_READ_ODT_CHIP(CFG_READ_ODT_CHIP),
	.CFG_PORT_WIDTH_WRITE_ODT_CHIP(CFG_PORT_WIDTH_WRITE_ODT_CHIP),
	.CFG_PORT_WIDTH_READ_ODT_CHIP(CFG_PORT_WIDTH_READ_ODT_CHIP),
	.MEM_IF_CKE_WIDTH(MEM_IF_CKE_WIDTH),
	.CTL_CSR_ENABLED(CTL_CSR_ENABLED),
	.CFG_ENABLE_NO_DM(CFG_ENABLE_NO_DM),
	.CSR_ADDR_WIDTH(CSR_ADDR_WIDTH),
	.CSR_DATA_WIDTH(CSR_DATA_WIDTH),
	.CSR_BE_WIDTH(CSR_BE_WIDTH),
	.CFG_WLAT_BUS_WIDTH(AFI_WLAT_WIDTH),
	.CFG_RLAT_BUS_WIDTH(AFI_RLAT_WIDTH),
	.MEM_IF_RD_TO_WR_TURNAROUND_OCT(MEM_IF_RD_TO_WR_TURNAROUND_OCT),
	.MEM_IF_WR_TO_RD_TURNAROUND_OCT(MEM_IF_WR_TO_RD_TURNAROUND_OCT),
	.CTL_RD_TO_PCH_EXTRA_CLK(CTL_RD_TO_PCH_EXTRA_CLK),
	.CTL_RD_TO_RD_DIFF_CHIP_EXTRA_CLK(CTL_RD_TO_RD_DIFF_CHIP_EXTRA_CLK),
	.CTL_WR_TO_WR_DIFF_CHIP_EXTRA_CLK(CTL_WR_TO_WR_DIFF_CHIP_EXTRA_CLK),
	.CFG_ECC_DECODER_REG(CFG_ECC_DECODER_REG),
	.CFG_ERRCMD_FIFO_REG(CFG_ERRCMD_FIFO_REG)
) controller_inst (
	.clk(clk),
	.half_clk(half_clk),
	.reset_n(reset_n),
	.itf_cmd_ready(itf_cmd_ready),
	.itf_cmd_valid(itf_cmd_valid),
	.itf_cmd(itf_cmd),
	.itf_cmd_address(itf_cmd_address),
	.itf_cmd_burstlen(itf_cmd_burstlen),
	.itf_cmd_id(itf_cmd_id),
	.itf_cmd_priority(itf_cmd_priority),
	.itf_cmd_autopercharge(itf_cmd_autopercharge),
	.itf_cmd_multicast(itf_cmd_multicast),
	.itf_wr_data_ready(itf_wr_data_ready),
	.itf_wr_data_valid(itf_wr_data_valid),
	.itf_wr_data(itf_wr_data),
	.itf_wr_data_byte_en(itf_wr_data_byte_en),
	.itf_wr_data_begin(itf_wr_data_begin),
	.itf_wr_data_last(itf_wr_data_last),
	.itf_wr_data_id(itf_wr_data_id),
	.itf_rd_data_ready(itf_rd_data_ready),
	.itf_rd_data_valid(itf_rd_data_valid),
	.itf_rd_data(itf_rd_data),
	.itf_rd_data_error(itf_rd_data_error),
	.itf_rd_data_begin(itf_rd_data_begin),
	.itf_rd_data_last(itf_rd_data_last),
	.itf_rd_data_id(itf_rd_data_id),
	.afi_rst_n(afi_rst_n),
	.afi_cs_n(afi_cs_n),
	.afi_cke(afi_cke),
	.afi_odt(afi_odt),
	.afi_addr(afi_addr),
	.afi_ba(afi_ba),
	.afi_ras_n(afi_ras_n),
	.afi_cas_n(afi_cas_n),
	.afi_we_n(afi_we_n),
	.afi_dqs_burst(afi_dqs_burst),
	.afi_wdata_valid(afi_wdata_valid),
	.afi_wdata(afi_wdata),
	.afi_dm(afi_dm),
	.afi_wlat(afi_wlat),
	.afi_rdata_en(afi_rdata_en),
	.afi_rdata_en_full(afi_rdata_en_full),
	.afi_rdata(afi_rdata),
	.afi_rdata_valid(afi_rdata_valid),
	.afi_rlat(afi_rlat),
	.afi_cal_success(afi_cal_success),
	.afi_cal_fail(afi_cal_fail),
	.afi_cal_req(afi_cal_req),
	.afi_mem_clk_disable(afi_mem_clk_disable),
	.afi_cal_byte_lane_sel_n(afi_cal_byte_lane_sel_n),
	.afi_ctl_refresh_done(afi_ctl_refresh_done),
	.afi_seq_busy(afi_seq_busy),
	.afi_ctl_long_idle(afi_ctl_long_idle),
	.local_init_done(local_init_done),
	.local_refresh_ack(local_refresh_ack),
	.local_powerdn_ack(local_powerdn_ack),
	.local_self_rfsh_ack(local_self_rfsh_ack),
	.local_refresh_req(local_refresh_req),
	.local_refresh_chip(local_refresh_chip),
	.local_powerdn_req(local_powerdn_req),
	.local_self_rfsh_req(local_self_rfsh_req),
	.local_self_rfsh_chip(local_self_rfsh_chip),
	.local_multicast(local_multicast),
	.local_priority(local_priority),
	.ecc_interrupt(ecc_interrupt),
	.csr_read_req(csr_read_req),
	.csr_write_req(csr_write_req),
	.csr_burst_count(csr_burst_count),
	.csr_beginbursttransfer(csr_beginbursttransfer),
	.csr_addr(csr_addr),
	.csr_wdata(csr_wdata),
	.csr_rdata(csr_rdata),
	.csr_be(csr_be),
	.csr_rdata_valid(csr_rdata_valid),
	.csr_waitrequest(csr_waitrequest)
);



endmodule

