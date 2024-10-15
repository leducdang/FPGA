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
--  Title           : Top level PHY

--  File:  $RCSfile : alt_mem_phy_admin.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : admin block for the non-levelling AFI PHY sequencer
--                    The admin block supports the autonomy of the sequencer from
--                    the memory interface controller. In this task admin handles
--                    memory initialisation (incl. the setting of mode registers)
--                    and memory refresh, bank activation and pre-charge commands
--                    (during memory interface calibration). Once calibration is
--                    complete admin is 'idle' and control of the memory device is
--                    passed to the users chosen memory interface controller. The
--                    supported memory types are exclusively DDR, DDR2 and DDR3.
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

-- The address and command package (alt_mem_phy_addr_cmd_pkg) is used to combine DRAM address
-- and command signals in one record and unify the functions operating on this record.
--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
    use work.alt_mem_phy_addr_cmd_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_admin")
entity alt_mem_phy_admin is
--#end
    generic (
        -- physical interface width definitions
        MEM_IF_DQS_WIDTH      : natural;
        MEM_IF_DWIDTH         : natural;
        MEM_IF_DM_WIDTH       : natural;
        MEM_IF_DQ_PER_DQS     : natural;
        DWIDTH_RATIO          : natural;
        CLOCK_INDEX_WIDTH     : natural;
        MEM_IF_CLK_PAIR_COUNT : natural;
        MEM_IF_ADDR_WIDTH     : natural;
        MEM_IF_BANKADDR_WIDTH : natural;
        MEM_IF_NUM_RANKS      : natural;
        ADV_LAT_WIDTH         : natural;
        MEM_IF_DQSN_EN        : natural;
        MEM_IF_MEMTYPE        : string;

        -- calibration address information
        MEM_IF_CAL_BANK       : natural; -- Bank to which calibration data is written
        MEM_IF_CAL_BASE_ROW   : natural;

        GENERATE_ADDITIONAL_DBG_RTL : natural;
        NON_OP_EVAL_MD              : string;  -- non_operational evaluation mode (used when GENERATE_ADDITIONAL_DBG_RTL = 1)

        -- timing parameters
        MEM_IF_CLK_PS         : natural;
        TINIT_TCK             : natural;  -- initial delay
        TINIT_RST             : natural   -- used for DDR3 device support
    );
    port (
        -- clk / reset
        clk                   : in  std_logic;
        rst_n                 : in  std_logic;

        -- the 2 signals below are unused for non-levelled sequencer (maintained for equivalent interface to levelled sequencer)
        mem_ac_swapped_ranks  : in  std_logic_vector(MEM_IF_NUM_RANKS - 1                     downto 0);
        ctl_cal_byte_lanes    : in  std_logic_vector(MEM_IF_NUM_RANKS * MEM_IF_DQS_WIDTH  - 1 downto 0);

        -- addr/cmd interface
        seq_ac                : out t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
        seq_ac_sel            : out std_logic;

        -- determined from MR settings
        enable_odt            : out std_logic;

        -- interface to the mmi block
        regs_admin_ctrl_rec   : in  t_admin_ctrl;
        admin_regs_status_rec : out t_admin_stat;
        trefi_failure         : out std_logic;

        -- interface to the ctrl block
        ctrl_admin            : in  t_ctrl_command;
        admin_ctrl            : out t_ctrl_stat;

        -- interface with dgrb/dgwb blocks
        ac_access_req         : in  std_logic;
        ac_access_gnt         : out std_logic;

        -- calibration status signals (from ctrl block)
        cal_fail              : in  std_logic;
        cal_success           : in  std_logic;

        -- recalibrate request issued
        ctl_recalibrate_req   : in std_logic

    );
end entity;

library work;

-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
    use work.alt_mem_phy_constants_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_admin")
architecture struct of alt_mem_phy_admin is
--#end

    constant c_max_mode_reg_index        : natural := 12;

    -- timing below is safe for range 80-400MHz operation - taken from worst case DDR2 (JEDEC JESD79-2E) / DDR3 (JESD79-3B)
    -- Note: timings account for worst case use for both full rate and half rate ALTMEMPHY interfaces
    constant c_init_prech_delay          : natural := 162;  -- precharge delay (360ns = tRFC+10ns) (TXPR for DDR3)
    constant c_trp_in_clks               : natural := 8;    -- set equal to trp / tck (trp = 15ns)
    constant c_tmrd_in_clks              : natural := 4;    -- maximum 4 clock cycles (DDR3)
    constant c_tmod_in_clks              : natural := 8;    -- ODT update from MRS command (tmod = 12ns (DDR2))

    constant c_trrd_min_in_clks          : natural := 4;    -- minimum clk cycles between bank activate cmds (10ns)
    constant c_trcd_min_in_clks          : natural := 8;    -- minimum bank activate to read/write cmd (15ns)

        -- the 2 constants below are parameterised to MEM_IF_CLK_PS due to the large range of possible clock frequency
    constant c_trfc_min_in_clks          : natural := (350000/MEM_IF_CLK_PS)/(DWIDTH_RATIO/2) + 2;  -- refresh-refresh timing (worst case trfc = 350 ns (DDR3))
    constant c_trefi_min_in_clks         : natural := (3900000/MEM_IF_CLK_PS)/(DWIDTH_RATIO/2) - 2; -- average refresh interval worst case trefi = 3.9 us (industrial grade devices)

    constant c_max_num_stacked_refreshes : natural := 8;   -- max no. of stacked refreshes allowed
    constant c_max_wait_value            : natural := 4;   -- delay before moving from s_idle to s_refresh_state

    -- DDR3 specific:
    constant c_zq_init_duration_clks     : natural := 514;  -- full rate (worst case) cycle count for tZQCL init
    constant c_tzqcs                     : natural := 66;   -- number of full rate clock cycles

    -- below is a record which is used to parameterise the address and command signals (addr_cmd) used in this block
    constant c_seq_addr_cmd_config       : t_addr_cmd_config_rec := set_config_rec(MEM_IF_ADDR_WIDTH, MEM_IF_BANKADDR_WIDTH, MEM_IF_NUM_RANKS, DWIDTH_RATIO, MEM_IF_MEMTYPE);

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant admin_report_prefix     : string  := "alt_mem_phy_seq (admin) : ";
--#end

    -- state type for admin_state (main state machine of admin block)
    type t_admin_state is
    (
        s_reset,                -- reset state
        s_run_init_seq,         -- run the initialisation sequence (up to but not including MR setting)
        s_program_cal_mrs,      -- program the mode registers ready for calibration (this is the user settings
                                -- with some overloads and extra init functionality)

        s_idle,                 -- idle (i.e. maintaining refresh to max)

        s_topup_refresh,        -- make sure refreshes are maxed out before going on.
        s_topup_refresh_done,   -- wait for tRFC after refresh command

        s_zq_cal_short,         -- ZQCAL short command (issued prior to activate) - DDR3 only

        s_access_act,           -- activate
        s_access,               -- dgrb, dgwb accesses,
        s_access_precharge,     -- precharge all memory banks

        s_prog_user_mrs,        -- program user mode register settings

        s_dummy_wait,           -- wait before going to s_refresh state
        s_refresh,              -- issue a memory refresh command
        s_refresh_done,         -- wait for trfc after refresh command
        s_non_operational       -- special debug state to toggle interface if calibration fails
    );

    signal state : t_admin_state; -- admin block state machine

    -- state type for ac_state
    -- #pb_del This could be replaced with something cleaner?
    type t_ac_state  is
    (   s_0 ,
        s_1 ,
        s_2 ,
        s_3 ,
        s_4 ,
        s_5 ,
        s_6 ,
        s_7 ,
        s_8 ,
        s_9 ,
        s_10,
        s_11,
        s_12,
        s_13,
        s_14);

    -- enforce one-hot fsm encoding
    attribute syn_encoding : string;
    attribute syn_encoding of t_ac_state : TYPE is "one-hot";

    signal ac_state               : t_ac_state;                   -- state machine for sub-states of t_admin_state states

    -- #pb_del TODO: set stage counter below to a lower value within the bounds of TINIT_RST
    signal stage_counter          : natural range 0 to 2**18 - 1; -- counter to support memory timing delays
    signal stage_counter_zero     : std_logic;

    signal addr_cmd               : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1); -- internal copy of output DRAM addr/cmd signals

    signal mem_init_complete      : std_logic; -- signifies memory initialisation is complete
    signal cal_complete           : std_logic; -- calibration complete (equals: cal_success OR cal_fail)

    signal int_mr0                : std_logic_vector(regs_admin_ctrl_rec.mr0'range); -- an internal copy of mode register settings
    signal int_mr1                : std_logic_vector(regs_admin_ctrl_rec.mr0'range);
    signal int_mr2                : std_logic_vector(regs_admin_ctrl_rec.mr0'range);
    signal int_mr3                : std_logic_vector(regs_admin_ctrl_rec.mr0'range);

    signal refresh_count          : natural range c_trefi_min_in_clks downto 0;            -- determine when refresh is due
    signal refresh_due            : std_logic;                                             -- need to do a refresh now
    signal refresh_done           : std_logic;                                             -- pulse when refresh complete
    signal num_stacked_refreshes  : natural range 0 to c_max_num_stacked_refreshes - 1;    -- can stack upto 8 refreshes (for DDR2)
    signal refreshes_maxed        : std_logic;                                             -- signal refreshes are maxed out
    signal initial_refresh_issued : std_logic;                                             -- to start the refresh counter off

    signal ctrl_rec               : t_ctrl_command;
    -- last state logic
    signal command_started        : std_logic;    -- provides a pulse when admin starts processing a command
    signal command_done           : std_logic;    -- provides a pulse when admin completes processing a command is completed
    signal finished_state         : std_logic;    -- finished current t_admin_state state

    signal admin_req_extended     : std_logic;                               -- keep requests for this block asserted until it is an ack is asserted
    signal current_cs             : natural range 0 to MEM_IF_NUM_RANKS - 1; -- which chip select being programmed at this instance
    signal per_cs_init_seen       : std_logic_vector(MEM_IF_NUM_RANKS - 1 downto 0);

    -- some signals to enable non_operational debug (optimised away if GENERATE_ADDITIONAL_DBG_RTL = 0)
    signal nop_toggle_signal      : t_addr_cmd_signals;
    signal nop_toggle_pin         : natural range 0 to MEM_IF_ADDR_WIDTH - 1;  -- track which pin in a signal to toggle
    signal nop_toggle_value       : std_logic;

begin  -- architecture struct

-- concurrent assignment of internal addr_cmd to output port seq_ac
    process (addr_cmd)
    begin
        seq_ac  <= addr_cmd;
    end process;

-- generate calibration complete signal
   process (cal_success, cal_fail)
   begin
       cal_complete <= cal_success or cal_fail;
   end process;

   -- register the control command record
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            ctrl_rec <= defaults;
        elsif rising_edge(clk) then
            ctrl_rec <= ctrl_admin;
        end if;
    end process;

-- extend the admin block request until ack is asserted
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            admin_req_extended <= '0';
        elsif rising_edge(clk) then
            if ( (ctrl_rec.command_req = '1') and ( curr_active_block(ctrl_rec.command) = admin) ) then
                admin_req_extended <= '1';
            elsif command_started = '1' then  -- this is effectively a copy of command_ack generation
                admin_req_extended <= '0';
            end if;
        end if;
    end process;

-- generate the current_cs signal to track which cs accessed by PHY at any instance
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            current_cs <= 0;
        elsif rising_edge(clk) then
            if ctrl_rec.command_req = '1' then
                current_cs <= ctrl_rec.command_op.current_cs;
            end if;
        end if;
    end process;


-- -----------------------------------------------------------------------------
--  refresh logic: DDR/DDR2/DDR3 allows upto 8 refreshes to be "stacked" or queued up.
--  In the idle state, will ensure refreshes are issued when necessary. Then,
--  when an access_request is received, 7 topup refreshes will be done to max out
--  the number of queued refreshes. That way, we know we have the maximum time
--  available before another refresh is due.
-- -----------------------------------------------------------------------------

-- initial_refresh_issued flag: used to sync refresh_count
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            initial_refresh_issued <= '0';
        elsif rising_edge(clk) then
            if cal_complete = '1' then
                initial_refresh_issued <= '0';
            else
                if state = s_refresh_done or
                   state = s_topup_refresh_done then
                    initial_refresh_issued <= '1';
                end if;
            end if;
        end if;
    end process;

-- refresh timer: used to work out when a refresh is due
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            refresh_count <= c_trefi_min_in_clks;
        elsif rising_edge(clk) then
            if cal_complete = '1' then
                refresh_count <= c_trefi_min_in_clks;
            else
                if refresh_count = 0 or
                  initial_refresh_issued = '0' or
                  (refreshes_maxed = '1' and refresh_done = '1') then -- if refresh issued when already maxed
                    refresh_count <= c_trefi_min_in_clks;
                else
                    refresh_count <= refresh_count - 1;
                end if;
            end if;
        end if;
    end process;

-- refresh_due generation: 1 cycle pulse to indicate that c_trefi_min_in_clks has elapsed, and
-- therefore a refresh is due
    process (clk, rst_n)
    begin
      if rst_n = '0' then
          refresh_due      <= '0';
      elsif rising_edge(clk) then
          if refresh_count = 0 and cal_complete = '0' then
              refresh_due <= '1';
          else
              refresh_due <= '0';
          end if;
      end if;
    end process;


-- counter to keep track of number of refreshes "stacked". NB: Up to 8
-- refreshes can be stacked.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            num_stacked_refreshes <= 0;
            trefi_failure <= '0'; -- default no trefi failure

        elsif rising_edge (clk) then

            if state = s_reset then
                trefi_failure <= '0'; -- default no trefi failure (in restart)
            end if;

            if cal_complete = '1' then
                num_stacked_refreshes <= 0;
            else
                if refresh_due = '1' and num_stacked_refreshes /= 0 then
                    num_stacked_refreshes <= num_stacked_refreshes - 1;
                elsif refresh_done = '1' and num_stacked_refreshes /= c_max_num_stacked_refreshes - 1 then
                    num_stacked_refreshes <= num_stacked_refreshes + 1;
                end if;

                -- debug message if stacked refreshes are depleted and refresh is due
                if refresh_due = '1' and num_stacked_refreshes = 0 and initial_refresh_issued = '1' then
                    report admin_report_prefix & "error refresh is due and num_stacked_refreshes is zero" severity error;
                    trefi_failure <= '1';  -- persist
                end if;
            end if;

        end if;
    end process;

-- generate signal to state if refreshes are maxed out
    process (clk, rst_n)
    begin
        if rst_n = '0' then

            refreshes_maxed <= '0';

        elsif rising_edge (clk) then

            if num_stacked_refreshes < c_max_num_stacked_refreshes - 1 then
                refreshes_maxed <= '0';
            else
                refreshes_maxed <= '1';
            end if;

        end if;

    end process;

-- ----------------------------------------------------
--  Mode register selection
-- #pb_del this is where per CS MR setting should be implemented - btc
-- -----------------------------------------------------

    int_mr0(regs_admin_ctrl_rec.mr0'range) <= regs_admin_ctrl_rec.mr0;
    int_mr1(regs_admin_ctrl_rec.mr1'range) <= regs_admin_ctrl_rec.mr1;
    int_mr2(regs_admin_ctrl_rec.mr2'range) <= regs_admin_ctrl_rec.mr2;
    int_mr3(regs_admin_ctrl_rec.mr3'range) <= regs_admin_ctrl_rec.mr3;

-- -------------------------------------------------------
-- State machine
-- -------------------------------------------------------
    process(rst_n, clk)
    begin
        if rst_n = '0' then
            state           <= s_reset;
            command_done    <= '0';
            command_started <= '0';

        elsif rising_edge(clk) then

            -- Last state logic
            command_done    <= '0';
            command_started <= '0';

            case state is

                when s_reset |
                     s_non_operational =>

                    if ctrl_rec.command = cmd_init_dram and admin_req_extended = '1' then
                        state <= s_run_init_seq;
                        command_started <= '1';
                    end if;

                when s_run_init_seq =>

                    if finished_state = '1' then
                          state        <= s_idle;
                          command_done <= '1';
                    end if;

                when s_program_cal_mrs =>

                    if finished_state = '1' then
                        if refreshes_maxed = '0' and mem_init_complete = '1' then  -- only refresh if all ranks initialised
                            state <= s_topup_refresh;
                        else
                            state <= s_idle;
                       end if;
                       command_done <= '1';
                    end if;

                when s_idle =>

                    if ac_access_req = '1' then
                        state           <= s_topup_refresh;

                    elsif ctrl_rec.command = cmd_init_dram and admin_req_extended = '1' then  -- start initialisation sequence
                        state           <= s_run_init_seq;
                        command_started <= '1';

                    elsif ctrl_rec.command = cmd_prog_cal_mr and admin_req_extended = '1' then  -- program mode registers (used for >1 chip select)
                        state           <= s_program_cal_mrs;
                        command_started <= '1';

                    -- always enter s_prog_user_mrs via topup refresh
                    elsif ctrl_rec.command = cmd_prep_customer_mr_setup and admin_req_extended = '1' then
                        state           <=  s_topup_refresh;

                    elsif refreshes_maxed = '0' and mem_init_complete = '1' then  -- only refresh once all ranks initialised
                        state <= s_dummy_wait;
                    end if;

                when s_dummy_wait =>

                    if finished_state = '1' then
                        state <= s_refresh;
                    end if;

                when s_topup_refresh =>

                    if finished_state = '1' then
                        state <= s_topup_refresh_done;
                    end if;

                when s_topup_refresh_done =>

                    if finished_state = '1' then -- to ensure trfc is not violated
                        if refreshes_maxed = '0' then
                            state <= s_topup_refresh;

                        elsif ctrl_rec.command = cmd_prep_customer_mr_setup and admin_req_extended = '1' then
                            state           <=  s_prog_user_mrs;
                            command_started <= '1';

                        elsif ac_access_req = '1' then

                            if MEM_IF_MEMTYPE = "DDR3" then
                                state <= s_zq_cal_short;
                            else
                                state <= s_access_act;
                            end if;

                        else
                            state <= s_idle;
                        end if;
                    end if;

                when s_zq_cal_short =>  -- DDR3 only

                    if finished_state = '1' then
                        state <= s_access_act;
                    end if;

                when s_access_act =>

                    if finished_state = '1' then
                        state <= s_access;
                    end if;

                when s_access =>

                    if ac_access_req = '0' then
                        state <= s_access_precharge;
                    end if;

                when s_access_precharge =>

                    -- ensure precharge all timer has elapsed.
                    if finished_state = '1' then
                        state <= s_idle;
                    end if;

                when s_prog_user_mrs =>

                    if finished_state = '1' then
                        state        <= s_idle;
                        command_done <= '1';
                    end if;

                when s_refresh =>

                    if finished_state = '1' then
                        state <= s_refresh_done;
                    end if;

                when s_refresh_done =>

                    if finished_state = '1' then  -- to ensure trfc is not violated
                        if refreshes_maxed = '0' then
                            state <= s_refresh;
                        else
                            state <= s_idle;
                        end if;
                    end if;

                when others =>

                    state <= s_reset;

            end case;

            if cal_complete = '1' then
                state <= s_idle;
                if GENERATE_ADDITIONAL_DBG_RTL = 1 and cal_success = '0' then
                    state <= s_non_operational; -- if calibration failed and debug enabled then toggle pins in pre-defined pattern
                end if;
            end if;

            -- if recalibrating then put admin in reset state to
            -- avoid issuing refresh commands when not needed
            if ctl_recalibrate_req = '1' then
                state <= s_reset;
            end if;

        end if;
    end process;

-- --------------------------------------------------
-- process to generate initialisation complete
-- --------------------------------------------------
    process (rst_n, clk)

    begin
        if rst_n = '0' then

            mem_init_complete <= '0';

        elsif rising_edge(clk) then

            if to_integer(unsigned(per_cs_init_seen)) = 2**MEM_IF_NUM_RANKS - 1 then
                mem_init_complete <= '1';
            else
                mem_init_complete <= '0';
            end if;

        end if;

    end process;

-- --------------------------------------------------
-- process to generate addr/cmd.
-- --------------------------------------------------
    process(rst_n, clk)

        variable v_mr_overload : std_logic_vector(regs_admin_ctrl_rec.mr0'range);

        -- required for non_operational state only
        variable v_nop_ac_0    : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
        variable v_nop_ac_1    : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);

    begin
        if rst_n = '0' then

            ac_state           <= s_0;
            stage_counter      <= 0;
            stage_counter_zero <= '1';
            finished_state     <= '0';
            seq_ac_sel         <= '1';
            refresh_done       <= '0';
            per_cs_init_seen   <= (others => '0');

            addr_cmd           <= int_pup_reset(c_seq_addr_cmd_config);

            if GENERATE_ADDITIONAL_DBG_RTL = 1 then
                nop_toggle_signal <= addr;
                nop_toggle_pin    <= 0;
                nop_toggle_value  <= '0';
            end if;

        elsif rising_edge(clk) then

            finished_state <= '0';
            refresh_done   <= '0';


            -- address / command path control
            -- if seq_ac_sel = 1 then sequencer has control of a/c
            -- if seq_ac_sel = 0 then memory controller has control of a/c
            seq_ac_sel        <= '1';

            if cal_complete = '1' then

                if cal_success = '1' or
                   GENERATE_ADDITIONAL_DBG_RTL = 0 then  -- hand over interface if cal successful or no debug enabled

                    seq_ac_sel    <= '0';

                end if;
            end if;

            -- if recalibration request then take control of a/c path
            if ctl_recalibrate_req = '1' then

                seq_ac_sel <= '1';

            end if;

            if state = s_reset then

                addr_cmd      <= reset(c_seq_addr_cmd_config);
                stage_counter <= 0;

            elsif state /= s_run_init_seq and
                  state /= s_non_operational then

                addr_cmd      <= deselect(c_seq_addr_cmd_config, -- configuration
                                          addr_cmd);             -- previous value

            end if;

            if (stage_counter = 1 or stage_counter = 0) then
                stage_counter_zero <= '1';
            else
                stage_counter_zero <= '0';
            end if;

            if stage_counter_zero /= '1' and state /= s_reset then
                stage_counter      <= stage_counter -1;
            else
                stage_counter_zero <= '0';
                case state is

                    when s_run_init_seq =>

                        per_cs_init_seen       <= (others => '0');  -- per cs test

                        if MEM_IF_MEMTYPE = "DDR" or MEM_IF_MEMTYPE = "DDR2" then

                            case ac_state is

                                -- JEDEC (JESD79-2E) stage c
                                when s_0 to s_9 =>
                                    ac_state      <= t_ac_state'succ(ac_state);
                                    stage_counter <= (TINIT_TCK/10)+1;
                                    addr_cmd      <= maintain_pd_or_sr(c_seq_addr_cmd_config,
                                                                       deselect(c_seq_addr_cmd_config, addr_cmd),
                                                                       2**MEM_IF_NUM_RANKS -1);

                                -- JEDEC (JESD79-2E) stage d
                                when s_10   =>
                                    ac_state      <= s_11;
                                    stage_counter <= c_init_prech_delay;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config, -- configuration
                                                              addr_cmd);             -- previous value

                                when s_11   =>
                                    ac_state       <= s_0;
                                    stage_counter  <= 1;
                                    finished_state <= '1';
                                -- finish sequence by going into s_program_cal_mrs state

                                when others =>
                                    ac_state <= s_0;
                            end case;

                        elsif MEM_IF_MEMTYPE = "DDR3" then  -- DDR3 specific initialisation sequence

                            case ac_state is

                                when s_0    =>
                                    ac_state       <= s_1;
                                    stage_counter  <= TINIT_RST + 1;
                                    addr_cmd       <= reset(c_seq_addr_cmd_config);

                                when s_1 to s_10 =>
                                    ac_state       <= t_ac_state'succ(ac_state);
                                    stage_counter  <= (TINIT_TCK/10) + 1;
                                    addr_cmd       <= maintain_pd_or_sr(c_seq_addr_cmd_config,
                                                                        deselect(c_seq_addr_cmd_config, addr_cmd),
                                                                        2**MEM_IF_NUM_RANKS -1);

                                when s_11   =>
                                    ac_state       <= s_12;
                                    stage_counter  <= c_init_prech_delay;
                                    addr_cmd       <= deselect(c_seq_addr_cmd_config, addr_cmd);

                                when s_12   =>
                                    ac_state       <= s_0;
                                    stage_counter  <= 1;
                                    finished_state <= '1';
                                -- finish sequence by going into s_program_cal_mrs state

                                when others =>
                                    ac_state       <= s_0;

                            end case;

                        else

                            report admin_report_prefix & "unsupported memory type specified" severity error;

                        end if;
                        -- end of initialisation sequence

                    when s_program_cal_mrs =>

                        if MEM_IF_MEMTYPE = "DDR2" then  -- DDR2 style mode register settings
                            case ac_state is
                                when s_0 =>
                                    ac_state      <= s_1;
                                    stage_counter <= 1;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config,                   -- configuration
                                                              addr_cmd);                               -- previous value

                                -- JEDEC (JESD79-2E) stage d
                                when s_1 =>
                                    ac_state      <= s_2;
                                    stage_counter <= c_trp_in_clks;
                                    addr_cmd      <= precharge_all(c_seq_addr_cmd_config,              -- configuration
                                                                   2**current_cs);                     -- rank

                                -- JEDEC (JESD79-2E) stage e
                                when s_2 =>
                                    ac_state      <= s_3;
                                    stage_counter <= c_tmrd_in_clks;
                                    addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                               2,                                      -- mode register number
                                                               int_mr2(c_max_mode_reg_index downto 0), -- mode register value
                                                               2**current_cs,                          -- rank
                                                               false);                                 -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage f
                                when s_3 =>
                                    ac_state      <= s_4;
                                    stage_counter <= c_tmrd_in_clks;
                                    addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                               3,                                      -- mode register number
                                                               int_mr3(c_max_mode_reg_index downto 0), -- mode register value
                                                               2**current_cs,                          -- rank
                                                               false);                                 -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage g
                                when s_4 =>
                                    ac_state                  <= s_5;
                                    stage_counter             <= c_tmrd_in_clks;
                                    v_mr_overload             := int_mr1(c_max_mode_reg_index downto 0);
                                    v_mr_overload(0)          := '0';    -- override DLL enable
                                    v_mr_overload(9 downto 7) := "000";  -- required in JESD79-2E (but not in JESD79-2B)
                                    addr_cmd                  <= load_mode(c_seq_addr_cmd_config,              -- configuration
                                                                           1,                                  -- mode register number
                                                                           v_mr_overload ,                     -- mode register value
                                                                           2**current_cs,                      -- rank
                                                                           false);                             -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage h
                                when s_5 =>
                                    ac_state      <= s_6;
                                    stage_counter <= c_tmod_in_clks;
                                    addr_cmd      <= dll_reset(c_seq_addr_cmd_config,                  -- configuration
                                                               int_mr0(c_max_mode_reg_index downto 0), -- mode register value
                                                               2**current_cs,                          -- rank
                                                               false);                                 -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage i
                                when s_6 =>
                                    ac_state      <= s_7;
                                    stage_counter <= c_trp_in_clks;
                                    addr_cmd      <= precharge_all(c_seq_addr_cmd_config,              -- configuration
                                                                   2**MEM_IF_NUM_RANKS - 1);           -- rank(s)

                                -- JEDEC (JESD79-2E) stage j
                                when s_7 =>
                                    ac_state      <= s_8;
                                    stage_counter <= c_trfc_min_in_clks;
                                    addr_cmd      <= refresh(c_seq_addr_cmd_config,                    -- configuration
                                                             addr_cmd,                                 -- previous value
                                                             2**current_cs);                           -- rank

                                -- JEDEC (JESD79-2E) stage j - second refresh
                                when s_8 =>
                                    ac_state      <= s_9;
                                    stage_counter <= c_trfc_min_in_clks;
                                    addr_cmd      <= refresh(c_seq_addr_cmd_config,                    -- configuration
                                                             addr_cmd,                                 -- previous value
                                                             2**current_cs);                           -- rank

                                -- JEDEC (JESD79-2E) stage k
                                when s_9 =>
                                    ac_state         <= s_10;
                                    stage_counter    <= c_tmrd_in_clks;

                                    v_mr_overload    := int_mr0(c_max_mode_reg_index downto 3) & "010";   -- override to burst length 4
                                    v_mr_overload(8) := '0';                                              -- required in JESD79-2E
                                    addr_cmd         <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                                  0,                                      -- mode register number
                                                                  v_mr_overload,                          -- mode register value
                                                                  2**current_cs,                          -- rank
                                                                  false);                                 -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage l - wait 200 cycles
                                when s_10 =>
                                    ac_state      <= s_11;
                                    stage_counter <= 200;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config,                   -- configuration
                                                              addr_cmd);                               -- previous value

                                -- JEDEC (JESD79-2E) stage l - OCD default
                                when s_11 =>
                                    ac_state                  <= s_12;
                                    stage_counter             <= c_tmrd_in_clks;
                                    v_mr_overload             := int_mr1(c_max_mode_reg_index downto 0);
                                    v_mr_overload(9 downto 7) := "111"; -- OCD calibration default (i.e. OCD unused)
                                    v_mr_overload(0)          := '0';   -- override for DLL enable
                                    addr_cmd                  <= load_mode(c_seq_addr_cmd_config,      -- configuration
                                                                           1,                          -- mode register number
                                                                           v_mr_overload ,             -- mode register value
                                                                           2**current_cs,              -- rank
                                                                           false);                     -- remap address and bank address

                                -- JEDEC (JESD79-2E) stage l - OCD cal exit
                                when s_12   =>
                                    ac_state                  <= s_13;
                                    stage_counter             <= c_tmod_in_clks;
                                    v_mr_overload             := int_mr1(c_max_mode_reg_index downto 0);
                                    v_mr_overload(9 downto 7) := "000"; -- OCD calibration exit
                                    v_mr_overload(0)          := '0';   -- override for DLL enable
                                    addr_cmd                  <= load_mode(c_seq_addr_cmd_config,      -- configuration
                                                                           1,                          -- mode register number
                                                                           v_mr_overload ,             -- mode register value
                                                                           2**current_cs,              -- rank
                                                                           false);                     -- remap address and bank address

                                    per_cs_init_seen(current_cs) <= '1';

                                -- JEDEC (JESD79-2E) stage m - cal finished
                                when s_13   =>
                                    ac_state          <= s_0;
                                    stage_counter     <= 1;
                                    finished_state    <= '1';

                                when others =>
                                    null;
                            end case;

                        elsif MEM_IF_MEMTYPE = "DDR" then  -- DDR style mode register setting following JEDEC (JESD79E)

                            case ac_state is
                                when s_0 =>
                                    ac_state      <= s_1;
                                    stage_counter <= 1;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config,                   -- configuration
                                                              addr_cmd);                               -- previous value

                                when s_1 =>
                                    ac_state      <= s_2;
                                    stage_counter <= c_trp_in_clks;
                                    addr_cmd      <= precharge_all(c_seq_addr_cmd_config,              -- configuration
                                                                   2**current_cs);                     -- rank(s)

                                when s_2 =>
                                    ac_state          <= s_3;
                                    stage_counter     <= c_tmrd_in_clks;
                                    v_mr_overload     := int_mr1(c_max_mode_reg_index downto 0);
                                    v_mr_overload(0)  := '0'; -- override DLL enable
                                    addr_cmd          <= load_mode(c_seq_addr_cmd_config,              -- configuration
                                                                   1,                                  -- mode register number
                                                                   v_mr_overload ,                     -- mode register value
                                                                   2**current_cs,                      -- rank
                                                                   false);                             -- remap address and bank address

                                when s_3 =>
                                    ac_state      <= s_4;
                                    stage_counter <= c_tmod_in_clks;
                                    addr_cmd      <= dll_reset(c_seq_addr_cmd_config,                  -- configuration
                                                               int_mr0(c_max_mode_reg_index downto 0), -- mode register value
                                                               2**current_cs,                          -- rank
                                                               false);                                 -- remap address and bank address

                                when s_4 =>
                                    ac_state      <= s_5;
                                    stage_counter <= c_trp_in_clks;
                                    addr_cmd      <= precharge_all(c_seq_addr_cmd_config,              -- configuration
                                                                   2**MEM_IF_NUM_RANKS - 1);           -- rank(s)

                                when s_5 =>
                                    ac_state      <= s_6;
                                    stage_counter <= c_trfc_min_in_clks;
                                    addr_cmd      <= refresh(c_seq_addr_cmd_config,                    -- configuration
                                                             addr_cmd,                                 -- previous value
                                                             2**current_cs);                           -- rank

                                when s_6 =>
                                    ac_state      <= s_7;
                                    stage_counter <= c_trfc_min_in_clks;
                                    addr_cmd      <= refresh(c_seq_addr_cmd_config,                    -- configuration
                                                             addr_cmd,                                 -- previous value
                                                             2**current_cs);                           -- rank

                                when s_7 =>
                                    ac_state      <= s_8;
                                    stage_counter <= c_tmrd_in_clks;

                                    v_mr_overload    := int_mr0(c_max_mode_reg_index downto 3) & "010";   -- override to burst length 4

                                    addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                               0,                                      -- mode register number
                                                               v_mr_overload,                          -- mode register value
                                                               2**current_cs,                          -- rank
                                                               false);                                 -- remap address and bank address

                                when s_8 =>
                                    ac_state      <= s_9;
                                    stage_counter <= 200;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config,                   -- configuration
                                                              addr_cmd);                               -- previous value

                                    per_cs_init_seen(current_cs) <= '1';

                                when s_9 =>
                                    ac_state          <= s_0;
                                    stage_counter     <= 1;
                                    finished_state    <= '1';

                                when others =>
                                    null;
                            end case;

                        elsif MEM_IF_MEMTYPE = "DDR3" then

                            case ac_state is

                                when s_0    =>
                                    ac_state      <= s_1;
                                    stage_counter <= c_trp_in_clks;
                                    addr_cmd      <= deselect(c_seq_addr_cmd_config,                    -- configuration
                                                              addr_cmd);                                -- previous value

                                when s_1    =>
                                    ac_state      <= s_2;
                                    stage_counter <= c_tmrd_in_clks;
                                    addr_cmd      <= load_mode(c_seq_addr_cmd_config,                   -- configuration
                                                               2,                                       -- mode register number
                                                               int_mr2(c_max_mode_reg_index downto 0),  -- mode register value
                                                               2**current_cs,                           -- rank
                                                               false);                                  -- remap address and bank address

                                when s_2    =>
                                    ac_state      <= s_3;
                                    stage_counter <= c_tmrd_in_clks;
                                    addr_cmd      <= load_mode(c_seq_addr_cmd_config,                   -- configuration
                                                               3,                                       -- mode register number
                                                               int_mr3(c_max_mode_reg_index downto 0),  -- mode register value
                                                               2**current_cs,                           -- rank
                                                               false);                                  -- remap address and bank address

                                when s_3    =>
                                    ac_state          <= s_4;
                                    stage_counter     <= c_tmrd_in_clks;

                                    v_mr_overload     := int_mr1(c_max_mode_reg_index downto 0);
                                    v_mr_overload(0)  := '0'; -- Override for DLL enable
                                    v_mr_overload(12) := '0'; -- output buffer enable.
                                    v_mr_overload(7)  := '0'; -- Disable Write levelling

                                    addr_cmd          <= load_mode(c_seq_addr_cmd_config,               -- configuration
                                                                   1,                                   -- mode register number
                                                                   v_mr_overload,                       -- mode register value
                                                                   2**current_cs,                       -- rank
                                                                   false);                              -- remap address and bank address

                                when s_4    =>
                                    ac_state                  <= s_5;
                                    stage_counter             <= c_tmod_in_clks;

                                    v_mr_overload             := int_mr0(c_max_mode_reg_index downto 0);

                                    v_mr_overload(1 downto 0) := "01"; -- override to on the fly burst length choice
                                    v_mr_overload(7)          := '0';  -- test mode not enabled
                                    v_mr_overload(8)          := '1';  -- DLL reset

                                    addr_cmd                  <= load_mode(c_seq_addr_cmd_config,       -- configuration
                                                                           0,                           -- mode register number
                                                                           v_mr_overload,               -- mode register value
                                                                           2**current_cs,               -- rank
                                                                           false);                      -- remap address and bank address


                                when s_5    =>
                                    ac_state      <= s_6;
                                    stage_counter <= c_zq_init_duration_clks;
                                    addr_cmd      <= ZQCL(c_seq_addr_cmd_config,                        -- configuration
                                                          2**current_cs);                               -- rank

                                    per_cs_init_seen(current_cs) <= '1';

                                when s_6          =>
                                    ac_state       <= s_0;
                                    stage_counter  <= 1;
                                    finished_state <= '1';

                                when others =>
                                    ac_state <= s_0;

                            end case;

                        else

                            report admin_report_prefix & "unsupported memory type specified" severity error;

                        end if;

                        -- end of s_program_cal_mrs case

                    when s_prog_user_mrs =>

                        case ac_state is
                            when s_0 =>
                                ac_state      <= s_1;
                                stage_counter <= 1;
                                addr_cmd      <= deselect(c_seq_addr_cmd_config,                   -- configuration
                                                              addr_cmd);                           -- previous value

                            when s_1 =>

                                if MEM_IF_MEMTYPE = "DDR" then -- for DDR memory skip MR2/3 because not present
                                    ac_state      <= s_4;
                                else                           -- for DDR2/DDR3 all MRs programmed
                                    ac_state      <= s_2;
                                end if;

                                stage_counter <= c_trp_in_clks;
                                addr_cmd      <= precharge_all(c_seq_addr_cmd_config,              -- configuration
                                                               2**MEM_IF_NUM_RANKS - 1);           -- rank(s)

                            when s_2 =>
                                ac_state      <= s_3;
                                stage_counter <= c_tmrd_in_clks;
                                addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                           2,                                      -- mode register number
                                                           int_mr2(c_max_mode_reg_index downto 0), -- mode register value
                                                           2**current_cs,                          -- rank
                                                           false);                                 -- remap address and bank address

                            when s_3 =>
                                ac_state      <= s_4;
                                stage_counter <= c_tmrd_in_clks;
                                addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                           3,                                      -- mode register number
                                                           int_mr3(c_max_mode_reg_index downto 0), -- mode register value
                                                           2**current_cs,                          -- rank
                                                           false);                                 -- remap address and bank address

                                if to_integer(unsigned(int_mr3)) /= 0 then
                                    report admin_report_prefix & " mode register 3 is expected to have a value of 0 but has a value of : " &
                                                                 integer'image(to_integer(unsigned(int_mr3))) severity warning;
                                end if;

                            when s_4 =>
                                ac_state      <= s_5;
                                stage_counter <= c_tmrd_in_clks;
                                addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                           1,                                      -- mode register number
                                                           int_mr1(c_max_mode_reg_index downto 0), -- mode register value
                                                           2**current_cs,                          -- rank
                                                           false);                                 -- remap address and bank address

                                if (MEM_IF_DQSN_EN = 0) and (int_mr1(10) = '0') and (MEM_IF_MEMTYPE = "DDR2") then
                                    report admin_report_prefix & "mode register and generic conflict:" & LF &
                                                                 "* generic MEM_IF_DQSN_EN is set to 'disable' DQSN" & LF &
                                                                 "* user mode register MEM_IF_MR1 bit 10 is set to 'enable' DQSN" severity warning;
                                end if;

                            when s_5 =>
                                ac_state      <= s_6;
                                stage_counter <= c_tmod_in_clks;
                                addr_cmd      <= load_mode(c_seq_addr_cmd_config,                  -- configuration
                                                           0,                                      -- mode register number
                                                           int_mr0(c_max_mode_reg_index downto 0), -- mode register value
                                                           2**current_cs,                          -- rank
                                                           false);                                 -- remap address and bank address

                            when s_6 =>
                                ac_state      <= s_7;
                                stage_counter <= 1;

                            when s_7 =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;

                        end case;

                        -- end of s_prog_user_mr case

                     when s_access_precharge =>

                         case ac_state is
                             when s_0 =>
                                 ac_state      <= s_1;
                                 -- #pb_del to ensure we do not violate read to pre-charge or write to pre-charge timing this is max (tWR, tRTP)
                                 stage_counter <= 10;
                                 addr_cmd      <= deselect(c_seq_addr_cmd_config,                      -- configuration
                                                           addr_cmd);                                  -- previous value

                             when s_1 =>
                                 ac_state      <= s_2;
                                 stage_counter <= c_trp_in_clks;
                                 addr_cmd      <= precharge_all(c_seq_addr_cmd_config,                 -- configuration
                                                                2**MEM_IF_NUM_RANKS - 1);              -- rank(s)

                             when s_2 =>
                                 ac_state       <= s_0;
                                 stage_counter  <= 1;
                                 finished_state <= '1';

                             when others =>
                                 ac_state <= s_0;
                         end case;

                    when s_topup_refresh | s_refresh =>

                        case ac_state is
                            when s_0 =>
                                ac_state      <= s_1;
                                stage_counter <= 1;

                            when s_1 =>
                                ac_state      <= s_2;
                                stage_counter <= 1;
                                addr_cmd      <= refresh(c_seq_addr_cmd_config,                        -- configuration
                                                         addr_cmd,                                     -- previous value
                                                         2**MEM_IF_NUM_RANKS - 1);                     -- rank

                            when s_2 =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;
                        end case;

                    when s_topup_refresh_done | s_refresh_done =>

                        case ac_state is
                            when s_0 =>
                                ac_state      <= s_1;
                                stage_counter <= c_trfc_min_in_clks;
                                refresh_done  <= '1';      -- ensure trfc not violated
                            when s_1 =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;
                        end case;

                    -- #pb_del this is a bit excessive but ensures ZQCS interval is not violated for multiple DDR3 chips
                    when s_zq_cal_short     =>

                        case ac_state is
                            when s_0    =>
                                ac_state      <= s_1;
                                stage_counter <= 1;

                            when s_1    =>
                                ac_state      <= s_2;
                                stage_counter <= c_tzqcs;
                                addr_cmd      <= ZQCS(c_seq_addr_cmd_config,                  -- configuration
                                                      2**current_cs);                         -- all ranks

                            when s_2    =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;

                        end case;

                    when s_access_act =>

                        case ac_state is
                            when s_0 =>
                                ac_state      <= s_1;
                                stage_counter <= c_trrd_min_in_clks;

                            when s_1 =>
                                ac_state      <= s_2;
                                stage_counter <= c_trcd_min_in_clks;
                                addr_cmd      <= activate(c_seq_addr_cmd_config,                       -- configuration
                                                          addr_cmd,                                    -- previous value
                                                          MEM_IF_CAL_BANK,                             -- bank
                                                          MEM_IF_CAL_BASE_ROW,                         -- row address
                                                          2**current_cs);                              -- rank

                            when s_2 =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;
                        end case;

                    -- counter to delay transition from s_idle to s_refresh - this is to ensure a refresh command is not sent
                    -- just as we enter operational state (could cause a trfc violation)
                    when s_dummy_wait =>

                        case ac_state is
                            when s_0 =>
                                ac_state      <= s_1;
                                stage_counter <= c_max_wait_value;

                            when s_1 =>
                                ac_state       <= s_0;
                                stage_counter  <= 1;
                                finished_state <= '1';

                            when others =>
                                ac_state <= s_0;
                        end case;

                    when s_reset =>

                        stage_counter <= 1;

                        -- default some s_non_operational signals
                        if GENERATE_ADDITIONAL_DBG_RTL = 1 then
                            nop_toggle_signal <= addr;
                            nop_toggle_pin    <= 0;
                            nop_toggle_value  <= '0';
                        end if;

                    when s_non_operational =>  -- if failed then output a recognised pattern to the memory (Only executes if GENERATE_ADDITIONAL_DBG_RTL set)

                        addr_cmd      <= deselect(c_seq_addr_cmd_config,                               -- configuration
                                                  addr_cmd);                                           -- previous value

                        if NON_OP_EVAL_MD = "PIN_FINDER" then  -- toggle pins in turn for 200 memory clk cycles

                            stage_counter  <= 200/(DWIDTH_RATIO/2);  -- 200 mem_clk cycles

                            case nop_toggle_signal is

                                when addr =>

                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, addr,  '0');
                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, addr,  nop_toggle_value, nop_toggle_pin);

                                    nop_toggle_value <= not nop_toggle_value;

                                    if nop_toggle_value = '1' then
                                        if nop_toggle_pin = MEM_IF_ADDR_WIDTH-1 then
                                            nop_toggle_signal <= ba;
                                            nop_toggle_pin    <= 0;
                                        else
                                            nop_toggle_pin    <= nop_toggle_pin + 1;
                                        end if;
                                    end if;

                                when ba =>

                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, ba,  '0');
                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, ba,  nop_toggle_value, nop_toggle_pin);

                                    nop_toggle_value <= not nop_toggle_value;

                                    if nop_toggle_value = '1' then
                                        if nop_toggle_pin = MEM_IF_BANKADDR_WIDTH-1 then
                                            nop_toggle_signal <= cas_n;
                                            nop_toggle_pin    <= 0;
                                        else
                                            nop_toggle_pin    <= nop_toggle_pin + 1;
                                        end if;
                                    end if;

                                when cas_n =>

                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, cas_n, nop_toggle_value);

                                    nop_toggle_value <= not nop_toggle_value;

                                    if nop_toggle_value = '1' then
                                        nop_toggle_signal <= ras_n;
                                    end if;

                                when ras_n =>

                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, ras_n, nop_toggle_value);

                                    nop_toggle_value <= not nop_toggle_value;

                                    if nop_toggle_value = '1' then
                                        nop_toggle_signal <= we_n;
                                    end if;

                                when we_n =>

                                    addr_cmd <= mask (c_seq_addr_cmd_config, addr_cmd, we_n, nop_toggle_value);

                                    nop_toggle_value <= not nop_toggle_value;

                                    if nop_toggle_value = '1' then
                                        nop_toggle_signal <= addr;
                                    end if;

                                when others =>

                                    report admin_report_prefix & " an attempt to toggle a non addr/cmd pin detected" severity failure;

                            end case;

                        elsif NON_OP_EVAL_MD = "SI_EVALUATOR" then  -- toggle all addr/cmd pins at fmax

                            stage_counter      <= 0;  -- every mem_clk cycle
                            stage_counter_zero <= '1';

                            v_nop_ac_0 := mask (c_seq_addr_cmd_config, addr_cmd,   addr,  nop_toggle_value);
                            v_nop_ac_0 := mask (c_seq_addr_cmd_config, v_nop_ac_0, ba,    nop_toggle_value);
                            v_nop_ac_0 := mask (c_seq_addr_cmd_config, v_nop_ac_0, we_n,  nop_toggle_value);
                            v_nop_ac_0 := mask (c_seq_addr_cmd_config, v_nop_ac_0, ras_n, nop_toggle_value);
                            v_nop_ac_0 := mask (c_seq_addr_cmd_config, v_nop_ac_0, cas_n, nop_toggle_value);

                            v_nop_ac_1 := mask (c_seq_addr_cmd_config, addr_cmd,   addr,  not nop_toggle_value);
                            v_nop_ac_1 := mask (c_seq_addr_cmd_config, v_nop_ac_1, ba,    not nop_toggle_value);
                            v_nop_ac_1 := mask (c_seq_addr_cmd_config, v_nop_ac_1, we_n,  not nop_toggle_value);
                            v_nop_ac_1 := mask (c_seq_addr_cmd_config, v_nop_ac_1, ras_n, not nop_toggle_value);
                            v_nop_ac_1 := mask (c_seq_addr_cmd_config, v_nop_ac_1, cas_n, not nop_toggle_value);

                            for i in 0 to DWIDTH_RATIO/2 - 1 loop
                                if i mod 2 = 0 then
                                    addr_cmd(i) <= v_nop_ac_0(i);
                                else
                                    addr_cmd(i) <= v_nop_ac_1(i);
                                end if;
                            end loop;

                            if DWIDTH_RATIO = 2 then
                                nop_toggle_value <= not nop_toggle_value;
                            end if;

                        else

                            report admin_report_prefix & "unknown non-operational evaluation mode " & NON_OP_EVAL_MD severity failure;

                        end if;

                    when others =>

                        addr_cmd      <= deselect(c_seq_addr_cmd_config,                               -- configuration
                                                  addr_cmd);                                           -- previous value
                        stage_counter <= 1;
                        ac_state <= s_0;

                end case;
            end if;

        end if;
    end process;

-- -------------------------------------------------------------------
-- output packing of mode register settings and enabling of ODT
-- -------------------------------------------------------------------
    process (int_mr0, int_mr1, int_mr2, int_mr3, mem_init_complete)
    begin
        admin_regs_status_rec.mr0       <= int_mr0;
        admin_regs_status_rec.mr1       <= int_mr1;
        admin_regs_status_rec.mr2       <= int_mr2;
        admin_regs_status_rec.mr3       <= int_mr3;
        admin_regs_status_rec.init_done <= mem_init_complete;
        enable_odt                      <= int_mr1(2) or int_mr1(6); -- if ODT enabled in MR settings (i.e. MR1 bits 2 or 6 /= 0)
    end process;

-- --------------------------------------------------------------------------------
-- generation of handshake signals with ctrl, dgrb and dgwb blocks (this includes
-- command ack, command done for ctrl and access grant for dgrb/dgwb)
-- --------------------------------------------------------------------------------
    process (rst_n, clk)
    begin
        if rst_n = '0' then

            admin_ctrl    <= defaults;
            ac_access_gnt <= '0';

        elsif rising_edge(clk) then

            admin_ctrl    <= defaults;
            ac_access_gnt <= '0';

            admin_ctrl.command_ack  <= command_started;
            admin_ctrl.command_done <= command_done;

            if state = s_access then
                ac_access_gnt <= '1';
            end if;

        end if;

    end process;

end architecture struct;
