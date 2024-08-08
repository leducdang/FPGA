# This file is auto-generated.
# It is used by make_qii_design.tcl and make_sim_design.tcl, and
# is not intended to be executed directly.

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
set ip_params(SHORT_QSYS_INTERFACE_NAMES) "true"
set ip_params(MEM_HAS_SIM_SUPPORT) "true"
set ed_params(EMIF_MODULE_NAME)    "alt_mem_if_civ_ddr2_emif"
set ed_params(EMIF_NAME)           "alt_mem_if_civ_ddr2_emif_0"
set ed_params(DEFAULT_DEVICE)      "EP4CE115F29C7"
set ed_params(SYNTH_QSYS_NAME)     "ed_synth"
set ed_params(SIM_QSYS_NAME)       "ed_sim"
set ed_params(TMP_SYNTH_QSYS_PATH) "C:/Users/DELL/AppData/Local/Temp/alt9919_2309074667928930051.dir/0002_alt_mem_if_civ_ddr2_emif_0_gen/ed_synth.qsys"
set ed_params(TMP_SIM_QSYS_PATH)   "C:/Users/DELL/AppData/Local/Temp/alt9919_2309074667928930051.dir/0002_alt_mem_if_civ_ddr2_emif_0_gen/ed_sim.qsys"
set pro_edition  false
