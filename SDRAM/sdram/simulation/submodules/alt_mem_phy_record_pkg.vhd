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
--/* Legal Notice: (C)2006 Altera Corporation. All rights reserved.  Your
--   use of Altera Corporation's design tools, logic functions and other
--   software and tools, and its AMPP partner logic functions, and any
--   output files any of the foregoing (including device programming or
--   simulation files), and any associated documentation or information are
--   expressly subject to the terms and conditions of the Altera Program
--   License Subscription Agreement or other applicable license agreement,
--   including, without limitation, that your use is for the sole purpose
--   of programming logic devices manufactured by Altera and sold by Altera
--   or its authorized distributors.  Please refer to the applicable
--   agreement for further details. */


--/*-----------------------------------------------------------------------------
--  Title           : record package

--  File:  $RCSfile : alt_mem_phy_seq_record_pkg.vhd,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : record package for the non-levelling AFI sequencer
--                    The record package (alt_mem_phy_record_pkg) is used to combine
--                    command and status signals (into records) to be passed between
--                    sequencer blocks. It also contains type and record definitions
--                    for the stages of DRAM memory calibration.
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--#mw_prefix ("alt_mem_phy_record_pkg")
package alt_mem_phy_record_pkg is
--#end

    -- set some maximum constraints to bound natural numbers below
    constant c_max_num_dqs_groups : natural := 24;
    constant c_max_num_pins       : natural := 8;
    constant c_max_ranks          : natural := 16;
    constant c_max_pll_steps      : natural := 80;

-- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_record_pkg")
    constant record_report_prefix     : string  := "alt_mem_phy_record_pkg : ";
--#end


    type t_family is (
        cyclone3,
        stratix2,
        stratix3
    );

-- -----------------------------------------------------------------------
--  the following are required for the non-levelling AFI PHY sequencer block interfaces
-- -----------------------------------------------------------------------

    -- admin mode register settings (from mmi block)
    type t_admin_ctrl is record
        mr0 : std_logic_vector(12 downto 0);
        mr1 : std_logic_vector(12 downto 0);
        mr2 : std_logic_vector(12 downto 0);
        mr3 : std_logic_vector(12 downto 0);
    end record;

    function defaults return t_admin_ctrl;

    -- current admin status
    type t_admin_stat is record
        mr0       : std_logic_vector(12 downto 0);
        mr1       : std_logic_vector(12 downto 0);
        mr2       : std_logic_vector(12 downto 0);
        mr3       : std_logic_vector(12 downto 0);
        init_done : std_logic;
    end record;

    function defaults return t_admin_stat;

    -- mmi to iram ctrl signals
    type t_iram_ctrl is record
        addr    : natural range 0 to 1023;
        wdata   : std_logic_vector(31 downto 0);
        write   : std_logic;
        read    : std_logic;
    end record;

    function defaults return t_iram_ctrl;

   -- broadcast iram status to mmi and dgrb
    type t_iram_stat is record
        rdata            : std_logic_vector(31 downto 0);
        done             : std_logic;
        err              : std_logic;
        err_code         : std_logic_vector(3 downto 0);
        init_done        : std_logic;
        out_of_mem       : std_logic;
        contested_access : std_logic;
    end record;

    function defaults return t_iram_stat;

    -- codvw status signals from dgrb to mmi block
    type t_dgrb_mmi is record
        cal_codvw_phase   : std_logic_vector(7 downto 0);
        cal_codvw_size    : std_logic_vector(7 downto 0);
        codvw_trk_shift   : std_logic_vector(11 downto 0);
        codvw_grt_one_dvw : std_logic;
    end record;

    function defaults return t_dgrb_mmi;

    -- signal to id which block is active
    type t_ctrl_active_block is (
                                    idle,
                                    admin,
                                    dgwb,
                                    dgrb,
                                    proc,  -- unused in non-levelling AFI sequencer
                                    setup, -- unused in non-levelling AFI sequencer
                                    iram
                              );
    function ret_proc return t_ctrl_active_block;
    function ret_dgrb return t_ctrl_active_block;

    -- control record for dgwb, dgrb, iram and admin blocks:

    -- the possible commands
    type t_ctrl_cmd_id is (
                            cmd_idle,

                            -- initialisation stages
                            cmd_phy_initialise,
                            cmd_init_dram,
                            cmd_prog_cal_mr,
                            cmd_write_ihi,

                            -- calibration stages
                            cmd_write_btp,
                            cmd_write_mtp,
                            cmd_read_mtp,
                            cmd_rrp_reset,
                            cmd_rrp_sweep,
                            cmd_rrp_seek,
                            cmd_rdv,
                            cmd_poa,
                            cmd_was,

                            -- advertise controller settings and re-configure for customer operation mode.
                            cmd_prep_adv_rd_lat,
                            cmd_prep_adv_wr_lat,
                            cmd_prep_customer_mr_setup,
                            cmd_tr_due

                          );

    -- which block should execute each command
    function curr_active_block (
        ctrl_cmd_id : t_ctrl_cmd_id
       ) return  t_ctrl_active_block;

    -- specify command operands as a record
    type t_command_op is record
        current_cs : natural range 0 to c_max_ranks-1; -- which chip select is being calibrated
        single_bit : std_logic;                        -- current operation should be single bit
        mtp_almt   : natural range 0 to 1;             -- signals mtp alignment to be used for operation
    end record;

    function defaults return t_command_op;

    -- command request record (sent to each block)
    type t_ctrl_command is record
        command       : t_ctrl_cmd_id;
        command_op    : t_command_op;
        command_req   : std_logic;
    end record;

    function defaults return t_ctrl_command;

    -- a generic status record for each block
    type t_ctrl_stat is record
        command_ack    : std_logic;
        command_done   : std_logic;
        command_result : std_logic_vector(7 downto 0 );
        command_err    : std_logic;
    end record;

    function defaults return t_ctrl_stat;

    -- push interface for dgwb / dgrb blocks (only the dgrb uses this interface at present)
    type t_iram_push is record
        iram_done     : std_logic;
        iram_write    : std_logic;
        iram_wordnum  : natural range 0 to 511;        -- acts as an offset to current location (max = 80 pll steps *2 sweeps and 80 pins)
        iram_bitnum   : natural range 0 to 31;         -- for bitwise packing modes
        iram_pushdata : std_logic_vector(31 downto 0); -- only bit zero used for bitwise packing_mode
    end record;

    function defaults return t_iram_push;

    -- control block "master" state machine
    type t_master_sm_state is
    (
        s_reset,
        s_phy_initialise,         -- wait for dll lock and init done flag from iram
        s_init_dram,              -- dram initialisation - reset sequence
        s_prog_cal_mr,            -- dram initialisation - programming mode registers (once per chip select)
        s_write_ihi,              -- write header information in iRAM
        s_cal,                    -- check if calibration to be executed
        s_write_btp,              -- write burst training pattern
        s_write_mtp,              -- write more training pattern
        s_read_mtp,               -- read training patterns to find correct alignment for 1100 burst
                                  -- (this is a special case of s_rrp_seek with no resych phase setting)
        s_rrp_reset,              -- read resync phase setup - reset initial conditions
        s_rrp_sweep,              -- read resync phase setup - sweep phases per chip select
        s_rrp_seek,               -- read resync phase setup - seek correct phase
        s_rdv,                    -- read data valid setup
        s_was,                    -- write datapath setup (ac to write data timing)
        s_adv_rd_lat,             -- advertise read latency
        s_adv_wr_lat,             -- advertise write latency
        s_poa,                    -- calibrate the postamble (dqs based capture only)
        s_tracking_setup,         -- perform tracking (1st pass to setup mimic window)
        s_prep_customer_mr_setup, -- apply user mode register settings (in admin block)
        s_tracking,               -- perform tracking (subsequent passes in user mode)
        s_operational,            -- calibration successful and in user mode
        s_non_operational         -- calibration unsuccessful and in user mode
    );

    -- record (set in mmi block) to disable calibration states
    type t_hl_css_reg is record

        phy_initialise_dis         : std_logic;
        init_dram_dis              : std_logic;
        write_ihi_dis              : std_logic;
        cal_dis                    : std_logic;
        write_btp_dis              : std_logic;
        write_mtp_dis              : std_logic;
        read_mtp_dis               : std_logic;
        rrp_reset_dis              : std_logic;
        rrp_sweep_dis              : std_logic;
        rrp_seek_dis               : std_logic;
        rdv_dis                    : std_logic;
        poa_dis                    : std_logic;
        was_dis                    : std_logic;
        adv_rd_lat_dis             : std_logic;
        adv_wr_lat_dis             : std_logic;
        prep_customer_mr_setup_dis : std_logic;
        tracking_dis               : std_logic;
    end record;

    function defaults return t_hl_css_reg;

    -- record (set in ctrl block) to identify when a command has been acknowledged
    type t_cal_stage_ack_seen is record

        cal                    : std_logic;
        phy_initialise         : std_logic;
        init_dram              : std_logic;
        write_ihi              : std_logic;
        write_btp              : std_logic;
        write_mtp              : std_logic;
        read_mtp               : std_logic;
        rrp_reset              : std_logic;
        rrp_sweep              : std_logic;
        rrp_seek               : std_logic;
        rdv                    : std_logic;
        poa                    : std_logic;
        was                    : std_logic;
        adv_rd_lat             : std_logic;
        adv_wr_lat             : std_logic;
        prep_customer_mr_setup : std_logic;
        tracking_setup         : std_logic;
    end record;

    function defaults return t_cal_stage_ack_seen;

    -- ctrl to mmi block interface (calibration status)
    type t_ctrl_mmi is record
        master_state_r             : t_master_sm_state;
        ctrl_calibration_success   : std_logic;
        ctrl_calibration_fail      : std_logic;
        ctrl_current_stage_done    : std_logic;
        ctrl_current_stage         : t_ctrl_cmd_id;
        ctrl_current_active_block  : t_ctrl_active_block;
        ctrl_cal_stage_ack_seen    : t_cal_stage_ack_seen;
        ctrl_err_code              : std_logic_vector(7 downto 0);
    end record;

    function defaults return t_ctrl_mmi;

    -- mmi to ctrl block interface (calibration control signals)
    type t_mmi_ctrl is record
        hl_css                   : t_hl_css_reg;
        calibration_start        : std_logic;
        tracking_period_ms       : natural range 0 to 255;
        tracking_orvd_to_10ms    : std_logic;
    end record;

    function defaults return t_mmi_ctrl;

    -- algorithm parameterisation (generated in mmi block)
    type t_algm_paramaterisation is record
         num_phases_per_tck_pll : natural range 1 to c_max_pll_steps;
         nominal_dqs_delay      : natural range 0 to 4;
         pll_360_sweeps         : natural range 0 to 15;
         nominal_poa_phase_lead : natural range 0 to 7;
         maximum_poa_delay      : natural range 0 to 15;
         odt_enabled            : boolean;
         extend_octrt_by        : natural range 0 to 15;
         delay_octrt_by         : natural range 0 to 15;
         tracking_period_ms     : natural range 0 to 255;
    end record;

    -- interface between mmi and pll to control phase shifting
    type t_mmi_pll_reconfig is record
        pll_phs_shft_phase_sel : natural range 0 to 15;
        pll_phs_shft_up_wc     : std_logic;
        pll_phs_shft_dn_wc     : std_logic;
    end record;

    type t_pll_mmi is record
        pll_busy : std_logic;
        err      : std_logic_vector(1 downto 0);
    end record;

    -- specify the iram configuration this is default
    -- currently always dq_bitwise packing and a write mode of overwrite_ram

    type t_iram_packing_mode is (
                                    dq_bitwise,
                                    dq_wordwise
                                );

    type t_iram_write_mode is (
                                    overwrite_ram,
                                    or_into_ram,
                                    and_into_ram
                              );

    type t_ctrl_iram is record
        packing_mode : t_iram_packing_mode;
        write_mode   : t_iram_write_mode;
        active_block : t_ctrl_active_block;
    end record;

    function defaults return t_ctrl_iram;

-- -----------------------------------------------------------------------
--  the following are required for compliance to levelling AFI PHY interface but
--  are non-functional for non-levelling AFI PHY sequencer
-- -----------------------------------------------------------------------

    type t_sc_ctrl_if is record
        read             : std_logic;
        write            : std_logic;
        dqs_group_sel    : std_logic_vector( 4 downto 0);
        sc_in_group_sel  : std_logic_vector( 5 downto 0);
        wdata            : std_logic_vector(45 downto 0);
        op_type          : std_logic_vector( 1 downto 0);
    end record;

    function defaults return t_sc_ctrl_if;

    type t_sc_stat is record
        rdata           : std_logic_vector(45 downto 0);
        busy            : std_logic;
        error_det       : std_logic;
        err_code        : std_logic_vector(1 downto 0);
        sc_cap          : std_logic_vector(7 downto 0);
    end record;

    function defaults return t_sc_stat;

    type t_element_to_reconfigure is (
                                       pp_t9,
                                       pp_t10,
                                       pp_t1,
                                       dqslb_rsc_phs,
                                       dqslb_poa_phs_ofst,
                                       dqslb_dqs_phs,
                                       dqslb_dq_phs_ofst,
                                       dqslb_dq_1t,
                                       dqslb_dqs_1t,
                                       dqslb_rsc_1t,
                                       dqslb_div2_phs,
                                       dqslb_oct_t9,
                                       dqslb_oct_t10,
                                       dqslb_poa_t7,
                                       dqslb_poa_t11,
                                       dqslb_dqs_dly,
                                       dqslb_lvlng_byps
                                     );

    type t_sc_type is (
                        DQS_LB,
                        DQS_DQ_DM_PINS,
                        DQ_DM_PINS,
                        dqs_dqsn_pins,
                        dq_pin,
                        dqs_pin,
                        dm_pin,
                        dq_pins
                       );

    type t_sc_int_ctrl is record
        group_num  : natural range 0 to c_max_num_dqs_groups;
        group_type : t_sc_type;
        pin_num    : natural range 0 to c_max_num_pins;
        sc_element : t_element_to_reconfigure;
        prog_val   : std_logic_vector(3 downto 0);
        ram_set    : std_logic;
        sc_update  : std_logic;
    end record;

    function defaults return t_sc_int_ctrl;

-- -----------------------------------------------------------------------
-- record and functions for instant on mode
-- -----------------------------------------------------------------------

    -- ranges on the below are not important because this logic is not synthesised
    type t_preset_cal is record
        codvw_phase  : natural range 0 to 2*c_max_pll_steps;-- rsc phase
        codvw_size   : natural range 0 to c_max_pll_steps;  -- rsc size (unused but reported)
        rlat         : natural;                             -- advertised read latency ctl_rlat (in phy clock cycles)
        rdv_lat      : natural;                             -- read data valid latency decrements needed (in memory clock cycles)
        wlat         : natural;                             -- advertised write latency ctl_wlat (in phy clock cycles)
        ac_1t        : std_logic;                           -- address / command 1t delay setting (HR only)
        poa_lat      : natural;                             -- poa latency decrements needed (in memory clock cycles)
    end record;

    -- the below are hardcoded (do not change)
    constant c_ddr_default_cl   : natural := 3;
    constant c_ddr2_default_cl  : natural := 6;
    constant c_ddr3_default_cl  : natural := 6;
    constant c_ddr2_default_cwl : natural := 5;
    constant c_ddr3_default_cwl : natural := 5;
    constant c_ddr2_default_al  : natural := 0;
    constant c_ddr3_default_al  : natural := 0;

    constant c_ddr_default_rl   : integer := c_ddr_default_cl;
    constant c_ddr2_default_rl  : integer := c_ddr2_default_cl + c_ddr2_default_al;
    constant c_ddr3_default_rl  : integer := c_ddr3_default_cl + c_ddr3_default_al;

    constant c_ddr_default_wl   : integer := 1;
    constant c_ddr2_default_wl  : integer := c_ddr2_default_cwl + c_ddr2_default_al;
    constant c_ddr3_default_wl  : integer := c_ddr3_default_cwl + c_ddr3_default_al;

    function defaults return t_preset_cal;

    function setup_instant_on (sim_time_red : natural;
                               family_id    : natural;
                               memory_type  : string;
                               dwidth_ratio : natural;
                               pll_steps    : natural;
                               mr0          : std_logic_vector(15 downto 0);
                               mr1          : std_logic_vector(15 downto 0);
                               mr2          : std_logic_vector(15 downto 0)) return t_preset_cal;



--#mw_prefix ("alt_mem_phy_record_pkg")
end alt_mem_phy_record_pkg;
--#end

--#mw_prefix ("alt_mem_phy_record_pkg")
package body alt_mem_phy_record_pkg IS
--#end

-- -----------------------------------------------------------------------
--  function implementations for the above declarations
--  these are mainly default conditions for records
-- -----------------------------------------------------------------------

    function defaults return t_admin_ctrl is
        variable output : t_admin_ctrl;
    begin
        output.mr0 := (others => '0');
        output.mr1 := (others => '0');
        output.mr2 := (others => '0');
        output.mr3 := (others => '0');
        return output;
    end function;

    function defaults return t_admin_stat is
        variable output : t_admin_stat;
    begin
        output.mr0 := (others => '0');
        output.mr1 := (others => '0');
        output.mr2 := (others => '0');
        output.mr3 := (others => '0');
        return output;
    end function;


    function defaults return t_iram_ctrl is
        variable output : t_iram_ctrl;
    begin
        output.addr    := 0;
        output.wdata   := (others => '0');
        output.write   := '0';
        output.read    := '0';
        return output;
    end function;

    function defaults return t_iram_stat is
        variable output : t_iram_stat;
    begin
        output.rdata            := (others => '0');
        output.done             := '0';
        output.err              := '0';
        output.err_code         := (others => '0');
        output.init_done        := '0';
        output.out_of_mem       := '0';
        output.contested_access := '0';
        return output;
    end function;

    function defaults return t_dgrb_mmi is
        variable output : t_dgrb_mmi;
    begin
        output.cal_codvw_phase   := (others => '0');
        output.cal_codvw_size    := (others => '0');
        output.codvw_trk_shift   := (others => '0');
        output.codvw_grt_one_dvw := '0';
        return output;
    end function;

    function ret_proc return t_ctrl_active_block is
        variable output : t_ctrl_active_block;
    begin
        output := proc;
        return output;
    end function;

    function ret_dgrb return t_ctrl_active_block is
        variable output : t_ctrl_active_block;
    begin
        output := dgrb;
        return output;
    end function;

    function defaults return t_ctrl_iram is
        variable output : t_ctrl_iram;
    begin
        output.packing_mode := dq_bitwise;
        output.write_mode   := overwrite_ram;
        output.active_block := idle;
        return output;
    end function;

    function defaults return t_command_op is
        variable output : t_command_op;
    begin
        output.current_cs := 0;
        output.single_bit := '0';
        output.mtp_almt   := 0;
        return output;
    end function;

    function defaults return t_ctrl_command is
        variable output : t_ctrl_command;
    begin
        output.command     := cmd_idle;
        output.command_req := '0';
        output.command_op  := defaults;
        return output;
    end function;

    -- decode which block is associated with which command
    function curr_active_block (
        ctrl_cmd_id : t_ctrl_cmd_id
       ) return  t_ctrl_active_block is
    begin
        case ctrl_cmd_id is
            when cmd_idle                   => return idle;
            when cmd_phy_initialise         => return idle;
            when cmd_init_dram              => return admin;
            when cmd_prog_cal_mr            => return admin;
            when cmd_write_ihi              => return iram;
            when cmd_write_btp              => return dgwb;
            when cmd_write_mtp              => return dgwb;
            when cmd_read_mtp               => return dgrb;
            when cmd_rrp_reset              => return dgrb;
            when cmd_rrp_sweep              => return dgrb;
            when cmd_rrp_seek               => return dgrb;
            when cmd_rdv                    => return dgrb;
            when cmd_poa                    => return dgrb;
            when cmd_was                    => return dgwb;
            when cmd_prep_adv_rd_lat        => return dgrb;
            when cmd_prep_adv_wr_lat        => return dgrb;
            when cmd_prep_customer_mr_setup => return admin;
            when cmd_tr_due                 => return dgrb;
            when others                     => return idle;
        end case;
    end function;

    function defaults return t_ctrl_stat is
        variable output : t_ctrl_stat;
    begin
        output.command_ack    := '0';
        output.command_done   := '0';
        output.command_err    := '0';
        output.command_result := (others => '0');
        return output;
    end function;

    function defaults return t_iram_push is
        variable output : t_iram_push;
    begin
        output.iram_done     := '0';
        output.iram_write    := '0';
        output.iram_wordnum  := 0;
        output.iram_bitnum   := 0;
        output.iram_pushdata := (others => '0');
        return output;
    end function;

    function defaults return t_hl_css_reg is
        variable output  : t_hl_css_reg;
    begin
        output.phy_initialise_dis         := '0';
        output.init_dram_dis              := '0';
        output.write_ihi_dis              := '0';
        output.cal_dis                    := '0';
        output.write_btp_dis              := '0';
        output.write_mtp_dis              := '0';
        output.read_mtp_dis               := '0';
        output.rrp_reset_dis              := '0';
        output.rrp_sweep_dis              := '0';
        output.rrp_seek_dis               := '0';
        output.rdv_dis                    := '0';
        output.poa_dis                    := '0';
        output.was_dis                    := '0';
        output.adv_rd_lat_dis             := '0';
        output.adv_wr_lat_dis             := '0';
        output.prep_customer_mr_setup_dis := '0';
        output.tracking_dis               := '0';
        return output;

    end function;

    function defaults return t_cal_stage_ack_seen is
        variable output : t_cal_stage_ack_seen;
    begin

       output.cal                    := '0';
       output.phy_initialise         := '0';
       output.init_dram              := '0';
       output.write_ihi              := '0';
       output.write_btp              := '0';
       output.write_mtp              := '0';
       output.read_mtp               := '0';
       output.rrp_reset              := '0';
       output.rrp_sweep              := '0';
       output.rrp_seek               := '0';
       output.rdv                    := '0';
       output.poa                    := '0';
       output.was                    := '0';
       output.adv_rd_lat             := '0';
       output.adv_wr_lat             := '0';
       output.prep_customer_mr_setup := '0';
       output.tracking_setup         := '0';

       return output;
    end function;


    function defaults return t_mmi_ctrl is
        variable output : t_mmi_ctrl;
    begin
        output.hl_css                                  := defaults;
        output.calibration_start                       := '0';
        output.tracking_period_ms                      := 0;
        output.tracking_orvd_to_10ms                   := '0';
        return output;
    end function;



    function defaults return t_ctrl_mmi is
        variable output : t_ctrl_mmi;
    begin
        output.master_state_r              := s_reset;
        output.ctrl_calibration_success    := '0';
        output.ctrl_calibration_fail       := '0';
        output.ctrl_current_stage_done     := '0';
        output.ctrl_current_stage          := cmd_idle;
        output.ctrl_current_active_block   := idle;
        output.ctrl_cal_stage_ack_seen     := defaults;
        output.ctrl_err_code               := (others => '0');
        return output;
    end function;

-------------------------------------------------------------------------
-- the following are required for compliance to levelling AFI PHY interface but
-- are non-functional for non-levelling AFi PHY sequencer
-------------------------------------------------------------------------

    function defaults return t_sc_ctrl_if is
        variable output : t_sc_ctrl_if;
    begin
        output.read            := '0';
        output.write           := '0';
        output.dqs_group_sel   := (others => '0');
        output.sc_in_group_sel := (others => '0');
        output.wdata           := (others => '0');
        output.op_type         := (others => '0');
        return output;
    end function;

    function defaults return t_sc_stat is
        variable output : t_sc_stat;
    begin
        output.rdata := (others => '0');
        output.busy      := '0';
        output.error_det := '0';
        output.err_code  := (others => '0');
        output.sc_cap    := (others => '0');
        return output;
    end function;

    function defaults return t_sc_int_ctrl is
        variable output : t_sc_int_ctrl;
    begin
        output.group_num  := 0;
        output.group_type := DQ_PIN;
        output.pin_num    := 0;
        output.sc_element := pp_t9;
        output.prog_val   := (others => '0');
        output.ram_set    := '0';
        output.sc_update  := '0';
        return output;
    end function;

-- -----------------------------------------------------------------------
-- functions for instant on mode
--
--
-- Guide on how to use:
--
-- The following factors effect the setup of the PHY:
-- - AC Phase - phase at which address/command signals launched wrt PHY clock
--            - this effects the read/write latency
-- - MR settings - CL, CWL, AL
-- - Data rate - HR or FR (DDR/DDR2 only)
-- - Family - datapaths are subtly different for each
-- - Memory type - DDR/DDR2/DDR3 (different latency behaviour - see specs)
--
-- Instant on mode is designed to work for the following subset of the
-- above factors:
-- - AC Phase - out of the box defaults, which is 240 degrees for SIII type
--              families (includes SIV, HCIII, HCIV), else 90 degrees
-- - MR Settings - DDR - CL 3 only
--               - DDR2 - CL 3,4,5,6, AL 0
--               - DDR3 - CL 5,6 CWL 5, AL 0
-- - Data rate - All
-- - Families - All
-- - Memory type - All
--
-- Hints on bespoke setup for parameters outside the above or if the
-- datapath is modified (only for VHDL sim mode):
--
-- Step 1 - Run simulation with REDUCE_SIM_TIME mode 2 (FAST)
--
-- Step 2 - From the output log find the following text:
-- # -----------------------------------------------------------------------
-- **** ALTMEMPHY CALIBRATION has completed ****
-- Status:
-- calibration has  : PASSED
-- PHY read latency (ctl_rlat) is  : 14
-- address/command to PHY write latency (ctl_wlat) is : 2
-- read resynch phase calibration report:
-- calibrated centre of data valid window phase : 32
-- calibrated centre of data valid window size  : 24
-- chosen address and command 1T delay: no 1T delay
-- poa 'dec' adjustments = 27
-- rdv 'dec' adjustments = 25
-- # -----------------------------------------------------------------------
--
-- Step 3 - Convert the text to bespoke instant on settings at the end of the
--          setup_instant_on function using the
--          override_instant_on function, note type is t_preset_cal
--
-- The mapping is as follows:
--
-- PHY read latency (ctl_rlat) is  : 14                   => rlat := 14
-- address/command to PHY write latency (ctl_wlat) is : 2 => wlat := 2
-- read resynch phase calibration report:
-- calibrated centre of data valid window phase : 32      => codvw_phase := 32
-- calibrated centre of data valid window size  : 24      => codvw_size  := 24
-- chosen address and command 1T delay: no 1T delay       => ac_1t := '0'
-- poa 'dec' adjustments = 27                             => poa_lat := 27
-- rdv 'dec' adjustments = 25                             => rdv_lat := 25
--
-- Step 4 - Try running in REDUCE_SIM_TIME mode 1 (SUPERFAST mode)
--
-- Step 5 - If still fails observe the behaviour of the controller, for the
--          following symptoms:
--    - If first 2 beats of read data lost (POA enable too late) - inc poa_lat by 1 (poa_lat is number of POA decrements not actual latency)
--    - If last 2 beats of read data lost (POA enable too early) - dec poa_lat by 1
--    - If ctl_rdata_valid misaligned to ctl_rdata then alter number of RDV adjustments (rdv_lat)
--    - If write data is not 4-beat aligned (when written into memory) toggle ac_1t (HR only)
--    - If read data is not 4-beat aligned (but write data is) add 360 degrees to phase (PLL_STEPS_PER_CYCLE) mod 2*PLL_STEPS_PER_CYCLE (HR only)
--
-- Step 6 - If the above fails revert to REDUCE_SIM_TIME = 2 (FAST) mode
--
-- --------------------------------------------------------------------------
    -- defaults
    function defaults return t_preset_cal is
        variable output : t_preset_cal;
    begin
        output.codvw_phase  := 0;
        output.codvw_size   := 0;
        output.wlat         := 0;
        output.rlat         := 0;
        output.rdv_lat      := 0;
        output.ac_1t        := '1'; -- default on for FR
        output.poa_lat      := 0;
        return output;
    end function;

    -- Functions to extract values from MR

    -- return cl (for DDR memory 2*cl because of 1/2 cycle latencies)
    procedure mr0_to_cl (memory_type : string;
                        mr0         : std_logic_vector(15 downto 0);
                        cl          : out natural;
                        half_cl     : out std_logic) is
        variable v_cl : natural;
    begin

        half_cl := '0';

        if memory_type = "DDR" then  -- DDR memories

            -- returns cl*2 because of 1/2 latencies
            v_cl := to_integer(unsigned(mr0(5 downto 4)));

            -- integer values of cl
            if mr0(6) = '0' then
                assert v_cl > 1 report record_report_prefix & "invalid cas latency for DDR memory, should be in range 1.5-3" severity failure;
            end if;

            if mr0(6) = '1' then
                assert (v_cl = 1 or v_cl = 2) report record_report_prefix & "invalid cas latency for DDR memory, should be in range 1.5-3" severity failure;
                half_cl := '1';
            end if;

        elsif memory_type = "DDR2" then -- DDR2 memories

            v_cl := to_integer(unsigned(mr0(6 downto 4)));
            -- sanity checks
            assert (v_cl > 1 and v_cl < 7) report record_report_prefix & "invalid cas latency for DDR2 memory, should be in range 2-6 but equals " & integer'image(v_cl) severity failure;

        elsif memory_type = "DDR3" then -- DDR3 memories

            v_cl := to_integer(unsigned(mr0(6 downto 4)))+4;
            --sanity checks
            assert mr0(2) = '0' report record_report_prefix & "invalid cas latency for DDR3 memory, bit a2 in mr0 is set"  severity failure;
            assert v_cl /= 4      report record_report_prefix & "invalid cas latency for DDR3 memory, bits a6:4 set to zero" severity failure;

        else
                report record_report_prefix & "Undefined memory type " & memory_type severity failure;
        end if;

        cl := v_cl;

    end procedure;

    function mr1_to_al (memory_type : string;
                        mr1         : std_logic_vector(15 downto 0);
                        cl          : natural) return natural is
        variable al : natural;
    begin

        if memory_type = "DDR" then  -- DDR memories

            -- unsupported so return zero
            al := 0;

        elsif memory_type = "DDR2" then -- DDR2 memories

            al := to_integer(unsigned(mr1(5 downto 3)));
            assert al < 6 report record_report_prefix & "invalid additive latency for DDR2 memory, should be in range 0-5 but equals " & integer'image(al) severity failure;

        elsif memory_type = "DDR3" then -- DDR3 memories

            al := to_integer(unsigned(mr1(4 downto 3)));
            assert al /= 3 report record_report_prefix & "invalid additive latency for DDR2 memory, should be in range 0-5 but equals " & integer'image(al) severity failure;

            if al /= 0 then -- CL-1 or CL-2
                al := cl - al;
            end if;

        else
                report record_report_prefix & "Undefined memory type " & memory_type severity failure;
        end if;

        return al;

    end function;

    -- return cwl
    function mr2_to_cwl (memory_type : string;
                         mr2         : std_logic_vector(15 downto 0);
                         cl          : natural) return natural is
        variable cwl : natural;
    begin

        if memory_type = "DDR" then  -- DDR memories

            cwl := 1;

        elsif memory_type = "DDR2" then -- DDR2 memories

            cwl := cl - 1;

        elsif memory_type = "DDR3" then -- DDR3 memories

            cwl := to_integer(unsigned(mr2(5 downto 3))) + 5;
            --sanity checks
            assert cwl < 9 report record_report_prefix & "invalid cas write latency for DDR3 memory, should be in range 5-8 but equals " & integer'image(cwl) severity failure;

        else
            report record_report_prefix & "Undefined memory type " & memory_type severity failure;
        end if;

        return cwl;

    end function;

    -- -----------------------------------
    -- Functions to determine which family group
    -- Include any family alias here
    -- -----------------------------------

    function is_siii(family_id : natural) return boolean is
    begin
        if family_id = 3 or family_id = 5 then

           return true;

        else

            return false;

        end if;

    end function;

    function is_ciii(family_id : natural) return boolean is
    begin
        if family_id = 2 then

           return true;

        else

            return false;

        end if;

    end function;

    function is_aii(family_id : natural) return boolean is
    begin
        if family_id = 4 then

           return true;

        else

            return false;

        end if;

    end function;

    function is_sii(family_id : natural) return boolean is
    begin
        if family_id = 1 then

           return true;

        else

            return false;

        end if;

    end function;

    -- -----------------------------------
    -- Functions to lookup hardcoded values
    -- on per family basis
    -- DDR: CL = 3
    -- DDR2: CL = 6, CWL = 5, AL = 0
    -- DDR3: CL = 6, CWL = 5, AL = 0
    -- #pb_del hard coded to delays as of release 9.1
    -- -----------------------------------

    -- default ac phase = 240
    function siii_family_settings (dwidth_ratio : integer;
                                   memory_type  : string;
                                   pll_steps    : natural
                                  ) return t_preset_cal is
        variable v_output : t_preset_cal;
    begin

        v_output := defaults;

        if memory_type = "DDR" then  -- CAS = 3

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 15;
                v_output.rdv_lat      := 11;
                v_output.poa_lat      := 11;
            else
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 15;
                v_output.rdv_lat      := 23;
                v_output.ac_1t        := '0';
                v_output.poa_lat      := 24;
            end if;

        elsif memory_type = "DDR2" then -- CAS = 6

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 5;
                v_output.rlat         := 16;
                v_output.rdv_lat      := 10;
                v_output.poa_lat      := 8;
            else
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 3;
                v_output.rlat         := 16;
                v_output.rdv_lat      := 21;
                v_output.ac_1t        := '0';
                v_output.poa_lat      := 22;
            end if;

        elsif memory_type = "DDR3" then -- HR only, CAS = 6

            v_output.codvw_phase  := pll_steps/4;
            v_output.wlat         := 2;
            v_output.rlat         := 15;
            v_output.rdv_lat      := 23;
            v_output.ac_1t        := '0';
            v_output.poa_lat      := 24;

        end if;

        -- adapt settings for ac_phase (default 240 degrees so leave commented)
        -- if dwidth_ratio = 2 then

            -- v_output.wlat := v_output.wlat - 1;
            -- v_output.rlat := v_output.rlat - 1;
            -- v_output.rdv_lat := v_output.rdv_lat + 1;
            -- v_output.poa_lat := v_output.poa_lat + 1;

        -- else

            -- v_output.ac_1t := not v_output.ac_1t;

        -- end if;

        v_output.codvw_size := pll_steps;

        return v_output;

    end function;

    -- default ac phase = 90
    function ciii_family_settings (dwidth_ratio : integer;
                                   memory_type  : string;
                                   pll_steps    : natural) return t_preset_cal is
        variable v_output : t_preset_cal;
    begin

        v_output := defaults;

        if memory_type = "DDR" then  -- CAS = 3

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := 3*pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 15;
                v_output.rdv_lat      := 11;
                v_output.poa_lat      := 11; --unused
            else
                v_output.codvw_phase  := 3*pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 13;
                v_output.rdv_lat      := 27;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 27; --unused
            end if;

        elsif memory_type = "DDR2" then  -- CAS = 6

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := 3*pll_steps/4;
                v_output.wlat         := 5;
                v_output.rlat         := 18;
                v_output.rdv_lat      := 8;
                v_output.poa_lat      := 8; --unused
            else
                v_output.codvw_phase  := pll_steps + 3*pll_steps/4;
                v_output.wlat         := 3;
                v_output.rlat         := 14;
                v_output.rdv_lat      := 25;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 25; --unused
            end if;

        end if;

        -- adapt settings for ac_phase (hardcode for 90 degrees)
        if dwidth_ratio = 2 then

            v_output.wlat := v_output.wlat + 1;
            v_output.rlat := v_output.rlat + 1;
            v_output.rdv_lat := v_output.rdv_lat - 1;
            v_output.poa_lat := v_output.poa_lat - 1;

        else

            v_output.ac_1t := not v_output.ac_1t;

        end if;

        v_output.codvw_size   := pll_steps/2;

        return v_output;

    end function;


    -- default ac phase = 90
    function sii_family_settings (dwidth_ratio : integer;
                                   memory_type  : string;
                                   pll_steps    : natural) return t_preset_cal is
        variable v_output : t_preset_cal;
    begin

        v_output := defaults;

        if memory_type = "DDR" then  -- CAS = 3

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 15;
                v_output.rdv_lat      := 11;
                v_output.poa_lat      := 13;
            else
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 13;
                v_output.rdv_lat      := 27;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 22;
            end if;

        elsif memory_type = "DDR2" then

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 5;
                v_output.rlat         := 18;
                v_output.rdv_lat      := 8;
                v_output.poa_lat      := 10;
            else
                v_output.codvw_phase  := pll_steps + pll_steps/4;
                v_output.wlat         := 3;
                v_output.rlat         := 14;
                v_output.rdv_lat      := 25;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 20;
            end if;

        end if;

        -- adapt settings for ac_phase (hardcode for 90 degrees)
        if dwidth_ratio = 2 then

            v_output.wlat := v_output.wlat + 1;
            v_output.rlat := v_output.rlat + 1;
            v_output.rdv_lat := v_output.rdv_lat - 1;
            v_output.poa_lat := v_output.poa_lat - 1;

        else

            v_output.ac_1t := not v_output.ac_1t;

        end if;

        v_output.codvw_size := pll_steps;

        return v_output;

    end function;

    -- default ac phase = 90
    function aii_family_settings (dwidth_ratio : integer;
                                  memory_type  : string;
                                  pll_steps    : natural) return t_preset_cal is
        variable v_output : t_preset_cal;
    begin

        v_output := defaults;

        if memory_type = "DDR" then  -- CAS = 3

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 16;
                v_output.rdv_lat      := 10;
                v_output.poa_lat      := 15;
            else
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 1;
                v_output.rlat         := 13;
                v_output.rdv_lat      := 27;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 24;
            end if;

        elsif memory_type = "DDR2" then

            if dwidth_ratio = 2 then
                v_output.codvw_phase  := pll_steps/4;
                v_output.wlat         := 5;
                v_output.rlat         := 19;
                v_output.rdv_lat      := 9;
                v_output.poa_lat      := 12;
            else
                v_output.codvw_phase  := pll_steps + pll_steps/4;
                v_output.wlat         := 3;
                v_output.rlat         := 14;
                v_output.rdv_lat      := 25;
                v_output.ac_1t        := '1';
                v_output.poa_lat      := 22;
            end if;

        elsif memory_type = "DDR3" then -- HR only, CAS = 6

            v_output.codvw_phase  := pll_steps + pll_steps/4;
            v_output.wlat         := 3;
            v_output.rlat         := 14;
            v_output.rdv_lat      := 25;
            v_output.ac_1t        := '1';
            v_output.poa_lat      := 22;

        end if;

        -- adapt settings for ac_phase (hardcode for 90 degrees)
        if dwidth_ratio = 2 then

            v_output.wlat := v_output.wlat + 1;
            v_output.rlat := v_output.rlat + 1;
            v_output.rdv_lat := v_output.rdv_lat - 1;
            v_output.poa_lat := v_output.poa_lat - 1;

        else

            v_output.ac_1t := not v_output.ac_1t;

        end if;

        v_output.codvw_size := pll_steps;

        return v_output;

    end function;


    function is_odd(num : integer) return boolean is
        variable v_num : integer;
    begin
        v_num := num;
        if v_num - (v_num/2)*2 = 0 then
            return false;
        else
            return true;
        end if;
    end function;

    ------------------------------------------------
    -- top level function to setup instant on mode
    ------------------------------------------------

    function override_instant_on return t_preset_cal is
        variable v_output : t_preset_cal;
    begin

        v_output := defaults;

        -- add in overrides here

        return v_output;

    end function;

    function setup_instant_on (sim_time_red : natural;
                               family_id    : natural;
                               memory_type  : string;
                               dwidth_ratio : natural;
                               pll_steps    : natural;
                               mr0          : std_logic_vector(15 downto 0);
                               mr1          : std_logic_vector(15 downto 0);
                               mr2          : std_logic_vector(15 downto 0)) return t_preset_cal is

        variable v_output : t_preset_cal;

        variable v_cl      : natural; -- cas latency
        variable v_half_cl : std_logic; -- + 0.5 cycles (DDR only)
        variable v_al      : natural; -- additive latency (ddr2/ddr3 only)
        variable v_cwl     : natural; -- cas write latency (ddr3 only)

        variable v_rl       : integer range 0 to 15;
        variable v_wl       : integer;
        variable v_delta_rl : integer range -10 to 10;  -- from given defaults
        variable v_delta_wl : integer;  -- from given defaults

        variable v_debug : boolean;

    begin

        v_debug := true;

        v_output := defaults;

        if sim_time_red = 1 then  -- only set if STR equals 1

            -- ----------------------------------------
            -- extract required parameters from MRs
            -- #pb_del unused for now but maybe used at a later date to
            -- #pb_del allow different CAS / AL than specified defaults
            -- ----------------------------------------
            mr0_to_cl(memory_type, mr0, v_cl, v_half_cl);
            v_al  := mr1_to_al(memory_type, mr1, v_cl);
            v_cwl := mr2_to_cwl(memory_type, mr2, v_cl);

            v_rl  := v_cl + v_al;
            v_wl  := v_cwl + v_al;

            if v_debug then
                report record_report_prefix & "Extracted MR parameters" & LF &
                                              "CAS = " & integer'image(v_cl) & LF &
                                              "CWL = " & integer'image(v_cwl) & LF &
                                              "AL  = " & integer'image(v_al) & LF;
            end if;

            -- ----------------------------------------
            -- apply per family, memory type and dwidth_ratio static setup
            -- ----------------------------------------
            if is_siii(family_id) then
                v_output := siii_family_settings(dwidth_ratio, memory_type, pll_steps);
            elsif is_ciii(family_id) then
                v_output := ciii_family_settings(dwidth_ratio, memory_type, pll_steps);
            elsif is_aii(family_id) then
                v_output := aii_family_settings(dwidth_ratio, memory_type, pll_steps);
            elsif is_sii(family_id) then
                v_output := sii_family_settings(dwidth_ratio, memory_type, pll_steps);
            end if;

            -- ----------------------------------------
            -- correct for different cwl, cl and al settings
            -- ----------------------------------------

            if memory_type = "DDR" then
                v_delta_rl := v_rl - c_ddr_default_rl;
                v_delta_wl := v_wl - c_ddr_default_wl;
            elsif memory_type = "DDR2" then
                v_delta_rl := v_rl - c_ddr2_default_rl;
                v_delta_wl := v_wl - c_ddr2_default_wl;
            else -- DDR3
                v_delta_rl := v_rl - c_ddr3_default_rl;
                v_delta_wl := v_wl - c_ddr3_default_wl;
            end if;

            if v_debug then
                report record_report_prefix & "Extracted memory latency (and delta from default)" & LF &
                                              "RL = " & integer'image(v_rl) & LF &
                                              "WL = " & integer'image(v_wl) & LF &
                                              "delta RL = " & integer'image(v_delta_rl) & LF &
                                              "delta WL = " & integer'image(v_delta_wl) & LF;
            end if;

            if dwidth_ratio = 2 then

                -- adjust rdp settings
                v_output.rlat    := v_output.rlat    + v_delta_rl;
                v_output.rdv_lat := v_output.rdv_lat - v_delta_rl;
                v_output.poa_lat := v_output.poa_lat - v_delta_rl;

                -- adjust wdp settings
                v_output.wlat    := v_output.wlat + v_delta_wl;

            elsif dwidth_ratio = 4 then

                -- adjust wdp settings
                v_output.wlat := v_output.wlat + v_delta_wl/2;

                if is_odd(v_delta_wl) then  -- add / sub 1t write latency

                    -- toggle ac_1t in all cases
                    v_output.ac_1t := not v_output.ac_1t;

                    if v_delta_wl < 0 then -- sub 1 from latency

                        if v_output.ac_1t = '0' then  -- phy_clk cc boundary
                            v_output.wlat := v_output.wlat - 1;
                        end if;

                    else -- add 1 to latency

                        if v_output.ac_1t = '1' then -- phy_clk cc boundary
                            v_output.wlat := v_output.wlat + 1;
                        end if;

                    end if;

                    -- update read latency
                    if v_output.ac_1t = '1' then  -- added 1t to address/command so inc read_lat
                        v_delta_rl := v_delta_rl + 1;
                    else -- subtracted 1t from address/command so dec read_lat
                        v_delta_rl := v_delta_rl - 1;
                    end if;

                end if;


                -- adjust rdp settings
                v_output.rlat    := v_output.rlat    + v_delta_rl/2;

                v_output.rdv_lat := v_output.rdv_lat - v_delta_rl;
                v_output.poa_lat := v_output.poa_lat - v_delta_rl;

                -- #pb_del The below works for CL=5, CWL=5 but other variants are untested
                if memory_type = "DDR3" then
                    if is_odd(v_delta_rl) xor is_odd(v_delta_wl) then

                        if is_aii(family_id) then
                            v_output.rdv_lat := v_output.rdv_lat - 1;
                            v_output.poa_lat := v_output.poa_lat - 1;
                        else
                            v_output.rdv_lat := v_output.rdv_lat + 1;
                            v_output.poa_lat := v_output.poa_lat + 1;
                        end if;

                    end if;

                end if;

                if is_odd(v_delta_rl) then

                    if v_delta_rl > 0 then -- add 1t

                        if v_output.codvw_phase < pll_steps then
                            v_output.codvw_phase := v_output.codvw_phase + pll_steps;
                        else
                            v_output.codvw_phase := v_output.codvw_phase - pll_steps;
                            v_output.rlat        := v_output.rlat + 1;
                        end if;

                    else -- subtract 1t

                        if v_output.codvw_phase < pll_steps then
                            v_output.codvw_phase := v_output.codvw_phase + pll_steps;
                            v_output.rlat        := v_output.rlat - 1;
                        else
                            v_output.codvw_phase := v_output.codvw_phase - pll_steps;
                        end if;

                    end if;

                end if;

            end if;

            if v_half_cl = '1' and is_ciii(family_id) then
                v_output.codvw_phase := v_output.codvw_phase - pll_steps/2;
            end if;

        end if;

        return v_output;

    end function;

    --#mw_prefix ("alt_mem_phy_record_pkg")
END alt_mem_phy_record_pkg;
--#end
