# This file is auto-generated.
# It is used by memphy.sdc for static timing analysis.

package require ::quartus::ddr_timing_model

set ip_params(SYS_INFO_DEVICE_FAMILY) "Cyclone IV E"
set ip_params(SYS_INFO_DEVICE) "EP4CE115F29C7"
set ip_params(ALT_MEM_IF_DEVICE_FAMILY) "Cyclone IV GX"
set ip_params(ALT_MEM_IF_SPEED_GRADE) "8L"
set ip_params(ALT_MEM_IF_PLL_REFCLK_FREQ) "50.0"
set ip_params(ALT_MEM_IF_MEM_CLK_FREQ) "100.0"
set ip_params(PHY_ADDR_CMD_CLOCK_PHASE) "90"
set ip_params(PHY_CALIBRATION_TYPE_FOR_SIMULATION) "Quick Calibration"
set ip_params(CTL_DATA_RATE) "Full"
set ip_params(CTL_ENABLE_SELF_REFRESH_CONTROLS) "false"
set ip_params(CTL_ENABLE_AUTO_POWER_DOWN) "false"
set ip_params(CTL_AUTO_POWER_DOWN_CYCLES) "0"
set ip_params(CTL_ENABLE_AUTO_REFRESH_CONTROLS) "false"
set ip_params(CTL_ENABLE_AUTO_PRECHARGE_CONTROL) "false"
set ip_params(CTL_ENABLE_REORDERING) "true"
set ip_params(CTL_REORDERING_STARVATION_LIMIT) "10"
set ip_params(CTL_LOCAL_TO_MEMORY_ADDRESS_MAPPING) "CHIP-ROW-BANK-COL"
set ip_params(CTL_COMMAND_QUEUE_LOOK_AHEAD_DEPTH) "4"
set ip_params(CTL_LOCAL_MAXIMUM_BURST_COUNT) "4"
set ip_params(CTL_ENABLE_CONFIG_STATUS_INTERFACE) "false"
set ip_params(CTL_ENABLE_ECC_LOGIC) "false"
set ip_params(CTL_ENABLE_AUTO_ECC) "false"
set ip_params(MEM_NUM_CLOCK_PAIRS) "1"
set ip_params(MEM_NUM_CHIP_SELECTS) "1"
set ip_params(MEM_TOTAL_DQ_WIDTH) "8"
set ip_params(MEM_BURST_LENGTH) "4"
set ip_params(MEM_BURST_ORDERING) "Sequential"
set ip_params(MEM_ENABLE_DEVICE_DLL) "true"
set ip_params(MEM_DRIVE_STRENGTH) "Normal"
set ip_params(MEM_ODT_SETTING) "Disabled"
set ip_params(MEM_CAS_LATENCY) "3"
set ip_params(MEM_ADDITIVE_CAS_LATENCY) "Disabled"
set ip_params(MEM_VENDOR) "JEDEC"
set ip_params(MEM_FORMAT) "Discrete Device"
set ip_params(MEM_MAX_MEM_FREQ) "200.0"
set ip_params(MEM_COLUMN_ADDR_WIDTH) "10"
set ip_params(MEM_ROW_ADDR_WIDTH) "13"
set ip_params(MEM_BANK_ADDR_WIDTH) "2"
set ip_params(MEM_CHIP_SELECTS_PER_DIMM) "1"
set ip_params(MEM_DQ_PER_DQS) "8"
set ip_params(MEM_PRECHARGE_ADDR_BIT) "10"
set ip_params(MEM_DRIVE_DM_PINS_FROM_FPGA) "true"
set ip_params(MEM_MEM_INIT_TIME_AT_POWER_UP) "200.0"
set ip_params(MEM_LOAD_MODE_REGISTER_COMMAND_PERIOD) "10.0"
set ip_params(MEM_ACTIVE_TO_PRECHARGE_TIME) "40.0"
set ip_params(MEM_ACTIVE_TO_READ_WRITE_TIME) "15.0"
set ip_params(MEM_PRECHARGE_COMMAND_PERIOD) "15.0"
set ip_params(MEM_REFRESH_COMMAND_INTERVAL) "7.0"
set ip_params(MEM_AUTO_REFRESH_COMMAND_INTERVAL) "75.0"
set ip_params(MEM_WRITE_RECOVERY_TIME) "15.0"
set ip_params(MEM_WRITE_TO_READ_PERIOD) "2"
set ip_params(MEM_DQ_OUTPUT_ACCESS_TIME_FROM_CK) "600"
set ip_params(MEM_DQ_DM_INPUT_SETUP_TIME_TO_DQS) "400"
set ip_params(MEM_DQ_DM_INPUT_HOLD_TIME_TO_DQS) "400"
set ip_params(MEM_DQS_OUTPUT_ACCESS_TIME_FROM_CK) "500"
set ip_params(MEM_DQS_DQ_SKEW) "400"
set ip_params(MEM_FIRST_DQS_EDGE_TO_ASSOC_CLOCK_EDGE) "0.25"
set ip_params(MEM_DQS_FALLING_EDGE_HOLD_TIME_FROM_CK) "0.2"
set ip_params(MEM_DQS_FALLING_EDGE_TO_CK_SETUP_TIME) "0.2"
set ip_params(MEM_ADDR_COMMAND_INPUT_SETUP_TIME) "600"
set ip_params(MEM_ADDR_COMMAND_INPUT_HOLD_TIME) "600"
set ip_params(MEM_DQ_HOLD_SKEW_FACTOR) "450"
set ip_params(MEM_FOUR_WINDOW_TIME) "37.5"
set ip_params(MEM_RAS_TO_RAS_DELAY) "7.5"
set ip_params(MEM_READ_TO_PRECHARGE_TIME) "7.5"
set ip_params(MEM_CAS_3_MAX_FREQ) "200.0"
set ip_params(MEM_CAS_4_MAX_FREQ) "200.0"
set ip_params(MEM_CAS_5_MAX_FREQ) "200.0"
set ip_params(MEM_CAS_6_MAX_FREQ) "200.0"
set ip_params(ALT_MEM_IF_ENABLE_DEBUG_INTERFACE) "false"
set ip_params(ALT_MEM_IF_ENABLE_SOFT_RESET_INTERFACE) "false"
set ip_params(ALT_MEM_IF_ENABLE_LOCAL_CTRL_INTERFACE) "false"
set ip_params(EX_DESIGN_SEL_DESIGN) "AltMemPHY Example Design"
set ip_params(EX_DESIGN_GEN_SIM) "true"
set ip_params(EX_DESIGN_GEN_SYNTH) "true"
set ip_params(EX_DESIGN_HDL_FORMAT) "Verilog"
set ip_params(DQS_OUT_MODE_INT) "2"
set ip_params(LOCAL_IF_CLK_MHZ) "100.0"
set ip_params(LOCAL_IF_CLK_PERIOD_PS) "10000"
set ip_params(MEM_TWR) "2"
set ip_params(PLL_REF_CLK_PERIOD_PS) "20000"
set ip_params(FAMILY) "Cyclone IV E"
set ip_params(MEM_IF_MEMTYPE) "DDR2"
set ip_params(LEVELLING) "0"
set ip_params(SPEED_GRADE) "C8L"
set ip_params(DLL_DELAY_BUFFER_MODE) "LOW"
set ip_params(DLL_DELAY_CHAIN_LENGTH) "12"
set ip_params(DQS_DELAY_CTL_WIDTH) "6"
set ip_params(DQS_OUT_MODE) "DELAY_CHAIN2"
set ip_params(DQS_PHASE) "6000"
set ip_params(DQS_PHASE_SETTING) "2"
set ip_params(DWIDTH_RATIO) "2"
set ip_params(MEM_IF_DWIDTH) "8"
set ip_params(MEM_IF_ADDR_WIDTH) "13"
set ip_params(MEM_IF_BANKADDR_WIDTH) "2"
set ip_params(MEM_IF_CS_WIDTH) "1"
set ip_params(MEM_IF_DM_WIDTH) "1"
set ip_params(MEM_IF_DM_PINS_EN) "1"
set ip_params(MEM_IF_DQ_PER_DQS) "8"
set ip_params(MEM_IF_DQS_WIDTH) "1"
set ip_params(MEM_IF_OCT_EN) "0"
set ip_params(MEM_IF_CLK_PAIR_COUNT) "1"
set ip_params(MEM_IF_CLK_PS) "10000"
set ip_params(MEM_IF_CLK_PS_STR) "10000 ps"
set ip_params(MEM_IF_MR_0) "562"
set ip_params(MEM_IF_MR_1) "1024"
set ip_params(MEM_IF_MR_2) "0"
set ip_params(MEM_IF_MR_3) "0"
set ip_params(MEM_IF_PRESET_RLAT) "0"
set ip_params(PLL_STEPS_PER_CYCLE) "80"
set ip_params(SCAN_CLK_DIVIDE_BY) "2"
set ip_params(REDUCE_SIM_TIME) "0"
set ip_params(CAPABILITIES) "2048"
set ip_params(TINIT_TCK) "200"
set ip_params(TINIT_RST) "0"
set ip_params(DBG_A_WIDTH) "13"
set ip_params(SEQ_STRING_ID) "seq_name"
set ip_params(MEM_IF_CS_PER_RANK) "1"
set ip_params(MEM_IF_RANKS_PER_SLOT) "1"
set ip_params(MEM_IF_RDV_PER_CHIP) "0"
set ip_params(GENERATE_ADDITIONAL_DBG_RTL) "0"
set ip_params(CAPTURE_PHASE_OFFSET) "0"
set ip_params(MEM_IF_ADDR_CMD_PHASE) "90"
set ip_params(DLL_EXPORT_IMPORT) "EXPORT"
set ip_params(MEM_IF_DQSN_EN) "0"
set ip_params(RANK_HAS_ADDR_SWAP) "0"
set ip_params(CLOCK_INDEX_WIDTH) "3"
set ip_params(ADV_LAT_WIDTH) "5"
set ip_params(RESYNCHRONISE_AVALON_DBG) "0"
set ip_params(RDP_ADDR_WIDTH) "4"
set ip_params(IOE_PHASES_PER_TCK) "12"
set ip_params(IOE_DELAYS_PER_PHS) "5"
set ip_params(MEM_IF_DQS_CAPTURE_EN) "0"
set ip_params(FAMILYGROUP_ID) "2"
set ip_params(SINGLE_DQS_DELAY_CONTROL_CODE) "0"
set ip_params(PRESET_RLAT) "0"
set ip_params(WRITE_DESKEW_T10) "0"
set ip_params(WRITE_DESKEW_HC_T10) "0"
set ip_params(WRITE_DESKEW_T9NI) "0"
set ip_params(WRITE_DESKEW_HC_T9NI) "0"
set ip_params(WRITE_DESKEW_T9I) "0"
set ip_params(WRITE_DESKEW_HC_T9I) "0"
set ip_params(WRITE_DESKEW_RANGE) "0"
set ip_params(IP_BUILDNUM) "0"
set ip_params(FORCE_HC) "0"
set ip_params(CHIP_OR_DIMM) "Discrete Device"
set ip_params(RDIMM_CONFIG_BITS) "0"
set ip_params(PLL_CLK0_DIVIDE_BY) "1"
set ip_params(PLL_CLK0_MULTIPLY_BY) "1"
set ip_params(PLL_CLK0_PHASE_SHIFT_PS) "0"
set ip_params(PLL_CLK1_DIVIDE_BY) "1"
set ip_params(PLL_CLK1_MULTIPLY_BY) "2"
set ip_params(PLL_CLK1_PHASE_SHIFT_PS) "0"
set ip_params(PLL_CLK2_DIVIDE_BY) "1"
set ip_params(PLL_CLK2_MULTIPLY_BY) "2"
set ip_params(PLL_CLK2_PHASE_SHIFT_PS) "-2917"
set ip_params(PLL_CLK3_DIVIDE_BY) "1"
set ip_params(PLL_CLK3_MULTIPLY_BY) "2"
set ip_params(PLL_CLK3_PHASE_SHIFT_PS) "0"
set ip_params(PLL_CLK4_DIVIDE_BY) "1"
set ip_params(PLL_CLK4_MULTIPLY_BY) "2"
set ip_params(PLL_CLK4_PHASE_SHIFT_PS) "0"
set ip_params(PLL_INCLK0_PERIOD_PS) "20000"
set ip_params(PLL_INTENDED_DEVICE_FAMILY) "Cyclone IV E"
set ip_params(PLL_VCO_PHASE_SHIFT_STEP) "125"
# Clock period and worst case skew between any pair of traces
set ::t(period) 5.000
set ::t(board_skew) 0.020
set ::t(min_additional_dqs_variation) 0.000
set ::t(max_additional_dqs_variation) 0.000

# Memory timing parameters

# tDS/tDH: write timing
set ::t(DS) [expr double($ip_params(MEM_DQ_DM_INPUT_SETUP_TIME_TO_DQS))/1000]
set ::t(DH) [expr double($ip_params(MEM_DQ_DM_INPUT_HOLD_TIME_TO_DQS))/1000]

# Data output timing for non-DQS capture
set ::t(AC) [expr double($ip_params(MEM_DQ_OUTPUT_ACCESS_TIME_FROM_CK))/1000]

# Address and command input timing
set ::t(IS) [expr double($ip_params(MEM_ADDR_COMMAND_INPUT_SETUP_TIME))/1000]
set ::t(IH) [expr double($ip_params(MEM_ADDR_COMMAND_INPUT_HOLD_TIME))/1000]

# DQS to CK input timing
set ::t(DSS) [expr double($ip_params(MEM_DQS_FALLING_EDGE_TO_CK_SETUP_TIME))/1000]
set ::t(DSH) [expr double($ip_params(MEM_DQS_FALLING_EDGE_HOLD_TIME_FROM_CK))/1000]
set ::t(DQSS) [expr double($ip_params(MEM_FIRST_DQS_EDGE_TO_ASSOC_CLOCK_EDGE))/1000]

# DQ to DQS timing on read
set ::t(DQSQ) [expr double($ip_params(MEM_DQS_DQ_SKEW))/1000]
set ::t(QHS) [expr double($ip_params(MEM_DQ_HOLD_SKEW_FACTOR))/1000]

# DQS to CK timing on reads
set ::t(DQSCK) [expr double($ip_params(MEM_DQS_OUTPUT_ACCESS_TIME_FROM_CK))/1000]
set ::t(HP) 2.250

# The maximum allowed length of the mimic path depends on the device family
set ::t(mimic_shift) 2.500
# The clock period of the PLL reference clock
set ::t(inclk_period) [expr (1/$ip_params(ALT_MEM_IF_PLL_REFCLK_FREQ))*1000]

# Duty cycle distortion from the device data sheet
set ::t(DCD_total) 0.250
# PLL phase shift error
set ::t(PLL_PSERR) 0.000

# SSN Info
set package_type [get_package_type]
set ::SSN(pushout_o) [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSABSOLUTE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(pullin_o)  [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSABSOLUTE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(pushout_i) [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSABSOLUTE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(pullin_i)  [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSABSOLUTE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(rel_pushout_o) [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSRELATIVE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(rel_pullin_o)  [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSRELATIVE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(rel_pushout_i) [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSRELATIVE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(rel_pullin_i)  [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSRELATIVE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]

# Board skews
set ::board(minCK_DQS_skew) -0.010
set ::board(maxCK_DQS_skew) 0.010
set ::board(tpd_inter_DIMM) 0.050
set ::board(intra_DQS_group_skew) 0.020
set ::board(inter_DQS_group_skew) 0.020
set ::board(addresscmd_CK_skew) 0.000
set ::t(additional_addresscmd_tpd) $::board(addresscmd_CK_skew)

# ISI effects
set ::ISI(addresscmd_setup) 0.000
set ::ISI(addresscmd_hold) 0.000
set ::ISI(DQ) 0.000
set ::ISI(DQS) 0.000

set amp_phy_use_flexible_timing 1

set corename ed_sim_ed_sim_emif_ed_emif_phy
