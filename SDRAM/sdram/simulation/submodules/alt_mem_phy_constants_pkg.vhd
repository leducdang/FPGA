-- (C) 2001-2022 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files from any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel FPGA IP License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


--#mw_delete ("")
--   Legal Notice: (C)2006 Altera Corporation. All rights reserved.  Your
--   use of Altera Corporation's design tools, logic functions and other
--   software and tools, and its AMPP partner logic functions, and any
--   output files any of the foregoing (including device programming or
--   simulation files), and any associated documentation or information are
--   expressly subject to the terms and conditions of the Altera Program
--   License Subscription Agreement or other applicable license agreement,
--   including, without limitation, that your use is for the sole purpose
--   of programming logic devices manufactured by Altera and sold by Altera
--   or its authorized distributors.  Please refer to the applicable
--   agreement for further details.
--
--
-------------------------------------------------------------------------------
--  Title           : Constants and Functions
--
--  File:  $RCSfile : alt_mem_phy_constants_pkg.vhd,v $
--
--  Last Modified   : $Date: 2018/07/18 $
--
--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : constants package for the non-levelling AFI PHY sequencer
--                    The constant package (alt_mem_phy_constants_pkg) contains global
--                    'constants' which are fixed thoughout the sequencer and will not
--                    change (for constants which may change between sequencer
--                    instances generics are used)
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--#mw_prefix ("alt_mem_phy_constants_pkg")
package alt_mem_phy_constants_pkg is
--#end

    -- -------------------------------
    -- Register number definitions
    -- -------------------------------


    constant c_max_mode_reg_index          : natural := 13;   -- number of MR bits..

    -- Top bit of vector (i.e. width -1) used for address decoding :
    constant c_debug_reg_addr_top          : natural := 3;


    constant c_mmi_access_codeword         : std_logic_vector(31 downto 0) := X"00D0_0DEB";  -- to check for legal Avalon interface accesses
    -- Register addresses.
    constant c_regofst_cal_status          : natural := 0;
    constant c_regofst_debug_access        : natural := 1;
    constant c_regofst_hl_css              : natural := 2;
    constant c_regofst_mr_register_a       : natural := 5;
    constant c_regofst_mr_register_b       : natural := 6;
    constant c_regofst_codvw_status        : natural := 12;
    constant c_regofst_if_param            : natural := 13;
    constant c_regofst_if_test             : natural := 14;   -- pll_phs_shft, ac_1t, extra stuff
    constant c_regofst_test_status         : natural := 15;


    constant c_hl_css_reg_cal_dis_bit                    : natural := 0;
    constant c_hl_css_reg_phy_initialise_dis_bit         : natural := 1;
    constant c_hl_css_reg_init_dram_dis_bit              : natural := 2;
    constant c_hl_css_reg_write_ihi_dis_bit              : natural := 3;
    constant c_hl_css_reg_write_btp_dis_bit              : natural := 4;
    constant c_hl_css_reg_write_mtp_dis_bit              : natural := 5;
    constant c_hl_css_reg_read_mtp_dis_bit               : natural := 6;
    constant c_hl_css_reg_rrp_reset_dis_bit              : natural := 7;
    constant c_hl_css_reg_rrp_sweep_dis_bit              : natural := 8;
    constant c_hl_css_reg_rrp_seek_dis_bit               : natural := 9;
    constant c_hl_css_reg_rdv_dis_bit                    : natural := 10;
    constant c_hl_css_reg_poa_dis_bit                    : natural := 11;
    constant c_hl_css_reg_was_dis_bit                    : natural := 12;
    constant c_hl_css_reg_adv_rd_lat_dis_bit             : natural := 13;
    constant c_hl_css_reg_adv_wr_lat_dis_bit             : natural := 14;
    constant c_hl_css_reg_prep_customer_mr_setup_dis_bit : natural := 15;
    constant c_hl_css_reg_tracking_dis_bit               : natural := 16;

    constant c_hl_ccs_num_stages                         : natural := 17;


    -- -----------------------------------------------------
    -- Constants for DRAM addresses used during calibration:
    -- -----------------------------------------------------

    -- the mtp training pattern is x30F5
    -- 1. write 0011 0000 and 1100 0000 such that one location will contains 0011 0000
    -- 2. write in 1111 0101
    -- also require locations containing all ones and all zeros

    -- default choice of calibration burst length (overriden to 8 for reads for DDR3 devices)
    constant c_cal_burst_len        : natural := 4;

    constant c_cal_ofs_step_size    : natural := 8;

    constant c_cal_ofs_zeros        : natural := 0 * c_cal_ofs_step_size;
    constant c_cal_ofs_ones         : natural := 1 * c_cal_ofs_step_size;

    constant c_cal_ofs_x30_almt_0   : natural := 2 * c_cal_ofs_step_size;
    constant c_cal_ofs_x30_almt_1   : natural := 3 * c_cal_ofs_step_size;

    constant c_cal_ofs_xF5          : natural := 5 * c_cal_ofs_step_size;

    constant c_cal_ofs_wd_lat       : natural := 6 * c_cal_ofs_step_size;

    constant c_cal_data_len         : natural := c_cal_ofs_wd_lat + c_cal_ofs_step_size;

    -- #pb_del these next seven constants should not be required.
    constant c_cal_ofs_mtp	        : natural := 6*c_cal_ofs_step_size;
    constant c_cal_ofs_mtp_len      : natural := 4*4;
    constant c_cal_ofs_01_pairs     : natural := 2 * c_cal_burst_len;
    constant c_cal_ofs_10_pairs     : natural := 3 * c_cal_burst_len;
    constant c_cal_ofs_1100_step    : natural := 4 * c_cal_burst_len;
    constant c_cal_ofs_0011_step    : natural := 5 * c_cal_burst_len;


    -- -----------------------------------------------------
    -- Reset values. - These are chosen as default values for one PHY variation
    --                 with DDR2 memory and CAS latency 6, however in each calibration
    --                 mode these values will be set for a given PHY configuration.
    -- #pb_del   Note: more PHY parameters than memory type and CAS latency effect
    -- #pb_del         the rd and wr latency figures quoted here.
    -- -----------------------------------------------------
    constant c_default_rd_lat : natural := 20;
    constant c_default_wr_lat : natural := 5;


    -- -----------------------------------------------------
    -- Errorcodes
    -- -----------------------------------------------------
    -- implemented
    constant C_SUCCESS                             : natural := 0;
    constant C_ERR_RESYNC_NO_VALID_PHASES          : natural := 5;  -- No valid data-valid windows found
    constant C_ERR_RESYNC_MULTIPLE_EQUAL_WINDOWS   : natural := 6;  -- Multiple equally-sized data valid windows
    constant C_ERR_RESYNC_NO_INVALID_PHASES        : natural := 7;  -- No invalid data-valid windows found.  Training patterns are designed so that there should always be at least one invalid phase.
    constant C_ERR_CRITICAL                        : natural := 15; -- A condition that can't happen just happened.

    constant C_ERR_READ_MTP_NO_VALID_ALMT          : natural := 23;
    constant C_ERR_READ_MTP_BOTH_ALMT_PASS         : natural := 24;

	constant C_ERR_WD_LAT_DISAGREEMENT			   : natural := 22; -- MEM_IF_DWIDTH/MEM_IF_DQ_PER_DQS copies of write-latency are written to memory.  If all of these are not the same this error is generated.
    constant C_ERR_MAX_RD_LAT_EXCEEDED             : natural := 25;

    constant C_ERR_MAX_TRK_SHFT_EXCEEDED           : natural := 26;

    -- not implemented yet
    constant c_err_ac_lat_some_beats_are_different : natural := 1;    -- implies DQ_1T setup failure or earlier.
    constant c_err_could_not_find_read_lat         : natural := 2;    -- dodgy RDP setup
    constant c_err_could_not_find_write_lat        : natural := 3;    -- dodgy WDP setup

    constant c_err_clock_cycle_iteration_timeout   : natural :=  8;    -- depends on srate calling error  -- GENERIC
    constant c_err_clock_cycle_it_timeout_rdp      : natural :=  9;
    constant c_err_clock_cycle_it_timeout_rdv      : natural := 10;
    constant c_err_clock_cycle_it_timeout_poa      : natural := 11;

    constant c_err_pll_ack_timeout                 : natural := 13;

    constant c_err_WindowProc_multiple_rsc_windows : natural := 16;
    constant c_err_WindowProc_window_det_no_ones   : natural := 17;
    constant c_err_WindowProc_window_det_no_zeros  : natural := 18;
    constant c_err_WindowProc_undefined            : natural := 19;   -- catch all

    constant c_err_tracked_mmc_offset_overflow     : natural := 20;
    constant c_err_no_mimic_feedback               : natural := 21;

    constant c_err_ctrl_ack_timeout                : natural := 32;
    constant c_err_ctrl_done_timeout               : natural := 33;

    -- -----------------------------------------------------
    -- PLL phase locations per device family
    -- (unused but a limited set is maintained here for reference)
    -- -----------------------------------------------------

    constant c_pll_resync_phs_select_ciii : natural := 5;
    constant c_pll_mimic_phs_select_ciii  : natural := 4;

    constant c_pll_resync_phs_select_siii : natural := 5;
    constant c_pll_mimic_phs_select_siii  : natural := 7;

    -- -----------------------------------------------------
    -- Maximum sizing constraints
    -- -----------------------------------------------------
    constant C_MAX_NUM_PLL_RSC_PHASES : natural := 32;

    -- -----------------------------------------------------
    -- IO control Params
    -- -----------------------------------------------------
    constant c_set_oct_to_rs : std_logic := '0';
    constant c_set_oct_to_rt : std_logic := '1';

    constant c_set_odt_rt    : std_logic := '1';
    constant c_set_odt_off   : std_logic := '0';

--#mw_prefix ("alt_mem_phy_constants_pkg")
end alt_mem_phy_constants_pkg;
--#end
