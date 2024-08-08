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
--  Title           : register package

--  File:  $RCSfile : alt_mem_phy_regs_pkg.vhd,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : register package for the non-levelling AFI PHY sequencer
--                    The registers package (alt_mem_phy_regs_pkg) is used to
--                    combine the definition of the registers for the mmi status
--                    registers and functions/procedures applied to the registers
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- The record package (alt_mem_phy_record_pkg) is used to combine command and status signals
-- (into records) to be passed between sequencer blocks. It also contains type and record definitions
-- for the stages of DRAM memory calibration.
--#mw_prefix ("alt_mem_phy_record_pkg")
use work.alt_mem_phy_record_pkg.all;
--#end

-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
use work.alt_mem_phy_constants_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_regs_pkg")
package alt_mem_phy_regs_pkg is
--#end

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant regs_report_prefix     : string  := "alt_mem_phy_seq (register package) : ";
--#end

-- ---------------------------------------------------------------
-- register declarations with associated functions of:
-- default     - assign default values
-- write       - write data into the reg (from avalon i/f)
-- read        - read data from the reg (sent to the avalon i/f)
-- write_clear - clear reg to all zeros
-- ---------------------------------------------------------------

    -- TYPE DECLARATIONS

    -- >>>>>>>>>>>>>>>>>>>>>>>>
    -- Read Only Registers
    -- >>>>>>>>>>>>>>>>>>>>>>>>

    -- cal_status
    type t_cal_status is record
        iram_addr_width  : std_logic_vector(3 downto 0);
        out_of_mem       : std_logic;
        contested_access : std_logic;
        cal_fail         : std_logic;
        cal_success      : std_logic;
        ctrl_err_code    : std_logic_vector(7 downto 0);
        trefi_failure    : std_logic;
        int_ac_1t        : std_logic;
        dqs_capture      : std_logic;
        iram_present     : std_logic;
        active_block     : std_logic_vector(3 downto 0);
        current_stage    : std_logic_vector(7 downto 0);
    end record;

    -- codvw status
    type t_codvw_status is record
        cal_codvw_phase   : std_logic_vector(7  downto 0);
        cal_codvw_size    : std_logic_vector(7  downto 0);
        codvw_trk_shift   : std_logic_vector(11 downto 0);
        codvw_grt_one_dvw : std_logic;
    end record t_codvw_status;

    -- test status report
    type t_test_status is record
        ack_seen    : std_logic_vector(c_hl_ccs_num_stages-1 downto 0);
        pll_mmi_err : std_logic_vector(1 downto 0);
        pll_busy    : std_logic;
    end record;

    -- define all the read only registers :
    type t_ro_regs is record
        cal_status    : t_cal_status;
        codvw_status  : t_codvw_status;
        test_status   : t_test_status;
    end record;

    -- >>>>>>>>>>>>>>>>>>>>>>>>
    -- Read / Write Registers
    -- >>>>>>>>>>>>>>>>>>>>>>>>

    -- Calibration control register
    type t_hl_css is record
        hl_css             : std_logic_vector(c_hl_ccs_num_stages-1 downto 0);
        cal_start          : std_logic;
    end record t_hl_css;

    -- Mode register A
    type t_mr_register_a is record
        mr0 : std_logic_vector(c_max_mode_reg_index -1 downto 0);
        mr1 : std_logic_vector(c_max_mode_reg_index -1 downto 0);
    end record t_mr_register_a;

    -- Mode register B
    type t_mr_register_b is record
        mr2 : std_logic_vector(c_max_mode_reg_index -1 downto 0);
        mr3 : std_logic_vector(c_max_mode_reg_index -1 downto 0);
    end record t_mr_register_b;

    -- algorithm parameterisation register
    type t_parameterisation_reg_a is record
        nominal_poa_phase_lead : std_logic_vector(3 downto 0);
        maximum_poa_delay      : std_logic_vector(3 downto 0);
        num_phases_per_tck_pll : std_logic_vector(3 downto 0);
        pll_360_sweeps         : std_logic_vector(3 downto 0);
-- #pb_del max num_phases_per_tck_pll of 48..  (300 Mhz *6 = 1.8 Ghz vco) note support increments
-- #pb_del of 4  -- bottom bit should be 0 though
        nominal_dqs_delay      : std_logic_vector(2 downto 0);
        extend_octrt_by        : std_logic_vector(3 downto 0);
        delay_octrt_by         : std_logic_vector(3 downto 0);
    end record;

    -- test signal register
    type t_if_test_reg is record
        pll_phs_shft_phase_sel  : natural range 0 to 15;
        pll_phs_shft_up_wc      : std_logic;
        pll_phs_shft_dn_wc      : std_logic;
        ac_1t_toggle            : std_logic;                     -- unused
        tracking_period_ms      : std_logic_vector(7 downto 0);  -- 0 = as fast as possible approx in ms
        tracking_units_are_10us : std_logic;
    end record;

    -- define all the read/write registers
    type t_rw_regs is record
        mr_reg_a       : t_mr_register_a;
        mr_reg_b       : t_mr_register_b;
        rw_hl_css      : t_hl_css;
        rw_param_reg   : t_parameterisation_reg_a;
        rw_if_test     : t_if_test_reg;
    end record;

    -- >>>>>>>>>>>>>>>>>>>>>>>
    -- Group all registers
    -- >>>>>>>>>>>>>>>>>>>>>>>

    type t_mmi_regs is record
        rw_regs       : t_rw_regs;
        ro_regs       : t_ro_regs;
        enable_writes : std_logic;
    end record;


    -- FUNCTION DECLARATIONS

    -- >>>>>>>>>>>>>>>>>>>>>>>>
    -- Read Only Registers
    -- >>>>>>>>>>>>>>>>>>>>>>>>

    -- cal_status
    function defaults return t_cal_status;
    function defaults   ( ctrl_mmi      : in t_ctrl_mmi;
                          USE_IRAM      : in std_logic;
                          dqs_capture   : in natural;
                          int_ac_1t     : in std_logic;
                          trefi_failure : in std_logic;
                          iram_status   : in t_iram_stat;
                          IRAM_AWIDTH   : in natural
                        ) return t_cal_status;

    function read (reg : t_cal_status) return std_logic_vector;

    -- codvw status
    function defaults return t_codvw_status;
    function defaults ( dgrb_mmi : t_dgrb_mmi
                      ) return t_codvw_status;

    function read (reg : in t_codvw_status) return std_logic_vector;


    -- test status report

    function defaults return t_test_status;

    function defaults   ( ctrl_mmi     : in t_ctrl_mmi;
                          pll_mmi      : in t_pll_mmi;
                          rw_if_test   : t_if_test_reg
                        ) return t_test_status;

    function read       (reg : t_test_status) return std_logic_vector;

    -- define all the read only registers

    function defaults return t_ro_regs;

    function defaults (dgrb_mmi        : t_dgrb_mmi;
                       ctrl_mmi        : t_ctrl_mmi;
                       pll_mmi         : t_pll_mmi;
                       rw_if_test      : t_if_test_reg;
                       USE_IRAM        : std_logic;
                       dqs_capture     : natural;
                       int_ac_1t       : std_logic;
                       trefi_failure   : std_logic;
                       iram_status     : t_iram_stat;
                       IRAM_AWIDTH     : natural
                      ) return t_ro_regs;

    -- >>>>>>>>>>>>>>>>>>>>>>>>
    -- Read / Write Registers
    -- >>>>>>>>>>>>>>>>>>>>>>>>

    -- Calibration control register
    -- high level calibration stage set register comprises a bit vector for
    -- the calibration stage coding and the 1 control bit.

    function defaults return t_hl_css;
    function write (wdata_in : std_logic_vector(31 downto 0)) return t_hl_css;
    function read  (reg : in t_hl_css)                        return std_logic_vector;
    procedure write_clear (signal reg : inout t_hl_css);

    -- Mode register A
    -- mode registers 0 and 1 (mr and emr1)

    function defaults return t_mr_register_a;
    function defaults ( mr0     : in    std_logic_vector;
                        mr1     : in    std_logic_vector
                       ) return t_mr_register_a;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_mr_register_a;
    function read (reg : in t_mr_register_a) return std_logic_vector;

    -- Mode register B
    -- mode registers 2 and 3 (emr2 and emr3) - not present in ddr DRAM

    function defaults return t_mr_register_b;
    function defaults ( mr2     : in    std_logic_vector;
                        mr3     : in    std_logic_vector
                       ) return t_mr_register_b;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_mr_register_b;
    function read (reg : in t_mr_register_b) return std_logic_vector;

    -- algorithm parameterisation register

    function defaults return t_parameterisation_reg_a;
    function defaults ( NOM_DQS_PHASE_SETTING   : in natural;
                        PLL_STEPS_PER_CYCLE     : in natural;
                        pll_360_sweeps          : in natural
                      ) return t_parameterisation_reg_a;
    function read ( reg : in t_parameterisation_reg_a) return std_logic_vector;
    function write (wdata_in : std_logic_vector(31 downto 0)) return t_parameterisation_reg_a;

    -- test signal register

    function defaults return t_if_test_reg;
    function defaults ( TRACKING_INTERVAL_IN_MS : in natural
                      ) return t_if_test_reg;
    function read ( reg : in t_if_test_reg) return std_logic_vector;
    function write (wdata_in : std_logic_vector(31 downto 0)) return t_if_test_reg;
    procedure write_clear (signal reg : inout t_if_test_reg);


    -- define all the read/write registers

    function defaults return t_rw_regs;

    function defaults(
                        mr0                     : in std_logic_vector;
                        mr1                     : in std_logic_vector;
                        mr2                     : in std_logic_vector;
                        mr3                     : in std_logic_vector;
                        NOM_DQS_PHASE_SETTING   : in natural;
                        PLL_STEPS_PER_CYCLE     : in natural;
                        pll_360_sweeps          : in natural;
                        TRACKING_INTERVAL_IN_MS : in natural;
                        C_HL_STAGE_ENABLE       : in std_logic_vector(c_hl_ccs_num_stages-1 downto 0)
                      )return t_rw_regs;

    procedure write_clear (signal regs    : inout t_rw_regs);

    -- >>>>>>>>>>>>>>>>>>>>>>>
    -- Group all registers
    -- >>>>>>>>>>>>>>>>>>>>>>>

    function defaults return t_mmi_regs;

    function v_read       (mmi_regs : in t_mmi_regs;
                           address  : in natural
                          ) return std_logic_vector;

    function read         (signal mmi_regs : in t_mmi_regs;
                                  address  : in natural
                          ) return std_logic_vector;

    procedure write       (mmi_regs : inout t_mmi_regs;
                           address  : in natural;
                           wdata    : in std_logic_vector(31 downto 0));

    -- >>>>>>>>>>>>>>>>>>>>>>>
    -- functions to communicate register settings to other sequencer blocks
    -- >>>>>>>>>>>>>>>>>>>>>>>
    function pack_record (ip_regs : t_rw_regs) return t_mmi_pll_reconfig;
    function pack_record (ip_regs : t_rw_regs) return t_admin_ctrl;
    function pack_record (ip_regs : t_rw_regs) return t_mmi_ctrl;

    function pack_record ( ip_regs : t_rw_regs) return t_algm_paramaterisation;


    -- >>>>>>>>>>>>>>>>>>>>>>>
    -- helper functions
    -- >>>>>>>>>>>>>>>>>>>>>>>

    function to_t_hl_css_reg (hl_css    : t_hl_css ) return t_hl_css_reg;

    function pack_ack_seen ( cal_stage_ack_seen : in t_cal_stage_ack_seen
                           ) return std_logic_vector;

    -- encoding of stage and active block for register setting
    function encode_current_stage (ctrl_cmd_id  : t_ctrl_cmd_id)       return std_logic_vector;
    function encode_active_block  (active_block : t_ctrl_active_block) return std_logic_vector;

--#mw_prefix ("alt_mem_phy_regs_pkg")
end alt_mem_phy_regs_pkg;
--#end

--#mw_prefix ("alt_mem_phy_regs_pkg")
package body alt_mem_phy_regs_pkg is
--#end

    -- >>>>>>>>>>>>>>>>>>>>
    -- Read Only Registers
    -- >>>>>>>>>>>>>>>>>>>

-- ---------------------------------------------------------------
-- CODVW status report
-- ---------------------------------------------------------------

    function defaults return t_codvw_status is
        variable temp: t_codvw_status;
    begin
        temp.cal_codvw_phase   := (others => '0');
        temp.cal_codvw_size    := (others => '0');
        temp.codvw_trk_shift   := (others => '0');
        temp.codvw_grt_one_dvw := '0';
        return temp;
    end function;

    function defaults ( dgrb_mmi : t_dgrb_mmi
                      ) return t_codvw_status is
        variable temp: t_codvw_status;
    begin
        temp                   := defaults;
        temp.cal_codvw_phase   := dgrb_mmi.cal_codvw_phase;
        temp.cal_codvw_size    := dgrb_mmi.cal_codvw_size;
        temp.codvw_trk_shift   := dgrb_mmi.codvw_trk_shift;
        temp.codvw_grt_one_dvw := dgrb_mmi.codvw_grt_one_dvw;
        return temp;
    end function;

    function read (reg : in t_codvw_status) return std_logic_vector is
        variable temp : std_logic_vector(31 downto 0);
    begin
        temp               := (others => '0');
        temp(31 downto 24) := reg.cal_codvw_phase;
        temp(23 downto 16) := reg.cal_codvw_size;
        temp(15 downto 4)  := reg.codvw_trk_shift;
        temp(0)            := reg.codvw_grt_one_dvw;
        return temp;
    end function;

-- ---------------------------------------------------------------
-- Calibration status report
-- ---------------------------------------------------------------

    function defaults return t_cal_status is
        variable temp: t_cal_status;
    begin
        temp.iram_addr_width  := (others => '0');
        temp.out_of_mem       := '0';
        temp.contested_access := '0';
        temp.cal_fail         := '0';
        temp.cal_success      := '0';
        temp.ctrl_err_code    := (others => '0');
        temp.trefi_failure    := '0';
        temp.int_ac_1t        := '0';
        temp.dqs_capture      := '0';
        temp.iram_present     := '0';
        temp.active_block     := (others => '0');
        temp.current_stage    := (others => '0');
        return temp;
    end function;

    --#pb_del like a write but named default to avoid confusion with property of ro_reg
    function defaults   ( ctrl_mmi      : in t_ctrl_mmi;
                          USE_IRAM      : in std_logic;
                          dqs_capture   : in natural;
                          int_ac_1t     : in std_logic;
                          trefi_failure : in std_logic;
                          iram_status   : in t_iram_stat;
                          IRAM_AWIDTH   : in natural
                        ) return t_cal_status is
        variable temp : t_cal_status;
    begin
        temp                  := defaults;
        temp.iram_addr_width  := std_logic_vector(to_unsigned(IRAM_AWIDTH, temp.iram_addr_width'length));
        temp.out_of_mem       := iram_status.out_of_mem;
        temp.contested_access := iram_status.contested_access;
        temp.cal_fail         := ctrl_mmi.ctrl_calibration_fail;
        temp.cal_success      := ctrl_mmi.ctrl_calibration_success;
        temp.ctrl_err_code    := ctrl_mmi.ctrl_err_code;
        temp.trefi_failure    := trefi_failure;
        temp.int_ac_1t        := int_ac_1t;

        if dqs_capture = 1 then
            temp.dqs_capture      := '1';
        elsif dqs_capture = 0 then
            temp.dqs_capture      := '0';
        else
            report regs_report_prefix & " invalid value for dqs_capture constant of " & integer'image(dqs_capture) severity failure;
        end if;

        temp.iram_present     := USE_IRAM;
        temp.active_block     := encode_active_block(ctrl_mmi.ctrl_current_active_block);
        temp.current_stage    := encode_current_stage(ctrl_mmi.ctrl_current_stage);
        return temp;
    end function;

    -- read for mmi status register
    function read       ( reg : t_cal_status
                        ) return std_logic_vector is
        variable output : std_logic_vector(31 downto 0);
    begin

        output               := (others => '0');
        output( 7 downto  0) := reg.current_stage;
        output(11 downto  8) := reg.active_block;
        output(12)           := reg.iram_present;
        output(13)           := reg.dqs_capture;
        output(14)           := reg.int_ac_1t;
        output(15)           := reg.trefi_failure;
        output(23 downto 16) := reg.ctrl_err_code;
        output(24)           := reg.cal_success;
        output(25)           := reg.cal_fail;
        output(26)           := reg.contested_access;
        output(27)           := reg.out_of_mem;
        output(31 downto 28) := reg.iram_addr_width;

        return output;
    end function;

-- ---------------------------------------------------------------
-- Test status report
-- ---------------------------------------------------------------

    function defaults return t_test_status is
        variable temp: t_test_status;
    begin
        temp.ack_seen         := (others => '0');
        temp.pll_mmi_err      := (others => '0');
        temp.pll_busy         := '0';
        return temp;
    end function;

    --#pb_del like a write but named default to avoid confusion with property of ro_reg
    function defaults   ( ctrl_mmi     : in t_ctrl_mmi;
                          pll_mmi      : in t_pll_mmi;
                          rw_if_test   : t_if_test_reg
                        ) return t_test_status is
        variable temp : t_test_status;
    begin
        temp             := defaults;
        temp.ack_seen    := pack_ack_seen(ctrl_mmi.ctrl_cal_stage_ack_seen);
        temp.pll_mmi_err := pll_mmi.err;
        temp.pll_busy    := pll_mmi.pll_busy or rw_if_test.pll_phs_shft_up_wc or rw_if_test.pll_phs_shft_dn_wc;
        return temp;
    end function;

    -- read for mmi status register
    function read       ( reg : t_test_status
                        ) return std_logic_vector is
        variable output : std_logic_vector(31 downto 0);
    begin

        output                                   := (others => '0');
        output(31 downto 32-c_hl_ccs_num_stages) := reg.ack_seen;
        output( 5 downto  4)                     := reg.pll_mmi_err;
        output(0)                                := reg.pll_busy;

        return output;
    end function;

-------------------------------------------------
-- FOR ALL RO REGS:
-------------------------------------------------

    function defaults return t_ro_regs is
        variable temp: t_ro_regs;
    begin
        temp.cal_status   := defaults;
        temp.codvw_status := defaults;
        return temp;
    end function;

    function defaults (dgrb_mmi        : t_dgrb_mmi;
                       ctrl_mmi        : t_ctrl_mmi;
                       pll_mmi         : t_pll_mmi;
                       rw_if_test      : t_if_test_reg;
                       USE_IRAM        : std_logic;
                       dqs_capture     : natural;
                       int_ac_1t       : std_logic;
                       trefi_failure   : std_logic;
                       iram_status     : t_iram_stat;
                       IRAM_AWIDTH     : natural
                      ) return t_ro_regs is
        variable output : t_ro_regs;
    begin
        output              := defaults;
        output.cal_status   := defaults(ctrl_mmi, USE_IRAM, dqs_capture, int_ac_1t, trefi_failure, iram_status, IRAM_AWIDTH);
        output.codvw_status := defaults(dgrb_mmi);
        output.test_status  := defaults(ctrl_mmi, pll_mmi, rw_if_test);
        return output;
    end function;


-- >>>>>>>>>>>>>>>>>>>>>>>>
-- Read / Write registers
-- >>>>>>>>>>>>>>>>>>>>>>>>

-- ---------------------------------------------------------------
-- mode register set A
-- ---------------------------------------------------------------
    function defaults return t_mr_register_a is
        variable temp :t_mr_register_a;
    begin
        temp.mr0 := (others => '0');
        temp.mr1 := (others => '0');
        return temp;
    end function;

    -- apply default mode register settings to register
    function defaults ( mr0     : in    std_logic_vector;
                        mr1     : in    std_logic_vector
                      ) return t_mr_register_a is
        variable temp :t_mr_register_a;
    begin
        temp     := defaults;
        temp.mr0 := mr0(temp.mr0'range);
        temp.mr1 := mr1(temp.mr1'range);
        return temp;
    end function;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_mr_register_a is
        variable temp :t_mr_register_a;
    begin
        temp.mr0 := wdata_in(c_max_mode_reg_index -1     downto 0);
        temp.mr1 := wdata_in(c_max_mode_reg_index -1 + 16 downto 16);
        return temp;
    end function;

    function read (reg : in t_mr_register_a) return std_logic_vector is
        variable temp : std_logic_vector(31 downto 0) := (others => '0');
    begin
        temp(c_max_mode_reg_index -1      downto  0) := reg.mr0;
        temp(c_max_mode_reg_index -1 + 16 downto 16) := reg.mr1;
        return temp;
    end function;

-- ---------------------------------------------------------------
-- mode register set B
-- ---------------------------------------------------------------
    function defaults return t_mr_register_b is
        variable temp :t_mr_register_b;
    begin
        temp.mr2 := (others => '0');
        temp.mr3 := (others => '0');
        return temp;
    end function;

    -- apply default mode register settings to register
    function defaults ( mr2     : in    std_logic_vector;
                        mr3     : in    std_logic_vector
                       ) return t_mr_register_b is
        variable temp :t_mr_register_b;
    begin
        temp     := defaults;
        temp.mr2 := mr2(temp.mr2'range);
        temp.mr3 := mr3(temp.mr3'range);
        return temp;
    end function;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_mr_register_b is
        variable temp :t_mr_register_b;
    begin
        temp.mr2 := wdata_in(c_max_mode_reg_index -1      downto 0);
        temp.mr3 := wdata_in(c_max_mode_reg_index -1 + 16 downto 16);
        return temp;
    end function;

    function read (reg : in t_mr_register_b) return std_logic_vector is
        variable temp : std_logic_vector(31 downto 0) := (others => '0');
    begin
        temp(c_max_mode_reg_index -1      downto  0) := reg.mr2;
        temp(c_max_mode_reg_index -1 + 16 downto 16) := reg.mr3;
        return temp;
    end function;


-- ---------------------------------------------------------------
-- HL CSS (high level calibration state status)
-- ---------------------------------------------------------------
    function defaults return t_hl_css is
        variable temp : t_hl_css;
    begin
        temp.hl_css             := (others => '0');
        temp.cal_start          := '0';
        return temp;
    end function;

    function defaults ( C_HL_STAGE_ENABLE : in std_logic_vector(c_hl_ccs_num_stages-1 downto 0)
                      ) return t_hl_css is
        variable temp: t_hl_css;
    begin
        temp        := defaults;
        temp.hl_css := temp.hl_css OR C_HL_STAGE_ENABLE;
        return temp;
    end function;

    function read ( reg : in t_hl_css) return std_logic_vector is
        variable temp : std_logic_vector (31 downto 0) := (others => '0');
    begin
        temp(30 downto 30-c_hl_ccs_num_stages+1) := reg.hl_css;
        temp(0)                                  := reg.cal_start;
        return temp;
    end function;

    function write (wdata_in : std_logic_vector(31 downto 0) )return t_hl_css is
       variable reg : t_hl_css;
    begin
        reg.hl_css             := wdata_in(30 downto 30-c_hl_ccs_num_stages+1);
        reg.cal_start          := wdata_in(0);
        return reg;
    end function;

    procedure write_clear (signal reg : inout t_hl_css) is
    begin
        reg.cal_start <= '0';
    end procedure;

-- ---------------------------------------------------------------
-- paramaterisation of sequencer through Avalon interface
-- ---------------------------------------------------------------
    function defaults return t_parameterisation_reg_a is
        variable temp : t_parameterisation_reg_a;
    begin
        temp.nominal_poa_phase_lead  := (others => '0');
        temp.maximum_poa_delay       := (others => '0');
        temp.pll_360_sweeps          := "0000";
        temp.num_phases_per_tck_pll  := "0011";
        temp.nominal_dqs_delay       := (others => '0');
        temp.extend_octrt_by         := "0100";
        temp.delay_octrt_by          := "0000";
        return temp;
    end function;

    -- reset the paramterisation reg to given values
    function defaults ( NOM_DQS_PHASE_SETTING   : in natural;
                        PLL_STEPS_PER_CYCLE     : in natural;
                        pll_360_sweeps          : in natural
                      ) return t_parameterisation_reg_a is
        variable temp: t_parameterisation_reg_a;
    begin
        temp                        := defaults;
        temp.num_phases_per_tck_pll := std_logic_vector(to_unsigned(PLL_STEPS_PER_CYCLE /8 , temp.num_phases_per_tck_pll'high + 1 ));
        temp.pll_360_sweeps         := std_logic_vector(to_unsigned(pll_360_sweeps         , temp.pll_360_sweeps'high + 1         ));
        temp.nominal_dqs_delay      := std_logic_vector(to_unsigned(NOM_DQS_PHASE_SETTING  , temp.nominal_dqs_delay'high + 1      ));
        temp.extend_octrt_by        := std_logic_vector(to_unsigned(5                      , temp.extend_octrt_by'high + 1        ));
        temp.delay_octrt_by         := std_logic_vector(to_unsigned(6                      , temp.delay_octrt_by'high + 1         ));
        return temp;
    end function;

    function read ( reg : in t_parameterisation_reg_a) return std_logic_vector is
        variable temp : std_logic_vector (31 downto 0) := (others => '0');
    begin
        temp( 3 downto  0) := reg.pll_360_sweeps;
        temp( 7 downto  4) := reg.num_phases_per_tck_pll;
        temp(10 downto  8) := reg.nominal_dqs_delay;
        temp(19 downto 16) := reg.nominal_poa_phase_lead;
        temp(23 downto 20) := reg.maximum_poa_delay;
        temp(27 downto 24) := reg.extend_octrt_by;
        temp(31 downto 28) := reg.delay_octrt_by;
        return temp;
    end function;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_parameterisation_reg_a is
        variable reg : t_parameterisation_reg_a;
    begin
        reg.pll_360_sweeps         := wdata_in( 3 downto  0);
        reg.num_phases_per_tck_pll := wdata_in( 7 downto  4);
        reg.nominal_dqs_delay      := wdata_in(10 downto  8);
        reg.nominal_poa_phase_lead := wdata_in(19 downto 16);
        reg.maximum_poa_delay      := wdata_in(23 downto 20);
        reg.extend_octrt_by        := wdata_in(27 downto 24);
        reg.delay_octrt_by         := wdata_in(31 downto 28);
        return reg;
    end function;

-- ---------------------------------------------------------------
-- t_if_test_reg - additional test support register
-- ---------------------------------------------------------------
    function defaults return t_if_test_reg is
        variable temp : t_if_test_reg;
    begin
        temp.pll_phs_shft_phase_sel  := 0;
        temp.pll_phs_shft_up_wc      := '0';
        temp.pll_phs_shft_dn_wc      := '0';
        temp.ac_1t_toggle            := '0';
        temp.tracking_period_ms      := "10000000"; -- 127 ms interval
        temp.tracking_units_are_10us := '0';
        return temp;
    end function;

    -- reset the paramterisation reg to given values
    function defaults ( TRACKING_INTERVAL_IN_MS : in natural
                      ) return t_if_test_reg is
        variable temp: t_if_test_reg;
    begin
        temp := defaults;
        temp.tracking_period_ms      := std_logic_vector(to_unsigned(TRACKING_INTERVAL_IN_MS, temp.tracking_period_ms'length));
        return temp;
    end function;

    function read ( reg : in t_if_test_reg) return std_logic_vector is
        variable temp : std_logic_vector (31 downto 0) := (others => '0');
    begin
        temp( 3 downto  0) := std_logic_vector(to_unsigned(reg.pll_phs_shft_phase_sel,4));
        temp(4)            := reg.pll_phs_shft_up_wc;
        temp(5)            := reg.pll_phs_shft_dn_wc;
        temp(16)           := reg.ac_1t_toggle;
        temp(15 downto  8) := reg.tracking_period_ms;
        temp(20)           := reg.tracking_units_are_10us;
        return temp;
    end function;

    function write (wdata_in : std_logic_vector(31 downto 0)) return t_if_test_reg is
        variable reg : t_if_test_reg;
    begin
        reg.pll_phs_shft_phase_sel  := to_integer(unsigned(wdata_in( 3 downto  0)));
        reg.pll_phs_shft_up_wc      := wdata_in(4);
        reg.pll_phs_shft_dn_wc      := wdata_in(5);
        reg.ac_1t_toggle            := wdata_in(16);
        reg.tracking_period_ms      := wdata_in(15 downto  8);
        reg.tracking_units_are_10us := wdata_in(20);
        return reg;
    end function;

    procedure write_clear (signal reg : inout t_if_test_reg) is
    begin
        reg.ac_1t_toggle       <= '0';
        reg.pll_phs_shft_up_wc <= '0';
        reg.pll_phs_shft_dn_wc <= '0';
    end procedure;

-- ---------------------------------------------------------------
-- RW Regs, record of read/write register records (to simplify handling)
-- ---------------------------------------------------------------
    function defaults return t_rw_regs is
        variable temp : t_rw_regs;
    begin
        temp.mr_reg_a     := defaults;
        temp.mr_reg_b     := defaults;
        temp.rw_hl_css    := defaults;
        temp.rw_param_reg := defaults;
        temp.rw_if_test   := defaults;
        return temp;
    end function;

    function defaults(
                       mr0                     : in std_logic_vector;
                       mr1                     : in std_logic_vector;
                       mr2                     : in std_logic_vector;
                       mr3                     : in std_logic_vector;
                       NOM_DQS_PHASE_SETTING   : in natural;
                       PLL_STEPS_PER_CYCLE     : in natural;
                       pll_360_sweeps          : in natural;
                       TRACKING_INTERVAL_IN_MS : in natural;
                       C_HL_STAGE_ENABLE       : in std_logic_vector(c_hl_ccs_num_stages-1 downto 0)
                      )return t_rw_regs is
        variable temp : t_rw_regs;
    begin
        temp              := defaults;
        temp.mr_reg_a     := defaults(mr0, mr1);
        temp.mr_reg_b     := defaults(mr2, mr3);
        temp.rw_param_reg := defaults(NOM_DQS_PHASE_SETTING,
                                      PLL_STEPS_PER_CYCLE,
                                      pll_360_sweeps);
        temp.rw_if_test   := defaults(TRACKING_INTERVAL_IN_MS);
        temp.rw_hl_css    := defaults(C_HL_STAGE_ENABLE);
        return temp;
    end function;

    procedure write_clear (signal regs : inout t_rw_regs) is
    begin
        write_clear(regs.rw_if_test);
        write_clear(regs.rw_hl_css);
    end procedure;


    -- >>>>>>>>>>>>>>>>>>>>>>>>>>
    -- All mmi registers:
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>

    function defaults return t_mmi_regs is
        variable v_mmi_regs : t_mmi_regs;
    begin
        v_mmi_regs.rw_regs       := defaults;
        v_mmi_regs.ro_regs       := defaults;
        v_mmi_regs.enable_writes := '0';
        return v_mmi_regs;
    end function;

    function v_read       (mmi_regs     : in t_mmi_regs;
                           address      : in natural
                          ) return std_logic_vector is
        variable output : std_logic_vector(31 downto 0);
    begin

        output := (others => '0');

        case address is

            -- status register
            when  c_regofst_cal_status     => output := read (mmi_regs.ro_regs.cal_status);

            -- debug access register
            when  c_regofst_debug_access   =>
                if (mmi_regs.enable_writes = '1') then
                    output := c_mmi_access_codeword;
                else
                    output := (others => '0');
                end if;

            -- test i/f to check which stages have acknowledged a command and pll checks
            when c_regofst_test_status     => output := read(mmi_regs.ro_regs.test_status);

            -- mode registers
            when c_regofst_mr_register_a   => output := read(mmi_regs.rw_regs.mr_reg_a);
            when c_regofst_mr_register_b   => output := read(mmi_regs.rw_regs.mr_reg_b);

            -- codvw r/o status register
            when c_regofst_codvw_status    => output := read(mmi_regs.ro_regs.codvw_status);

            -- read/write registers
            when  c_regofst_hl_css         => output := read(mmi_regs.rw_regs.rw_hl_css);
            when  c_regofst_if_param       => output := read(mmi_regs.rw_regs.rw_param_reg);
            when  c_regofst_if_test        => output := read(mmi_regs.rw_regs.rw_if_test);

            when others                    => report regs_report_prefix & "MMI registers detected an attempt to read to non-existant register location" severity warning;
                                                                            -- set illegal addr interrupt.
        end case;

        return output;

    end function;


    function read         (signal mmi_regs       : in t_mmi_regs;
                                  address        : in natural
                          ) return std_logic_vector is
        variable output     : std_logic_vector(31 downto 0);
        variable v_mmi_regs : t_mmi_regs;
    begin
        v_mmi_regs := mmi_regs;
        output     := v_read(v_mmi_regs, address);
        return output;
    end function;

    procedure write       (mmi_regs : inout t_mmi_regs;
                           address  : in natural;
                           wdata    : in std_logic_vector(31 downto 0)) is

    begin

        -- intercept writes to codeword.  This needs to be set for iRAM access :
        if address = c_regofst_debug_access then
            if wdata = c_mmi_access_codeword then
                mmi_regs.enable_writes := '1';
            else
                mmi_regs.enable_writes := '0';
            end if;

        else 

            case address is

                -- read only registers
                when  c_regofst_cal_status |
                      c_regofst_codvw_status |
                      c_regofst_test_status =>

                      report regs_report_prefix & "MMI registers detected an attempt to write to read only register number" & integer'image(address) severity failure;

                -- read/write registers
                when c_regofst_mr_register_a  => mmi_regs.rw_regs.mr_reg_a     := write(wdata);
                when c_regofst_mr_register_b  => mmi_regs.rw_regs.mr_reg_b     := write(wdata);
                when c_regofst_hl_css         => mmi_regs.rw_regs.rw_hl_css    := write(wdata);
                when c_regofst_if_param       => mmi_regs.rw_regs.rw_param_reg := write(wdata);
                when c_regofst_if_test        => mmi_regs.rw_regs.rw_if_test   := write(wdata);

                when others  => -- set illegal addr interrupt.

                    report regs_report_prefix & "MMI registers detected an attempt to write to non existant register, with expected number" & integer'image(address) severity failure;

            end case;

        end if;

    end procedure;

    -- >>>>>>>>>>>>>>>>>>>>>>>>>>
    -- the following functions enable register data to be communicated to other sequencer blocks
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>

    function pack_record ( ip_regs : t_rw_regs
                         ) return t_algm_paramaterisation is
        variable output : t_algm_paramaterisation;
    begin
        -- default assignments
        output.num_phases_per_tck_pll := 16;
        output.pll_360_sweeps         := 1;
        output.nominal_dqs_delay      := 2;
        output.nominal_poa_phase_lead := 1;
        output.maximum_poa_delay      := 5;
        output.odt_enabled            := false;

		output.num_phases_per_tck_pll := to_integer(unsigned(ip_regs.rw_param_reg.num_phases_per_tck_pll)) * 8;

        case ip_regs.rw_param_reg.nominal_dqs_delay      is
            when "010" => output.nominal_dqs_delay := 2;
            when "001" => output.nominal_dqs_delay := 1;
            when "000" => output.nominal_dqs_delay := 0;
            when "011" => output.nominal_dqs_delay := 3;
            when others => report regs_report_prefix &
                                  "there is a unsupported number of DQS taps (" &
                                  natural'image(to_integer(unsigned(ip_regs.rw_param_reg.nominal_dqs_delay))) &
                                  ") being advertised as the standard value" severity error;
        end case;

       case ip_regs.rw_param_reg.nominal_poa_phase_lead  is
            when "0001" => output.nominal_poa_phase_lead := 1;
            when "0010" => output.nominal_poa_phase_lead := 2;
            when "0011" => output.nominal_poa_phase_lead := 3;
            when "0000" => output.nominal_poa_phase_lead := 0;
            when others => report regs_report_prefix &
                                  "there is an unsupported nominal postamble phase lead paramater set (" &
                                  natural'image(to_integer(unsigned(ip_regs.rw_param_reg.nominal_poa_phase_lead))) &
                                  ")" severity error;
       end case;

       if (    (ip_regs.mr_reg_a.mr1(2) = '1')
            or (ip_regs.mr_reg_a.mr1(6) = '1')
            or (ip_regs.mr_reg_a.mr1(9) = '1')
          ) then
          output.odt_enabled            := true;
       end if;

       output.pll_360_sweeps     := to_integer(unsigned(ip_regs.rw_param_reg.pll_360_sweeps));
       output.maximum_poa_delay  := to_integer(unsigned(ip_regs.rw_param_reg.maximum_poa_delay));
       output.extend_octrt_by    := to_integer(unsigned(ip_regs.rw_param_reg.extend_octrt_by));
       output.delay_octrt_by     := to_integer(unsigned(ip_regs.rw_param_reg.delay_octrt_by));
       output.tracking_period_ms := to_integer(unsigned(ip_regs.rw_if_test.tracking_period_ms));
        return output;
    end function;


    function pack_record (ip_regs : t_rw_regs) return t_mmi_pll_reconfig is
        variable output : t_mmi_pll_reconfig;
    begin
        output.pll_phs_shft_phase_sel := ip_regs.rw_if_test.pll_phs_shft_phase_sel;
        output.pll_phs_shft_up_wc     := ip_regs.rw_if_test.pll_phs_shft_up_wc;
        output.pll_phs_shft_dn_wc     := ip_regs.rw_if_test.pll_phs_shft_dn_wc;
        return output;
    end function;


    function pack_record (ip_regs : t_rw_regs) return t_admin_ctrl is
        variable output : t_admin_ctrl := defaults;
    begin
        output.mr0          := ip_regs.mr_reg_a.mr0;
        output.mr1          := ip_regs.mr_reg_a.mr1;
        output.mr2          := ip_regs.mr_reg_b.mr2;
        output.mr3          := ip_regs.mr_reg_b.mr3;
        return output;
    end function;

    function pack_record (ip_regs : t_rw_regs) return t_mmi_ctrl is
        variable output : t_mmi_ctrl := defaults;
    begin
        output.hl_css                := to_t_hl_css_reg (ip_regs.rw_hl_css);
        output.calibration_start     := ip_regs.rw_hl_css.cal_start;
        output.tracking_period_ms    := to_integer(unsigned(ip_regs.rw_if_test.tracking_period_ms));
        output.tracking_orvd_to_10ms := ip_regs.rw_if_test.tracking_units_are_10us;
        return output;
    end function;

    -- >>>>>>>>>>>>>>>>>>>>>>>>>>
    -- Helper functions :
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>

    function to_t_hl_css_reg (hl_css    : t_hl_css
                         ) return t_hl_css_reg is
        variable output : t_hl_css_reg := defaults;
    begin

        output.phy_initialise_dis           := hl_css.hl_css(c_hl_css_reg_phy_initialise_dis_bit);
        output.init_dram_dis                := hl_css.hl_css(c_hl_css_reg_init_dram_dis_bit);
        output.write_ihi_dis                := hl_css.hl_css(c_hl_css_reg_write_ihi_dis_bit);
        output.cal_dis                      := hl_css.hl_css(c_hl_css_reg_cal_dis_bit);
        output.write_btp_dis                := hl_css.hl_css(c_hl_css_reg_write_btp_dis_bit);
        output.write_mtp_dis                := hl_css.hl_css(c_hl_css_reg_write_mtp_dis_bit);
        output.read_mtp_dis                 := hl_css.hl_css(c_hl_css_reg_read_mtp_dis_bit);
        output.rrp_reset_dis                := hl_css.hl_css(c_hl_css_reg_rrp_reset_dis_bit);
        output.rrp_sweep_dis                := hl_css.hl_css(c_hl_css_reg_rrp_sweep_dis_bit);
        output.rrp_seek_dis                 := hl_css.hl_css(c_hl_css_reg_rrp_seek_dis_bit);
        output.rdv_dis                      := hl_css.hl_css(c_hl_css_reg_rdv_dis_bit);
        output.poa_dis                      := hl_css.hl_css(c_hl_css_reg_poa_dis_bit);
        output.was_dis                      := hl_css.hl_css(c_hl_css_reg_was_dis_bit);
        output.adv_rd_lat_dis               := hl_css.hl_css(c_hl_css_reg_adv_rd_lat_dis_bit);
        output.adv_wr_lat_dis               := hl_css.hl_css(c_hl_css_reg_adv_wr_lat_dis_bit);
        output.prep_customer_mr_setup_dis   := hl_css.hl_css(c_hl_css_reg_prep_customer_mr_setup_dis_bit);
        output.tracking_dis                 := hl_css.hl_css(c_hl_css_reg_tracking_dis_bit);
        return output;
    end function;

    -- pack the ack seen record element into a std_logic_vector
    function pack_ack_seen ( cal_stage_ack_seen : in t_cal_stage_ack_seen
                        )    return std_logic_vector is
        variable v_output: std_logic_vector(c_hl_ccs_num_stages-1 downto 0);
        variable v_start : natural range 0 to c_hl_ccs_num_stages-1;
    begin
        v_output := (others => '0');

        v_output(c_hl_css_reg_cal_dis_bit                   ) := cal_stage_ack_seen.cal;
        v_output(c_hl_css_reg_phy_initialise_dis_bit        ) := cal_stage_ack_seen.phy_initialise;
        v_output(c_hl_css_reg_init_dram_dis_bit             ) := cal_stage_ack_seen.init_dram;
        v_output(c_hl_css_reg_write_ihi_dis_bit             ) := cal_stage_ack_seen.write_ihi;
        v_output(c_hl_css_reg_write_btp_dis_bit             ) := cal_stage_ack_seen.write_btp;
        v_output(c_hl_css_reg_write_mtp_dis_bit             ) := cal_stage_ack_seen.write_mtp;
        v_output(c_hl_css_reg_read_mtp_dis_bit              ) := cal_stage_ack_seen.read_mtp;
        v_output(c_hl_css_reg_rrp_reset_dis_bit             ) := cal_stage_ack_seen.rrp_reset;
        v_output(c_hl_css_reg_rrp_sweep_dis_bit             ) := cal_stage_ack_seen.rrp_sweep;
        v_output(c_hl_css_reg_rrp_seek_dis_bit              ) := cal_stage_ack_seen.rrp_seek;
        v_output(c_hl_css_reg_rdv_dis_bit                   ) := cal_stage_ack_seen.rdv;
        v_output(c_hl_css_reg_poa_dis_bit                   ) := cal_stage_ack_seen.poa;
        v_output(c_hl_css_reg_was_dis_bit                   ) := cal_stage_ack_seen.was;
        v_output(c_hl_css_reg_adv_rd_lat_dis_bit            ) := cal_stage_ack_seen.adv_rd_lat;
        v_output(c_hl_css_reg_adv_wr_lat_dis_bit            ) := cal_stage_ack_seen.adv_wr_lat;
        v_output(c_hl_css_reg_prep_customer_mr_setup_dis_bit) := cal_stage_ack_seen.prep_customer_mr_setup;
        v_output(c_hl_css_reg_tracking_dis_bit              ) := cal_stage_ack_seen.tracking_setup;

        return v_output;

    end function;

    -- reg encoding of current stage
    function encode_current_stage (ctrl_cmd_id    : t_ctrl_cmd_id
                         ) return std_logic_vector  is
        variable output :  std_logic_vector(7 downto 0);
    begin

       case ctrl_cmd_id is

           when cmd_idle                         => output := X"00";
           when cmd_phy_initialise               => output := X"01";
           when cmd_init_dram |
                cmd_prog_cal_mr                  => output := X"02";
           when cmd_write_ihi                    => output := X"03";
           when cmd_write_btp                    => output := X"04";
           when cmd_write_mtp                    => output := X"05";
           when cmd_read_mtp                     => output := X"06";
           when cmd_rrp_reset                    => output := X"07";
           when cmd_rrp_sweep                    => output := X"08";
           when cmd_rrp_seek                     => output := X"09";
           when cmd_rdv                          => output := X"0A";
           when cmd_poa                          => output := X"0B";
           when cmd_was                          => output := X"0C";
           when cmd_prep_adv_rd_lat              => output := X"0D";
           when cmd_prep_adv_wr_lat              => output := X"0E";
           when cmd_prep_customer_mr_setup       => output := X"0F";
           when cmd_tr_due                       => output := X"10";

           when others =>
                 null;
                 report regs_report_prefix & "unknown cal command (" & t_ctrl_cmd_id'image(ctrl_cmd_id) & ") seen in encode_current_stage function" severity failure;

        end case;

        return output;

    end function;

    -- reg encoding of current active block
    function encode_active_block (active_block    : t_ctrl_active_block
                         ) return std_logic_vector  is
        variable output :  std_logic_vector(3 downto 0);
    begin

       case active_block is

           when idle   => output := X"0";
           when admin  => output := X"1";
           when dgwb   => output := X"2";
           when dgrb   => output := X"3";
           when proc   => output := X"4";
           when setup  => output := X"5";
           when iram   => output := X"6";

           when others =>
                 output := X"7";
                 report regs_report_prefix & "unknown active_block seen in encode_active_block function" severity failure;

        end case;

        return output;

    end function;

--#mw_prefix ("alt_mem_phy_regs_pkg")
end alt_mem_phy_regs_pkg;
--#end
