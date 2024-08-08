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
--  Title           : Top level non-levelling AFI PHY sequencer

--  File:  $RCSfile : alt_mem_phy_seq.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : top level for the non-levelling AFI PHY sequencer
--                    The top level instances the sub-blocks of the AFI PHY
--                    sequencer. In addition a number of multiplexing and high-
--                    level control operations are performed. This includes the
--                    multiplexing and generation of control signals for: the
--                    address and command DRAM interface and pll, oct and datapath
--                    latency control signals.
-- -----------------------------------------------------------------------------

--altera message_off 10036

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--#mw_prefix ("alt_mem_phy_seq")
entity alt_mem_phy_seq IS
--#end
    generic (
        -- choice of FPGA device family and DRAM type
        FAMILY                         : string;
        MEM_IF_MEMTYPE                 : string;
        SPEED_GRADE                    : string;
        FAMILYGROUP_ID                 : natural;

        -- physical interface width definitions
        MEM_IF_DQS_WIDTH               : natural;
        MEM_IF_DWIDTH                  : natural;
        MEM_IF_DM_WIDTH                : natural;
        MEM_IF_DQ_PER_DQS              : natural;
        DWIDTH_RATIO                   : natural;
        CLOCK_INDEX_WIDTH              : natural;
        MEM_IF_CLK_PAIR_COUNT          : natural;
        MEM_IF_ADDR_WIDTH              : natural;
        MEM_IF_BANKADDR_WIDTH          : natural;
        MEM_IF_CS_WIDTH                : natural;
        MEM_IF_NUM_RANKS               : natural;
        MEM_IF_RANKS_PER_SLOT          : natural;
        ADV_LAT_WIDTH                  : natural;
        RESYNCHRONISE_AVALON_DBG       : natural;  -- 0 = false, 1 = true
        AV_IF_ADDR_WIDTH               : natural;

        -- Not used for non-levelled seq
        CHIP_OR_DIMM                    : string;
        RDIMM_CONFIG_BITS               : string;

        -- setup / algorithm information
        NOM_DQS_PHASE_SETTING          : natural;
        SCAN_CLK_DIVIDE_BY             : natural;
        RDP_ADDR_WIDTH                 : natural;
        PLL_STEPS_PER_CYCLE            : natural;
        IOE_PHASES_PER_TCK             : natural;
        IOE_DELAYS_PER_PHS             : natural;
        MEM_IF_CLK_PS                  : natural;

        WRITE_DESKEW_T10               : natural;
        WRITE_DESKEW_HC_T10            : natural;
        WRITE_DESKEW_T9NI              : natural;
        WRITE_DESKEW_HC_T9NI           : natural;
        WRITE_DESKEW_T9I               : natural;
        WRITE_DESKEW_HC_T9I            : natural;
        WRITE_DESKEW_RANGE             : natural;

        -- initial mode register settings
        PHY_DEF_MR_1ST                 : natural;
        PHY_DEF_MR_2ND                 : natural;
        PHY_DEF_MR_3RD                 : natural;
        PHY_DEF_MR_4TH                 : natural;

        MEM_IF_DQSN_EN                 : natural;      -- default off for Cyclone-III
        MEM_IF_DQS_CAPTURE_EN          : natural;

        GENERATE_ADDITIONAL_DBG_RTL    : natural;      -- 1 signals to include iram and mmi blocks and 0 not to include

        SINGLE_DQS_DELAY_CONTROL_CODE  : natural;      -- reserved for future use
        PRESET_RLAT                    : natural;      -- reserved for future use
        EN_OCT                         : natural;      -- Does the sequencer use OCT during calibration.
        OCT_LAT_WIDTH                  : natural;
        SIM_TIME_REDUCTIONS            : natural;      -- if 0 null, if 2 rrp for 1 dqs group and 1 cs
        FORCE_HC                       : natural;      -- Use to force HardCopy in simulation.
        CAPABILITIES                   : natural;       -- advertise capabilities i.e. which ctrl block states to execute (default all on)
        TINIT_TCK                      : natural;
        TINIT_RST                      : natural;
        GENERATE_TRACKING_PHASE_STORE  : natural;      -- reserved for future use
        IP_BUILDNUM                    : natural
    );
    port (
        -- clk / reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        -- calibration status and prompt
        ctl_init_success               : out   std_logic;
        ctl_init_fail                  : out   std_logic;
        ctl_init_warning               : out   std_logic;  -- unused
        ctl_recalibrate_req            : in    std_logic;

        -- the following two signals are reserved for future use
        mem_ac_swapped_ranks           : in    std_logic_vector(MEM_IF_NUM_RANKS                         - 1  downto 0);
        ctl_cal_byte_lanes             : in    std_logic_vector(MEM_IF_NUM_RANKS * MEM_IF_DQS_WIDTH      - 1 downto 0);

        -- pll reconfiguration
        seq_pll_inc_dec_n              : out   std_logic;
        seq_pll_start_reconfig         : out   std_logic;
        seq_pll_select                 : out   std_logic_vector(CLOCK_INDEX_WIDTH                        - 1 downto 0);
        seq_pll_phs_shift_busy         : in    std_logic;
        pll_resync_clk_index           : in    std_logic_vector(CLOCK_INDEX_WIDTH                        - 1 downto 0); -- PLL phase used to select resync clock
        pll_measure_clk_index          : in    std_logic_vector(CLOCK_INDEX_WIDTH                        - 1 downto 0); -- PLL phase used to select mimic/measure clock


        -- scanchain associated signals (reserved for future use)
        seq_scan_clk                   : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_enable_dqs_config     : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_update                : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_din                   : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_enable_ck             : out   std_logic_vector(MEM_IF_CLK_PAIR_COUNT                    - 1 downto 0);
        seq_scan_enable_dqs            : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_enable_dqsn           : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_scan_enable_dq             : out   std_logic_vector(MEM_IF_DWIDTH                            - 1 downto 0);
        seq_scan_enable_dm             : out   std_logic_vector(MEM_IF_DM_WIDTH                          - 1 downto 0);
        hr_rsc_clk                     : in    std_logic;

        -- address / command interface (note these are mapped internally to the seq_ac record)
        seq_ac_addr                    : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_ADDR_WIDTH     - 1 downto 0);
        seq_ac_ba                      : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_BANKADDR_WIDTH - 1 downto 0);
        seq_ac_cas_n                   : out   std_logic_vector((DWIDTH_RATIO/2)                         - 1 downto 0);
        seq_ac_ras_n                   : out   std_logic_vector((DWIDTH_RATIO/2)                         - 1 downto 0);
        seq_ac_we_n                    : out   std_logic_vector((DWIDTH_RATIO/2)                         - 1 downto 0);
        seq_ac_cke                     : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_NUM_RANKS      - 1 downto 0);
        seq_ac_cs_n                    : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_NUM_RANKS      - 1 downto 0);
        seq_ac_odt                     : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_NUM_RANKS      - 1 downto 0);
        seq_ac_rst_n                   : out   std_logic_vector((DWIDTH_RATIO/2)                         - 1 downto 0);
        seq_ac_sel                     : out   std_logic;
        seq_mem_clk_disable            : out   std_logic;

        -- additional datapath latency (reserved for future use)
        seq_ac_add_1t_ac_lat_internal  : out   std_logic;
        seq_ac_add_1t_odt_lat_internal : out   std_logic;
        seq_ac_add_2t                  : out   std_logic;

        -- read datapath interface
        seq_rdp_reset_req_n            : out   std_logic;
        seq_rdp_inc_read_lat_1x        : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_rdp_dec_read_lat_1x        : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        rdata                          : in    std_logic_vector( DWIDTH_RATIO    * MEM_IF_DWIDTH         - 1 downto 0);

        -- read data valid (associated signals) interface
        seq_rdv_doing_rd               : out   std_logic_vector(MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2        - 1 downto 0);
        rdata_valid                    : in    std_logic_vector( DWIDTH_RATIO/2                          - 1 downto 0);
        seq_rdata_valid_lat_inc        : out   std_logic;
        seq_rdata_valid_lat_dec        : out   std_logic;
        seq_ctl_rlat                   : out   std_logic_vector(ADV_LAT_WIDTH                            - 1 downto 0);

        -- postamble interface (unused for Cyclone-III)
        seq_poa_lat_dec_1x             : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_poa_lat_inc_1x             : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_poa_protection_override_1x : out   std_logic;

        -- OCT path control
        seq_oct_oct_delay              : out   std_logic_vector(OCT_LAT_WIDTH - 1 downto 0);
        seq_oct_oct_extend             : out   std_logic_vector(OCT_LAT_WIDTH - 1 downto 0);
        seq_oct_value                  : out   std_logic;

        -- write data path interface
        seq_wdp_dqs_burst              : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_DQS_WIDTH      - 1 downto 0);
        seq_wdp_wdata_valid            : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_DQS_WIDTH      - 1 downto 0);
        seq_wdp_wdata                  : out   std_logic_vector( DWIDTH_RATIO    * MEM_IF_DWIDTH         - 1 downto 0);
        seq_wdp_dm                     : out   std_logic_vector( DWIDTH_RATIO    * MEM_IF_DM_WIDTH       - 1 downto 0);
        seq_wdp_dqs                    : out   std_logic_vector( DWIDTH_RATIO                            - 1 downto 0);
        seq_wdp_ovride                 : out   std_logic;
        seq_dqs_add_2t_delay           : out   std_logic_vector(MEM_IF_DQS_WIDTH                         - 1 downto 0);
        seq_ctl_wlat                   : out   std_logic_vector(ADV_LAT_WIDTH                            - 1 downto 0);

        -- mimic path interface
        seq_mmc_start                  : out   std_logic;
        mmc_seq_done                   : in    std_logic;
        mmc_seq_value                  : in    std_logic;

        -- parity signals (not used for non-levelled PHY)
        mem_err_out_n                  : in    std_logic;
        parity_error_n                 : out   std_logic;

        --synchronous Avalon debug interface  (internally re-synchronised to input clock (a generic option))
        dbg_seq_clk                    : in    std_logic;
        dbg_seq_rst_n                  : in    std_logic;
        dbg_seq_addr                   : in    std_logic_vector(AV_IF_ADDR_WIDTH                         - 1 downto 0);
        dbg_seq_wr                     : in    std_logic;
        dbg_seq_rd                     : in    std_logic;
        dbg_seq_cs                     : in    std_logic;
        dbg_seq_wr_data                : in    std_logic_vector(31                                           downto 0);
        seq_dbg_rd_data                : out   std_logic_vector(31                                           downto 0);
        seq_dbg_waitrequest            : out   std_logic
    );
end entity;

library work;

-- The record package (alt_mem_phy_record_pkg) is used to combine command and status signals
-- (into records) to be passed between sequencer blocks. It also contains type and record definitions
-- for the stages of DRAM memory calibration.
--#mw_prefix ("alt_mem_phy_record_pkg")
use work.alt_mem_phy_record_pkg.all;
--#end

-- The registers package (alt_mem_phy_regs_pkg) is used to combine the definition of the
-- registers for the mmi status registers and functions/procedures applied to the registers
--#mw_prefix ("alt_mem_phy_regs_pkg")
use work.alt_mem_phy_regs_pkg.all;
--#end

-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
use work.alt_mem_phy_constants_pkg.all;
--#end

-- The iram address package (alt_mem_phy_iram_addr_pkg) is used to define the base addresses used
-- for iram writes during calibration
--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
use work.alt_mem_phy_iram_addr_pkg.all;
--#end

-- The address and command package (alt_mem_phy_addr_cmd_pkg) is used to combine DRAM address
-- and command signals in one record and unify the functions operating on this record.
--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
use work.alt_mem_phy_addr_cmd_pkg.all;
--#end


-- Individually include each of library files for the sub-blocks of the sequencer:
--#mw_prefix ("alt_mem_phy_admin")
use work.alt_mem_phy_admin;
--#end
--#mw_prefix ("alt_mem_phy_mmi")
use work.alt_mem_phy_mmi;
--#end
--#mw_prefix ("alt_mem_phy_iram")
use work.alt_mem_phy_iram;
--#end
--#mw_prefix ("alt_mem_phy_dgrb")
use work.alt_mem_phy_dgrb;
--#end
--#mw_prefix ("alt_mem_phy_dgwb")
use work.alt_mem_phy_dgwb;
--#end
--#mw_prefix ("alt_mem_phy_ctrl")
use work.alt_mem_phy_ctrl;
--#end

--#mw_prefix ("alt_mem_phy_seq")
architecture struct of alt_mem_phy_seq IS
--#end

    -- #pb_del disable power up level warning messages
    attribute altera_attribute : string;
    attribute altera_attribute of struct : architecture is "-name MESSAGE_DISABLE 18010";

    -- debug signals (similar to those seen in the Quartus v8.0 DDR/DDR2 sequencer)
    signal rsu_multiple_valid_latencies_err : std_logic;                                     -- true if >2 valid latency values are detected
    signal rsu_grt_one_dvw_err              : std_logic;                                     -- true if >1 data valid window is detected
    signal rsu_no_dvw_err                   : std_logic;                                     -- true if no data valid window is detected
    signal rsu_codvw_phase                  : std_logic_vector(11                downto 0);  -- set to the phase of the DVW detected if calibration is successful
    signal rsu_codvw_size                   : std_logic_vector(11                downto 0);  -- set to the phase of the DVW detected if calibration is successful
    signal rsu_read_latency                 : std_logic_vector(ADV_LAT_WIDTH - 1 downto 0);   -- set to the correct read latency if calibration is successful

    -- outputs from the dgrb to generate the above rsu_codvw_* signals and report status to the mmi
    signal dgrb_mmi                         : t_dgrb_mmi;

    -- admin to mmi interface
    signal regs_admin_ctrl_rec            : t_admin_ctrl;  -- mmi register settings information
    signal admin_regs_status_rec          : t_admin_stat;  -- admin status information

    -- odt enable from the admin block based on mr settings
    signal enable_odt                     : std_logic;

    -- iram status information (sent to the ctrl block)
    signal iram_status                    : t_iram_stat;

    -- dgrb iram write interface
    signal dgrb_iram                      : t_iram_push;

    -- ctrl to iram interface
    signal ctrl_idib_top                  : natural;              -- current write location in the iram
    signal ctrl_active_block              : t_ctrl_active_block;
    signal ctrl_iram_push                 : t_ctrl_iram;
    signal iram_push_done                 : std_logic;
    signal ctrl_iram_ihi_write            : std_logic;

    -- local copies of calibration status
    signal ctl_init_success_int           : std_logic;
    signal ctl_init_fail_int              : std_logic;

    -- refresh period failure flag
    signal trefi_failure                  : std_logic;

    -- unified ctrl signal broadcast to all blocks from the ctrl block
    signal ctrl_broadcast                 : t_ctrl_command;

    -- standardised status report per block to control block
    signal admin_ctrl                     : t_ctrl_stat;
    signal dgwb_ctrl                      : t_ctrl_stat;
    signal dgrb_ctrl                      : t_ctrl_stat;

    -- mmi and ctrl block interface
    signal mmi_ctrl                       : t_mmi_ctrl;
    signal ctrl_mmi                       : t_ctrl_mmi;

    -- write datapath override signals
    signal dgwb_wdp_override              : std_logic;
    signal dgrb_wdp_override              : std_logic;

    -- address/command access request and grant between the dgrb/dgwb blocks and the admin block
    signal dgb_ac_access_gnt              : std_logic;
    signal dgb_ac_access_gnt_r            : std_logic;
    signal dgb_ac_access_req              : std_logic;
    signal dgwb_ac_access_req             : std_logic;
    signal dgrb_ac_access_req             : std_logic;

    -- per block address/command record (multiplexed in this entity)
    signal admin_ac                       : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
    signal dgwb_ac                        : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
    signal dgrb_ac                        : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);

    -- doing read signal
    signal seq_rdv_doing_rd_int           : std_logic_vector(seq_rdv_doing_rd'range);

    -- local copy of interface to inc/dec latency on rdata_valid and postamble
    signal seq_rdata_valid_lat_dec_int    : std_logic;
    signal seq_rdata_valid_lat_inc_int    : std_logic;
    signal seq_poa_lat_inc_1x_int         : std_logic_vector(MEM_IF_DQS_WIDTH -1 downto 0);
    signal seq_poa_lat_dec_1x_int         : std_logic_vector(MEM_IF_DQS_WIDTH -1 downto 0);

    -- local copy of write/read latency
    signal seq_ctl_wlat_int               : std_logic_vector(seq_ctl_wlat'range);
    signal seq_ctl_rlat_int               : std_logic_vector(seq_ctl_rlat'range);

    -- parameterisation of dgrb / dgwb / admin blocks from mmi register settings
    signal parameterisation_rec           : t_algm_paramaterisation;

    -- PLL reconfig
    signal seq_pll_phs_shift_busy_r       : std_logic;
    signal seq_pll_phs_shift_busy_ccd     : std_logic;
    signal dgrb_pll_inc_dec_n             : std_logic;
    signal dgrb_pll_start_reconfig        : std_logic;
    signal dgrb_pll_select                : std_logic_vector(CLOCK_INDEX_WIDTH - 1 downto 0);
    signal dgrb_phs_shft_busy             : std_logic;
    signal mmi_pll_inc_dec_n              : std_logic;
    signal mmi_pll_start_reconfig         : std_logic;
    signal mmi_pll_select                 : std_logic_vector(CLOCK_INDEX_WIDTH - 1 downto 0);
    signal pll_mmi                        : t_pll_mmi;
    signal mmi_pll                        : t_mmi_pll_reconfig;


    -- address and command 1t setting (unused for Full Rate)
    signal int_ac_nt                      : std_logic_vector(((DWIDTH_RATIO+2)/4) - 1 downto 0);
    signal dgrb_ctrl_ac_nt_good           : std_logic;

    -- the following signals are reserved for future use
    signal ctl_cal_byte_lanes_r           : std_logic_vector(ctl_cal_byte_lanes'range);
    signal mmi_setup                      : t_ctrl_cmd_id;
    signal dgwb_iram                      : t_iram_push;

    -- track number of poa / rdv adjustments (reporting only)
    signal poa_adjustments                : natural;
    signal rdv_adjustments                : natural;

    -- convert input generics from natural to std_logic_vector
    constant c_phy_def_mr_1st_sl_vector   : std_logic_vector(15 downto 0)   := std_logic_vector(to_unsigned(PHY_DEF_MR_1ST, 16));
    constant c_phy_def_mr_2nd_sl_vector   : std_logic_vector(15 downto 0)   := std_logic_vector(to_unsigned(PHY_DEF_MR_2ND, 16));
    constant c_phy_def_mr_3rd_sl_vector   : std_logic_vector(15 downto 0)   := std_logic_vector(to_unsigned(PHY_DEF_MR_3RD, 16));
    constant c_phy_def_mr_4th_sl_vector   : std_logic_vector(15 downto 0)   := std_logic_vector(to_unsigned(PHY_DEF_MR_4TH, 16));

    -- overrride on capabilities to speed up simulation time
    function capabilities_override(capabilities        : natural;
                                   sim_time_reductions : natural) return natural is
    begin
        if sim_time_reductions = 1 then
            return 2**c_hl_css_reg_cal_dis_bit; -- disable calibration completely
        else
            return capabilities;
        end if;
    end function;

    -- set sequencer capabilities
    constant c_capabilities_override      : natural                         := capabilities_override(CAPABILITIES, SIM_TIME_REDUCTIONS);
    constant c_capabilities               : std_logic_vector(31 downto 0)   := std_logic_vector(to_unsigned(c_capabilities_override,32));

    -- setup for address/command interface
    constant c_seq_addr_cmd_config        : t_addr_cmd_config_rec           := set_config_rec(MEM_IF_ADDR_WIDTH, MEM_IF_BANKADDR_WIDTH, MEM_IF_NUM_RANKS, DWIDTH_RATIO, MEM_IF_MEMTYPE);

    -- setup for odt signals
    -- odt setting as implemented in the altera high-performance controller for ddrx memories
    constant c_odt_settings               : t_odt_array(0 to MEM_IF_NUM_RANKS-1) := set_odt_values(MEM_IF_NUM_RANKS, MEM_IF_RANKS_PER_SLOT, MEM_IF_MEMTYPE);

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant seq_report_prefix     : string  := "alt_mem_phy_seq (top) : ";
--#end

    -- setup iram configuration
    constant c_iram_addresses             : t_base_hdr_addresses            := calc_iram_addresses(DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, MEM_IF_DWIDTH, MEM_IF_NUM_RANKS, MEM_IF_DQS_CAPTURE_EN);
    constant c_int_iram_awidth            : natural                         := c_iram_addresses.required_addr_bits;

    -- #pb_del The values below are used for hidden SIM_TIME_REDUCTIONS = 1 mode and are working presets
    constant c_preset_cal_setup   : t_preset_cal := setup_instant_on(SIM_TIME_REDUCTIONS, FAMILYGROUP_ID, MEM_IF_MEMTYPE, DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, c_phy_def_mr_1st_sl_vector, c_phy_def_mr_2nd_sl_vector, c_phy_def_mr_3rd_sl_vector);
    constant c_preset_codvw_phase : natural := c_preset_cal_setup.codvw_phase;
    constant c_preset_codvw_size  : natural := c_preset_cal_setup.codvw_size;

    -- #pb_del the below may in the future be generics passed down from sequencer wrapper
    constant c_tracking_interval_in_ms : natural := 128;
    constant c_mem_if_cal_bank         : natural := 0;      -- location to calibrate to
    constant c_mem_if_cal_base_col     : natural := 0;      -- default all zeros
    constant c_mem_if_cal_base_row     : natural := 0;
    constant c_non_op_eval_md          : string  := "PIN_FINDER";  -- non_operational evaluation mode (used when GENERATE_ADDITIONAL_DBG_RTL = 1)

begin  -- architecture struct

-- ---------------------------------------------------------------
-- tie off unused signals to default values
-- ---------------------------------------------------------------

    -- scan chain associated signals
    seq_scan_clk               <= (others => '0');
    seq_scan_enable_dqs_config <= (others => '0');
    seq_scan_update            <= (others => '0');
    seq_scan_din               <= (others => '0');
    seq_scan_enable_ck         <= (others => '0');
    seq_scan_enable_dqs        <= (others => '0');
    seq_scan_enable_dqsn       <= (others => '0');
    seq_scan_enable_dq         <= (others => '0');
    seq_scan_enable_dm         <= (others => '0');

    -- #pb_del: TODO: Following signals need a source - btc
    seq_dqs_add_2t_delay       <= (others => '0');

    seq_rdp_inc_read_lat_1x    <= (others => '0');
    seq_rdp_dec_read_lat_1x    <= (others => '0');

    -- warning flag (not used in non-levelled sequencer)
    ctl_init_warning           <= '0';

    -- parity error flag (not used in non-levelled sequencer)
    parity_error_n             <= '1';

    --#mw_prefix ("alt_mem_phy_admin")
    admin: entity alt_mem_phy_admin
    --#end
    generic map
    (
        MEM_IF_DQS_WIDTH             => MEM_IF_DQS_WIDTH,
        MEM_IF_DWIDTH                => MEM_IF_DWIDTH,
        MEM_IF_DM_WIDTH              => MEM_IF_DM_WIDTH,
        MEM_IF_DQ_PER_DQS            => MEM_IF_DQ_PER_DQS,
        DWIDTH_RATIO                 => DWIDTH_RATIO,
        CLOCK_INDEX_WIDTH            => CLOCK_INDEX_WIDTH,
        MEM_IF_CLK_PAIR_COUNT        => MEM_IF_CLK_PAIR_COUNT,
        MEM_IF_ADDR_WIDTH            => MEM_IF_ADDR_WIDTH,
        MEM_IF_BANKADDR_WIDTH        => MEM_IF_BANKADDR_WIDTH,
        MEM_IF_NUM_RANKS             => MEM_IF_NUM_RANKS,
        ADV_LAT_WIDTH                => ADV_LAT_WIDTH,
        MEM_IF_DQSN_EN               => MEM_IF_DQSN_EN,
        MEM_IF_MEMTYPE               => MEM_IF_MEMTYPE,
        MEM_IF_CAL_BANK              => c_mem_if_cal_bank,
        MEM_IF_CAL_BASE_ROW          => c_mem_if_cal_base_row,
        GENERATE_ADDITIONAL_DBG_RTL  => GENERATE_ADDITIONAL_DBG_RTL,
        NON_OP_EVAL_MD               => c_non_op_eval_md,
        MEM_IF_CLK_PS                => MEM_IF_CLK_PS,
        TINIT_TCK                    => TINIT_TCK,
        TINIT_RST                    => TINIT_RST
    )
    port map
    (
        clk                          => clk,
        rst_n                        => rst_n,
        mem_ac_swapped_ranks         => mem_ac_swapped_ranks,
        ctl_cal_byte_lanes           => ctl_cal_byte_lanes_r,
        seq_ac                       => admin_ac,
        seq_ac_sel                   => seq_ac_sel,
        enable_odt                   => enable_odt,
        regs_admin_ctrl_rec          => regs_admin_ctrl_rec,
        admin_regs_status_rec        => admin_regs_status_rec,
        trefi_failure                => trefi_failure,
        ctrl_admin                   => ctrl_broadcast,
        admin_ctrl                   => admin_ctrl,
        ac_access_req                => dgb_ac_access_req,
        ac_access_gnt                => dgb_ac_access_gnt,
        cal_fail                     => ctl_init_fail_int,
        cal_success                  => ctl_init_success_int,
        ctl_recalibrate_req          => ctl_recalibrate_req
    );

    -- selectively include the debug i/f (iram and mmi blocks)
    with_debug_if : if GENERATE_ADDITIONAL_DBG_RTL = 1 generate

    signal mmi_iram                       : t_iram_ctrl;
    signal mmi_iram_enable_writes         : std_logic;
    signal rrp_mem_loc                    : natural range 0 to 2 ** c_int_iram_awidth - 1;
    signal command_req_r                  : std_logic;

    signal ctrl_broadcast_r               : t_ctrl_command;

    begin

        -- register ctrl_broadcast locally
         -- #pb_del to reduce fan out and for speed
         process (clk, rst_n)
         begin
            if rst_n = '0' then
                ctrl_broadcast_r <= defaults;
            elsif rising_edge(clk) then
                ctrl_broadcast_r <= ctrl_broadcast;
            end if;
         end process;

        --#mw_prefix ("alt_mem_phy_mmi")
        mmi : entity alt_mem_phy_mmi
        --#end
        generic map (
            MEM_IF_DQS_WIDTH           => MEM_IF_DQS_WIDTH,
            MEM_IF_DWIDTH              => MEM_IF_DWIDTH,
            MEM_IF_DM_WIDTH            => MEM_IF_DM_WIDTH,
            MEM_IF_DQ_PER_DQS          => MEM_IF_DQ_PER_DQS,
            DWIDTH_RATIO               => DWIDTH_RATIO,
            CLOCK_INDEX_WIDTH          => CLOCK_INDEX_WIDTH,
            MEM_IF_CLK_PAIR_COUNT      => MEM_IF_CLK_PAIR_COUNT,
            MEM_IF_ADDR_WIDTH          => MEM_IF_ADDR_WIDTH,
            MEM_IF_BANKADDR_WIDTH      => MEM_IF_BANKADDR_WIDTH,
            MEM_IF_NUM_RANKS           => MEM_IF_NUM_RANKS,
            MEM_IF_DQS_CAPTURE         => MEM_IF_DQS_CAPTURE_EN,
            ADV_LAT_WIDTH              => ADV_LAT_WIDTH,
            RESYNCHRONISE_AVALON_DBG   => RESYNCHRONISE_AVALON_DBG,
            AV_IF_ADDR_WIDTH           => AV_IF_ADDR_WIDTH,
            NOM_DQS_PHASE_SETTING      => NOM_DQS_PHASE_SETTING,
            SCAN_CLK_DIVIDE_BY         => SCAN_CLK_DIVIDE_BY,
            RDP_ADDR_WIDTH             => RDP_ADDR_WIDTH,
            PLL_STEPS_PER_CYCLE        => PLL_STEPS_PER_CYCLE,
            IOE_PHASES_PER_TCK         => IOE_PHASES_PER_TCK,
            IOE_DELAYS_PER_PHS         => IOE_DELAYS_PER_PHS,
            MEM_IF_CLK_PS              => MEM_IF_CLK_PS,
            PHY_DEF_MR_1ST             => c_phy_def_mr_1st_sl_vector,
            PHY_DEF_MR_2ND             => c_phy_def_mr_2nd_sl_vector,
            PHY_DEF_MR_3RD             => c_phy_def_mr_3rd_sl_vector,
            PHY_DEF_MR_4TH             => c_phy_def_mr_4th_sl_vector,
            MEM_IF_MEMTYPE             => MEM_IF_MEMTYPE,
            PRESET_RLAT                => PRESET_RLAT,
            CAPABILITIES               => c_capabilities_override,
            USE_IRAM                   => '1',  -- always use iram (generic is rfu)
            IRAM_AWIDTH                => c_int_iram_awidth,
            TRACKING_INTERVAL_IN_MS    => c_tracking_interval_in_ms,
            READ_LAT_WIDTH             => ADV_LAT_WIDTH
        )
        port map(
            clk                        => clk,
            rst_n                      => rst_n,
            dbg_seq_clk                => dbg_seq_clk,
            dbg_seq_rst_n              => dbg_seq_rst_n,
            dbg_seq_addr               => dbg_seq_addr,
            dbg_seq_wr                 => dbg_seq_wr,
            dbg_seq_rd                 => dbg_seq_rd,
            dbg_seq_cs                 => dbg_seq_cs,
            dbg_seq_wr_data            => dbg_seq_wr_data,
            seq_dbg_rd_data            => seq_dbg_rd_data,
            seq_dbg_waitrequest        => seq_dbg_waitrequest,
            regs_admin_ctrl            => regs_admin_ctrl_rec,
            admin_regs_status          => admin_regs_status_rec,
            mmi_iram                   => mmi_iram,
            mmi_iram_enable_writes     => mmi_iram_enable_writes,
            iram_status                => iram_status,
            mmi_ctrl                   => mmi_ctrl,
            ctrl_mmi                   => ctrl_mmi,
            int_ac_1t                  => int_ac_nt(0),
            invert_ac_1t               => open,
            trefi_failure              => trefi_failure,
            parameterisation_rec       => parameterisation_rec,
            pll_mmi                    => pll_mmi,
            mmi_pll                    => mmi_pll,
            dgrb_mmi                   => dgrb_mmi
        );


    --#mw_prefix ("alt_mem_phy_iram")
     iram : entity alt_mem_phy_iram
     --#end
         generic map(
             MEM_IF_MEMTYPE          => MEM_IF_MEMTYPE,
             FAMILYGROUP_ID          => FAMILYGROUP_ID,
             MEM_IF_DQS_WIDTH        => MEM_IF_DQS_WIDTH,
             MEM_IF_DQ_PER_DQS       => MEM_IF_DQ_PER_DQS,
             MEM_IF_DWIDTH           => MEM_IF_DWIDTH,
             MEM_IF_DM_WIDTH         => MEM_IF_DM_WIDTH,
             MEM_IF_NUM_RANKS        => MEM_IF_NUM_RANKS,
             IRAM_AWIDTH             => c_int_iram_awidth,
             REFRESH_COUNT_INIT      => 12,
             PRESET_RLAT             => PRESET_RLAT,
             PLL_STEPS_PER_CYCLE     => PLL_STEPS_PER_CYCLE,
             CAPABILITIES            => c_capabilities_override,
             IP_BUILDNUM             => IP_BUILDNUM
        )
         port map(
             clk                     => clk,
             rst_n                   => rst_n,
             mmi_iram                => mmi_iram,
             mmi_iram_enable_writes  => mmi_iram_enable_writes,
             iram_status             => iram_status,
             iram_push_done          => iram_push_done,
             ctrl_iram               => ctrl_broadcast_r,
             dgrb_iram               => dgrb_iram,
             admin_regs_status_rec   => admin_regs_status_rec,
             ctrl_idib_top           => ctrl_idib_top,
             ctrl_iram_push          => ctrl_iram_push,
             dgwb_iram               => dgwb_iram
         );

         -- calculate where current data should go in the iram
         process (clk, rst_n)

             variable v_words_req     : natural range 0 to 2 * MEM_IF_DWIDTH * PLL_STEPS_PER_CYCLE * DWIDTH_RATIO - 1;  -- how many words are required

         begin
             if rst_n = '0' then

                 ctrl_idib_top <= 0;
                 command_req_r <= '0';
                 rrp_mem_loc   <= 0;

             elsif rising_edge(clk) then

                 if command_req_r = '0' and ctrl_broadcast_r.command_req = '1' then  -- execute once on each command_req assertion

                     -- default a 'safe location'
                     ctrl_idib_top <= c_iram_addresses.safe_dummy;

                     case ctrl_broadcast_r.command is

                         when cmd_write_ihi =>  -- reset pointers

                             rrp_mem_loc <= c_iram_addresses.rrp;
                             ctrl_idib_top <= 0; -- write header to zero location always

                         when cmd_rrp_sweep =>

                             -- add previous space requirement onto the current address
                             ctrl_idib_top <= rrp_mem_loc;

                             -- add the current space requirement to v_rrp_mem_loc
                             -- there are (DWIDTH_RATIO/2) * PLL_STEPS_PER_CYCLE phases swept packed into 32 bit words per pin
                             -- note: special case for single_bit calibration stages (e.g. read_mtp alignment)

                             if ctrl_broadcast_r.command_op.single_bit = '1' then
                                 v_words_req := iram_wd_for_one_pin_rrp(DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, MEM_IF_DWIDTH, MEM_IF_DQS_CAPTURE_EN);
                             else
                                 v_words_req := iram_wd_for_full_rrp(DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, MEM_IF_DWIDTH, MEM_IF_DQS_CAPTURE_EN);
                             end if;

                             v_words_req := v_words_req + 2; -- add 1 word location for header / footer information

                             rrp_mem_loc <= rrp_mem_loc + v_words_req;

                         when cmd_rrp_seek |
                              cmd_read_mtp =>

                            -- add previous space requirement onto the current address
                             ctrl_idib_top <= rrp_mem_loc;

                             -- require 3 words - header, result and footer
                             v_words_req := 3;

                             rrp_mem_loc <= rrp_mem_loc + v_words_req;

                         when others =>
                             null;

                     end case;

                 end if;

                 command_req_r <= ctrl_broadcast_r.command_req;

                 -- if recalibration request then reset iram address
                 if ctl_recalibrate_req = '1' or mmi_ctrl.calibration_start = '1' then

                    rrp_mem_loc <= c_iram_addresses.rrp;

                 end if;

             end if;

         end process;

    end generate;  -- with debug interface

    -- if no debug interface (iram/mmi block) tie off relevant signals
    without_debug_if : if GENERATE_ADDITIONAL_DBG_RTL = 0 generate

    constant c_slv_hl_stage_enable   : std_logic_vector(31 downto 0)                    := std_logic_vector(to_unsigned(c_capabilities_override, 32));
    constant c_hl_stage_enable       : std_logic_vector(c_hl_ccs_num_stages-1 downto 0) := c_slv_hl_stage_enable(c_hl_ccs_num_stages-1 downto 0);
    constant c_pll_360_sweeps        : natural                       := rrp_pll_phase_mult(DWIDTH_RATIO, MEM_IF_DQS_CAPTURE_EN);

    signal mmi_regs                  : t_mmi_regs := defaults;

    begin

        -- avalon interface signals
        seq_dbg_rd_data     <= (others => '0');
        seq_dbg_waitrequest <= '0';

        -- The following registers are generated to simplify the assignments which follow
        -- but will be optimised away in synthesis
        mmi_regs.rw_regs    <= defaults(c_phy_def_mr_1st_sl_vector,
                                        c_phy_def_mr_2nd_sl_vector,
                                        c_phy_def_mr_3rd_sl_vector,
                                        c_phy_def_mr_4th_sl_vector,
                                        NOM_DQS_PHASE_SETTING,
                                        PLL_STEPS_PER_CYCLE,
                                        c_pll_360_sweeps,
                                        c_tracking_interval_in_ms,
                                        c_hl_stage_enable);

        mmi_regs.ro_regs    <= defaults(dgrb_mmi,
                                        ctrl_mmi,
                                        pll_mmi,
                                        mmi_regs.rw_regs.rw_if_test,
                                        '0',  -- do not use iram
                                        MEM_IF_DQS_CAPTURE_EN,
                                        int_ac_nt(0),
                                        trefi_failure,
                                        iram_status,
                                        c_int_iram_awidth);

        process(mmi_regs)
        begin
            --  debug parameterisation signals
            regs_admin_ctrl_rec          <= pack_record(mmi_regs.rw_regs);
            parameterisation_rec         <= pack_record(mmi_regs.rw_regs);
            mmi_pll                      <= pack_record(mmi_regs.rw_regs);
            mmi_ctrl                     <= pack_record(mmi_regs.rw_regs);
        end process;

        -- from the iram
        iram_status                      <= defaults;
        iram_push_done                   <= '0';

    end generate; -- without debug interface

    --#mw_prefix ("alt_mem_phy_dgrb")
    dgrb : entity alt_mem_phy_dgrb
    --#end
    generic map(
        MEM_IF_DQS_WIDTH                 => MEM_IF_DQS_WIDTH,
        MEM_IF_DQ_PER_DQS			     => MEM_IF_DQ_PER_DQS,
        MEM_IF_DWIDTH                    => MEM_IF_DWIDTH,
        MEM_IF_DM_WIDTH                  => MEM_IF_DM_WIDTH,
        MEM_IF_DQS_CAPTURE               => MEM_IF_DQS_CAPTURE_EN,
        DWIDTH_RATIO                     => DWIDTH_RATIO,
        CLOCK_INDEX_WIDTH                => CLOCK_INDEX_WIDTH,
        MEM_IF_ADDR_WIDTH                => MEM_IF_ADDR_WIDTH,
        MEM_IF_BANKADDR_WIDTH            => MEM_IF_BANKADDR_WIDTH,
        MEM_IF_NUM_RANKS                 => MEM_IF_NUM_RANKS,
        MEM_IF_MEMTYPE                   => MEM_IF_MEMTYPE,
        ADV_LAT_WIDTH                    => ADV_LAT_WIDTH,
        PRESET_RLAT                      => PRESET_RLAT,
        PLL_STEPS_PER_CYCLE              => PLL_STEPS_PER_CYCLE,
        SIM_TIME_REDUCTIONS              => SIM_TIME_REDUCTIONS,
        GENERATE_ADDITIONAL_DBG_RTL      => GENERATE_ADDITIONAL_DBG_RTL,
        PRESET_CODVW_PHASE               => c_preset_codvw_phase,
        PRESET_CODVW_SIZE                => c_preset_codvw_size,
        MEM_IF_CAL_BANK                  => c_mem_if_cal_bank,
        MEM_IF_CAL_BASE_COL              => c_mem_if_cal_base_col,
        EN_OCT                           => EN_OCT
   )
    port map(
        clk                              => clk,
        rst_n                            => rst_n,
        dgrb_ctrl                        => dgrb_ctrl,
        ctrl_dgrb                        => ctrl_broadcast,
        parameterisation_rec             => parameterisation_rec,
        phs_shft_busy                    => dgrb_phs_shft_busy,
        seq_pll_inc_dec_n                => dgrb_pll_inc_dec_n,
        seq_pll_select                   => dgrb_pll_select,
        seq_pll_start_reconfig           => dgrb_pll_start_reconfig,
        pll_resync_clk_index             => pll_resync_clk_index,
        pll_measure_clk_index            => pll_measure_clk_index,
        dgrb_iram                        => dgrb_iram,
        iram_push_done                   => iram_push_done,
        dgrb_ac                          => dgrb_ac,
        dgrb_ac_access_req               => dgrb_ac_access_req,
        dgrb_ac_access_gnt               => dgb_ac_access_gnt_r,
        seq_rdata_valid_lat_inc          => seq_rdata_valid_lat_inc_int,
        seq_rdata_valid_lat_dec          => seq_rdata_valid_lat_dec_int,
        seq_poa_lat_dec_1x               => seq_poa_lat_dec_1x_int,
        seq_poa_lat_inc_1x               => seq_poa_lat_inc_1x_int,
        rdata_valid                      => rdata_valid,
        rdata                            => rdata,
        doing_rd                         => seq_rdv_doing_rd_int,
        rd_lat                           => seq_ctl_rlat_int,
        wd_lat                           => seq_ctl_wlat_int,
        dgrb_wdp_ovride                  => dgrb_wdp_override,
        seq_oct_value                    => seq_oct_value,
        seq_mmc_start                    => seq_mmc_start,
        mmc_seq_done                     => mmc_seq_done,
        mmc_seq_value                    => mmc_seq_value,
        ctl_cal_byte_lanes               => ctl_cal_byte_lanes_r,
        odt_settings                     => c_odt_settings,
        dgrb_ctrl_ac_nt_good             => dgrb_ctrl_ac_nt_good,
        dgrb_mmi                         => dgrb_mmi
    );

    --#mw_prefix ("alt_mem_phy_dgwb")
    dgwb : entity alt_mem_phy_dgwb
    --#end
    generic map(
        -- Physical IF width definitions
        MEM_IF_DQS_WIDTH             => MEM_IF_DQS_WIDTH,
        MEM_IF_DQ_PER_DQS			 => MEM_IF_DQ_PER_DQS,
        MEM_IF_DWIDTH                => MEM_IF_DWIDTH,
        MEM_IF_DM_WIDTH              => MEM_IF_DM_WIDTH,
        DWIDTH_RATIO                 => DWIDTH_RATIO,
        MEM_IF_ADDR_WIDTH            => MEM_IF_ADDR_WIDTH,
        MEM_IF_BANKADDR_WIDTH        => MEM_IF_BANKADDR_WIDTH,
        MEM_IF_NUM_RANKS             => MEM_IF_NUM_RANKS,
        MEM_IF_MEMTYPE               => MEM_IF_MEMTYPE,
        ADV_LAT_WIDTH                => ADV_LAT_WIDTH,
        MEM_IF_CAL_BANK              => c_mem_if_cal_bank,
        MEM_IF_CAL_BASE_COL          => c_mem_if_cal_base_col
   )
    port map(
        clk                          => clk,
        rst_n                        => rst_n,
        parameterisation_rec         => parameterisation_rec,
        dgwb_ctrl                    => dgwb_ctrl,
        ctrl_dgwb                    => ctrl_broadcast,
        dgwb_iram                    => dgwb_iram,
        iram_push_done               => iram_push_done,
        dgwb_ac_access_req           => dgwb_ac_access_req,
        dgwb_ac_access_gnt           => dgb_ac_access_gnt_r,
        dgwb_dqs_burst               => seq_wdp_dqs_burst,
        dgwb_wdata_valid             => seq_wdp_wdata_valid,
        dgwb_wdata                   => seq_wdp_wdata,
        dgwb_dm                      => seq_wdp_dm,
        dgwb_dqs                     => seq_wdp_dqs,
        dgwb_wdp_ovride              => dgwb_wdp_override,
        dgwb_ac                      => dgwb_ac,
        bypassed_rdata               => rdata(DWIDTH_RATIO * MEM_IF_DWIDTH -1 downto (DWIDTH_RATIO-1) * MEM_IF_DWIDTH),
        odt_settings                 => c_odt_settings
    );

    --#mw_prefix ("alt_mem_phy_ctrl")
    ctrl: entity alt_mem_phy_ctrl
    --#end
    generic map(
        FAMILYGROUP_ID               => FAMILYGROUP_ID,
        MEM_IF_DLL_LOCK_COUNT        => 1280/(DWIDTH_RATIO/2),
        MEM_IF_MEMTYPE               => MEM_IF_MEMTYPE,
        DWIDTH_RATIO                 => DWIDTH_RATIO,
        IRAM_ADDRESSING              => c_iram_addresses,
        MEM_IF_CLK_PS                => MEM_IF_CLK_PS,
        TRACKING_INTERVAL_IN_MS      => c_tracking_interval_in_ms,
        GENERATE_ADDITIONAL_DBG_RTL  => GENERATE_ADDITIONAL_DBG_RTL,
        MEM_IF_NUM_RANKS             => MEM_IF_NUM_RANKS,
        MEM_IF_DQS_WIDTH             => MEM_IF_DQS_WIDTH,
        SIM_TIME_REDUCTIONS          => SIM_TIME_REDUCTIONS,
        ACK_SEVERITY                 => warning
    )
    port map(
        clk                          => clk,
        rst_n                        => rst_n,
        ctl_init_success             => ctl_init_success_int,
        ctl_init_fail                => ctl_init_fail_int,
        ctl_recalibrate_req          => ctl_recalibrate_req,
        iram_status                  => iram_status,
        iram_push_done               => iram_push_done,
        ctrl_op_rec                  => ctrl_broadcast,
        admin_ctrl                   => admin_ctrl,
        dgrb_ctrl                    => dgrb_ctrl,
        dgwb_ctrl                    => dgwb_ctrl,
        ctrl_iram_push               => ctrl_iram_push,
        ctl_cal_byte_lanes           => ctl_cal_byte_lanes_r,
        dgrb_ctrl_ac_nt_good         => dgrb_ctrl_ac_nt_good,
        int_ac_nt                    => int_ac_nt,
        mmi_ctrl                     => mmi_ctrl,
        ctrl_mmi                     => ctrl_mmi
    );


-- ------------------------------------------------------------------
-- generate legacy rsu signals
-- ------------------------------------------------------------------
    process(rst_n, clk)
    begin
        if rst_n = '0' then
            rsu_multiple_valid_latencies_err <= '0';
            rsu_grt_one_dvw_err              <= '0';
            rsu_no_dvw_err                   <= '0';
            rsu_codvw_phase                  <= (others => '0');
            rsu_codvw_size                   <= (others => '0');
            rsu_read_latency                 <= (others => '0');
        elsif rising_edge(clk) then

            if dgrb_ctrl.command_err = '1' then
                case to_integer(unsigned(dgrb_ctrl.command_result)) is
                    when C_ERR_RESYNC_NO_VALID_PHASES =>
                        rsu_no_dvw_err      <= '1';
                    when C_ERR_RESYNC_MULTIPLE_EQUAL_WINDOWS =>
                        rsu_multiple_valid_latencies_err <= '1';
                    when others => null;
                end case;
            end if;

            rsu_codvw_phase(dgrb_mmi.cal_codvw_phase'range)  <= dgrb_mmi.cal_codvw_phase;
            rsu_codvw_size(dgrb_mmi.cal_codvw_size'range)    <= dgrb_mmi.cal_codvw_size;
            rsu_read_latency                                 <= seq_ctl_rlat_int;
	    rsu_grt_one_dvw_err                              <= dgrb_mmi.codvw_grt_one_dvw;

	    -- Reset the flag on a recal request :
	    if ( ctl_recalibrate_req = '1') then
	        rsu_grt_one_dvw_err <= '0';
                rsu_no_dvw_err      <= '0';
                rsu_multiple_valid_latencies_err <= '0';
	    end if;

        end if;
    end process;

-- ---------------------------------------------------------------
-- top level multiplexing and ctrl functionality
-- ---------------------------------------------------------------

    oct_delay_block : block
        constant DEFAULT_OCT_DELAY_CONST : integer := - 2; -- higher increases delay by one mem_clk cycle, lower decreases delay by one mem_clk cycle.
        constant DEFAULT_OCT_EXTEND      : natural := 3;

        -- Returns additive latency extracted from mr0 as a natural number.
        function decode_cl(mr0 : in std_logic_vector(12 downto 0))
                return natural is
            variable v_cl : natural range 0 to 2**4 - 1;
        begin
            if MEM_IF_MEMTYPE = "DDR" or MEM_IF_MEMTYPE = "DDR2" then
                v_cl := to_integer(unsigned(mr0(6 downto 4)));
            elsif MEM_IF_MEMTYPE = "DDR3" then
                v_cl := to_integer(unsigned(mr0(6 downto 4))) + 4;
            else
                report "Unsupported memory type " & MEM_IF_MEMTYPE severity failure;
            end if;

            return v_cl;
        end function;


        -- Returns additive latency extracted from mr1 as a natural number.
        function decode_al(mr1 : in std_logic_vector(12 downto 0))
                return natural is
            variable v_al : natural range 0 to 2**4 - 1;
        begin
            if MEM_IF_MEMTYPE = "DDR" or MEM_IF_MEMTYPE = "DDR2" then
                v_al := to_integer(unsigned(mr1(5 downto 3)));
            elsif MEM_IF_MEMTYPE = "DDR3" then
                v_al := to_integer(unsigned(mr1(4 downto 3)));
            else
                report "Unsupported memory type " & MEM_IF_MEMTYPE severity failure;
            end if;

            return v_al;
        end function;


        -- Returns cas write latency extracted from mr2 as a natural number.
        function decode_cwl(
                mr0 : in std_logic_vector(12 downto 0);
                mr2 : in std_logic_vector(12 downto 0)
            )
                return natural is
            variable v_cwl : natural range 0 to 2**4 - 1;
        begin
            if MEM_IF_MEMTYPE = "DDR" then
                v_cwl := 1;
            elsif MEM_IF_MEMTYPE = "DDR2" then
                v_cwl := decode_cl(mr0) - 1;
            elsif MEM_IF_MEMTYPE = "DDR3" then
                v_cwl := to_integer(unsigned(mr2(4 downto 3))) + 5;
            else
                report "Unsupported memory type " & MEM_IF_MEMTYPE severity failure;
            end if;

            return v_cwl;
        end function;

    begin
        -- Process to work out timings for OCT extension and delay with respect to doing_read. NOTE that it is calculated on the basis of CL, CWL, ctl_wlat
        oct_delay_proc : process(clk, rst_n)
            variable v_cl : natural range 0 to 2**4 - 1; -- Total read latency.
            variable v_cwl : natural range 0 to 2**4 - 1; -- Total write latency
            variable oct_delay : natural range 0 to 2**OCT_LAT_WIDTH - 1;

            variable v_wlat : natural range 0 to 2**ADV_LAT_WIDTH - 1;

        begin
            if rst_n = '0' then
                seq_oct_oct_delay <= (others => '0');
                seq_oct_oct_extend <= std_logic_vector(to_unsigned(DEFAULT_OCT_EXTEND, OCT_LAT_WIDTH));
            elsif rising_edge(clk) then
                if ctl_init_success_int = '1' then
                    seq_oct_oct_extend <= std_logic_vector(to_unsigned(DEFAULT_OCT_EXTEND, OCT_LAT_WIDTH));

                    v_cl := decode_cl(admin_regs_status_rec.mr0);
                    v_cwl := decode_cwl(admin_regs_status_rec.mr0, admin_regs_status_rec.mr2);

                    if SIM_TIME_REDUCTIONS = 1 then
                        v_wlat := c_preset_cal_setup.wlat;
                    else
                        v_wlat := to_integer(unsigned(seq_ctl_wlat_int));
                    end if;

                    oct_delay := DWIDTH_RATIO * v_wlat / 2 +  (v_cl - v_cwl) + DEFAULT_OCT_DELAY_CONST;

                    if not (FAMILYGROUP_ID = 2) then  -- CIII doesn't support OCT
                        seq_oct_oct_delay <= std_logic_vector(to_unsigned(oct_delay, OCT_LAT_WIDTH));
                    end if;
                else
                    seq_oct_oct_delay <= (others => '0');
                    seq_oct_oct_extend <= std_logic_vector(to_unsigned(DEFAULT_OCT_EXTEND, OCT_LAT_WIDTH));
                end if;
            end if;
        end process;
    end block;


    -- control postamble protection override signal (seq_poa_protection_override_1x)
    process(clk, rst_n)
        variable v_warning_given : std_logic;
    begin
        if rst_n = '0' then
            seq_poa_protection_override_1x <= '0';

            v_warning_given := '0';
        elsif rising_edge(clk) then

            case ctrl_broadcast.command is
                when cmd_rdv             |
                     cmd_rrp_sweep       |
                     cmd_rrp_seek        |
                     cmd_prep_adv_rd_lat |
                     cmd_prep_adv_wr_lat => seq_poa_protection_override_1x <= '1';
                when others              => seq_poa_protection_override_1x <= '0';
            end case;

        end if;
    end process;

    ac_mux : block

        -- #pb_del pipeline the memory clock disable signal to synchronise disable and mem_cke when ctl_cal_req asserted
        constant c_mem_clk_disable_pipe_len : natural := 3;


        signal seen_phy_init_complete  : std_logic;
        signal mem_clk_disable         : std_logic_vector(c_mem_clk_disable_pipe_len - 1 downto 0);

        signal ctrl_broadcast_r        : t_ctrl_command;

    begin

        -- register ctrl_broadcast locally
        -- #for speed and to reduce fan out
        process (clk, rst_n)
         begin
            if rst_n = '0' then
                ctrl_broadcast_r <= defaults;
            elsif rising_edge(clk) then
                ctrl_broadcast_r <= ctrl_broadcast;
            end if;
         end process;

        -- multiplex mem interface control between admin, dgrb and dgwb
        process(clk, rst_n)
            variable v_seq_ac_mux : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
        begin
            if rst_n = '0' then

                seq_rdv_doing_rd    <= (others => '0');

                seq_mem_clk_disable     <= '1';
                mem_clk_disable         <= (others => '1');
                seen_phy_init_complete  <= '0';

                seq_ac_addr      <= (others => '0');
                seq_ac_ba        <= (others => '0');
                seq_ac_cas_n     <= (others => '1');
                seq_ac_ras_n     <= (others => '1');
                seq_ac_we_n      <= (others => '1');
                seq_ac_cke       <= (others => '0');
                seq_ac_cs_n      <= (others => '1');
                seq_ac_odt       <= (others => '0');
                seq_ac_rst_n     <= (others => '0');

            elsif rising_edge(clk) then

                seq_rdv_doing_rd                                       <= seq_rdv_doing_rd_int;
                seq_mem_clk_disable                                    <= mem_clk_disable(c_mem_clk_disable_pipe_len-1);
                mem_clk_disable(c_mem_clk_disable_pipe_len-1 downto 1) <= mem_clk_disable(c_mem_clk_disable_pipe_len-2 downto 0);

                if dgwb_ac_access_req = '1' and dgb_ac_access_gnt = '1' then
                   v_seq_ac_mux := dgwb_ac;
                elsif dgrb_ac_access_req = '1' and dgb_ac_access_gnt = '1' then
                   v_seq_ac_mux := dgrb_ac;
                else
                   v_seq_ac_mux := admin_ac;
                end if;

                if ctl_recalibrate_req = '1' then
                    mem_clk_disable(0)     <= '1';
                    seen_phy_init_complete <= '0';
                elsif ctrl_broadcast_r.command = cmd_init_dram and ctrl_broadcast_r.command_req = '1' then
                    mem_clk_disable(0)     <= '0';
                    seen_phy_init_complete <= '1';
                end if;

                if seen_phy_init_complete /= '1' then -- if not initialised the phy hold in reset

                    seq_ac_addr      <= (others => '0');
                    seq_ac_ba        <= (others => '0');
                    seq_ac_cas_n     <= (others => '1');
                    seq_ac_ras_n     <= (others => '1');
                    seq_ac_we_n      <= (others => '1');
                    seq_ac_cke       <= (others => '0');
                    seq_ac_cs_n      <= (others => '1');
                    seq_ac_odt       <= (others => '0');
                    seq_ac_rst_n     <= (others => '0');

                else

                    -- #pb_del note parameterisation_rec.odt_enabled should be included below for GUI interface - btc
                    if enable_odt = '0' then
                        v_seq_ac_mux := mask(c_seq_addr_cmd_config, v_seq_ac_mux, odt, '0');
                    end if;

                    unpack_addr_cmd_vector (
                        c_seq_addr_cmd_config,
                        v_seq_ac_mux,
                        seq_ac_addr,
                        seq_ac_ba,
                        seq_ac_cas_n,
                        seq_ac_ras_n,
                        seq_ac_we_n,
                        seq_ac_cke,
                        seq_ac_cs_n,
                        seq_ac_odt,
                        seq_ac_rst_n);

                end if;

            end if;
        end process;

    end block;

    -- register dgb_ac_access_gnt signal to ensure ODT set correctly in dgrb and dgwb prior to a read or write operation
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            dgb_ac_access_gnt_r <= '0';
        elsif rising_edge(clk) then
            dgb_ac_access_gnt_r <= dgb_ac_access_gnt;
        end if;
    end process;

    -- multiplex access request from dgrb/dgwb to admin block with checking for multiple accesses
    process (dgrb_ac_access_req, dgwb_ac_access_req)
    begin
        dgb_ac_access_req <= '0';
        if dgwb_ac_access_req = '1' and dgrb_ac_access_req = '1' then
            report seq_report_prefix & "multiple accesses attempted from DGRB and DGWB to admin block via signals dg.b_ac_access_reg " severity failure;
        elsif dgwb_ac_access_req = '1' or dgrb_ac_access_req = '1' then
            dgb_ac_access_req <= '1';
        end if;
    end process;


    rdv_poa_blk : block

        -- signals to control static setup of ctl_rdata_valid signal for instant on mode:
        constant c_static_rdv_offset : integer := c_preset_cal_setup.rdv_lat;                     -- required change in RDV latency (should always be > 0)
        signal static_rdv_offset     : natural range 0 to abs(c_static_rdv_offset);               -- signal to count # RDV shifts
        constant c_dly_rdv_set       : natural := 7;                                              -- delay between RDV shifts
        signal dly_rdv_inc_dec       : std_logic;                                                 -- 1 = inc, 0 = dec
        signal rdv_set_delay         : natural range 0 to c_dly_rdv_set;                          -- signal to delay RDV shifts

        -- same for poa protection
        constant c_static_poa_offset : integer := c_preset_cal_setup.poa_lat;
        signal static_poa_offset     : natural range 0 to abs(c_static_poa_offset);
        constant c_dly_poa_set       : natural := 7;
        signal dly_poa_inc_dec       : std_logic;
        signal poa_set_delay         : natural range 0 to c_dly_poa_set;

        -- function to abstract increment or decrement checking
        function set_inc_dec(offset : integer) return std_logic is
        begin
            if offset < 0 then
                return '1';
            else
                return '0';
            end if;
        end function;

    begin

        -- register postamble and rdata_valid latencies
        -- note: postamble unused for Cyclone-III

        -- RDV
        process(clk, rst_n)
        begin
            if rst_n = '0' then

                if SIM_TIME_REDUCTIONS = 1 then

                    -- setup offset calc
                    static_rdv_offset <= abs(c_static_rdv_offset);
                    dly_rdv_inc_dec   <= set_inc_dec(c_static_rdv_offset);
                    rdv_set_delay     <= c_dly_rdv_set;

                end if;

                seq_rdata_valid_lat_dec <= '0';
                seq_rdata_valid_lat_inc <= '0';

            elsif rising_edge(clk) then

                if SIM_TIME_REDUCTIONS = 1 then  -- perform static setup of RDV signal

                    if ctl_recalibrate_req = '1' then -- second reset condition

                        -- setup offset calc
                        static_rdv_offset <= abs(c_static_rdv_offset);
                        dly_rdv_inc_dec   <= set_inc_dec(c_static_rdv_offset);
                        rdv_set_delay     <= c_dly_rdv_set;

                    else

                        if static_rdv_offset /= 0 and
                           rdv_set_delay = 0 then

                            seq_rdata_valid_lat_dec <= not dly_rdv_inc_dec;
                            seq_rdata_valid_lat_inc <= dly_rdv_inc_dec;

                            static_rdv_offset       <= static_rdv_offset - 1;
                            rdv_set_delay           <= c_dly_rdv_set;

                        else  -- once conplete pass through internal signals

                            seq_rdata_valid_lat_dec <= seq_rdata_valid_lat_dec_int;
                            seq_rdata_valid_lat_inc <= seq_rdata_valid_lat_inc_int;

                        end if;

                        if rdv_set_delay /= 0 then
                            rdv_set_delay <= rdv_set_delay - 1;
                        end if;

                    end if;

                else  -- no static setup

                    seq_rdata_valid_lat_dec <= seq_rdata_valid_lat_dec_int;
                    seq_rdata_valid_lat_inc <= seq_rdata_valid_lat_inc_int;

                end if;

            end if;

        end process;

        -- count number of RDV adjustments for debug
        process(clk, rst_n)
        begin

            if rst_n = '0' then
                rdv_adjustments <= 0;
            elsif rising_edge(clk) then
                if seq_rdata_valid_lat_dec_int = '1' then
                    rdv_adjustments <= rdv_adjustments + 1;
                end if;
                if seq_rdata_valid_lat_inc_int = '1' then
                    if rdv_adjustments = 0 then
                        report seq_report_prefix & " read data valid adjustment wrap around detected - more increments than decrements" severity failure;
                    else
                        rdv_adjustments <= rdv_adjustments - 1;
                    end if;
                end if;

            end if;

        end process;

        -- POA protection
        process(clk, rst_n)
        begin
            if rst_n = '0' then

                if SIM_TIME_REDUCTIONS = 1 then

                    -- setup offset calc
                    static_poa_offset <= abs(c_static_poa_offset);
                    dly_poa_inc_dec   <= set_inc_dec(c_static_poa_offset);
                    poa_set_delay     <= c_dly_poa_set;

                end if;

                seq_poa_lat_dec_1x      <= (others => '0');
                seq_poa_lat_inc_1x      <= (others => '0');

            elsif rising_edge(clk) then

                if SIM_TIME_REDUCTIONS = 1 then  -- static setup

                    if ctl_recalibrate_req = '1' then  -- second reset condition

                        -- setup offset calc
                        static_poa_offset <= abs(c_static_poa_offset);
                        dly_poa_inc_dec   <= set_inc_dec(c_static_poa_offset);
                        poa_set_delay     <= c_dly_poa_set;

                    else

                        if static_poa_offset /= 0 and
                           poa_set_delay = 0 then

                            seq_poa_lat_dec_1x <= (others => not(dly_poa_inc_dec));
                            seq_poa_lat_inc_1x <= (others => dly_poa_inc_dec);

                            static_poa_offset  <= static_poa_offset - 1;
                            poa_set_delay      <= c_dly_poa_set;

                        else

                            seq_poa_lat_inc_1x <= seq_poa_lat_inc_1x_int;
                            seq_poa_lat_dec_1x <= seq_poa_lat_dec_1x_int;

                        end if;

                        if poa_set_delay /= 0 then
                            poa_set_delay <= poa_set_delay - 1;
                        end if;

                    end if;

                else  -- no static setup

                    seq_poa_lat_inc_1x      <= seq_poa_lat_inc_1x_int;
                    seq_poa_lat_dec_1x      <= seq_poa_lat_dec_1x_int;

                end if;

            end if;

        end process;

        -- count POA protection adjustments for debug
        process(clk, rst_n)
        begin

            if rst_n = '0' then
                poa_adjustments <= 0;
            elsif rising_edge(clk) then
                if seq_poa_lat_dec_1x_int(0) = '1' then
                    poa_adjustments <= poa_adjustments + 1;
                end if;
                if seq_poa_lat_inc_1x_int(0) = '1' then
                    if poa_adjustments = 0 then
                        report seq_report_prefix & " postamble adjustment wrap around detected - more increments than decrements" severity failure;
                    else
                        poa_adjustments <= poa_adjustments - 1;
                    end if;
                end if;
            end if;

        end process;

    end block;

    -- register output fail/success signals - avoiding optimisation out
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ctl_init_fail    <= '0';
            ctl_init_success <= '0';
        elsif rising_edge(clk) then
            ctl_init_fail    <= ctl_init_fail_int;
            ctl_init_success <= ctl_init_success_int;
        end if;
    end process;

    -- ctl_cal_byte_lanes register
    -- seq_rdp_reset_req_n - when ctl_recalibrate_req issued
    process(clk,rst_n)
    begin
        if rst_n = '0' then
            seq_rdp_reset_req_n  <= '0';
            ctl_cal_byte_lanes_r <= (others => '1');
        elsif rising_edge(clk) then
            ctl_cal_byte_lanes_r <= not ctl_cal_byte_lanes;

            if ctl_recalibrate_req = '1' then
                seq_rdp_reset_req_n <= '0';
            else

                if ctrl_broadcast.command = cmd_rrp_sweep or
                   SIM_TIME_REDUCTIONS = 1 then
                    seq_rdp_reset_req_n <= '1';
                end if;

            end if;

        end if;
    end process;

    -- register 1t addr/cmd and odt latency outputs
    -- #pb_del NOTE: for quarter rate will need to adjust ac_add_2t also
    -- #pb_del       also need to check if seq_ac_add_2t also effects ODT.
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            seq_ac_add_1t_ac_lat_internal  <= '0';
            seq_ac_add_1t_odt_lat_internal <= '0';
            seq_ac_add_2t                  <= '0';
        elsif rising_edge(clk) then
            if SIM_TIME_REDUCTIONS = 1 then
                seq_ac_add_1t_ac_lat_internal  <= c_preset_cal_setup.ac_1t;
                seq_ac_add_1t_odt_lat_internal <= c_preset_cal_setup.ac_1t;
            else
                seq_ac_add_1t_ac_lat_internal  <= int_ac_nt(0);
                seq_ac_add_1t_odt_lat_internal <= int_ac_nt(0);
            end if;
            seq_ac_add_2t                  <= '0';
        end if;
    end process;

    -- override write datapath signal generation
    process(dgwb_wdp_override, dgrb_wdp_override, ctl_init_success_int, ctl_init_fail_int)
    begin
        if ctl_init_success_int = '0' and ctl_init_fail_int = '0' then -- if calibrating
            seq_wdp_ovride <= dgwb_wdp_override or dgrb_wdp_override;
        else
            seq_wdp_ovride <= '0';
        end if;
    end process;

    -- output write/read latency (override with preset values when sim time reductions equals 1
    seq_ctl_wlat <= std_logic_vector(to_unsigned(c_preset_cal_setup.wlat,ADV_LAT_WIDTH)) when SIM_TIME_REDUCTIONS = 1 else seq_ctl_wlat_int;
    seq_ctl_rlat <= std_logic_vector(to_unsigned(c_preset_cal_setup.rlat,ADV_LAT_WIDTH)) when SIM_TIME_REDUCTIONS = 1 else seq_ctl_rlat_int;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            seq_pll_phs_shift_busy_r   <= '0';
            seq_pll_phs_shift_busy_ccd <= '0';
        elsif rising_edge(clk) then
            seq_pll_phs_shift_busy_r   <= seq_pll_phs_shift_busy;
            seq_pll_phs_shift_busy_ccd <= seq_pll_phs_shift_busy_r;
        end if;
    end process;


    pll_ctrl: block

        -- static resync setup variables for sim time reductions
        signal static_rst_offset  : natural range 0 to 2*PLL_STEPS_PER_CYCLE;
        signal phs_shft_busy_1r   : std_logic;
        signal pll_set_delay      : natural range 100 downto 0; -- wait 100 clock cycles for clk to be stable before setting resync phase

        -- pll signal generation
        signal mmi_pll_active                : boolean;
        signal seq_pll_phs_shift_busy_ccd_1t : std_logic;

    begin

        -- multiplex ppl interface between dgrb and mmi blocks
        -- plus static setup of rsc phase to a known 'good' condition
        process(clk,rst_n)

        begin
            if rst_n = '0' then

                seq_pll_inc_dec_n      <= '0';
                seq_pll_start_reconfig <= '0';
                seq_pll_select         <= (others => '0');

                dgrb_phs_shft_busy     <= '0';

                -- static resync setup variables for sim time reductions
                if SIM_TIME_REDUCTIONS = 1 then
                    static_rst_offset    <= c_preset_codvw_phase;
                else
                    static_rst_offset    <= 0;
                end if;

                phs_shft_busy_1r     <= '0';
                pll_set_delay        <= 100;

            elsif rising_edge(clk) then

                dgrb_phs_shft_busy         <= '0';

                if static_rst_offset /= 0 and   -- not finished decrementing
                   pll_set_delay = 0 and        -- initial reset period over
                   SIM_TIME_REDUCTIONS = 1 then -- in reduce sim time mode (optimse logic away when not in this mode)

                            seq_pll_inc_dec_n      <= '1';
                            seq_pll_start_reconfig <= '1';
                            seq_pll_select         <= pll_resync_clk_index;

                            if seq_pll_phs_shift_busy_ccd = '1' then -- no metastability hardening needed in simulation
                                -- PLL phase shift started - so stop requesting a shift
                                seq_pll_start_reconfig <= '0';
                            end if;

                            if seq_pll_phs_shift_busy_ccd = '0' and phs_shft_busy_1r = '1' then
                                -- PLL phase shift finished - so proceed to flush the datapath
                                static_rst_offset    <= static_rst_offset - 1;
                                seq_pll_start_reconfig <= '0';
                            end if;

                            phs_shft_busy_1r <= seq_pll_phs_shift_busy_ccd;

                else

                    if ctrl_iram_push.active_block = ret_dgrb then
                        seq_pll_inc_dec_n      <= dgrb_pll_inc_dec_n;
                        seq_pll_start_reconfig <= dgrb_pll_start_reconfig;
                        seq_pll_select         <= dgrb_pll_select;
                        dgrb_phs_shft_busy     <= seq_pll_phs_shift_busy_ccd;
                    else
                        seq_pll_inc_dec_n      <= mmi_pll_inc_dec_n;
                        seq_pll_start_reconfig <= mmi_pll_start_reconfig;
                        seq_pll_select         <= mmi_pll_select;
                    end if;

                end if;

                if pll_set_delay /= 0 then
                    pll_set_delay <= pll_set_delay - 1;
                end if;

                if ctl_recalibrate_req = '1' then
                    pll_set_delay <= 100;
                end if;

            end if;
        end process;



        -- generate mmi pll signals
        process (clk, rst_n)

        begin
          if rst_n = '0' then

              pll_mmi.pll_busy              <= '0';
              pll_mmi.err                   <= (others => '0');
              mmi_pll_inc_dec_n             <= '0';
              mmi_pll_start_reconfig        <= '0';
              mmi_pll_select                <= (others => '0');
              mmi_pll_active                <= false;
              seq_pll_phs_shift_busy_ccd_1t <= '0';

          elsif rising_edge(clk) then

              if mmi_pll_active = true then
                  pll_mmi.pll_busy <= '1';
              else
                  pll_mmi.pll_busy <= mmi_pll.pll_phs_shft_up_wc or mmi_pll.pll_phs_shft_dn_wc;
              end if;

              if    pll_mmi.err = "00" and dgrb_pll_start_reconfig = '1' then
                pll_mmi.err <= "01";
              elsif pll_mmi.err = "00" and mmi_pll_active = true then
                pll_mmi.err <= "10";
              elsif pll_mmi.err = "00" and dgrb_pll_start_reconfig = '1' and mmi_pll_active = true then
                pll_mmi.err <= "11";
              end if;

              if mmi_pll.pll_phs_shft_up_wc = '1' and mmi_pll_active = false then
                  mmi_pll_inc_dec_n <= '1';
                  mmi_pll_select    <= std_logic_vector(to_unsigned(mmi_pll.pll_phs_shft_phase_sel,mmi_pll_select'length));
                  mmi_pll_active    <= true;

              elsif mmi_pll.pll_phs_shft_dn_wc = '1' and mmi_pll_active = false  then
                  mmi_pll_inc_dec_n <= '0';
                  mmi_pll_select    <= std_logic_vector(to_unsigned(mmi_pll.pll_phs_shft_phase_sel,mmi_pll_select'length));
                  mmi_pll_active    <= true;

              elsif seq_pll_phs_shift_busy_ccd_1t = '1' and seq_pll_phs_shift_busy_ccd = '0' then
                  mmi_pll_start_reconfig <= '0';
                  mmi_pll_active         <= false;

              elsif mmi_pll_active = true and mmi_pll_start_reconfig = '0' and seq_pll_phs_shift_busy_ccd = '0' then
                  mmi_pll_start_reconfig <= '1';

              elsif seq_pll_phs_shift_busy_ccd_1t = '0' and seq_pll_phs_shift_busy_ccd = '1' then
                  mmi_pll_start_reconfig <= '0';

              end if;

              seq_pll_phs_shift_busy_ccd_1t <= seq_pll_phs_shift_busy_ccd;

          end if;
        end process;

    end block; -- pll_ctrl

--synopsys synthesis_off

    reporting : block

        function pass_or_fail_report( cal_success : in std_logic;
                                      cal_fail    : in std_logic
                                    ) return string is
        begin
            if cal_success = '1' and cal_fail = '1' then
                return "unknown state cal_fail and cal_success both high";
            end if;
            if cal_success = '1' then
                return "PASSED";
            end if;
            if cal_fail = '1' then
                return "FAILED";
            end if;
            return "calibration report run whilst sequencer is still calibrating";
        end function;

        function is_stage_disabled ( stage_name : in string;
                                     stage_dis  : in std_logic
                                   ) return string is
        begin
            if stage_dis = '0' then
                return "";
            else
                return stage_name & " stage is disabled" & LF;
            end if;
        end function;

        function disabled_stages ( capabilities : in std_logic_vector
                                 ) return string is
        begin
            return is_stage_disabled("all calibration",                              c_capabilities(c_hl_css_reg_cal_dis_bit)) &
                   is_stage_disabled("initialisation",                               c_capabilities(c_hl_css_reg_phy_initialise_dis_bit)) &
                   is_stage_disabled("DRAM initialisation",                          c_capabilities(c_hl_css_reg_init_dram_dis_bit)) &
                   is_stage_disabled("iram header write",                            c_capabilities(c_hl_css_reg_write_ihi_dis_bit)) &
                   is_stage_disabled("burst training pattern write",                 c_capabilities(c_hl_css_reg_write_btp_dis_bit)) &
                   is_stage_disabled("more training pattern (MTP) write",            c_capabilities(c_hl_css_reg_write_mtp_dis_bit)) &
                   is_stage_disabled("check MTP pattern alignment calculation",      c_capabilities(c_hl_css_reg_read_mtp_dis_bit)) &
                   is_stage_disabled("read resynch phase reset stage",               c_capabilities(c_hl_css_reg_rrp_reset_dis_bit)) &
                   is_stage_disabled("read resynch phase sweep stage",               c_capabilities(c_hl_css_reg_rrp_sweep_dis_bit)) &
                   is_stage_disabled("read resynch phase seek stage (set phase)",    c_capabilities(c_hl_css_reg_rrp_seek_dis_bit)) &
                   is_stage_disabled("read data valid window setup",                 c_capabilities(c_hl_css_reg_rdv_dis_bit)) &
                   is_stage_disabled("postamble calibration",                        c_capabilities(c_hl_css_reg_poa_dis_bit)) &
                   is_stage_disabled("write latency timing calc",                    c_capabilities(c_hl_css_reg_was_dis_bit)) &
                   is_stage_disabled("advertise read latency",                       c_capabilities(c_hl_css_reg_adv_rd_lat_dis_bit)) &
                   is_stage_disabled("advertise write latency",                      c_capabilities(c_hl_css_reg_adv_wr_lat_dis_bit)) &
                   is_stage_disabled("write customer mode register settings",        c_capabilities(c_hl_css_reg_prep_customer_mr_setup_dis_bit)) &
                   is_stage_disabled("tracking",                                     c_capabilities(c_hl_css_reg_tracking_dis_bit));
        end function;

        function ac_nt_report(  ac_nt                : in std_logic_vector;
                                dgrb_ctrl_ac_nt_good : in std_logic;
                                preset_cal_setup     : in t_preset_cal) return string
        is
            variable v_ac_nt : std_logic_vector(0 downto 0);
        begin
            if SIM_TIME_REDUCTIONS = 1 then
                v_ac_nt(0) := preset_cal_setup.ac_1t;

                if v_ac_nt(0) = '1' then
                    return "-- statically set address and command 1T delay: add 1T delay" & LF;
                else
                    return "-- statically set address and command 1T delay: no 1T delay" & LF;
                end if;

            else
                v_ac_nt(0) := ac_nt(0);

                if dgrb_ctrl_ac_nt_good = '1' then
                    if v_ac_nt(0) = '1' then
                        return "-- chosen address and command 1T delay: add 1T delay" & LF;
                    else
                        return "-- chosen address and command 1T delay: no 1T delay" & LF;
                    end if;
                else
                    return "-- no valid address and command phase chosen (calibration FAILED)" & LF;
                end if;

            end if;

        end function;

        function read_resync_report ( codvw_phase      : in std_logic_vector;
                                      codvw_size       : in std_logic_vector;
                                      ctl_rlat         : in std_logic_vector;
                                      ctl_wlat         : in std_logic_vector;
                                      preset_cal_setup : in t_preset_cal) return string
        is
        begin
            if SIM_TIME_REDUCTIONS = 1 then
                return "-- read resynch phase static setup (no calibration run) report:" & LF &
                       "    -- statically set centre of data valid window phase : " & natural'image(preset_cal_setup.codvw_phase) & LF &
                       "    -- statically set centre of data valid window size  : " & natural'image(preset_cal_setup.codvw_size) & LF &
                       "    -- statically set read latency (ctl_rlat)           : " & natural'image(preset_cal_setup.rlat) & LF &
                       "    -- statically set write latency (ctl_wlat)          : " & natural'image(preset_cal_setup.wlat) & LF &
                       "    -- note: this mode only works for simulation and sets resync phase" & LF &
                       "             to a known good operating condition for no test bench" & LF &
                       "             delays on mem_dq signal" & LF;
            else
                return "-- PHY read latency (ctl_rlat) is  : " & natural'image(to_integer(unsigned(ctl_rlat))) & LF &
                       "-- address/command to PHY write latency (ctl_wlat) is : " & natural'image(to_integer(unsigned(ctl_wlat))) & LF &
                       "-- read resynch phase calibration report:" & LF &
                       "    -- calibrated centre of data valid window phase : " & natural'image(to_integer(unsigned(codvw_phase))) & LF &
                       "    -- calibrated centre of data valid window size  : " & natural'image(to_integer(unsigned(codvw_size))) & LF;
            end if;
        end function;

        function poa_rdv_adjust_report( poa_adjust : in natural;
                                        rdv_adjust : in natural;
                                        preset_cal_setup : in t_preset_cal) return string
        is
        begin
            if SIM_TIME_REDUCTIONS = 1 then
                return "Statically set poa and rdv (adjustments from reset value):" & LF &
                       "poa 'dec' adjustments = " & natural'image(preset_cal_setup.poa_lat) & LF &
                       "rdv 'dec' adjustments = " & natural'image(preset_cal_setup.rdv_lat) & LF;
            else
                return "poa 'dec' adjustments = " & natural'image(poa_adjust) & LF &
                       "rdv 'dec' adjustments = " & natural'image(rdv_adjust) & LF;

            end if;
        end function;

        function calibration_report ( capabilities : in std_logic_vector;
                                      cal_success  : in std_logic;
                                      cal_fail     : in std_logic;
                                      ctl_rlat     : in std_logic_vector;
                                      ctl_wlat     : in std_logic_vector;
                                      codvw_phase  : in std_logic_vector;
                                      codvw_size   : in std_logic_vector;
                                      ac_nt        : in std_logic_vector;
                                      dgrb_ctrl_ac_nt_good : in std_logic;
                                      preset_cal_setup : in t_preset_cal;
                                      poa_adjust : in natural;
                                      rdv_adjust : in natural) return string
        is

        begin
            return seq_report_prefix & " report..." & LF &
                   "-----------------------------------------------------------------------" & LF &
                   "-- **** ALTMEMPHY CALIBRATION has completed ****" & LF &
                   "-- Status:"  & LF &
                   "-- calibration has  : " & pass_or_fail_report(cal_success, cal_fail) & LF &
                   read_resync_report(codvw_phase, codvw_size, ctl_rlat, ctl_wlat, preset_cal_setup) &
                   ac_nt_report(ac_nt, dgrb_ctrl_ac_nt_good, preset_cal_setup) &
                   poa_rdv_adjust_report(poa_adjust, rdv_adjust, preset_cal_setup) &
                   disabled_stages(capabilities) &
                   "-----------------------------------------------------------------------";
        end function;

    begin

        -- -------------------------------------------------------
        -- calibration result reporting
        -- -------------------------------------------------------
        process(rst_n, clk)
        variable v_reports_written : std_logic;
        variable v_cal_request_r   : std_logic;
        variable v_rewrite_report  : std_logic;

        begin
            if rst_n = '0' then
                v_reports_written := '0';
                v_cal_request_r   := '0';
                v_rewrite_report  := '0';

            elsif Rising_Edge(clk) then
                if v_reports_written = '0' then
                    if ctl_init_success_int = '1' or ctl_init_fail_int = '1' then
                        v_reports_written := '1';

                        report calibration_report(c_capabilities,
                                                  ctl_init_success_int,
                                                  ctl_init_fail_int,
                                                  seq_ctl_rlat_int,
                                                  seq_ctl_wlat_int,
                                                  dgrb_mmi.cal_codvw_phase,
                                                  dgrb_mmi.cal_codvw_size,
                                                  int_ac_nt,
                                                  dgrb_ctrl_ac_nt_good,
                                                  c_preset_cal_setup,
                                                  poa_adjustments,
                                                  rdv_adjustments
                                                 ) severity note;

                    end if;
                end if;

                -- if recalibrate request triggered watch for cal success / fail going low and re-trigger report writing
                if ctl_recalibrate_req = '1' and v_cal_request_r = '0' then
                    v_rewrite_report := '1';
                end if;
                if v_rewrite_report = '1' and ctl_init_success_int = '0' and ctl_init_fail_int = '0' then
                    v_reports_written := '0';
                    v_rewrite_report  := '0';
                end if;

                v_cal_request_r := ctl_recalibrate_req;
            end if;
        end process;

        -- -------------------------------------------------------
        -- capabilities vector reporting and coarse PHY setup sanity checks
        -- -------------------------------------------------------

        process(rst_n, clk)
        variable reports_written : std_logic;
        begin
            if rst_n = '0' then
                reports_written := '0';

            elsif Rising_Edge(clk) then

                if reports_written = '0' then
                    reports_written := '1';
                    if MEM_IF_MEMTYPE="DDR" or MEM_IF_MEMTYPE="DDR2" or MEM_IF_MEMTYPE="DDR3" then
                        if DWIDTH_RATIO = 2 or DWIDTH_RATIO = 4 then
                            report disabled_stages(c_capabilities) severity note;
                            -- #pb_del Insert more checks as capabilites field is enhanced
                        else
                            report seq_report_prefix & "unsupported rate for non-levelling AFI PHY sequencer - only full- or half-rate supported" severity warning;
                        end if;
                    else
                        report seq_report_prefix & "memory type " & MEM_IF_MEMTYPE & " is not supported in non-levelling AFI PHY sequencer" severity failure;
                    end if;
                end if;
            end if;

        end process;

    end block;  -- reporting

--synopsys synthesis_on

end architecture struct;
