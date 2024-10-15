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


-------------------------------------------------------------------------------
-- Title : control block

-- File: $RCSfile : alt_mem_phy_ctrl.v,v $

-- Last Modified : $Date: 2018/07/18 $

-- Revision : $Revision: #1 $
-------------------------------------------------------------------------------
--#end

-- -----------------------------------------------------------------------------
-- Abstract : ctrl block for the non-levelling AFI PHY sequencer
--            This block is the central control unit for the sequencer. The method
--            of control is to issue commands (prefixed cmd_) to each of the other
--            sequencer blocks to execute. Each command corresponds to a stage of
--            the AFI PHY calibaration stage, and in turn each state represents a
--            command or a supplimentary flow control operation. In addition to
--            controlling the sequencer this block also checks for time out
--            conditions which occur when a different system block is faulty.
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

-- The iram address package (alt_mem_phy_iram_addr_pkg) is used to define the base addresses used
-- for iram writes during calibration
--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
    use work.alt_mem_phy_iram_addr_pkg.all;
--#end
-- #pb_del: note the alt_mem_phy_iram_addr_pkg is unused in this version of sequencer but maintained
-- #pb_del such that the IRAM_ADDRESSING generic can be maintained to conform to the leveling sequencer
-- #pb_del interface

--#mw_prefix ("alt_mem_phy_ctrl")
entity alt_mem_phy_ctrl is
--#end
    generic (
        FAMILYGROUP_ID                 : natural;
        MEM_IF_DLL_LOCK_COUNT          : natural;
        MEM_IF_MEMTYPE                 : string;
        DWIDTH_RATIO                   : natural;
        IRAM_ADDRESSING                : t_base_hdr_addresses;
        MEM_IF_CLK_PS                  : natural;
        TRACKING_INTERVAL_IN_MS        : natural;
        MEM_IF_NUM_RANKS               : natural;
        MEM_IF_DQS_WIDTH               : natural;

        GENERATE_ADDITIONAL_DBG_RTL    : natural;
        SIM_TIME_REDUCTIONS            : natural; -- if 0 null, if 1 skip rrp, if 2 rrp for 1 dqs group and 1 cs

        ACK_SEVERITY                   : severity_level
    );
    port (
        -- clk / reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        -- calibration status and redo request
        ctl_init_success               : out   std_logic;
        ctl_init_fail                  : out   std_logic;
        ctl_recalibrate_req            : in    std_logic;    -- acts as a synchronous reset

        -- status signals from iram
        iram_status                    : in    t_iram_stat;
        iram_push_done                 : in    std_logic;

        -- standard control signal to all blocks
        ctrl_op_rec                    : out   t_ctrl_command;

        -- standardised response from all system blocks
        admin_ctrl                     : in    t_ctrl_stat;
        dgrb_ctrl                      : in    t_ctrl_stat;
        dgwb_ctrl                      : in    t_ctrl_stat;

        -- mmi to ctrl interface
        mmi_ctrl                       : in   t_mmi_ctrl;
        ctrl_mmi                       : out  t_ctrl_mmi;

        -- byte lane select
        ctl_cal_byte_lanes             : in    std_logic_vector(MEM_IF_NUM_RANKS * MEM_IF_DQS_WIDTH  - 1 downto 0);

        -- signals to control the ac_nt setting
        dgrb_ctrl_ac_nt_good           : in   std_logic;
        int_ac_nt                      : out  std_logic_vector(((DWIDTH_RATIO+2)/4) - 1 downto 0);  -- width of 1 for DWIDTH_RATIO =2,4 and 2 for DWIDTH_RATIO = 8

        -- the following signals are reserved for future use
        ctrl_iram_push                 : out   t_ctrl_iram

    );
end entity;

library work;
-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
    use work.alt_mem_phy_constants_pkg.all;
--#end


--#mw_prefix ("alt_mem_phy_ctrl")
architecture struct of alt_mem_phy_ctrl is
--#end

        -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant ctrl_report_prefix     : string  := "alt_mem_phy_seq (ctrl) : ";
--#end

    -- decoder to find the relevant disable bit (from mmi registers) for a given state
    function find_dis_bit
        (
         state    : t_master_sm_state;
         mmi_ctrl : t_mmi_ctrl
        ) return std_logic is
        variable v_dis : std_logic;
    begin
        case state is
            when s_phy_initialise         => v_dis := mmi_ctrl.hl_css.phy_initialise_dis;
            when s_init_dram |
                 s_prog_cal_mr            => v_dis := mmi_ctrl.hl_css.init_dram_dis;
            when s_write_ihi              => v_dis := mmi_ctrl.hl_css.write_ihi_dis;
            when s_cal                    => v_dis := mmi_ctrl.hl_css.cal_dis;
            when s_write_btp              => v_dis := mmi_ctrl.hl_css.write_btp_dis;
            when s_write_mtp              => v_dis := mmi_ctrl.hl_css.write_mtp_dis;
            when s_read_mtp               => v_dis := mmi_ctrl.hl_css.read_mtp_dis;
            when s_rrp_reset              => v_dis := mmi_ctrl.hl_css.rrp_reset_dis;
            when s_rrp_sweep              => v_dis := mmi_ctrl.hl_css.rrp_sweep_dis;
            when s_rrp_seek               => v_dis := mmi_ctrl.hl_css.rrp_seek_dis;
            when s_rdv                    => v_dis := mmi_ctrl.hl_css.rdv_dis;
            when s_poa                    => v_dis := mmi_ctrl.hl_css.poa_dis;
            when s_was                    => v_dis := mmi_ctrl.hl_css.was_dis;
            when s_adv_rd_lat             => v_dis := mmi_ctrl.hl_css.adv_rd_lat_dis;
            when s_adv_wr_lat             => v_dis := mmi_ctrl.hl_css.adv_wr_lat_dis;
            when s_prep_customer_mr_setup => v_dis := mmi_ctrl.hl_css.prep_customer_mr_setup_dis;
            when s_tracking_setup |
                 s_tracking               => v_dis := mmi_ctrl.hl_css.tracking_dis;
            when others                   => v_dis := '1'; -- default change stage
        end case;
        return v_dis;
    end function;

    -- decoder to find the relevant command for a given state
    function find_cmd
       (
        state : t_master_sm_state
       ) return t_ctrl_cmd_id is
    begin
        case state is
            when s_phy_initialise         => return cmd_phy_initialise;
            when s_init_dram              => return cmd_init_dram;
            when s_prog_cal_mr            => return cmd_prog_cal_mr;
            when s_write_ihi              => return cmd_write_ihi;
            when s_cal                    => return cmd_idle;
            when s_write_btp              => return cmd_write_btp;
            when s_write_mtp              => return cmd_write_mtp;
            when s_read_mtp               => return cmd_read_mtp;
            when s_rrp_reset              => return cmd_rrp_reset;
            when s_rrp_sweep              => return cmd_rrp_sweep;
            when s_rrp_seek               => return cmd_rrp_seek;
            when s_rdv                    => return cmd_rdv;
            when s_poa                    => return cmd_poa;
            when s_was                    => return cmd_was;
            when s_adv_rd_lat             => return cmd_prep_adv_rd_lat;
            when s_adv_wr_lat             => return cmd_prep_adv_wr_lat;
            when s_prep_customer_mr_setup => return cmd_prep_customer_mr_setup;
            when s_tracking_setup |
                 s_tracking               => return cmd_tr_due;
            when others                   => return cmd_idle;
        end case;
    end function;

    function mcs_rw_state -- returns true for multiple cs read/write states
        (
         state : t_master_sm_state
        ) return boolean is
    begin
        case state is

            when s_write_btp | s_write_mtp | s_rrp_sweep =>
                return true;

            when s_reset | s_phy_initialise | s_init_dram | s_prog_cal_mr | s_write_ihi | s_cal |
                 s_read_mtp | s_rrp_reset | s_rrp_seek | s_rdv | s_poa |
                 s_was | s_adv_rd_lat | s_adv_wr_lat | s_prep_customer_mr_setup |
                 s_tracking_setup | s_tracking | s_operational | s_non_operational =>

                return false;

            when others =>
--#mw_delete ("")
                report ctrl_report_prefix & " state " & t_master_sm_state'image(state) & " has not been specified to be multiple cs read/write enabled or not in mcs_rw_state function"
                       severity failure;
--#end
                return false;

        end case;

    end function;

    -- timing parameters
    constant c_done_timeout_count     : natural := 32768;
    constant c_ack_timeout_count      : natural := 1000;
    constant c_ticks_per_ms           : natural := 1000000000/(MEM_IF_CLK_PS*(DWIDTH_RATIO/2));
    constant c_ticks_per_10us         : natural := 10000000  /(MEM_IF_CLK_PS*(DWIDTH_RATIO/2));

    -- local copy of calibration fail/success signals
    signal int_ctl_init_fail          : std_logic;
    signal int_ctl_init_success       : std_logic;

    -- state machine (master for sequencer)
    signal state                      : t_master_sm_state;
    signal last_state                 : t_master_sm_state;

    -- flow control signals for state machine
    signal dis_state                  : std_logic;   -- disable state
    signal hold_state                 : std_logic;   -- hold in state for 1 clock cycle

    signal master_ctrl_op_rec         : t_ctrl_command; -- master command record to all sequencer blocks
    signal master_ctrl_iram_push      : t_ctrl_iram;    -- record indicating control details for pushes

    signal dll_lock_counter           : natural range MEM_IF_DLL_LOCK_COUNT - 1 downto 0;  -- to wait for dll to lock
    signal iram_init_complete         : std_logic;

    -- timeout signals to check if a block has 'hung'
    signal timeout_counter            : natural range c_done_timeout_count - 1 downto 0;
    signal timeout_counter_stop       : std_logic;
    signal timeout_counter_enable     : std_logic;
    signal timeout_counter_clear      : std_logic;

    signal cmd_req_asserted           : std_logic;     -- a command has been issued

    signal flag_ack_timeout           : std_logic;     -- req -> ack timed out
    signal flag_done_timeout          : std_logic;     -- reg -> done timed out

    signal waiting_for_ack            : std_logic;     -- command issued
    signal cmd_ack_seen               : std_logic;     -- command completed

    signal curr_ctrl                  : t_ctrl_stat;   -- response for current active block
    signal curr_cmd                   : t_ctrl_cmd_id;

    -- store state information based on issued command
    signal int_ctrl_prev_stage        : t_ctrl_cmd_id;
    signal int_ctrl_current_stage     : t_ctrl_cmd_id;

    -- multiple chip select counter
    signal cs_counter                 : natural range 0 to MEM_IF_NUM_RANKS - 1;
    signal reissue_cmd_req            : std_logic; -- reissue command request for multiple cs

    signal cal_cs_enabled             : std_logic_vector(MEM_IF_NUM_RANKS - 1 downto 0);

    -- signals to check the ac_nt setting
    signal ac_nt_almts_checked        : natural range 0 to DWIDTH_RATIO/2-1;
    signal ac_nt                      : std_logic_vector(((DWIDTH_RATIO+2)/4) - 1 downto 0);

    -- track the mtp alignment setting
    signal mtp_almts_checked          : natural range 0 to 2;
    signal mtp_correct_almt           : natural range 0 to 1;
    signal mtp_no_valid_almt          : std_logic;
    signal mtp_both_valid_almt        : std_logic;
    signal mtp_err                    : std_logic;

    -- tracking timing
    signal milisecond_tick_gen_count  : natural range 0 to c_ticks_per_ms -1 := c_ticks_per_ms -1;
    signal tracking_ms_counter        : natural range 0 to 255;
    signal tracking_update_due        : std_logic;

begin  -- architecture struct

-------------------------------------------------------------------------------
-- check if chip selects are enabled
-- this only effects reactive stages (i,e, those requiring memory reads)
-- #pb_del This is currently registered for speed but may be removable for optimisation
-------------------------------------------------------------------------------

-- #pb_del concurrent process so that logic optimised away when ctl_cal_byte_lanes is tied to constant
    process(ctl_cal_byte_lanes)
        variable v_cs_enabled : std_logic;
    begin

        for i in 0 to MEM_IF_NUM_RANKS - 1 loop

            -- check if any bytes enabled
            v_cs_enabled := '0';
            for j in 0 to MEM_IF_DQS_WIDTH - 1 loop
                v_cs_enabled := v_cs_enabled or ctl_cal_byte_lanes(i*MEM_IF_DQS_WIDTH + j);
            end loop;

            -- if any byte enabled set cs as enabled else not
            cal_cs_enabled(i) <= v_cs_enabled;

            -- sanity checking:
            if i = 0 and v_cs_enabled = '0' then
                report ctrl_report_prefix & " disabling of chip select 0 is unsupported by the sequencer," & LF &
                       "-> if this is your intention then please remap CS pins such that CS 0 is not disabled" severity failure;
            end if;

        end loop;

    end process;

-- -----------------------------------------------------------------------------
--  dll lock counter
--  #pb_del The dll lock, timeout counter and tracking counter can all be merged
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            dll_lock_counter   <= MEM_IF_DLL_LOCK_COUNT -1;

        elsif rising_edge(clk) then
            if ctl_recalibrate_req = '1' then
                dll_lock_counter <= MEM_IF_DLL_LOCK_COUNT -1;

            elsif dll_lock_counter /= 0 then
                dll_lock_counter <= dll_lock_counter - 1;
            end if;
        end if;
    end process;

-- -----------------------------------------------------------------------------
--  timeout counter : this counter is used to determine if an ack, or done has
--  not been received within the expected number of clock cycles of a req being
--  asserted.
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timeout_counter <= c_done_timeout_count - 1;

        elsif rising_edge(clk) then
          if timeout_counter_clear = '1' then
              timeout_counter <= c_done_timeout_count - 1;

          elsif timeout_counter_enable = '1' and state /= s_init_dram then
              if timeout_counter /= 0 then
                  timeout_counter <= timeout_counter - 1;
              end if;
          end if;
        end if;

    end process;

-- -----------------------------------------------------------------------------
--  register current ctrl signal based on current command
-- #pb_del note this is pipelined for speed (response time from blocks is > 2 so should be ok)
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then

            curr_ctrl <= defaults;
            curr_cmd  <= cmd_idle;

        elsif rising_edge(clk) then

            case curr_active_block(curr_cmd) is
                when admin  => curr_ctrl <= admin_ctrl;
                when dgrb   => curr_ctrl <= dgrb_ctrl;
                when dgwb   => curr_ctrl <= dgwb_ctrl;
                when others => curr_ctrl <= defaults;
            end case;

            curr_cmd <= master_ctrl_op_rec.command;

        end if;

    end process;

-- -----------------------------------------------------------------------------
--  generation of cmd_ack_seen
-- -----------------------------------------------------------------------------

    process (curr_ctrl)
    begin
        cmd_ack_seen <= curr_ctrl.command_ack;
    end process;

-------------------------------------------------------------------------------
-- generation of waiting_for_ack flag (to determine whether ack has timed out)
-------------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            waiting_for_ack <= '0';

        elsif rising_edge(clk) then
            if cmd_req_asserted = '1' then
                waiting_for_ack <= '1';

            elsif cmd_ack_seen = '1' then
                waiting_for_ack <= '0';
            end if;
        end if;

    end process;

-- -----------------------------------------------------------------------------
--  generation of timeout flags
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            flag_ack_timeout  <= '0';
            flag_done_timeout <= '0';

        elsif rising_edge(clk) then
            if mmi_ctrl.calibration_start = '1' or ctl_recalibrate_req = '1' then
                flag_ack_timeout <= '0';

            elsif timeout_counter = 0 and waiting_for_ack = '1' then
                flag_ack_timeout <= '1';
            end if;

            if mmi_ctrl.calibration_start = '1' or ctl_recalibrate_req = '1' then
                flag_done_timeout <= '0';

            elsif timeout_counter = 0 and
                  state /= s_rrp_sweep and          -- rrp can take enough cycles to overflow counter so don't timeout
                  state /= s_init_dram and          -- init_dram takes about 200 us, so don't timeout
                  timeout_counter_clear /= '1' then -- check if currently clearing the timeout (i.e. command_done asserted for s_init_dram or s_rrp_sweep)

                flag_done_timeout <= '1';
            end if;
        end if;

    end process;

    -- generation of timeout_counter_stop
    timeout_counter_stop <= curr_ctrl.command_done;

-- -----------------------------------------------------------------------------
--  generation of timeout_counter_enable and timeout_counter_clear
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
    begin
        if rst_n = '0' then

            timeout_counter_enable <= '0';
            timeout_counter_clear  <= '0';

        elsif rising_edge(clk) then
            if cmd_req_asserted = '1' then
                timeout_counter_enable <= '1';
                timeout_counter_clear  <= '0';

            elsif timeout_counter_stop = '1'
               or state = s_operational
               or state = s_non_operational
               or state = s_reset then
                timeout_counter_enable <= '0';
                timeout_counter_clear  <= '1';
            end if;
        end if;

    end process;

-------------------------------------------------------------------------------
-- assignment to ctrl_mmi record
-------------------------------------------------------------------------------

    process (clk, rst_n)
    variable v_ctrl_mmi : t_ctrl_mmi;
    begin
        if rst_n = '0' then

            v_ctrl_mmi             := defaults;
            ctrl_mmi               <= defaults;
            int_ctrl_prev_stage    <= cmd_idle;
            int_ctrl_current_stage <= cmd_idle;

        elsif rising_edge(clk) then

            ctrl_mmi <= v_ctrl_mmi;

            v_ctrl_mmi.ctrl_calibration_success := '0';
            v_ctrl_mmi.ctrl_calibration_fail    := '0';

            if (curr_ctrl.command_ack = '1') then
                case state is
                    when s_init_dram              => v_ctrl_mmi.ctrl_cal_stage_ack_seen.init_dram              := '1';
                    when s_write_btp              => v_ctrl_mmi.ctrl_cal_stage_ack_seen.write_btp              := '1';
                    when s_write_mtp              => v_ctrl_mmi.ctrl_cal_stage_ack_seen.write_mtp              := '1';
                    when s_read_mtp               => v_ctrl_mmi.ctrl_cal_stage_ack_seen.read_mtp               := '1';
                    when s_rrp_reset              => v_ctrl_mmi.ctrl_cal_stage_ack_seen.rrp_reset              := '1';
                    when s_rrp_sweep              => v_ctrl_mmi.ctrl_cal_stage_ack_seen.rrp_sweep              := '1';
                    when s_rrp_seek               => v_ctrl_mmi.ctrl_cal_stage_ack_seen.rrp_seek               := '1';
                    when s_rdv                    => v_ctrl_mmi.ctrl_cal_stage_ack_seen.rdv                    := '1';
                    when s_poa                    => v_ctrl_mmi.ctrl_cal_stage_ack_seen.poa                    := '1';
                    when s_was                    => v_ctrl_mmi.ctrl_cal_stage_ack_seen.was                    := '1';
                    when s_adv_rd_lat             => v_ctrl_mmi.ctrl_cal_stage_ack_seen.adv_rd_lat             := '1';
                    when s_adv_wr_lat             => v_ctrl_mmi.ctrl_cal_stage_ack_seen.adv_wr_lat             := '1';
                    when s_prep_customer_mr_setup => v_ctrl_mmi.ctrl_cal_stage_ack_seen.prep_customer_mr_setup := '1';
                    when s_tracking_setup |
                         s_tracking               => v_ctrl_mmi.ctrl_cal_stage_ack_seen.tracking_setup         := '1';
                    when others => null;
                end case;
            end if;

            -- special 'ack' (actually finished) triggers for phy_initialise, writing iram header info and s_cal
            if state = s_phy_initialise then
                if iram_status.init_done = '1' and dll_lock_counter = 0 then
                    v_ctrl_mmi.ctrl_cal_stage_ack_seen.phy_initialise := '1';
                end if;
            end if;

            if state = s_write_ihi then
                if iram_push_done = '1' then
                    v_ctrl_mmi.ctrl_cal_stage_ack_seen.write_ihi := '1';
                end if;
            end if;

            if state = s_cal and find_dis_bit(state, mmi_ctrl) = '0' then  -- if cal state and calibration not disabled acknowledge
                v_ctrl_mmi.ctrl_cal_stage_ack_seen.cal := '1';
            end if;


            if state = s_operational then
                v_ctrl_mmi.ctrl_calibration_success := '1';
            end if;

            if state = s_non_operational then
                v_ctrl_mmi.ctrl_calibration_fail := '1';
            end if;

            if state /= s_non_operational then
                v_ctrl_mmi.ctrl_current_active_block := master_ctrl_iram_push.active_block;
                v_ctrl_mmi.ctrl_current_stage        := master_ctrl_op_rec.command;
            else
                v_ctrl_mmi.ctrl_current_active_block := v_ctrl_mmi.ctrl_current_active_block;
                v_ctrl_mmi.ctrl_current_stage        := v_ctrl_mmi.ctrl_current_stage;
            end if;

            int_ctrl_prev_stage    <= int_ctrl_current_stage;
            int_ctrl_current_stage <= v_ctrl_mmi.ctrl_current_stage;

            if int_ctrl_prev_stage /= int_ctrl_current_stage then
                v_ctrl_mmi.ctrl_current_stage_done := '0';

            else
                if curr_ctrl.command_done  = '1' then
                    v_ctrl_mmi.ctrl_current_stage_done   := '1';
                end if;
            end if;

            v_ctrl_mmi.master_state_r := last_state;

            if mmi_ctrl.calibration_start = '1' or ctl_recalibrate_req = '1' then
                v_ctrl_mmi := defaults;
                ctrl_mmi   <= defaults;
            end if;

            -- assert error codes here
            if curr_ctrl.command_err = '1' then
                v_ctrl_mmi.ctrl_err_code := curr_ctrl.command_result;
            elsif flag_ack_timeout = '1' then
                v_ctrl_mmi.ctrl_err_code := std_logic_vector(to_unsigned(c_err_ctrl_ack_timeout, v_ctrl_mmi.ctrl_err_code'length));
            elsif flag_done_timeout = '1' then
                v_ctrl_mmi.ctrl_err_code := std_logic_vector(to_unsigned(c_err_ctrl_done_timeout, v_ctrl_mmi.ctrl_err_code'length));
            elsif mtp_err = '1' then
                if mtp_no_valid_almt = '1' then
                    v_ctrl_mmi.ctrl_err_code := std_logic_vector(to_unsigned(C_ERR_READ_MTP_NO_VALID_ALMT, v_ctrl_mmi.ctrl_err_code'length));
                elsif mtp_both_valid_almt = '1' then
                    v_ctrl_mmi.ctrl_err_code := std_logic_vector(to_unsigned(C_ERR_READ_MTP_BOTH_ALMT_PASS, v_ctrl_mmi.ctrl_err_code'length));
                end if;
            end if;

        end if;

    end process;

    -- check if iram finished init
    process(iram_status)
    begin
        if GENERATE_ADDITIONAL_DBG_RTL = 0 then
            iram_init_complete <= '1';
        else
            iram_init_complete <= iram_status.init_done;
        end if;
    end process;

-- -----------------------------------------------------------------------------
--  master state machine
--  (this controls the operation of the entire sequencer)
--  the states are summarised as follows:
--     s_reset
-- #pb_del note that the s_reset state has been known in DDR3 case to be the critical
-- #pb_del path when restarting calibration - add no_prune / keep attribute if this
-- #pb_del is the case here. - btc
--     s_phy_initialise          - wait for dll lock and init done flag from iram
--     s_init_dram,              -- dram initialisation - reset sequence
--     s_prog_cal_mr,            -- dram initialisation - programming mode registers (once per chip select)
--     s_write_ihi               - write header information in iRAM
--     s_cal                     - check if calibration to be executed
--     s_write_btp               - write burst training pattern
--     s_write_mtp               - write more training pattern
--     s_rrp_reset               - read resync phase setup - reset initial conditions
--     s_rrp_sweep               - read resync phase setup - sweep phases per chip select
--     s_read_mtp                - read training patterns to find correct alignment for 1100 burst
--                                 (this is a special case of s_rrp_seek with no resych phase setting)
--     s_rrp_seek                - read resync phase setup - seek correct alignment
--     s_rdv                     - read data valid setup
--     s_poa                     - calibrate the postamble
--     s_was                     - write datapath setup (ac to write data timing)
--     s_adv_rd_lat              - advertise read latency
--     s_adv_wr_lat              - advertise write latency
--     s_tracking_setup          - perform tracking (1st pass to setup mimic window)
--     s_prep_customer_mr_setup  - apply user mode register settings (in admin block)
--     s_tracking                - perform tracking (subsequent passes in user mode)
--     s_operational             - calibration successful and in user mode
--     s_non_operational         - calibration unsuccessful and in user mode
-- -----------------------------------------------------------------------------

    process(clk, rst_n)
        variable v_seen_ack : boolean;
        variable v_dis      : std_logic; -- disable bit
    begin
        if rst_n = '0' then

            state                <= s_reset;
            last_state           <= s_reset;
            int_ctl_init_success <= '0';
            int_ctl_init_fail    <= '0';
            v_seen_ack           := false;
            hold_state           <= '0';
            cs_counter           <= 0;
            mtp_almts_checked    <= 0;
            ac_nt                <= (others => '1');
            ac_nt_almts_checked  <= 0;
            reissue_cmd_req      <= '0';

            dis_state            <= '0';

        elsif rising_edge(clk) then
            last_state           <= state;

            -- check if state_tx required
            if curr_ctrl.command_ack = '1' then
                v_seen_ack := true;
            end if;

            -- find disable bit for current state (do once to avoid exit mid-state)
            if state /= last_state then
                dis_state <= find_dis_bit(state, mmi_ctrl);
            end if;

            -- Set special conditions:
            -- #pb_del the functionality of this can be moved inside the state machine with control of hold_state if timing requires

            if state = s_reset or
               state = s_operational or
               state = s_non_operational then
                dis_state <= '1';
            end if;

            -- override to ensure execution of next state logic
            if (state = s_cal) then
                dis_state <= '1';
            end if;

            -- if header writing in iram check finished
            if (state = s_write_ihi) then
                if iram_push_done = '1' or mmi_ctrl.hl_css.write_ihi_dis = '1' then
                    dis_state <= '1';
                else
                    dis_state <= '0';
                end if;
            end if;

            -- Special condition for initialisation
            if (state = s_phy_initialise) then
                if ((dll_lock_counter = 0) and (iram_init_complete = '1')) or
                   (mmi_ctrl.hl_css.phy_initialise_dis = '1') then
                    dis_state <= '1';
                else
                    dis_state <= '0';
                end if;
            end if;

            --#pb_del find disable bit for next state (this may be required to skip state?):
            --#pb_del v_nxt_dis := find_dis_bit(t_master_sm_state'succ(state), mmi_ctrl);
            if dis_state = '1' then
                v_seen_ack := false;
            elsif curr_ctrl.command_done = '1' then
                if v_seen_ack = false then
                    report ctrl_report_prefix & "have not seen ack but have seen command done from " & t_ctrl_active_block'image(curr_active_block(master_ctrl_op_rec.command)) & "_block in state " & t_master_sm_state'image(state) severity warning;
                end if;
                v_seen_ack := false;
            end if;

            -- default do not reissue command request
            reissue_cmd_req <= '0';

            if (hold_state = '1') then
                hold_state <= '0';
            else
                if ((dis_state = '1') or
                   (curr_ctrl.command_done = '1') or
                   ((cal_cs_enabled(cs_counter) = '0') and (mcs_rw_state(state) = True))) then  -- current chip select is disabled and read/write

                    hold_state <= '1';

                    -- Only reset the below if making state change
                    int_ctl_init_success <= '0';
                    int_ctl_init_fail    <= '0';

                    -- default chip select counter gets reset to zero
                    cs_counter <= 0;

                    case state is
                        when s_reset =>                  state               <= s_phy_initialise;
                                                         ac_nt               <= (others => '1');
                                                         mtp_almts_checked   <= 0;
                                                         ac_nt_almts_checked <= 0;

                        when s_phy_initialise =>         state      <= s_init_dram;

                        when s_init_dram =>              state <= s_prog_cal_mr;

                        when s_prog_cal_mr =>            if cs_counter = MEM_IF_NUM_RANKS - 1 then

                                                             -- if no debug interface don't write iram header
                                                             if GENERATE_ADDITIONAL_DBG_RTL = 1 then
                                                                 state <= s_write_ihi;
                                                             else
                                                                 state <= s_cal;
                                                             end if;

                                                         else

                                                             cs_counter      <= cs_counter + 1;
                                                             reissue_cmd_req <= '1';

                                                         end if;

                        when s_write_ihi =>              state <= s_cal;

                        when s_cal =>                    if mmi_ctrl.hl_css.cal_dis = '0' then
                                                             state <= s_write_btp;
                                                         else
                                                             state <= s_tracking_setup;
                                                         end if;

                                                         -- always enter s_cal before calibration so reset some variables here
                                                         mtp_almts_checked   <= 0;
                                                         ac_nt_almts_checked <= 0;

                        when s_write_btp =>              if cs_counter = MEM_IF_NUM_RANKS-1 or
                                                            SIM_TIME_REDUCTIONS = 2 then

                                                             state      <= s_write_mtp;

                                                         else
                                                             cs_counter <= cs_counter + 1;

                                                             -- only reissue command if current chip select enabled
                                                             if cal_cs_enabled(cs_counter + 1) = '1' then
                                                                reissue_cmd_req <= '1';
                                                             end if;

                                                         end if;

                        when s_write_mtp =>              if cs_counter = MEM_IF_NUM_RANKS - 1 or
                                                            SIM_TIME_REDUCTIONS = 2 then

                                                             if SIM_TIME_REDUCTIONS = 1 then
                                                                 state      <= s_rdv;
                                                             else
                                                                 state      <= s_rrp_reset;
                                                             end if;

                                                         else
                                                             cs_counter      <= cs_counter + 1;

                                                             -- only reissue command if current chip select enabled
                                                             if cal_cs_enabled(cs_counter + 1) = '1' then
                                                                reissue_cmd_req <= '1';
                                                             end if;

                                                         end if;

                        when s_rrp_reset =>              state      <= s_rrp_sweep;

                        when s_rrp_sweep =>              if cs_counter = MEM_IF_NUM_RANKS - 1 or
                                                            mtp_almts_checked /= 2 or
                                                            SIM_TIME_REDUCTIONS = 2 then

                                                             if mtp_almts_checked /= 2 then
                                                                 state <= s_read_mtp;
                                                             else
                                                                 state <= s_rrp_seek;
                                                             end if;

                                                         else
                                                             cs_counter      <= cs_counter + 1;

                                                             -- only reissue command if current chip select enabled
                                                             if cal_cs_enabled(cs_counter + 1) = '1' then
                                                                reissue_cmd_req <= '1';
                                                             end if;

                                                         end if;

                        when s_read_mtp =>               if mtp_almts_checked /= 2 then
                                                             mtp_almts_checked <= mtp_almts_checked + 1;
                                                         end if;
                                                         state      <= s_rrp_reset;

                        when s_rrp_seek =>               state      <= s_rdv;

                        when s_rdv =>                    state <= s_was;
                        when s_was =>                    state <= s_adv_rd_lat;
                        when s_adv_rd_lat =>             state <= s_adv_wr_lat;

                        when s_adv_wr_lat =>             if dgrb_ctrl_ac_nt_good = '1' then
                                                             state <= s_poa;
                                                         else
                                                             if ac_nt_almts_checked = (DWIDTH_RATIO/2 - 1) then
                                                                 -- #pb_del: TODO: insert an error for this condition
                                                                 state <= s_non_operational;
                                                             else
                                                                 -- switch alignment and restart calibration
                                                                 ac_nt               <= std_logic_vector(unsigned(ac_nt) + 1);
                                                                 ac_nt_almts_checked <= ac_nt_almts_checked + 1;

                                                                if SIM_TIME_REDUCTIONS = 1 then
                                                                    state               <= s_rdv;
                                                                else
                                                                    state               <= s_rrp_reset;
                                                                end if;

                                                                mtp_almts_checked   <= 0;
                                                             end if;
                                                         end if;

                        when s_poa =>                    state <= s_tracking_setup;

                        when s_tracking_setup =>         state      <= s_prep_customer_mr_setup;

                        when s_prep_customer_mr_setup => if cs_counter = MEM_IF_NUM_RANKS - 1 then  -- s_prep_customer_mr_setup is always performed over all cs
                                                             state      <= s_operational;
                                                         else
                                                             cs_counter      <= cs_counter + 1;
                                                             reissue_cmd_req <= '1';
                                                         end if;

                        when s_tracking =>               state                <= s_operational;
                                                         int_ctl_init_success <= int_ctl_init_success;
                                                         int_ctl_init_fail    <= int_ctl_init_fail;

                        when s_operational =>            int_ctl_init_success <= '1';
                                                         int_ctl_init_fail    <= '0';
                                                         hold_state           <= '0';
                                                         if tracking_update_due = '1' and mmi_ctrl.hl_css.tracking_dis = '0' then
                                                             state      <= s_tracking;
                                                             hold_state <= '1';
                                                         end if;

                        when s_non_operational =>        int_ctl_init_success <= '0';
                                                         int_ctl_init_fail    <= '1';
                                                         hold_state           <= '0';
                                                         if last_state /= s_non_operational then -- print a warning on entering this state
                                                             report ctrl_report_prefix & "memory calibration has failed (output from ctrl block)" severity WARNING;
                                                         end if;

                        when others =>                   state <= t_master_sm_state'succ(state);
                    end case;
                end if;
            end if;

        if   flag_done_timeout = '1'            -- no done signal from current active block
          or flag_ack_timeout = '1'             -- or no ack signal from current active block
          or curr_ctrl.command_err = '1'         -- or an error from current active block
          or mtp_err = '1' then                  -- or an error due to mtp alignment
            state <= s_non_operational;
        end if;

        if mmi_ctrl.calibration_start = '1' then  -- restart calibration process
            state <= s_cal;
        end if;

        if ctl_recalibrate_req = '1' then  -- restart all incl. initialisation
            state <= s_reset;
        end if;

      end if;

    end process;

    -- generate output calibration fail/success signals
    -- #pb_del registered to improve timing
    process(clk, rst_n)
    begin
        if rst_n = '0' then

            ctl_init_fail    <= '0';
            ctl_init_success <= '0';

        elsif rising_edge(clk) then

            ctl_init_fail    <= int_ctl_init_fail;
            ctl_init_success <= int_ctl_init_success;

        end if;
    end process;

    -- assign ac_nt to the output int_ac_nt
    process(ac_nt)
    begin
        int_ac_nt <= ac_nt;
    end process;

-- ------------------------------------------------------------------------------
-- find correct mtp_almt from returned data
-- ------------------------------------------------------------------------------

    mtp_almt: block

        signal dvw_size_a0 : natural range 0 to 255;  -- maximum size of command result
        signal dvw_size_a1 : natural range 0 to 255;

    begin

        process (clk, rst_n)

            variable v_dvw_a0_small : boolean;
            variable v_dvw_a1_small : boolean;

        begin
            if rst_n = '0' then

               mtp_correct_almt    <= 0;
               dvw_size_a0         <= 0;
               dvw_size_a1         <= 0;
               mtp_no_valid_almt   <= '0';
               mtp_both_valid_almt <= '0';
               mtp_err             <= '0';

            elsif rising_edge(clk) then

                -- update the dvw sizes
                if state = s_read_mtp then
                    if curr_ctrl.command_done = '1' then
                        if mtp_almts_checked = 0 then
                            dvw_size_a0 <= to_integer(unsigned(curr_ctrl.command_result));
                        else
                            dvw_size_a1 <= to_integer(unsigned(curr_ctrl.command_result));
                        end if;
                    end if;
                end if;

                -- check dvw size and set mtp almt
                if dvw_size_a0 < dvw_size_a1 then
                    mtp_correct_almt <= 1;
                else
                    mtp_correct_almt <= 0;
                end if;

                -- error conditions
                if mtp_almts_checked = 2 and GENERATE_ADDITIONAL_DBG_RTL = 1 then  -- if finished alignment checking (and GENERATE_ADDITIONAL_DBG_RTL set)

                    -- perform size checks once per dvw
                    if dvw_size_a0 < 3 then
                        v_dvw_a0_small := true;
                    else
                        v_dvw_a0_small := false;
                    end if;

                    if dvw_size_a1 < 3 then
                        v_dvw_a1_small := true;
                    else
                        v_dvw_a1_small := false;
                    end if;

                    if v_dvw_a0_small = true and v_dvw_a1_small = true then
                        mtp_no_valid_almt   <= '1';
                        mtp_err             <= '1';
                    end if;

                    if v_dvw_a0_small = false and v_dvw_a1_small = false then
                        mtp_both_valid_almt <= '1';
                        mtp_err             <= '1';
                    end if;

                else

                    mtp_no_valid_almt   <= '0';
                    mtp_both_valid_almt <= '0';
                    mtp_err             <= '0';

                end if;

            end if;

        end process;

    end block;

-- ------------------------------------------------------------------------------
-- process to generate command outputs, based on state, last_state and mmi_ctrl.
-- asynchronously
-- ------------------------------------------------------------------------------

    process (state, last_state, mmi_ctrl, reissue_cmd_req, cs_counter, mtp_almts_checked, mtp_correct_almt)
    begin
        master_ctrl_op_rec         <= defaults;
        master_ctrl_iram_push      <= defaults;

        case state is

            -- special condition states
            when s_reset | s_phy_initialise | s_cal =>
                null;

            when s_write_ihi =>
                if mmi_ctrl.hl_css.write_ihi_dis = '0' then
                    master_ctrl_op_rec.command <= find_cmd(state);
                    if state /= last_state then
                        master_ctrl_op_rec.command_req <= '1';
                    end if;
                end if;

            when s_operational | s_non_operational =>
                master_ctrl_op_rec.command <= find_cmd(state);

            when others =>  -- default condition for most states
                -- #pb_del the following comparison can be registered if on critical path?
                if find_dis_bit(state, mmi_ctrl) = '0' then
                    master_ctrl_op_rec.command <= find_cmd(state);
                    if state /= last_state or reissue_cmd_req = '1' then
                        master_ctrl_op_rec.command_req <= '1';
                    end if;
                else
                    if state = last_state then  -- safe state exit if state disabled mid-calibration
                        master_ctrl_op_rec.command <= find_cmd(state);
                    end if;
                end if;

        end case;

        -- for multiple chip select commands assign operand to cs_counter
        -- #pb_del TODO: need to consider MEM_IF_CS_PER_RANK here?
        master_ctrl_op_rec.command_op            <= defaults;
        master_ctrl_op_rec.command_op.current_cs <= cs_counter;
        if state = s_rrp_sweep or state = s_read_mtp or state = s_poa then
           if mtp_almts_checked /= 2 or SIM_TIME_REDUCTIONS = 2 then
               master_ctrl_op_rec.command_op.single_bit <= '1';
           end if;
           if mtp_almts_checked /= 2 then
               master_ctrl_op_rec.command_op.mtp_almt <= mtp_almts_checked;
           else
               master_ctrl_op_rec.command_op.mtp_almt <= mtp_correct_almt;
           end if;
        end if;

        -- set write mode and packing mode for iram
        if GENERATE_ADDITIONAL_DBG_RTL = 1 then

            case state is
                when s_rrp_sweep =>
                    master_ctrl_iram_push.write_mode   <= overwrite_ram;
                    master_ctrl_iram_push.packing_mode <= dq_bitwise;

                when s_rrp_seek |
                     s_read_mtp =>

                    master_ctrl_iram_push.write_mode   <= overwrite_ram;
                    master_ctrl_iram_push.packing_mode <= dq_wordwise;

                when others =>

                    null;

            end case;
        end if;

        -- set current active block
        master_ctrl_iram_push.active_block <= curr_active_block(find_cmd(state));

    end process;

    -- some concurc_read_burst_trent assignments to outputs
    -- #pb_del these can be registered if timing dictates
    process (master_ctrl_iram_push, master_ctrl_op_rec)
    begin
        ctrl_iram_push      <= master_ctrl_iram_push;
        ctrl_op_rec         <= master_ctrl_op_rec;
        cmd_req_asserted    <= master_ctrl_op_rec.command_req;
    end process;

-- -----------------------------------------------------------------------------
--  tracking interval counter
-- -----------------------------------------------------------------------------
    process(clk, rst_n)
    begin
       if rst_n = '0' then
           milisecond_tick_gen_count <= c_ticks_per_ms -1;
           tracking_ms_counter       <= 0;
           tracking_update_due       <= '0';

       elsif rising_edge(clk) then
           if state = s_operational and last_state/= s_operational then

               if mmi_ctrl.tracking_orvd_to_10ms = '1' then
                   milisecond_tick_gen_count <= c_ticks_per_10us -1;
               else
                   milisecond_tick_gen_count <= c_ticks_per_ms -1;
               end if;

               tracking_ms_counter <= mmi_ctrl.tracking_period_ms;

           elsif state = s_operational then
               if milisecond_tick_gen_count = 0  and tracking_update_due /= '1' then

                   if tracking_ms_counter = 0 then
                       tracking_update_due <= '1';
                   else
                       tracking_ms_counter <= tracking_ms_counter -1;
                   end if;

                   if mmi_ctrl.tracking_orvd_to_10ms = '1' then
                       milisecond_tick_gen_count <= c_ticks_per_10us -1;
                   else
                       milisecond_tick_gen_count <= c_ticks_per_ms -1;
                   end if;

                elsif milisecond_tick_gen_count /= 0 then
                   milisecond_tick_gen_count <= milisecond_tick_gen_count -1;
                end if;

           else

               tracking_update_due <= '0';
           end if;
       end if;

    end process;

end architecture struct;
