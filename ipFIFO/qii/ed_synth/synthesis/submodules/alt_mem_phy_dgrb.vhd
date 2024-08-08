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
--/* Legal Notice: (C)2007 Altera Corporation. All rights reserved.  Your
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
--  Title           : dgrb

--  File:  $RCSfile : alt_mem_phy_dgrb.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : data gatherer (read bias) [dgrb] block for the non-levelling
--                    AFI PHY sequencer
--                    This block handles all calibration commands which require
--                    memory read operations.
--
--            These include:
--                    Resync phase calibration - sweep of phases, calculation of
--                                             result and optional storage to iram
--                    Postamble calibration - clock cycle calibration of the postamble
--                                            enable signal
--                    Read data valid signal alignment
--                    Calculation of advertised read and write latencies
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

-- The iram address package (alt_mem_phy_iram_addr_pkg) is used to define the base addresses used
-- for iram writes during calibration
--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
    use work.alt_mem_phy_iram_addr_pkg.all;
--#end

-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
    use work.alt_mem_phy_constants_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_dgrb")
entity alt_mem_phy_dgrb is
--#end
    generic (
        MEM_IF_DQS_WIDTH               : natural;
        MEM_IF_DQ_PER_DQS              : natural;
        MEM_IF_DWIDTH                  : natural;
        MEM_IF_DM_WIDTH                : natural;
        MEM_IF_DQS_CAPTURE             : natural;
        MEM_IF_ADDR_WIDTH              : natural;
        MEM_IF_BANKADDR_WIDTH          : natural;
        MEM_IF_NUM_RANKS               : natural;
        MEM_IF_MEMTYPE                 : string;

        ADV_LAT_WIDTH                  : natural;

        CLOCK_INDEX_WIDTH              : natural;

        DWIDTH_RATIO                   : natural;
        PRESET_RLAT                    : natural;

        PLL_STEPS_PER_CYCLE            : natural; -- number of PLL phase steps per PHY clock cycle

        SIM_TIME_REDUCTIONS            : natural;
        GENERATE_ADDITIONAL_DBG_RTL    : natural;

        -- #pb_del known working CODVW parameters:
        PRESET_CODVW_PHASE             : natural;
        PRESET_CODVW_SIZE              : natural;

        -- base column address to which calibration data is written
        -- memory at MEM_IF_CAL_BASE_COL - MEM_IF_CAL_BASE_COL + C_CAL_DATA_LEN - 1
        -- is assumed to contain the proper data
        MEM_IF_CAL_BANK                : natural; -- bank to which calibration data is written
        MEM_IF_CAL_BASE_COL            : natural;
        EN_OCT                         : natural
    );
    port (
        -- clk / reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        -- control interface
        dgrb_ctrl                      : out   t_ctrl_stat;
        ctrl_dgrb                      : in    t_ctrl_command;
        parameterisation_rec           : in    t_algm_paramaterisation;

        -- PLL reconfig interface
        phs_shft_busy                  : in    std_logic;
        seq_pll_inc_dec_n              : out   std_logic;
        seq_pll_select                 : out   std_logic_vector(CLOCK_INDEX_WIDTH - 1 DOWNTO 0);
        seq_pll_start_reconfig         : out   std_logic;
        pll_resync_clk_index           : in    std_logic_vector(CLOCK_INDEX_WIDTH - 1 downto 0); -- PLL phase used to select resync clock
        pll_measure_clk_index          : in    std_logic_vector(CLOCK_INDEX_WIDTH - 1 downto 0); -- PLL phase used to select mimic / aka measure clock

        -- iram 'push' interface
        dgrb_iram                      : out   t_iram_push;
        iram_push_done                 : in    std_logic;

        -- addr/cmd output for write commands
        dgrb_ac                        : out t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);

        -- admin block req/gnt interface
        dgrb_ac_access_req             : out   std_logic;
        dgrb_ac_access_gnt             : in    std_logic;

        -- RDV latency controls
        seq_rdata_valid_lat_inc        : out   std_logic;
        seq_rdata_valid_lat_dec        : out   std_logic;

        -- POA latency controls
        seq_poa_lat_dec_1x             : out   std_logic_vector(MEM_IF_DQS_WIDTH - 1 downto 0);
        seq_poa_lat_inc_1x             : out   std_logic_vector(MEM_IF_DQS_WIDTH - 1 downto 0);

        -- read datapath interface
        rdata_valid                    : in    std_logic_vector(DWIDTH_RATIO/2 - 1 downto 0);
        rdata                          : in    std_logic_vector(DWIDTH_RATIO * MEM_IF_DWIDTH - 1 downto 0);
        doing_rd                       : out   std_logic_vector(MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 downto 0);
        rd_lat                         : out   std_logic_vector(ADV_LAT_WIDTH - 1 downto 0);

        -- advertised write latency
        wd_lat                         : out   std_logic_vector(ADV_LAT_WIDTH - 1 downto 0);

        -- OCT control
        seq_oct_value                  : out   std_logic;
        dgrb_wdp_ovride                : out   std_logic;

        -- mimic path interface
        seq_mmc_start                  : out   std_logic;
        mmc_seq_done                   : in    std_logic;
        mmc_seq_value                  : in    std_logic;

        -- calibration byte lane select (reserved for future use - RFU)
        ctl_cal_byte_lanes             : in    std_logic_vector(MEM_IF_NUM_RANKS * MEM_IF_DQS_WIDTH  - 1 downto 0);

        -- odt settings per chip select
        odt_settings                   : in    t_odt_array(0 to MEM_IF_NUM_RANKS-1);

        -- signal to identify if a/c nt setting is correct (set after wr_lat calculation)
        -- NOTE: labelled nt for future scalability to quarter rate interfaces
        dgrb_ctrl_ac_nt_good           : out   std_logic;

        -- status signals on calibrated cdvw
        dgrb_mmi                       : out   t_dgrb_mmi
    );

end entity;

--#mw_prefix ("alt_mem_phy_dgrb")
architecture struct of alt_mem_phy_dgrb is
--#end

-- ------------------------------------------------------------------
--  constant declarations
-- ------------------------------------------------------------------

    constant c_seq_addr_cmd_config      : t_addr_cmd_config_rec := set_config_rec(MEM_IF_ADDR_WIDTH, MEM_IF_BANKADDR_WIDTH, MEM_IF_NUM_RANKS, DWIDTH_RATIO, MEM_IF_MEMTYPE);

    -- command/result length
    constant c_command_result_len       : natural := 8;

    -- burst characteristics and latency characteristics
    constant c_max_read_lat             : natural := 2**rd_lat'length - 1;  -- maximum read latency in phy clock-cycles

    -- training pattern characteristics
    constant c_cal_mtp_len              : natural := 16;
    constant c_cal_mtp                  : std_logic_vector(c_cal_mtp_len - 1 downto 0) := x"30F5";
    constant c_cal_mtp_t                : natural := c_cal_mtp_len / DWIDTH_RATIO; -- number of phy-clk cycles required to read BTP

    -- read/write latency defaults
    constant c_default_rd_lat_slv       : std_logic_vector(ADV_LAT_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(c_default_rd_lat, ADV_LAT_WIDTH));
    constant c_default_wd_lat_slv       : std_logic_vector(ADV_LAT_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(c_default_wr_lat, ADV_LAT_WIDTH));

    -- tracking reporting parameters
    constant c_max_rsc_drift_in_phases    : natural := 127;  -- this must be a value of < 2^10 - 1 because of the range of signal codvw_trk_shift


    -- Returns '1' when boolean b is True; '0' otherwise.
    function active_high(b : in boolean) return std_logic is
        variable r : std_logic;
    begin
        if b then
            r := '1';
        else
            r := '0';
        end if;

        return r;
    end function;

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant dgrb_report_prefix        : string  := "alt_mem_phy_seq (dgrb) : ";
--#end

    -- Return the number of clock periods the resync clock should sweep.
    --
    -- On half-rate systems and in DQS-capture based systems a 720
    -- to guarantee the resync window can be properly observed.
    function rsc_sweep_clk_periods return natural is
        variable v_num_periods : natural;
    begin
        if DWIDTH_RATIO = 2 then
            if MEM_IF_DQS_CAPTURE = 1 then  -- families which use DQS capture require a 720 degree sweep for FR to show a window
                v_num_periods := 2;
            else
                v_num_periods := 1;
            end if;
        elsif DWIDTH_RATIO = 4 then
            v_num_periods := 2;
        else
            report dgrb_report_prefix & "unsupported DWIDTH_RATIO." severity failure;
        end if;

        return v_num_periods;
    end function;


    -- window for PLL sweep
    -- #pb_del note that for other families with dqs based capture a 720 degrees sweep may be required
    -- #pb_del in this case max_phase_shifts is 2*PLL_STEPS_PER_CYCLE
    constant c_max_phase_shifts        : natural := rsc_sweep_clk_periods*PLL_STEPS_PER_CYCLE;

    constant c_pll_phs_inc              : std_logic := '1';
    constant c_pll_phs_dec              : std_logic := not c_pll_phs_inc;

-- ------------------------------------------------------------------
--  type declarations
-- ------------------------------------------------------------------

    -- dgrb main state machine
    type t_dgrb_state is (
        -- idle state
        s_idle,
        -- request access to memory address/command bus from the admin block
        s_wait_admin,
        -- relinquish address/command bus access
        s_release_admin,
        -- wind back resync phase to a 'zero' point
        s_reset_cdvw,
        -- perform resync phase sweep (used for MTP alignment checking and actual RRP sweep)
        s_test_phases,
        -- processing to when checking MTP alignment
        s_read_mtp,
        -- processing for RRP (read resync phase) sweep
        s_seek_cdvw,
        -- clock cycle alignment of read data valid signal
        s_rdata_valid_align,
        -- calculate advertised read latency
        s_adv_rd_lat_setup,
        s_adv_rd_lat,
        -- calculate advertised write latency
        s_adv_wd_lat,
        -- postamble clock cycle calibration
        s_poa_cal,
        -- tracking - setup and periodic update
        s_track
    );

    -- dgrb slave state machine for addr/cmd signals
    type t_ac_state is (
        -- idle state
        s_ac_idle,
        -- wait X cycles (issuing NOP command) to flush address/command and DQ buses
        s_ac_relax,
        -- read MTP pattern
        s_ac_read_mtp,
        -- read pattern for read data valid alignment
        s_ac_read_rdv,
        -- read pattern for POA calibration
        s_ac_read_poa_mtp,
        -- read pattern to calculate advertised write latency
        s_ac_read_wd_lat
    );

    -- dgrb slave state machine for read resync phase calibration
    type t_resync_state is (
        -- idle state
        s_rsc_idle,
        -- shift resync phase by one
        s_rsc_next_phase,
        -- start test sequence for current pin and current phase
        s_rsc_test_phase,
        -- flush the read datapath
        s_rsc_wait_for_idle_dimm,  -- wait until no longer driving
        s_rsc_flush_datapath,      -- flush a/c path
        -- sample DQ data to test phase
        s_rsc_test_dq,
        -- reset rsc phase to a zero position
        s_rsc_reset_cdvw,
        s_rsc_rewind_phase,
        -- calculate the centre of resync window
        s_rsc_cdvw_calc,
        s_rsc_cdvw_wait,  -- wait for calc result
        -- set rsc clock phase to centre of data valid window
        s_rsc_seek_cdvw,
        -- wait until all results written to iram
        s_rsc_wait_iram  -- only entered if GENERATE_ADDITIONAL_DBG_RTL = 1
    );

    -- record definitions for window processing
    type t_win_processing_status is ( calculating,
                                      valid_result,
                                      no_invalid_phases,
                                      multiple_equal_windows,
                                      no_valid_phases
                                    );

    type t_window_processing is record
        working_window        : std_logic_vector(  c_max_phase_shifts - 1 downto 0);
        first_good_edge       : natural range 0 to c_max_phase_shifts - 1;             -- pointer to first detected good edge
        current_window_start  : natural range 0 to c_max_phase_shifts - 1;
        current_window_size   : natural range 0 to c_max_phase_shifts - 1;
        current_window_centre : natural range 0 to c_max_phase_shifts - 1;
        largest_window_start  : natural range 0 to c_max_phase_shifts - 1;
        largest_window_size   : natural range 0 to c_max_phase_shifts - 1;
        largest_window_centre : natural range 0 to c_max_phase_shifts - 1;
        current_bit           : natural range 0 to c_max_phase_shifts - 1;
        window_centre_update  : std_logic;
        last_bit_value        : std_logic;
        valid_phase_seen      : boolean;
        invalid_phase_seen    : boolean;
        first_cycle           : boolean;
        multiple_eq_windows   : boolean;
        found_a_good_edge     : boolean;
        status                : t_win_processing_status;
        windows_seen          : natural range 0 to c_max_phase_shifts/2 - 1;
    end record;

-- ------------------------------------------------------------------
--  function and procedure definitions
-- ------------------------------------------------------------------

    -- Returns a string representation of a std_logic_vector.
    -- Not synthesizable.
    function str(v: std_logic_vector) return string is
        variable str_value : string (1 to v'length);
        variable str_len   : integer;
        variable c         : character;
    begin
        str_len := 1;
        for i in v'range loop
            case v(i) is
                when '0'    => c := '0';
                when '1'    => c := '1';
                when others => c := '?';
            end case;

            str_value(str_len) := c;
            str_len            := str_len + 1;
        end loop;
        return str_value;
    end str;


    --  functions and procedures for window processing
    -- #pb_del we need to add more comments to the below processes - btc

    function defaults return t_window_processing is
        variable output : t_window_processing;
    begin
        output.working_window        := (others => '1');
        output.last_bit_value        := '1';
        output.first_good_edge       := 0;
        output.current_window_start  := 0;
        output.current_window_size   := 0;
        output.current_window_centre := 0;
        output.largest_window_start  := 0;
        output.largest_window_size   := 0;
        output.largest_window_centre := 0;
        output.window_centre_update  := '1';
        output.current_bit           := 0;
        output.multiple_eq_windows   := false;
        output.valid_phase_seen      := false;
        output.invalid_phase_seen    := false;
        output.found_a_good_edge     := false;
        output.status                := no_valid_phases;
        output.first_cycle           := false;
        output.windows_seen          := 0;
        return output;
    end function defaults;


    procedure initialise_window_for_proc ( working : inout t_window_processing ) is
        variable v_working_window : std_logic_vector(  c_max_phase_shifts - 1 downto 0);
    begin
        v_working_window             := working.working_window;
        working                      := defaults;
        working.working_window       := v_working_window;
        working.status               := calculating;
        working.first_cycle          := true;
        working.window_centre_update := '1';
        working.windows_seen         := 0;
    end procedure initialise_window_for_proc;


    procedure shift_window (working    : inout t_window_processing;
                            num_phases : in    natural range 1 to c_max_phase_shifts
                           )
    is
    begin
        if working.working_window(0) = '0' then
            working.invalid_phase_seen   := true;
        else
            working.valid_phase_seen     := true;
        end if;

        -- general bit serial shifting of window and incrementing of current bit counter.
        if working.current_bit < num_phases - 1 then
            working.current_bit := working.current_bit + 1;
        else
            working.current_bit := 0;
        end if;

        working.last_bit_value  := working.working_window(0);
        working.working_window  := working.working_window(0) & working.working_window(working.working_window'high downto 1);

        --synopsis translate_off
        -- for simulation to make it simpler to see IF we are not using all the bits in the window
        working.working_window(working.working_window'high) := 'H';  -- for visual debug
        --synopsis translate_on
        working.working_window(num_phases -1) := working.last_bit_value;

        working.first_cycle    := false;
    end procedure shift_window;


    procedure find_centre_of_largest_data_valid_window
                             ( working    : inout t_window_processing;
                               num_phases : in    natural range 1 to c_max_phase_shifts
                              ) is
    begin
        if working.first_cycle = false then  -- not first call to procedure, then handle end conditions
            if working.current_bit = 0 and working.found_a_good_edge = false then  -- have been all way arround window  (circular)
                if working.valid_phase_seen = false then
                    working.status := no_valid_phases;
                elsif working.invalid_phase_seen = false then
                      working.status := no_invalid_phases;
                end if;
            elsif working.current_bit = working.first_good_edge then  -- if have found a good edge then complete a circular sweep to that edge
                if working.multiple_eq_windows = true then
                    working.status := multiple_equal_windows;
                else
                    working.status := valid_result;
                end if;
            end if;
        end if;

        -- start of a window condition
        if working.last_bit_value = '0' and working.working_window(0) = '1' then
            working.current_window_start  := working.current_bit;
            working.current_window_size   := working.current_window_size + 1;   -- equivalent to assigning to one because if not in a window then it is set to 0
            working.window_centre_update  := not working.window_centre_update;
            working.current_window_centre := working.current_bit;

            if working.found_a_good_edge /= true then                          -- if have not yet found a good edge then store this value
                working.first_good_edge   := working.current_bit;
                working.found_a_good_edge := true;
            end if;

        -- end of window conditions
        elsif working.last_bit_value = '1' and working.working_window(0) = '0' then

            if working.current_window_size > working.largest_window_size then

                working.largest_window_size   := working.current_window_size;
                working.largest_window_start  := working.current_window_start;
                working.largest_window_centre := working.current_window_centre;
                working.multiple_eq_windows   := false;

            elsif working.current_window_size = working.largest_window_size then

                working.multiple_eq_windows   := true;

            end if;

            -- put counter in here because start of window 1 is observed twice
            if working.found_a_good_edge = true then
                working.windows_seen := working.windows_seen + 1;
            end if;

            working.current_window_size  := 0;

        elsif working.last_bit_value = '1' and working.working_window(0) = '1' and (working.found_a_good_edge = true) then  --note operand in brackets is excessive but for may provide power savings and makes visual inspection of simulatuion easier

            if working.window_centre_update = '1' then
                if working.current_window_centre < num_phases -1 then
                    working.current_window_centre := working.current_window_centre + 1;
                else
                    working.current_window_centre := 0;
                end if;
            end if;

            working.window_centre_update := not working.window_centre_update;

            working.current_window_size  := working.current_window_size + 1;
        end if;

        shift_window(working,num_phases);
    end procedure find_centre_of_largest_data_valid_window;


    procedure find_last_failing_phase
                             ( working    : inout t_window_processing;
                               num_phases : in    natural range 1 to c_max_phase_shifts + 1
                              ) is
    begin
        if working.first_cycle = false then  -- not first call to procedure
            if working.current_bit = 0 then --     and working.found_a_good_edge = false then
                if working.valid_phase_seen = false then
                    working.status := no_valid_phases;
                elsif working.invalid_phase_seen = false then
                    working.status := no_invalid_phases;
                else
                    working.status := valid_result;
                end if;
            end if;
        end if;

        -- #pb_del: TODO: is this true -- if 1 is a pass 0 is a fail ?? this returns last failing
        if working.working_window(1) = '1' and working.working_window(0) = '0' and working.status = calculating then
            working.current_window_start := working.current_bit;
        end if;

        shift_window(working, num_phases);  -- shifts window and sets first_cycle = false
    end procedure find_last_failing_phase;


    procedure find_first_passing_phase
                             ( working    : inout t_window_processing;
                               num_phases : in    natural range 1 to c_max_phase_shifts
                              ) is
    begin
        if working.first_cycle = false then  -- not first call to procedure
            if working.current_bit = 0 then --     and working.found_a_good_edge = false then
                if working.valid_phase_seen = false then
                    working.status := no_valid_phases;
                elsif working.invalid_phase_seen = false then
                    working.status := no_invalid_phases;
                else
                    working.status := valid_result;
                end if;
            end if;
        end if;

        if working.working_window(0) = '1' and working.last_bit_value = '0' and working.status = calculating then
            working.current_window_start := working.current_bit;
        end if;

        shift_window(working, num_phases);  -- shifts window and sets first_cycle = false
    end procedure find_first_passing_phase;


    -- shift in current pass/fail result to the working window
    procedure shift_in(
                    working    : inout t_window_processing;
                    status     : in    std_logic;
                    num_phases : in    natural range 1 to c_max_phase_shifts
                ) is
    begin
        working.last_bit_value                        := working.working_window(0);
        working.working_window(num_phases-1 downto 0) := (working.working_window(0) and status) & working.working_window(num_phases-1 downto 1);
    end procedure;

    -- The following function sets the width over which
    -- write latency should be repeated on the dq bus
    -- the default value is MEM_IF_DQ_PER_DQS
    function set_wlat_dq_rep_width return natural is
    begin
        for i in 1 to MEM_IF_DWIDTH/MEM_IF_DQ_PER_DQS loop
            if (i*MEM_IF_DQ_PER_DQS) >= ADV_LAT_WIDTH then
                return i*MEM_IF_DQ_PER_DQS;
            end if;
        end loop;
        report dgrb_report_prefix & "the specified maximum write latency cannot be fully represented in the given number of DQ pins" & LF &
                                    "** NOTE: This may cause overflow when setting ctl_wlat signal" severity warning;
        return MEM_IF_DQ_PER_DQS;
    end function;

    -- extract PHY 'addr/cmd' to 'wdata_valid' write latency from current read data
    function wd_lat_from_rdata(signal rdata : in std_logic_vector(DWIDTH_RATIO * MEM_IF_DWIDTH - 1 downto 0))
            return std_logic_vector is
        variable v_wd_lat : std_logic_vector(ADV_LAT_WIDTH - 1 downto 0);
    begin
        v_wd_lat := (others => '0');

        if set_wlat_dq_rep_width >= ADV_LAT_WIDTH then
            v_wd_lat := rdata(v_wd_lat'high downto 0);
        else
            v_wd_lat                                   := (others => '0');
            v_wd_lat(set_wlat_dq_rep_width - 1 downto 0) := rdata(set_wlat_dq_rep_width - 1 downto 0);
        end if;

        return v_wd_lat;
    end function;

    -- check if rdata_valid is correctly aligned
    function rdata_valid_aligned(
                signal rdata       : in std_logic_vector(DWIDTH_RATIO * MEM_IF_DWIDTH - 1 downto 0);
                signal rdata_valid : in std_logic_vector(DWIDTH_RATIO/2 - 1 downto 0)
            ) return std_logic is

        variable v_dq_rdata    : std_logic_vector(DWIDTH_RATIO - 1 downto 0);
        variable v_aligned     : std_logic;
    begin
        -- Look at data from a single DQ pin 0 (DWIDTH_RATIO data bits)
        for i in 0 to DWIDTH_RATIO - 1 loop
            v_dq_rdata(i) := rdata(i*MEM_IF_DWIDTH);
        end loop;

        -- Check each alignment (necessary because in the HR case rdata can be in any alignment)
        -- #pb_del for HR : v_aligned = ((rdata_valid(0) = '1' and rdata_pin0(1st 2 beats) = "00") or (rdata_valid(1) = '1' and rdata_pin0(2nd 2 beats) = "00"))
        -- #pb_del for FR : v_aligned = (rdata_valid(0) = '1' and rdata_pin0(1st 2 beats) = "00")
        v_aligned := '0';
        for i in 0 to DWIDTH_RATIO/2 - 1 loop
            if rdata_valid(i) = '1' then
                if v_dq_rdata(2*i + 1 downto 2*i) = "00" then
                    v_aligned := '1';
                end if;
            end if;
        end loop;

        return v_aligned;
    end function;


    -- set severity level for calibration failures
    -- #pb_del i.e. if debug gui enabled then downgrade to warnings
    function set_cal_fail_sev_level (
        generate_additional_debug_rtl : natural
        ) return severity_level is
    begin
        if generate_additional_debug_rtl = 1 then
            return warning;
        else
            return failure;
        end if;
    end function;

    constant cal_fail_sev_level : severity_level := set_cal_fail_sev_level(GENERATE_ADDITIONAL_DBG_RTL);

-- ------------------------------------------------------------------
--  signal declarations
-- rsc = resync - the mechanism of capturing DQ pin data onto a local clock domain
-- trk = tracking - a mechanism to track rsc clock phase with PVT variations
-- poa = postamble - protection circuitry from postamble glitched on DQS
-- ac  = memory address / command signals
-- ------------------------------------------------------------------

    -- main state machine
    signal sig_dgrb_state             : t_dgrb_state;
    signal sig_dgrb_last_state        : t_dgrb_state;

    signal sig_rsc_req                : t_resync_state; -- tells resync block which state to transition to.

    -- centre of data-valid window process
    signal sig_cdvw_state             : t_window_processing;

    -- control signals for the address/command process
    signal sig_addr_cmd               : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);
    signal sig_ac_req                 : t_ac_state;
    signal sig_dimm_driving_dq        : std_logic;
    signal sig_doing_rd               : std_logic_vector(MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 downto 0);
    signal sig_ac_even                : std_logic; -- odd/even count of PHY clock cycles.
        --
        --#pb_del Ascii SillyScope (2008-11-24) -ktc
        --  sig_ac_even behaviour
        --
        --  sig_ac_even is always '1' on the cycle a command is issued.  It will
        -- be '1' on even clock cycles thereafter and '0' otherwise.
        --
        --                    ;         ;         ;         ;         ;         ;
        --                    ; _______ ;         ;         ;         ;         ;
        --               XXXXX /       \ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        --      addr/cmd XXXXXX   CMD   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        --               XXXXX \_______/ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        --                    ;         ;         ;         ;         ;         ;
        --                    ;         ;         ;         ;         ;         ;
        --                     _________           _________           _________
        --   sig_ac_even  ____|         |_________|         |_________|         |__________
        --                    ;         ;         ;         ;         ;         ;
        --                    ;         ;         ;         ;         ;         ;
        --   phy clk
        --    count               (0)       (1)       (2)       (3)       (4)
        --
        --

    -- resync related signals
    signal sig_rsc_ack                : std_logic;
    signal sig_rsc_err                : std_logic;
    signal sig_rsc_result             : std_logic_vector(c_command_result_len - 1 downto 0 );

    signal sig_rsc_cdvw_phase         : std_logic;
    signal sig_rsc_cdvw_shift_in      : std_logic;
    signal sig_rsc_cdvw_calc          : std_logic;

    signal sig_rsc_pll_start_reconfig : std_logic;
    signal sig_rsc_pll_inc_dec_n      : std_logic;

    signal sig_rsc_ac_access_req      : std_logic; -- High when the resync block requires a training pattern to be read.

    -- tracking related signals
    signal sig_trk_ack                : std_logic;
    signal sig_trk_err                : std_logic;
    signal sig_trk_result             : std_logic_vector(c_command_result_len - 1 downto 0 );

    signal sig_trk_cdvw_phase         : std_logic;
    signal sig_trk_cdvw_shift_in      : std_logic;
    signal sig_trk_cdvw_calc          : std_logic;

    signal sig_trk_pll_start_reconfig : std_logic;
    signal sig_trk_pll_select         : std_logic_vector(CLOCK_INDEX_WIDTH - 1 DOWNTO 0);
    signal sig_trk_pll_inc_dec_n      : std_logic;

    signal sig_trk_rsc_drift          : integer range -c_max_rsc_drift_in_phases to c_max_rsc_drift_in_phases;  -- stores total change in rsc phase from first calibration

    -- phs_shft_busy could (potentially) be asynchronous
    -- triple register it for metastability hardening
    -- these signals are the taps on the shift register
    signal sig_phs_shft_busy          : std_logic;
    signal sig_phs_shft_busy_1t       : std_logic;
    signal sig_phs_shft_start         : std_logic;
    signal sig_phs_shft_end           : std_logic;

    -- locally register crl_dgrb to minimise fan out
    signal ctrl_dgrb_r                : t_ctrl_command;

    -- command_op signals
    signal current_cs                 : natural range 0 to MEM_IF_NUM_RANKS - 1;
    signal current_mtp_almt           : natural range 0 to 1;
    signal single_bit_cal             : std_logic;

    -- codvw status signals (packed into record and sent to mmi block)
    signal cal_codvw_phase            : std_logic_vector(7 downto 0);
    signal codvw_trk_shift            : std_logic_vector(11 downto 0);
    signal cal_codvw_size             : std_logic_vector(7 downto 0);

    -- error signal and result from main state machine (operations other than rsc or tracking)
    signal sig_cmd_err                : std_logic;
    signal sig_cmd_result             : std_logic_vector(c_command_result_len - 1 downto 0 );


    -- signals that the training pattern matched correctly on the last clock
    -- cycle.
    signal sig_dq_pin_ctr             : natural range 0 to MEM_IF_DWIDTH - 1;
    signal sig_mtp_match              : std_logic;

    -- controls postamble match and timing.
    signal sig_poa_match_en           : std_logic;
    signal sig_poa_match              : std_logic;

    -- postamble signals
    signal sig_poa_ack                : std_logic;  -- '1' for postamble block to acknowledge.

    -- calibration byte lane select
    signal cal_byte_lanes             : std_logic_vector(MEM_IF_DQS_WIDTH  - 1 downto 0);

    signal codvw_grt_one_dvw          : std_logic;

begin


    doing_rd  <= sig_doing_rd;

    -- pack record of codvw status signals
    dgrb_mmi.cal_codvw_phase   <= cal_codvw_phase;
    dgrb_mmi.codvw_trk_shift   <= codvw_trk_shift;
    dgrb_mmi.cal_codvw_size    <= cal_codvw_size;
    dgrb_mmi.codvw_grt_one_dvw <= codvw_grt_one_dvw;

    -- map some internal signals to outputs
    dgrb_ac <= sig_addr_cmd;

    -- locally register crl_dgrb to minimise fan out
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            ctrl_dgrb_r <= defaults;
        elsif rising_edge(clk) then
            ctrl_dgrb_r <= ctrl_dgrb;
        end if;
    end process;

    -- generate the current_cs signal to track which cs accessed by PHY at any instance
    current_cs_proc : process (clk, rst_n)
    begin
        if rst_n = '0' then
            current_cs       <= 0;
            current_mtp_almt <= 0;
            single_bit_cal   <= '0';

            cal_byte_lanes   <= (others => '0');

        elsif rising_edge(clk) then
            if ctrl_dgrb_r.command_req = '1' then
                current_cs       <= ctrl_dgrb_r.command_op.current_cs;
                current_mtp_almt <= ctrl_dgrb_r.command_op.mtp_almt;
                single_bit_cal   <= ctrl_dgrb_r.command_op.single_bit;
            end if;

            -- mux byte lane select for given chip select
            for i in 0 to MEM_IF_DQS_WIDTH - 1 loop
                cal_byte_lanes(i) <= ctl_cal_byte_lanes((current_cs * MEM_IF_DQS_WIDTH) + i);
            end loop;

            assert ctl_cal_byte_lanes(0) = '1' report dgrb_report_prefix & " Byte lane 0 (chip select 0) disable is not supported - ending simulation" severity failure;
        end if;
    end process;


    -- ------------------------------------------------------------------
    -- main state machine for dgrb architecture
    --
    -- process of commands from control (ctrl) block and overall control of
    -- the subsequent calibration processing functions
    -- also communicates completion and any errors back to the ctrl block
    -- read data valid alignment and advertised latency calculations are
    -- included in this block
    -- #pb_del the above calculation ops could be processed in a seperate 'block'
    -- ------------------------------------------------------------------

    dgrb_main_block : block
        signal sig_count    : natural range 0 to 2**8 - 1;
        signal sig_wd_lat   : std_logic_vector(ADV_LAT_WIDTH - 1 downto 0);
    begin
        dgrb_state_proc : process(rst_n, clk)
        begin
            if rst_n = '0' then
                -- initialise state
                sig_dgrb_state          <= s_idle;
                sig_dgrb_last_state     <= s_idle;

                sig_ac_req              <= s_ac_idle;
                sig_rsc_req             <= s_rsc_idle;

                -- set up rd_lat defaults
                rd_lat                  <= c_default_rd_lat_slv;
                wd_lat                  <= c_default_wd_lat_slv;

                -- set up rdata_valid latency control defaults
                seq_rdata_valid_lat_inc <= '0';
                seq_rdata_valid_lat_dec <= '0';

                -- reset counter
                sig_count               <= 0;

                -- error signals
                sig_cmd_err             <= '0';
                sig_cmd_result          <= (others => '0');

                -- sig_wd_lat
                sig_wd_lat              <= (others => '0');

                -- status of the ac_nt alignment
                dgrb_ctrl_ac_nt_good    <= '1';

            elsif rising_edge(clk) then
                sig_dgrb_last_state     <= sig_dgrb_state;
                sig_rsc_req             <= s_rsc_idle;

                -- set up rdata_valid latency control defaults
                seq_rdata_valid_lat_inc <= '0';
                seq_rdata_valid_lat_dec <= '0';

                -- error signals
                sig_cmd_err             <= '0';
                sig_cmd_result          <= (others => '0');

                -- register wd_lat output.
                wd_lat                  <= sig_wd_lat;

                case sig_dgrb_state is
                    when s_idle =>
                        sig_count <= 0;

                        if ctrl_dgrb_r.command_req = '1' then
                            if curr_active_block(ctrl_dgrb_r.command) = dgrb then
                                sig_dgrb_state <= s_wait_admin;
                            end if;
                        end if;

                        sig_ac_req <= s_ac_idle;


                    when s_wait_admin =>
                        sig_dgrb_state <= s_wait_admin;

                        case ctrl_dgrb_r.command is

                            when cmd_read_mtp        => sig_dgrb_state <= s_read_mtp;
                            when cmd_rrp_reset       => sig_dgrb_state <= s_reset_cdvw;
                            when cmd_rrp_sweep       => sig_dgrb_state <= s_test_phases;
                            when cmd_rrp_seek        => sig_dgrb_state <= s_seek_cdvw;
                            when cmd_rdv             => sig_dgrb_state <= s_rdata_valid_align;
                            when cmd_prep_adv_rd_lat => sig_dgrb_state <= s_adv_rd_lat_setup;
                            when cmd_prep_adv_wr_lat => sig_dgrb_state <= s_adv_wd_lat;
                            when cmd_tr_due          => sig_dgrb_state <= s_track;
                            when cmd_poa             => sig_dgrb_state <= s_poa_cal;

                            when others              =>
                                report dgrb_report_prefix & "unknown command" severity failure;
                                sig_dgrb_state <= s_idle;
                        end case;


                    when s_reset_cdvw =>
                        -- the cdvw proc watches for this state and resets the cdvw
                        -- state block.
                        if sig_rsc_ack = '1' then
                            sig_dgrb_state <= s_release_admin;
                        else
                            sig_rsc_req <= s_rsc_reset_cdvw;
                        end if;


                    when s_test_phases =>
                        if sig_rsc_ack = '1' then
                            sig_dgrb_state <= s_release_admin;
                        else
                            sig_rsc_req <= s_rsc_test_phase;
                            if sig_rsc_ac_access_req = '1' then
                                sig_ac_req <= s_ac_read_mtp;
                            else
                                sig_ac_req <= s_ac_idle;
                            end if;
                        end if;


                    when s_seek_cdvw | s_read_mtp =>
                        if sig_rsc_ack = '1' then
                            sig_dgrb_state <= s_release_admin;
                        else
                            sig_rsc_req <= s_rsc_cdvw_calc;
                        end if;


                    when s_release_admin =>
                        sig_ac_req     <= s_ac_idle;

                        if dgrb_ac_access_gnt = '0' and sig_dimm_driving_dq = '0' then
                            sig_dgrb_state <= s_idle;
                        end if;


                    when s_rdata_valid_align =>
                        sig_ac_req <= s_ac_read_rdv;

                        seq_rdata_valid_lat_dec <= '0';
                        seq_rdata_valid_lat_inc <= '0';

                        if sig_dimm_driving_dq = '1' then
                            -- only do comparison if rdata_valid is all 'ones'
                            if rdata_valid /= std_logic_vector(to_unsigned(0, DWIDTH_RATIO/2)) then
                                -- rdata_valid is all ones
                                if rdata_valid_aligned(rdata, rdata_valid) = '1' then
                                    -- success: rdata_valid and rdata are properly aligned
                                    sig_dgrb_state <= s_release_admin;
                                else
                                    -- misaligned: bring in rdata_valid by a clock cycle
                                    seq_rdata_valid_lat_dec <= '1';
                                end if;
                            end if;
                        end if;


                    when s_adv_rd_lat_setup =>
                        -- wait for sig_doing_rd to go high
                        sig_ac_req <= s_ac_read_rdv;

                        if sig_dgrb_state /= sig_dgrb_last_state then
                            rd_lat    <= (others => '0');
                            sig_count <= 0;
                        elsif sig_dimm_driving_dq = '1' and sig_doing_rd(MEM_IF_DQS_WIDTH*(DWIDTH_RATIO/2-1)) = '1' then
                            -- a read has started: start counter
                            sig_dgrb_state <= s_adv_rd_lat;
                        end if;


                    when s_adv_rd_lat =>
                        sig_ac_req <= s_ac_read_rdv;

                        if sig_dimm_driving_dq = '1' then
                            if sig_count >= 2**rd_lat'length then
                                report dgrb_report_prefix & "maximum read latency exceeded while waiting for rdata_valid" severity cal_fail_sev_level;
                                sig_cmd_err             <= '1';
                                sig_cmd_result          <= std_logic_vector(to_unsigned(C_ERR_MAX_RD_LAT_EXCEEDED,sig_cmd_result'length));
                            end if;

                            if rdata_valid /= std_logic_vector(to_unsigned(0, rdata_valid'length)) then
                                -- have found the read latency
                                sig_dgrb_state <= s_release_admin;
                            else
                                sig_count <= sig_count + 1;
                            end if;

                            rd_lat <= std_logic_vector(to_unsigned(sig_count, rd_lat'length));
                        end if;


                    when s_adv_wd_lat =>
                        sig_ac_req <= s_ac_read_wd_lat;

                        if sig_dgrb_state /= sig_dgrb_last_state then
                            sig_wd_lat <= (others => '0');
                        else
                            if sig_dimm_driving_dq = '1' and rdata_valid /= std_logic_vector(to_unsigned(0, rdata_valid'length)) then
                                -- construct wd_lat using data from the lowest addresses
                                -- wd_lat <= rdata(MEM_IF_DQ_PER_DQS - 1 downto 0);
                                sig_wd_lat     <= wd_lat_from_rdata(rdata);
                                sig_dgrb_state <= s_release_admin;

                                -- check data integrity
                                for i in 1 to MEM_IF_DWIDTH/set_wlat_dq_rep_width - 1 loop
                                    -- wd_lat is copied across MEM_IF_DWIDTH bits in fields of width MEM_IF_DQ_PER_DQS.
                                    -- All of these fields must have the same value or it is an error.

                                    -- only check if byte lane not disabled
                                    if cal_byte_lanes((i*set_wlat_dq_rep_width)/MEM_IF_DQ_PER_DQS) = '1' then

                                        if rdata(set_wlat_dq_rep_width - 1 downto 0) /= rdata((i+1)*set_wlat_dq_rep_width - 1 downto i*set_wlat_dq_rep_width) then
                                            -- signal write latency different between DQS groups
                                            report dgrb_report_prefix & "the write latency read from memory is different accross dqs groups" severity cal_fail_sev_level;
                                            sig_cmd_err             <= '1';
                                            sig_cmd_result          <= std_logic_vector(to_unsigned(C_ERR_WD_LAT_DISAGREEMENT, sig_cmd_result'length));
                                        end if;
                                    end if;

                                end loop;

                                -- check if ac_nt alignment is ok
                                -- in this condition all DWIDTH_RATIO copies of rdata should be identical
                                -- #pb_del NOTE: this calculation may require pipelining
                                dgrb_ctrl_ac_nt_good <= '1';
                                if DWIDTH_RATIO /= 2 then
                                    for j in 0 to DWIDTH_RATIO/2 - 1 loop
                                        if rdata(j*MEM_IF_DWIDTH + MEM_IF_DQ_PER_DQS - 1 downto j*MEM_IF_DWIDTH) /= rdata((j+2)*MEM_IF_DWIDTH + MEM_IF_DQ_PER_DQS - 1 downto (j+2)*MEM_IF_DWIDTH) then
                                            dgrb_ctrl_ac_nt_good <= '0';
                                        end if;
                                    end loop;
                                end if;

                            end if;
                        end if;


                    when s_poa_cal =>
                        -- Request the address/command block begins reading the "M"
                        -- training pattern here.  There is no provision for doing
                        -- refreshes so this limits the time spent in this state
                        -- to 9 x tREFI (by the DDR2 JEDEC spec).  Instead of the
                        -- maximum value, a maximum "safe" time in this postamble
                        -- state is chosen to be tpoamax = 5 x tREFI = 5 x 3.9us.
                        -- When entering this s_poa_cal state it must be guaranteed
                        -- that the number of stacked refreshes is at maximum.
                        --
                        -- Minimum clock freq supported by DRAM is fck,min=125MHz.
                        -- Each adjustment to postamble latency requires 16*clock
                        -- cycles (time to read "M" training pattern twice) so
                        -- maximum number of adjustments to POA latency (n) is:
                        --
                        --   n = (5 x trefi x fck,min) / 16
                        --     = (5 x 3.9us x 125MHz) / 16
                        --     ~ 152
                        --
                        -- Postamble latency must be adjusted less than 152 cycles
                        -- to meet this requirement.
                        --
                        -- #pb_del -ktc (2008/11/18)

                        --#pb_del TODO: turn on postamble!
                        sig_ac_req <= s_ac_read_poa_mtp;

                        if sig_poa_ack = '1' then
                            sig_dgrb_state <= s_release_admin;
                        end if;

                    when s_track =>
                        if sig_trk_ack = '1' then
                            sig_dgrb_state <= s_release_admin;
                        end if;


                    when others => null;
                        report dgrb_report_prefix & "undefined state" severity failure;
                        sig_dgrb_state <= s_idle;
                end case;


                -- default if not calibrating go to idle state via s_release_admin
                if ctrl_dgrb_r.command = cmd_idle and
                   sig_dgrb_state /= s_idle and
                   sig_dgrb_state /= s_release_admin then

                    sig_dgrb_state <= s_release_admin;
                end if;

            end if;
        end process;
    end block;

    -- ------------------------------------------------------------------
    -- metastability hardening of potentially async phs_shift_busy signal
    --
    -- Triple register it for metastability hardening.  This process
    -- creates the shift register.  Also add a sig_phs_shft_busy and
    -- an sig_phs_shft_busy_1t echo because various other processes find
    -- this useful.
    -- ------------------------------------------------------------------
    phs_shft_busy_reg: block
            signal phs_shft_busy_1r : std_logic;
            signal phs_shft_busy_2r : std_logic;
            signal phs_shft_busy_3r : std_logic;
    begin
        phs_shift_busy_sync : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_phs_shft_busy    <= '0';
                sig_phs_shft_busy_1t <= '0';

                phs_shft_busy_1r     <= '0';
                phs_shft_busy_2r     <= '0';
                phs_shft_busy_3r     <= '0';

                sig_phs_shft_start   <= '0';
                sig_phs_shft_end     <= '0';

            elsif rising_edge(clk) then
                sig_phs_shft_busy_1t <= phs_shft_busy_3r;
                sig_phs_shft_busy    <= phs_shft_busy_2r;

                -- register the below to reduce fan out on sig_phs_shft_busy and sig_phs_shft_busy_1t
                sig_phs_shft_start   <= phs_shft_busy_3r or  phs_shft_busy_2r;
                sig_phs_shft_end     <= phs_shft_busy_3r and not(phs_shft_busy_2r);

                phs_shft_busy_3r     <= phs_shft_busy_2r;
                phs_shft_busy_2r     <= phs_shft_busy_1r;
                phs_shft_busy_1r     <= phs_shft_busy;
            end if;
        end process;
    end block;

    -- ------------------------------------------------------------------
    -- PLL reconfig MUX
    --
    -- switches PLL Reconfig input between tracking and resync blocks
    -- #pb_del: TODO: Look closely at seq_pll_start_reconfig and seq_pll_inc_dec_n
    -- #pb_del: because they go undefined.
    -- ------------------------------------------------------------------
    pll_reconf_mux : process (clk, rst_n)
    begin
        if rst_n = '0' then
            seq_pll_inc_dec_n       <= '0';
            seq_pll_select          <= (others => '0');
            seq_pll_start_reconfig  <= '0';
        elsif rising_edge(clk) then
            if sig_dgrb_state = s_seek_cdvw or
               sig_dgrb_state = s_test_phases or
               sig_dgrb_state = s_reset_cdvw then
                seq_pll_select         <= pll_resync_clk_index;
                seq_pll_inc_dec_n      <= sig_rsc_pll_inc_dec_n;
                seq_pll_start_reconfig <= sig_rsc_pll_start_reconfig;
            elsif sig_dgrb_state = s_track then
                seq_pll_select         <= sig_trk_pll_select;
                seq_pll_inc_dec_n      <= sig_trk_pll_inc_dec_n;
                seq_pll_start_reconfig <= sig_trk_pll_start_reconfig;
            else
                seq_pll_select         <= pll_measure_clk_index;
                seq_pll_inc_dec_n      <= '0';
                seq_pll_start_reconfig <= '0';
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------
    -- Centre of data valid window calculation block
    --
    -- This block handles the sharing of the centre of window calculation
    -- logic between the rsc and trk operations. Functions defined in the
    -- header of this entity are called to do this.
    -- ------------------------------------------------------------------
    cdvw_block : block
        signal sig_cdvw_calc_1t : std_logic;
    begin
        -- purpose: manages centre of data valid window calculations
        -- type   : sequential
        -- inputs : clk, rst_n
        -- outputs: sig_cdvw_state
        cdvw_proc: process (clk, rst_n)
            variable v_cdvw_state  : t_window_processing;
            variable v_start_calc  : std_logic;
            variable v_shift_in    : std_logic;
            variable v_phase       : std_logic;
        begin  -- process cdvw_proc
            if rst_n = '0' then             -- asynchronous reset (active low)

                sig_cdvw_state   <= defaults;
                sig_cdvw_calc_1t <= '0';

            elsif rising_edge(clk) then  -- rising clock edge
                v_cdvw_state := sig_cdvw_state;

                case sig_dgrb_state is
                when s_track =>
                    v_start_calc := sig_trk_cdvw_calc;
                    v_phase := sig_trk_cdvw_phase;
                    v_shift_in := sig_trk_cdvw_shift_in;

                when s_read_mtp | s_seek_cdvw | s_test_phases =>
                    v_start_calc := sig_rsc_cdvw_calc;
                    v_phase      := sig_rsc_cdvw_phase;
                    v_shift_in   := sig_rsc_cdvw_shift_in;

                when others =>
                    v_start_calc := '0';
                    v_phase := '0';
                    v_shift_in := '0';
                end case;

                if sig_dgrb_state = s_reset_cdvw or (sig_dgrb_state = s_track and sig_dgrb_last_state /= s_track) then
                    -- reset *C*entre of *D*ata *V*alid *W*indow
                    v_cdvw_state := defaults;
                elsif sig_cdvw_calc_1t /= '1' and v_start_calc = '1' then
                    initialise_window_for_proc(v_cdvw_state);
                elsif v_cdvw_state.status = calculating then
                    if sig_dgrb_state = s_track then  -- ensure 360 degrees sweep
                        find_centre_of_largest_data_valid_window(v_cdvw_state, PLL_STEPS_PER_CYCLE);
                    else -- can be a 720 degrees sweep
                        find_centre_of_largest_data_valid_window(v_cdvw_state, c_max_phase_shifts);
                    end if;
                elsif v_shift_in = '1' then
                    if sig_dgrb_state = s_track then  -- ensure 360 degrees sweep
                        shift_in(v_cdvw_state, v_phase, PLL_STEPS_PER_CYCLE);
                    else
                        shift_in(v_cdvw_state, v_phase, c_max_phase_shifts);
                    end if;
                end if;

                sig_cdvw_calc_1t <= v_start_calc;
                sig_cdvw_state <= v_cdvw_state;
            end if;
        end process cdvw_proc;
    end block;


    -- ------------------------------------------------------------------
    -- block for resync calculation.
    --
    -- This block implements the following:
    -- 1) Control logic for the rsc slave state machine
    -- 2) Processing of resync operations - through reports form cdvw block and
    --    test pattern match blocks
    -- 3) Shifting of the resync phase for rsc sweeps
    -- 4) Writing of results to iram (optional)
    -- ------------------------------------------------------------------
    rsc_block : block

        signal sig_rsc_state             : t_resync_state;
        signal sig_rsc_last_state        : t_resync_state;

        signal sig_num_phase_shifts      : natural range c_max_phase_shifts - 1 downto 0;

        signal sig_rewind_direction      : std_logic;
        signal sig_count                 : natural range 0 to 2**8 - 1;
        signal sig_test_dq_expired       : std_logic;
        signal sig_chkd_all_dq_pins      : std_logic;

        -- prompts to write data to iram
        signal sig_dgrb_iram             : t_iram_push;                               -- internal copy of dgrb to iram control signals
        signal sig_rsc_push_rrp_sweep    : std_logic;                                 -- push result of a rrp sweep pass (for cmd_rrp_sweep)
        signal sig_rsc_push_rrp_pass     : std_logic;                                 -- result of a rrp sweep result (for cmd_rrp_sweep)
        signal sig_rsc_push_rrp_seek     : std_logic;                                 -- write seek results (for cmd_rrp_seek / cmd_read_mtp states)
        signal sig_rsc_push_footer       : std_logic;                                 -- write a footer
        signal sig_dq_pin_ctr_r          : natural range 0 to MEM_IF_DWIDTH - 1;      -- registered version of dq_pin_ctr
        signal sig_rsc_curr_phase        : natural range 0 to c_max_phase_shifts - 1; -- which phase is being processed
        signal sig_iram_idle             : std_logic;                                 -- track if iram currently writing data
        signal sig_mtp_match_en          : std_logic;

        -- current byte lane disabled?
        signal sig_curr_byte_ln_dis      : std_logic;

        signal sig_iram_wds_req          : integer;  -- words required for a given iram dump (used to locate where to write footer)

    begin
        -- When using DQS capture or not at full-rate only match on "even" clock cycles.
        sig_mtp_match_en <= active_high(sig_ac_even = '1' or MEM_IF_DQS_CAPTURE = 0 or DWIDTH_RATIO /= 2);

        -- register current byte lane disable mux for speed
        byte_lane_dis: process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_curr_byte_ln_dis <= '0';
            elsif rising_edge(clk) then
                sig_curr_byte_ln_dis <= cal_byte_lanes(sig_dq_pin_ctr/MEM_IF_DQ_PER_DQS);
            end if;
        end process;

        -- check if all dq pins checked in rsc sweep
        chkd_dq : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_chkd_all_dq_pins  <= '0';
            elsif rising_edge(clk) then
                if sig_dq_pin_ctr = 0 then
                    sig_chkd_all_dq_pins <= '1';
                else
                    sig_chkd_all_dq_pins <= '0';
                end if;
            end if;
        end process;

        -- main rsc process
        rsc_proc : process (clk, rst_n)
            -- these are temporary variables which should not infer FFs and
            -- are not guaranteed to be initialized by s_rsc_idle.
            variable v_rdata_correct     : std_logic;
            variable v_phase_works       : std_logic;

        begin
            if rst_n = '0' then
                -- initialise signals
                sig_rsc_state         <= s_rsc_idle;
                sig_rsc_last_state    <= s_rsc_idle;

                sig_dq_pin_ctr        <= 0;
                sig_num_phase_shifts  <= c_max_phase_shifts - 1;  -- want c_max_phase_shifts-1 inc / decs of phase

                sig_count             <= 0;
                sig_test_dq_expired   <= '0';

                v_phase_works         := '0';

                -- interface to other processes to tell them when we are done.
                sig_rsc_ack           <= '0';
                sig_rsc_err           <= '0';
                sig_rsc_result        <= std_logic_vector(to_unsigned(C_SUCCESS, c_command_result_len));

                -- centre of data valid window functions
                sig_rsc_cdvw_phase    <= '0';
                sig_rsc_cdvw_shift_in <= '0';
                sig_rsc_cdvw_calc     <= '0';

                -- set up PLL reconfig interface controls
                sig_rsc_pll_start_reconfig <= '0';
                sig_rsc_pll_inc_dec_n      <= c_pll_phs_inc;
                sig_rewind_direction       <= c_pll_phs_dec;

                -- True when access to the ac_block is required.
                sig_rsc_ac_access_req      <= '0';

                -- default values on centre and size of data valid window
                if SIM_TIME_REDUCTIONS = 1 then
                    cal_codvw_phase        <= std_logic_vector(to_unsigned(PRESET_CODVW_PHASE, 8));
                    cal_codvw_size         <= std_logic_vector(to_unsigned(PRESET_CODVW_SIZE,  8));
                else
                    cal_codvw_phase        <= (others => '0');
                    cal_codvw_size         <= (others => '0');
                end if;

                sig_rsc_push_rrp_sweep     <= '0';
                sig_rsc_push_rrp_seek      <= '0';
                sig_rsc_push_rrp_pass      <= '0';
                sig_rsc_push_footer        <= '0';

                codvw_grt_one_dvw          <= '0';

            elsif rising_edge(clk) then
                -- default values assigned to some signals
                sig_rsc_ack                <= '0';

                sig_rsc_cdvw_phase         <= '0';
                sig_rsc_cdvw_shift_in      <= '0';
                sig_rsc_cdvw_calc          <= '0';

                sig_rsc_pll_start_reconfig <= '0';
                sig_rsc_pll_inc_dec_n      <= c_pll_phs_inc;
                sig_rewind_direction       <= c_pll_phs_dec;

                -- by default don't ask the resync block to read anything
                sig_rsc_ac_access_req      <= '0';

                sig_rsc_push_rrp_sweep     <= '0';
                sig_rsc_push_rrp_seek      <= '0';
                sig_rsc_push_rrp_pass      <= '0';
                sig_rsc_push_footer        <= '0';

                sig_test_dq_expired        <= '0';

                -- resync state machine
                case sig_rsc_state is
                    when s_rsc_idle =>
                        -- initialize those signals we are ready to use.
                        sig_dq_pin_ctr        <= 0;

                        sig_count             <= 0;

                        if sig_rsc_state = sig_rsc_last_state then  -- avoid transition when acknowledging a command has finished
                            if sig_rsc_req = s_rsc_test_phase then
                                sig_rsc_state <= s_rsc_test_phase;
                            elsif sig_rsc_req = s_rsc_cdvw_calc then
                                sig_rsc_state <= s_rsc_cdvw_calc;
                            elsif sig_rsc_req = s_rsc_seek_cdvw then
                                sig_rsc_state <= s_rsc_seek_cdvw;
                            elsif sig_rsc_req = s_rsc_reset_cdvw then
                                sig_rsc_state <= s_rsc_reset_cdvw;
                            else
                                sig_rsc_state <= s_rsc_idle;
                            end if;
                        end if;


                    when s_rsc_next_phase =>
                        sig_rsc_pll_inc_dec_n      <= c_pll_phs_inc;
                        sig_rsc_pll_start_reconfig <= '1';
                        if sig_phs_shft_start = '1' then
                            -- PLL phase shift started - so stop requesting a shift
                            sig_rsc_pll_start_reconfig <= '0';
                        end if;

                        if sig_phs_shft_end = '1' then
                            -- PLL phase shift finished - so proceed to flush the datapath
                            sig_num_phase_shifts <= sig_num_phase_shifts - 1;
                            sig_rsc_state <= s_rsc_test_phase;
                        end if;

                    when s_rsc_test_phase  =>
                        v_phase_works   := '1';
                        -- Note: For single pin single CS calibration set sig_dq_pin_ctr to 0 to
                        --       ensure that only 1 pin calibrated

                        sig_rsc_state   <= s_rsc_wait_for_idle_dimm;

                        if single_bit_cal = '1' then
                            sig_dq_pin_ctr      <= 0;
                        else
                            sig_dq_pin_ctr      <= MEM_IF_DWIDTH-1;
                        end if;

                    when s_rsc_wait_for_idle_dimm  =>
                        if sig_dimm_driving_dq = '0' then
                            sig_rsc_state <= s_rsc_flush_datapath;
                        end if;


                    when s_rsc_flush_datapath =>
                        sig_rsc_ac_access_req <= '1';
                        if sig_rsc_state /= sig_rsc_last_state then
                            -- reset variables we are interested in when we first arrive in this state.
                            sig_count <= c_max_read_lat - 1;
                        else
                            if sig_dimm_driving_dq = '1' then
                                if sig_count = 0 then
                                    sig_rsc_state <= s_rsc_test_dq;
                                else
                                    sig_count <= sig_count - 1;
                                end if;
                            end if;
                        end if;


                    when s_rsc_test_dq =>
                        sig_rsc_ac_access_req <= '1';

                        if sig_rsc_state  /= sig_rsc_last_state then
                            -- reset variables we are interested in when we first arrive in this state.
                            sig_count             <= 2*c_cal_mtp_t;

                        else

                            if sig_dimm_driving_dq = '1' then

                                if (
                                    (sig_mtp_match = '1' and sig_mtp_match_en = '1') or -- have a pattern match
                                    (sig_test_dq_expired = '1') or -- time in this phase has expired.
                                    sig_curr_byte_ln_dis = '0'  -- byte lane disabled
                                ) then

                                    v_phase_works := v_phase_works and ((sig_mtp_match and sig_mtp_match_en) or (not sig_curr_byte_ln_dis));

                                    sig_rsc_push_rrp_sweep <= '1';
                                    sig_rsc_push_rrp_pass <= (sig_mtp_match and sig_mtp_match_en) or (not sig_curr_byte_ln_dis);

                                    if sig_chkd_all_dq_pins = '1' then
                                        -- finished checking all dq pins.
                                        -- done checking this phase.

                                        -- shift phase status into
                                        sig_rsc_cdvw_phase    <= v_phase_works;
                                        sig_rsc_cdvw_shift_in <= '1';

                                        if sig_num_phase_shifts /= 0 then
                                            -- there are more phases to test so shift to next phase
                                            sig_rsc_state        <= s_rsc_next_phase;
                                        else
                                            -- no more phases to check.
                                            -- clean up after ourselves by
                                            -- going into s_rsc_rewind_phase
                                            sig_rsc_state        <= s_rsc_rewind_phase;
                                            sig_rewind_direction <= c_pll_phs_dec;
                                            sig_num_phase_shifts <= c_max_phase_shifts - 1;
                                        end if;
                                    else
                                        -- shift to next dq pin
                                        -- #pb_del NOTE: it is necessary to transition to another state after this one
                                        -- #pb_del       due to pipelining on sig_chkd_all_dq_pins
                                        -- #pb_del: Note refreshes every 64 pins chosen here to minimise logic
                                        if MEM_IF_DWIDTH > 71 and             -- if >= 72 pins then:
                                           (sig_dq_pin_ctr mod 64) = 0 then   -- ensure refreshes at least once every 64 pins

                                            sig_rsc_state <= s_rsc_wait_for_idle_dimm;

                                        else -- otherwise continue sweep

                                            sig_rsc_state <= s_rsc_flush_datapath;
                                        end if;

                                        sig_dq_pin_ctr <= sig_dq_pin_ctr - 1;

                                    end if;

                                else

                                    sig_count <= sig_count - 1;

                                    if sig_count = 1 then
                                        sig_test_dq_expired <= '1';
                                    end if;

                                end if;
                            end if;
                       end if;

                    when s_rsc_reset_cdvw =>
                        sig_rsc_state        <= s_rsc_rewind_phase;

                        -- determine the amount to rewind by (may be wind forward depending on tracking behaviour)
                        if to_integer(unsigned(cal_codvw_phase)) + sig_trk_rsc_drift < 0 then
                            sig_num_phase_shifts <= - (to_integer(unsigned(cal_codvw_phase)) + sig_trk_rsc_drift);
                            sig_rewind_direction <= c_pll_phs_inc;
                        else
                            sig_num_phase_shifts <= (to_integer(unsigned(cal_codvw_phase)) + sig_trk_rsc_drift);
                            sig_rewind_direction <= c_pll_phs_dec;
                        end if;

                        -- reset the calibrated phase and size to zero (because un-doing prior calibration here)
                        cal_codvw_phase      <= (others => '0');
                        cal_codvw_size       <= (others => '0');

                    when s_rsc_rewind_phase =>
                        -- rewinds the resync PLL by sig_num_phase_shifts steps and returns to idle state
                        if sig_num_phase_shifts = 0 then
                            -- no more steps to take off, go to next state
                            sig_num_phase_shifts       <= c_max_phase_shifts - 1;

                            if GENERATE_ADDITIONAL_DBG_RTL = 1 then  -- if iram present hold off until access finished
                                sig_rsc_state <= s_rsc_wait_iram;
                            else
                                sig_rsc_ack   <= '1';
                                sig_rsc_state <= s_rsc_idle;
                            end if;

                        else
                            sig_rsc_pll_inc_dec_n <= sig_rewind_direction;

                            -- request a phase shift
                            sig_rsc_pll_start_reconfig <= '1';
                            if sig_phs_shft_busy = '1' then
                                -- inhibit a phase shift if phase shift is busy.
                                sig_rsc_pll_start_reconfig <= '0';
                            end if;

                            if sig_phs_shft_busy_1t = '1' and sig_phs_shft_busy /= '1' then
                                -- we've just successfully removed a phase step
                                -- decrement counter
                                sig_num_phase_shifts <= sig_num_phase_shifts - 1;
                                sig_rsc_pll_start_reconfig <= '0';
                            end if;
                        end if;


                    when s_rsc_cdvw_calc =>
                        if sig_rsc_state /= sig_rsc_last_state then
                            if sig_dgrb_state = s_read_mtp then
                                report dgrb_report_prefix & "gathered resync phase samples (for mtp alignment " & natural'image(current_mtp_almt) & ") is DGRB_PHASE_SAMPLES: " & str(sig_cdvw_state.working_window) severity note;
                            else
                                report dgrb_report_prefix & "gathered resync phase samples DGRB_PHASE_SAMPLES: " & str(sig_cdvw_state.working_window) severity note;
                            end if;
                            sig_rsc_cdvw_calc <= '1';  -- begin calculating result
                        else
                            sig_rsc_state <= s_rsc_cdvw_wait;
                        end if;


                    when s_rsc_cdvw_wait =>
                        if sig_cdvw_state.status /= calculating then
                            -- a result has been reached.
                            if sig_dgrb_state = s_read_mtp then  -- if doing mtp alignment then skip setting phase

                                if GENERATE_ADDITIONAL_DBG_RTL = 1 then  -- if iram present hold off until access finished
                                    sig_rsc_state <= s_rsc_wait_iram;
                                else
                                    sig_rsc_ack   <= '1';
                                    sig_rsc_state <= s_rsc_idle;
                                end if;

                            else
                                if sig_cdvw_state.status = valid_result then
                                    -- calculation successfully found a
                                    -- data-valid window to seek to.
                                    sig_rsc_state <= s_rsc_seek_cdvw;

				    sig_rsc_result <= std_logic_vector(to_unsigned(C_SUCCESS, sig_rsc_result'length));

				    -- If more than one data valid window was seen, then set the result code :
				    if (sig_cdvw_state.windows_seen > 1) then
                                        report dgrb_report_prefix & "Warning : multiple data-valid windows found, largest chosen." severity note;
					codvw_grt_one_dvw <= '1';
                                    else
                                        report dgrb_report_prefix & "data-valid window found successfully." severity note;
				    end if;

                                else
                                    -- calculation failed to find a data-valid window.

                                    --#pb_del note: downgrading the below to warning for test purposes
                                    report dgrb_report_prefix & "couldn't find a data-valid window in resync." severity warning;
                                    sig_rsc_ack  <= '1';
                                    sig_rsc_err  <= '1';
                                    sig_rsc_state <= s_rsc_idle;

                                    -- set resync result code
                                    case sig_cdvw_state.status is
                                        when no_invalid_phases =>
                                            sig_rsc_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_NO_VALID_PHASES, sig_rsc_result'length));
                                        when multiple_equal_windows =>
                                            sig_rsc_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_MULTIPLE_EQUAL_WINDOWS, sig_rsc_result'length));
                                        when no_valid_phases =>
                                            sig_rsc_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_NO_VALID_PHASES, sig_rsc_result'length));
                                        when others =>
                                            sig_rsc_result <= std_logic_vector(to_unsigned(C_ERR_CRITICAL, sig_rsc_result'length));
                                    end case;
                                end if;
                            end if;

                            -- signal to write a rrp_sweep result to iram
                            if GENERATE_ADDITIONAL_DBG_RTL = 1 then
                                sig_rsc_push_rrp_seek <= '1';
                            end if;

                        end if;


                    when s_rsc_seek_cdvw =>
                        if sig_rsc_state /= sig_rsc_last_state then
                            -- reset variables we are interested in when we first arrive in this state
                            sig_count <= sig_cdvw_state.largest_window_centre;
                        else
                            if sig_count = 0 or
                            ((MEM_IF_DQS_CAPTURE = 1 and DWIDTH_RATIO = 2) and
                             sig_count = PLL_STEPS_PER_CYCLE) -- if FR and DQS capture ensure within 0-360 degrees phase

                            then
                                -- ready to transition to next state
                                if GENERATE_ADDITIONAL_DBG_RTL = 1 then  -- if iram present hold off until access finished
                                    sig_rsc_state <= s_rsc_wait_iram;
                                else
                                    sig_rsc_ack   <= '1';
                                    sig_rsc_state <= s_rsc_idle;
                                end if;

                                -- return largest window centre and size in the result

                                -- perform cal_codvw phase / size update only if a valid result is found
                                if sig_cdvw_state.status = valid_result then

                                    cal_codvw_phase <= std_logic_vector(to_unsigned(sig_cdvw_state.largest_window_centre, 8));
                                    cal_codvw_size  <= std_logic_vector(to_unsigned(sig_cdvw_state.largest_window_size,   8));

                                end if;

                                -- leaving sig_rsc_err or sig_rsc_result at
                                -- their default values (of success)
                            else
                                sig_rsc_pll_inc_dec_n <= c_pll_phs_inc;

                                -- request a phase shift
                                sig_rsc_pll_start_reconfig <= '1';
                                if sig_phs_shft_start = '1' then
                                    -- inhibit a phase shift if phase shift is busy
                                    sig_rsc_pll_start_reconfig <= '0';
                                end if;

                                if sig_phs_shft_end = '1'  then
                                    -- we've just successfully removed a phase step
                                    -- decrement counter
                                    sig_count <= sig_count - 1;
                                end if;
                            end if;
                        end if;

                    when s_rsc_wait_iram =>

                        -- hold off check 1 clock cycle to enable last rsc push operations to start
                        if sig_rsc_state = sig_rsc_last_state then

                            if sig_iram_idle = '1' then

                                sig_rsc_ack         <= '1';
                                sig_rsc_state       <= s_rsc_idle;
                                if sig_dgrb_state = s_test_phases or
                                   sig_dgrb_state = s_seek_cdvw or
                                   sig_dgrb_state = s_read_mtp then

                                    sig_rsc_push_footer <= '1';

                                end if;

                            end if;

                        end if;

                    when others =>
                        null;
                end case;

                sig_rsc_last_state <= sig_rsc_state;
            end if;

        end process;


        -- write results to the iram

        iram_push: process (clk, rst_n)

        begin

            if rst_n = '0' then

                sig_dgrb_iram      <= defaults;
                sig_iram_idle      <= '0';
                sig_dq_pin_ctr_r   <= 0;
                sig_rsc_curr_phase <= 0;

                sig_iram_wds_req   <= 0;


            elsif rising_edge(clk) then

                if GENERATE_ADDITIONAL_DBG_RTL = 1 then

                    if sig_dgrb_iram.iram_write = '1' and sig_dgrb_iram.iram_done = '1' then
                        report dgrb_report_prefix & "iram_done and iram_write signals concurrently set - iram contents may be corrupted" severity failure;
                    end if;

                    if sig_dgrb_iram.iram_write = '0' and sig_dgrb_iram.iram_done = '0' then
                        sig_iram_idle            <= '1';
                    else
                        sig_iram_idle            <= '0';
                    end if;

                    -- registered sig_dq_pin_ctr to align with rrp_sweep result
                    sig_dq_pin_ctr_r   <= sig_dq_pin_ctr;

                    -- calculate current phase (registered to align with rrp_sweep result)
                    sig_rsc_curr_phase <= (c_max_phase_shifts - 1) - sig_num_phase_shifts;

                    -- serial push of rrp_sweep results into memory
                    if sig_rsc_push_rrp_sweep = '1' then

                        -- signal an iram write and track a write pending
                        sig_dgrb_iram.iram_write <= '1';
                        sig_iram_idle            <= '0';

                        -- if not single_bit_cal then pack pin phase results in MEM_IF_DWIDTH word blocks
                        if single_bit_cal = '1' then
                            sig_dgrb_iram.iram_wordnum <= sig_dq_pin_ctr_r + (sig_rsc_curr_phase/32);
                            sig_iram_wds_req           <= iram_wd_for_one_pin_rrp( DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, MEM_IF_DWIDTH, MEM_IF_DQS_CAPTURE);  -- note total word requirement
                        else
                            sig_dgrb_iram.iram_wordnum <= sig_dq_pin_ctr_r + (sig_rsc_curr_phase/32) * MEM_IF_DWIDTH;
                            sig_iram_wds_req           <= iram_wd_for_full_rrp( DWIDTH_RATIO, PLL_STEPS_PER_CYCLE, MEM_IF_DWIDTH, MEM_IF_DQS_CAPTURE);     -- note total word requirement
                        end if;

                        -- check if current pin and phase passed:
                        sig_dgrb_iram.iram_pushdata(0) <= sig_rsc_push_rrp_pass;

                        -- bit offset is modulo phase
                        sig_dgrb_iram.iram_bitnum  <= sig_rsc_curr_phase mod 32;

                    end if;

                    -- write result of rrp_calc to iram when completed
                    if sig_rsc_push_rrp_seek = '1' then  -- a result found

                        sig_dgrb_iram.iram_write <= '1';
                        sig_iram_idle            <= '0';

                        sig_dgrb_iram.iram_wordnum <= 0;
                        sig_iram_wds_req           <= 1; -- note total word requirement

                        if sig_cdvw_state.status = valid_result then  -- result is valid

                            sig_dgrb_iram.iram_pushdata <= x"0000" &
                                                           std_logic_vector(to_unsigned(sig_cdvw_state.largest_window_centre, 8)) &
                                                           std_logic_vector(to_unsigned(sig_cdvw_state.largest_window_size, 8));

                        else  -- invalid result (error code communicated elsewhere)

                            sig_dgrb_iram.iram_pushdata <= x"FFFF" & -- signals an error condition
                                                           x"0000";

                        end if;

                    end if;

                    -- when stage finished write footer
                    -- #pb_del Note: this can occur once the dgrb state has finished because there is no dependency on the write_mode and packing_mode
                    -- #pb_del       as with the pushing of rrp_sweep and rrp_seek results
                    if sig_rsc_push_footer = '1' then

                        sig_dgrb_iram.iram_done <= '1';
                        sig_iram_idle           <= '0';

                        -- set address location of footer
                        sig_dgrb_iram.iram_wordnum <= sig_iram_wds_req;

                    end if;

                    -- if write completed deassert iram_write and done signals
                    if iram_push_done = '1' then

                        sig_dgrb_iram.iram_write <= '0';
                        sig_dgrb_iram.iram_done  <= '0';

                    end if;

                else

                    sig_iram_idle      <= '0';
                    sig_dq_pin_ctr_r   <= 0;
                    sig_rsc_curr_phase <= 0;

                    sig_dgrb_iram      <= defaults;

                end if;

            end if;

        end process;

        -- concurrently assign sig_dgrb_iram to dgrb_iram
        dgrb_iram <= sig_dgrb_iram;

    end block; -- resync calculation

    -- ------------------------------------------------------------------
    -- test pattern match block
    --
    -- This block handles the sharing of logic for test pattern matching
    -- which is used in resync and postamble calibration / code blocks
    -- ------------------------------------------------------------------
    tp_match_block : block
    --
    --#pb_del Ascii SillyScope:
    --  Ascii Waveforms:
    --
    --                    ;         ;         ;         ;         ;         ;
    --                     ____      ____      ____      ____      ____      ____
    --   delayed_dqs |____|    |____|    |____|    |____|    |____|    |____|    |____|
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                    ; _______ ; _______ ; _______ ; _______ ; _______   _______
    --               XXXXX /       \ /       \ /       \ /       \ /       \ /       \
    --         c0,c1 XXXXXX   A B   X   C D   X   E F   X   G H   X   I J   X   L M   X  captured data
    --               XXXXX \_______/ \_______/ \_______/ \_______/ \_______/ \_______/
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                ____;     ____;     ____      ____      ____      ____      ____
    -- 180-resync_clk     |____|    |____|    |____|    |____|    |____|    |____|    |  180deg shift from delayed dqs
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                    ;      _______   _______   _______   _______   _______   ____
    --               XXXXXXXXXX /       \ /       \ /       \ /       \ /       \ /
    --     180-r0,r1 XXXXXXXXXXX   A B   X   C D   X   E F   X   G H   X   I J   X   L   resync data
    --               XXXXXXXXXX \_______/ \_______/ \_______/ \_______/ \_______/ \____
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                     ____      ____      ____      ____      ____      ____
    -- 360-resync_clk ____|    |____|    |____|    |____|    |____|    |____|    |____|
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ; _______ ; _______ ; _______ ; _______ ; _______
    --               XXXXXXXXXXXXXXX /       \ /       \ /       \ /       \ /       \
    --     360-r0,r1 XXXXXXXXXXXXXXXX   A B   X   C D   X   E F   X   G H   X   I J   X resync data
    --               XXXXXXXXXXXXXXX \_______/ \_______/ \_______/ \_______/ \_______/
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                ____      ____      ____      ____      ____      ____      ____
    -- 540-resync_clk     |____|    |____|    |____|    |____|    |____|    |____|    |
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;      _______   _______   _______   _______   ____
    --                XXXXXXXXXXXXXXXXXXX /       \ /       \ /       \ /       \ /
    --      540-r0,r1 XXXXXXXXXXXXXXXXXXXX   A B   X   C D   X   E F   X   G H   X   I  resync data
    --                XXXXXXXXXXXXXXXXXXX \_______/ \_______/ \_______/ \_______/ \____
    --                    ;         ;         ;         ;         ;         ;
    --                    ;         ;         ;         ;         ;         ;
    --                    ;____      ____      ____      ____      ____      ____
    --       phy_clk |____|    |____|    |____|    |____|    |____|    |____|    |____|
    --
    --                    0         1         2         3         4         5         6
    --
    --
    --              |<- Aligned Data ->|
    --      phy_clk 180-r0,r1  540-r0,r1  sig_mtp_match_en (generated from sig_ac_even)
    --            0  XXXXXXXX   XXXXXXXX  '1'
    --            1  XXXXXXAB   XXXXXXXX  '0'
    --            2  XXXXABCD   XXXXXXAB  '1'
    --            3  XXABCDEF   XXXXABCD  '0'
    --            4  ABCDEFGH   XXABCDEF  '1'
    --            5  CDEFGHAB   ABCDEFGH  '0'
    --
    --  In DQS-based capture, sweeping resync_clk from 180 degrees to 360
    --  does not necessarily result in a failure because the setup/hold
    --  requirements are so small.  The data comparison needs to fail when
    --  the resync_clk is shifted more than 360 degrees.  The
    --  sig_mtp_match_en signal allows the sequencer to blind itself
    --  training pattern matches that occur above 360 degrees.
    --
    --#pb_del -ktc
    --
    --
    --
    --
    --  Asserts sig_mtp_match.
    --
    --  Data comes in from rdata and is pushed into a two-bit wide shift register.
    --  It is a critical assumption that the rdata comes back byte aligned.
    --
    --
    --sig_mtp_match_valid
    --   rdata_valid  (shift-enable)
    --      |
    --      |
    --      +-----------------------+-----------+------------------+
    --                 ___          |           |                  |
    --     dq(0)  >---|   \         |     Shift Register           |
    --     dq(1)  >---|    \     +------+    +------+           +------------------+
    --     dq(2)  >---|     )--->| D(0) |-+->| D(1) |-+->...-+->| D(c_cal_mtp_len - 1) |
    --     ...        |    /     +------+ |  +------+ |      |  +------------------+
    --   dq(n-1)  >---|___/               +-----------++-...-+
    --                  |                             ||                                 +---+
    --                  |                            (==)--------> sig_mtp_match_0t ---->|   |-->sig_mtp_match_1t-->sig_mtp_match
    --                  |                             ||                                 +---+
    --                  |                 +-----------++...-+
    -- sig_dq_pin_ctr >-+        +------+ |  +------+ |     |  +------------------+
    --                           | P(0) |-+  | P(1) |-+ ...-+->| P(c_cal_mtp_len - 1) |
    --                           +------+    +------+          +------------------+
    --
    --
    --
    --
        signal sig_rdata_current_pin : std_logic_vector(c_cal_mtp_len - 1 downto 0);

        -- A fundamental assumption here is that rdata_valid is all
        -- ones or all zeros - not both.
        signal sig_rdata_valid_1t : std_logic; -- rdata_valid delayed by 1 clock period.
        signal sig_rdata_valid_2t : std_logic; -- rdata_valid delayed by 2 clock periods.

    begin
        rdata_valid_1t_proc : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_rdata_valid_1t <= '0';
                sig_rdata_valid_2t <= '0';
            elsif rising_edge(clk) then
                sig_rdata_valid_2t <= sig_rdata_valid_1t;
                sig_rdata_valid_1t <= rdata_valid(0);
            end if;
        end process;


        -- MUX data into sig_rdata_current_pin shift register.
        rdata_current_pin_proc: process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_rdata_current_pin <= (others => '0');
            elsif rising_edge(clk) then
                -- shift old data down the shift register
                sig_rdata_current_pin(sig_rdata_current_pin'high - DWIDTH_RATIO downto 0) <=
                    sig_rdata_current_pin(sig_rdata_current_pin'high downto DWIDTH_RATIO);

                -- shift new data into the bottom of the shift register.
                for i in 0 to DWIDTH_RATIO - 1 loop
                    sig_rdata_current_pin(sig_rdata_current_pin'high - DWIDTH_RATIO + 1 + i) <= rdata(i*MEM_IF_DWIDTH + sig_dq_pin_ctr);
                end loop;
           end if;
        end process;



        mtp_match_proc : process (clk, rst_n)
        begin
            if rst_n = '0' then --  * when at least c_max_read_lat clock cycles have passed
                sig_mtp_match <= '0';
            elsif rising_edge(clk) then
                sig_mtp_match <= '0';

                if sig_rdata_current_pin = c_cal_mtp then
                    sig_mtp_match <= '1';
                end if;
            end if;
        end process;


        poa_match_proc : process (clk, rst_n)
        -- poa_match_Calibration Strategy
        --
        --#pb_del Ascii SillyScope (FR):
        --  Ascii Waveforms:
        --
        --                   __    __    __    __    __    __    __    __    __
        --            clk __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |
        --
        --                                          ;     ;     ;     ;
        --                         _________________
        --    rdata_valid ________|                 |___________________________
        --
        --                                          ;     ;     ;     ;
        --                                                       _____
        --   poa_match_en ______________________________________|     |_______________
        --
        --                                          ;     ;     ;     ;
        --                                                       _____
        --      poa_match XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     XXXXXXXXXXXXXXXX
        --
        --
        -- Notes:
        --   -poa_match is only valid while poa_match_en is asserted.
        --
        --
        --
        --
        --
        --
        begin
            if rst_n = '0' then

                sig_poa_match_en <= '0';
                sig_poa_match    <= '0';

            elsif rising_edge(clk) then
                sig_poa_match <= '0';

                sig_poa_match_en <= '0';
                if sig_rdata_valid_2t = '1' and sig_rdata_valid_1t = '0' then
                    sig_poa_match_en <= '1';
                end if;

                if DWIDTH_RATIO = 2 then
                    if sig_rdata_current_pin(sig_rdata_current_pin'high downto sig_rdata_current_pin'length - 6) = "111100" then
                        sig_poa_match <= '1';
                    end if;
                elsif DWIDTH_RATIO = 4 then
                    if sig_rdata_current_pin(sig_rdata_current_pin'high downto sig_rdata_current_pin'length - 8) = "11111100" then
                        sig_poa_match <= '1';
                    end if;
                else
                    report dgrb_report_prefix & "unsupported DWIDTH_RATIO" severity failure;
                end if;

            end if;
        end process;
    end block;

    -- ------------------------------------------------------------------
    -- Postamble calibration
    --
    -- Implements the postamble slave state machine and collates the
    -- processing data from the test pattern match block.
    -- ------------------------------------------------------------------
    poa_block : block
    -- Postamble Calibration Strategy
    --
    --#pb_del Ascii SillyScope:
    --  Ascii Waveforms:
    --
    --                   c_read_burst_t      c_read_burst_t
    --                    ;<------->;         ;<------->;
    --                    ;         ;         ;         ;
    --                            __      / /         __
    --      mem_dq[0] ___________|  |_____\ \________|  |___
    --
    --                    ;         ;         ;         ;
    --                    ;         ;         ;         ;
    --                       _________    / /  _________
    --     poa_enable ______|         |___\ \_|         |___
    --                    ;         ;         ;         ;
    --                    ;         ;         ;         ;
    --                            __       / /        ______
    --       rdata[0] ___________|  |______\ \_______|
    --                    ;         ;         ;         ;
    --                    ;         ;         ;         ;
    --                    ;         ;         ;         ;
    --                               _    / /            _
    --    poa_match_en _____________| |___\ \___________| |_
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                                    / /            _
    --       poa_match ___________________\ \___________| |_
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                                 _  / /
    -- seq_poa_lat_dec _______________| |_\ \_______________
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --                                    / /
    -- seq_poa_lat_inc ___________________\ \_______________
    --                    ;         ; ;       ;         ; ;
    --                    ;         ; ;       ;         ; ;
    --
    --                             (1)                 (2)
    --
    --
    -- (1) poa_enable signal is late, and the zeros on mem_dq after (1)
    --    are captured.
    -- (2) poa_enable signal is aligned.  Zeros following (2) are not
    --    captured rdata remains at '1'.
    --
    --   The DQS capture circuit wth the dqs enable asynchronous set.
    --
    --
    --
    --  dqs_en_async_preset ----------+
    --                                |
    --                                v
    --                           +---------+
    --                        +--|Q  SET  D|----------- gnd
    --                        |  |        <O---+
    --                        |  +---------+   |
    --                        |                |
    --                        |                |
    --                        +--+---.         |
    --                           |AND )--------+------- dqs_bus
    --          delayed_dqs -----+---^
    --
    --
    --
    --                     _____       _____       _____       _____
    --           dqs  ____|     |_____|     |_____|     |_____|     |_____XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    --                    ;  ;           ;           ;           ;
    --                       ;           ;           ;           ;
    --                        _____       _____       _____       _____
    --   delayed_dqs  _______|     |_____|     |_____|     |_____|     |_____XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    --
    --                       ;           ;           ;           ;           ;
    --                       ;                      ______________________________________________________________
    -- dqs_en_async_  _____________________________|                                                              |_____
    --        preset
    --                       ;           ;           ;           ;           ;
    --                       ;           ;           ;           ;           ;
    --                        _____                   _____       _____
    --       dqs_bus  _______|     |_________________|     |_____|     |_____XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    --
    --                       ;                       ;
    --                      (1)                     (2)
    --
    --
    -- Notes:
    --    (1) The dqs_bus pulse here comes because the last value of Q
    --       is '1' until the first DQS pulse clocks gnd into the FF,
    --       brings low the AND gate, and disables dqs_bus.  A training
    --       pattern could potentially match at this point even though
    --       between (1) and (2) there are no dqs_bus triggers.  Data
    --       is frozen on rdata while awaiting the dqs_bus pulses at
    --       (2).  For this reason, wait until the first match of the
    --       training pattern, and continue reducing latency until it
    --       TP no longer matches, then increase latency by one.  In
    --       this case, dqs_en_async_preset will have its latency
    --       reduced by three until the training pattern is not matched,
    --       then latency is increased by one.
    --
    --
    -- #pb_del -ktc (2008-12-02)
    --
    --

        -- Postamble calibration state
        type t_poa_state is (
            -- decrease poa enable latency by 1 cycle iteratively until 'correct' position found
            s_poa_rewind_to_pass,
            -- poa cal complete
            s_poa_done
        );

        constant c_poa_lat_cmd_wait : natural := 10; -- Number of clock cycles to wait for lat_inc/lat_dec signal to take effect.
        constant c_poa_max_lat : natural := 100; -- Maximum number of allowable latency changes.
        signal sig_poa_adjust_count : integer range 0 to 2**8 - 1;

        signal sig_poa_state : t_poa_state;


    begin

        poa_proc : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_poa_ack <= '0';
                seq_poa_lat_dec_1x <= (others => '0');
                seq_poa_lat_inc_1x <= (others => '0');
                sig_poa_adjust_count <= 0;

                sig_poa_state <= s_poa_rewind_to_pass;

            elsif rising_edge(clk) then
                sig_poa_ack        <= '0';
                seq_poa_lat_inc_1x <= (others => '0');
                seq_poa_lat_dec_1x <= (others => '0');

                if sig_dgrb_state = s_poa_cal then
                    case sig_poa_state is
                        when s_poa_rewind_to_pass =>
                            -- In postamble calibration
                            --
                            -- Normally, must wait for sig_dimm_driving_dq to be '1'
                            -- before reading, but by this point in calibration
                            -- rdata_valid is assumed to be set up properly.  The
                            -- sig_poa_match_en (derived from rdata_valid) is used
                            -- here rather than sig_dimm_driving_dq.
                            if sig_poa_match_en = '1' then
                                if sig_poa_match = '1' then
                                    sig_poa_state <= s_poa_done;
                                else
                                    seq_poa_lat_dec_1x <= (others => '1');
                                end if;

                                sig_poa_adjust_count <= sig_poa_adjust_count + 1;
                            end if;


                        when s_poa_done =>
                            sig_poa_ack <= '1';
                    end case;
                else
                    sig_poa_state        <= s_poa_rewind_to_pass;
                    sig_poa_adjust_count <= 0;
                end if;


                assert sig_poa_adjust_count <= c_poa_max_lat
                    report dgrb_report_prefix & "Maximum number of postamble latency adjustments exceeded."
                    severity failure;
            end if;
        end process;

    end block;

    -- ------------------------------------------------------------------
    -- code block for tracking signal generation
    --
    -- this is used for initial tracking setup (finding a reference window)
    -- and periodic tracking operations (PVT compensation on rsc phase)
    --
    -- A slave trk state machine is described and implemented within the block
    -- The mimic path is controlled within this block
    -- ------------------------------------------------------------------
    trk_block : block

        type t_tracking_state is (
            -- initialise variables out of reset
            s_trk_init,
            -- idle state
            s_trk_idle,
            -- sample data from the mimic path (build window)
            s_trk_mimic_sample,
            -- 'shift' mimic path phase
            s_trk_next_phase,
            -- calculate mimic window
            s_trk_cdvw_calc,
            s_trk_cdvw_wait, -- for results
            -- calculate how much mimic window has moved (only entered in periodic tracking)
            s_trk_cdvw_drift,
            -- track rsc phase (only entered in periodic tracking)
            s_trk_adjust_resync,
            -- communicate command complete to the master state machine
            s_trk_complete
        );

        signal sig_mmc_seq_done              : std_logic;
        signal sig_mmc_seq_done_1t           : std_logic;
        signal mmc_seq_value_r               : std_logic;

        signal sig_mmc_start                 : std_logic;

        signal sig_trk_state                 : t_tracking_state;
        signal sig_trk_last_state            : t_tracking_state;

        signal sig_rsc_drift                 : integer range -c_max_rsc_drift_in_phases to c_max_rsc_drift_in_phases;  -- stores total change in rsc phase from first calibration
        signal sig_req_rsc_shift             : integer range -c_max_rsc_drift_in_phases to c_max_rsc_drift_in_phases;  -- stores required shift in rsc phase instantaneously
        signal sig_mimic_cdv_found           : std_logic;
        signal sig_mimic_cdv                 : integer range 0 to PLL_STEPS_PER_CYCLE;  -- centre of data valid window calculated from first mimic-cycle
        signal sig_mimic_delta               : integer range -PLL_STEPS_PER_CYCLE to PLL_STEPS_PER_CYCLE;
        signal sig_large_drift_seen          : std_logic;

        signal sig_remaining_samples         : natural range 0 to 2**8 - 1;

    begin

        -- advertise the codvw phase shift
        process (clk, rst_n)
            variable v_length : integer;
        begin

            if rst_n = '0' then

                codvw_trk_shift <= (others => '0');

            elsif rising_edge(clk) then

                if sig_mimic_cdv_found = '1' then

                    -- check range
                    v_length := codvw_trk_shift'length;

                    codvw_trk_shift <= std_logic_vector(to_signed(sig_rsc_drift, v_length));

                else

                    codvw_trk_shift <= (others => '0');

                end if;

            end if;
        end process;

        -- request a mimic sample
        mimic_sample_req : process (clk, rst_n)
            variable seq_mmc_start_r : std_logic_vector(3 downto 0);
        begin
            if rst_n = '0' then
                seq_mmc_start   <= '0';
                seq_mmc_start_r := "0000";
           elsif rising_edge(clk) then

                seq_mmc_start_r(3) := seq_mmc_start_r(2);
                seq_mmc_start_r(2) := seq_mmc_start_r(1);
                seq_mmc_start_r(1) := seq_mmc_start_r(0);

                -- extend sig_mmc_start by one clock cycle
                if sig_mmc_start = '1' then
                    seq_mmc_start <= '1';
                    seq_mmc_start_r(0) := '1';

                elsif ( (seq_mmc_start_r(3) = '1') or (seq_mmc_start_r(2) = '1') or (seq_mmc_start_r(1) = '1') or (seq_mmc_start_r(0) = '1') ) then
                    seq_mmc_start <= '1';
                    seq_mmc_start_r(0) := '0';

                else
                    seq_mmc_start <= '0';

                end if;

            end if;
        end process;

        -- metastability hardening of async mmc_seq_done signal
        -- #pb_del Triple register it for metastability hardening.  Other
        -- #pb_del processes are intended to read the sig_mmc_seq_done and
        -- #pb_del sig_mmc_seq_done_1t signal.
        mmc_seq_req_sync : process (clk, rst_n)
            variable v_mmc_seq_done_1r           : std_logic;
            variable v_mmc_seq_done_2r           : std_logic;
            variable v_mmc_seq_done_3r           : std_logic;
        begin
            if rst_n = '0' then
                sig_mmc_seq_done    <= '0';
                sig_mmc_seq_done_1t <= '0';

                v_mmc_seq_done_1r   := '0';
                v_mmc_seq_done_2r   := '0';
                v_mmc_seq_done_3r   := '0';
            elsif rising_edge(clk) then
                sig_mmc_seq_done_1t <= v_mmc_seq_done_3r;
                sig_mmc_seq_done    <= v_mmc_seq_done_2r;

                mmc_seq_value_r     <= mmc_seq_value;

                v_mmc_seq_done_3r   := v_mmc_seq_done_2r;
                v_mmc_seq_done_2r   := v_mmc_seq_done_1r;
                v_mmc_seq_done_1r   := mmc_seq_done;

            end if;
        end process;


        -- collect mimic samples as they arrive
        shift_in_mmc_seq_value : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_trk_cdvw_shift_in <= '0';
                sig_trk_cdvw_phase    <= '0';
            elsif rising_edge(clk) then
                sig_trk_cdvw_shift_in <= '0';
                sig_trk_cdvw_phase    <= '0';
                if sig_mmc_seq_done_1t = '1' and sig_mmc_seq_done = '0' then
                    sig_trk_cdvw_shift_in <= '1';
                    sig_trk_cdvw_phase <= mmc_seq_value_r;
                end if;
            end if;
        end process;


        -- main tracking state machine
        trk_proc : process (clk, rst_n)
        begin
            if rst_n = '0' then
                sig_trk_state      <= s_trk_init;
                sig_trk_last_state <= s_trk_init;

                sig_trk_result          <= (others => '0');
                sig_trk_err             <= '0';
                sig_mmc_start           <= '0';

                sig_trk_pll_select      <= (others => '0');

                sig_req_rsc_shift       <= -c_max_rsc_drift_in_phases;
                sig_rsc_drift           <= -c_max_rsc_drift_in_phases;
                sig_mimic_delta         <= -PLL_STEPS_PER_CYCLE;

                sig_mimic_cdv_found     <= '0';
                sig_mimic_cdv           <= 0;

                sig_large_drift_seen    <= '0';

                sig_trk_cdvw_calc       <= '0';

                sig_remaining_samples   <= 0;

                sig_trk_pll_start_reconfig <= '0';
                sig_trk_pll_inc_dec_n      <= c_pll_phs_inc;

                sig_trk_ack                <= '0';

            elsif rising_edge(clk) then
                sig_trk_pll_select         <= pll_measure_clk_index;
                sig_trk_pll_start_reconfig <= '0';
                sig_trk_pll_inc_dec_n      <= c_pll_phs_inc;
                sig_large_drift_seen       <= '0';

                sig_trk_cdvw_calc  <= '0';

                sig_trk_ack        <= '0';
                sig_trk_err        <= '0';
                sig_trk_result     <= (others => '0');

                sig_mmc_start      <= '0';

                -- if no cdv found then reset tracking results
                if sig_mimic_cdv_found = '0' then
                    sig_rsc_drift       <= 0;
                    sig_req_rsc_shift   <= 0;
                    sig_mimic_delta     <= 0;
                end if;

                if sig_dgrb_state = s_track then

                    -- resync state machine
                    case sig_trk_state is
                        when s_trk_init =>
                            sig_trk_state       <= s_trk_idle;
                            sig_mimic_cdv_found <= '0';
                            sig_rsc_drift       <= 0;
                            sig_req_rsc_shift   <= 0;
                            sig_mimic_delta     <= 0;


                        when s_trk_idle =>
                            sig_remaining_samples <= PLL_STEPS_PER_CYCLE;  -- ensure a 360 degrees sweep
                            sig_trk_state         <= s_trk_mimic_sample;


                        when s_trk_mimic_sample =>
                            if sig_remaining_samples = 0 then
                                sig_trk_state  <= s_trk_cdvw_calc;
                            else
                                if sig_trk_state /= sig_trk_last_state then
                                    -- request a sample as soon as we arrive in this state.
                                    -- the default value of sig_mmc_start is zero!
                                    sig_mmc_start <= '1';
                                end if;

                                if sig_mmc_seq_done_1t = '1' and sig_mmc_seq_done = '0' then
                                    -- a sample has been collected, go to next PLL phase
                                    sig_remaining_samples <= sig_remaining_samples - 1;
                                    sig_trk_state         <= s_trk_next_phase;
                                end if;
                            end if;


                        when s_trk_next_phase =>
                            sig_trk_pll_start_reconfig <= '1';
                            sig_trk_pll_inc_dec_n      <= c_pll_phs_inc;

                            if sig_phs_shft_start = '1' then
                                sig_trk_pll_start_reconfig <= '0';
                            end if;

                            if sig_phs_shft_end = '1' then
                                sig_trk_state <= s_trk_mimic_sample;
                            end if;


                        when s_trk_cdvw_calc =>
                            if sig_trk_state /= sig_trk_last_state then
                                -- reset variables we are interested in when we first arrive in this state
                                sig_trk_cdvw_calc <= '1';
                                report dgrb_report_prefix & "gathered mimic phase samples DGRB_MIMIC_SAMPLES: " & str(sig_cdvw_state.working_window(sig_cdvw_state.working_window'high downto sig_cdvw_state.working_window'length - PLL_STEPS_PER_CYCLE)) severity note;
                            else
                                sig_trk_state <= s_trk_cdvw_wait;
                            end if;


                        when s_trk_cdvw_wait =>
                            if sig_cdvw_state.status /= calculating then
                                if sig_cdvw_state.status = valid_result then
                                    report dgrb_report_prefix & "mimic window successfully found." severity note;
                                    if sig_mimic_cdv_found = '0' then  -- first run of tracking operation
                                        sig_mimic_cdv_found <= '1';
                                        sig_mimic_cdv       <= sig_cdvw_state.largest_window_centre;
                                        sig_trk_state       <= s_trk_complete;
                                    else  -- subsequent tracking operation runs
                                        sig_mimic_delta     <= sig_mimic_cdv - sig_cdvw_state.largest_window_centre;
                                        sig_mimic_cdv       <= sig_cdvw_state.largest_window_centre;
                                        sig_trk_state       <= s_trk_cdvw_drift;
                                    end if;
                                else
                                    report dgrb_report_prefix & "couldn't find a data-valid window for tracking." severity cal_fail_sev_level;
                                    sig_trk_ack   <= '1';
                                    sig_trk_err   <= '1';
                                    sig_trk_state <= s_trk_idle;

                                    -- set resync result code
                                    case sig_cdvw_state.status is
                                        when no_invalid_phases =>
                                            sig_trk_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_NO_INVALID_PHASES, sig_trk_result'length));
                                        when multiple_equal_windows =>
                                            sig_trk_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_MULTIPLE_EQUAL_WINDOWS, sig_trk_result'length));
                                        when no_valid_phases =>
                                            sig_trk_result <= std_logic_vector(to_unsigned(C_ERR_RESYNC_NO_VALID_PHASES, sig_trk_result'length));
                                        when others =>
                                            sig_trk_result <= std_logic_vector(to_unsigned(C_ERR_CRITICAL, sig_trk_result'length));
                                    end case;
                                end if;
                            end if;

                        when s_trk_cdvw_drift =>  -- calculate the drift in rsc phase
                            -- pipeline stage 1
                            if abs(sig_mimic_delta) > PLL_STEPS_PER_CYCLE/2 then
                                sig_large_drift_seen <= '1';
                            else
                                sig_large_drift_seen <= '0';
                            end if;

                            --pipeline stage 2
                            -- #pb_del Note: this stage may need pipelining further
                            if sig_trk_state = sig_trk_last_state then
                                if sig_large_drift_seen = '1' then
                                    if sig_mimic_delta < 0 then -- anti-clockwise movement
                                        sig_req_rsc_shift <= sig_req_rsc_shift + sig_mimic_delta + PLL_STEPS_PER_CYCLE;
                                    else  -- clockwise movement
                                        sig_req_rsc_shift <= sig_req_rsc_shift + sig_mimic_delta - PLL_STEPS_PER_CYCLE;
                                    end if;
                                else
                                    sig_req_rsc_shift <= sig_req_rsc_shift + sig_mimic_delta;
                                end if;
                                sig_trk_state <= s_trk_adjust_resync;
                            end if;

                        when s_trk_adjust_resync =>
                            sig_trk_pll_select <= pll_resync_clk_index;

                            --#pb_del TIP: test for equality, and greater-than could
                            --#pb_del be more efficient logic utilization.
                            sig_trk_pll_start_reconfig <= '1';

                            if sig_trk_state /= sig_trk_last_state then
                                if sig_req_rsc_shift < 0 then
                                    sig_trk_pll_inc_dec_n <= c_pll_phs_inc;
                                    sig_req_rsc_shift <= sig_req_rsc_shift + 1;
                                    sig_rsc_drift     <= sig_rsc_drift + 1;
                                elsif sig_req_rsc_shift > 0 then
                                    sig_trk_pll_inc_dec_n <= c_pll_phs_dec;
                                    sig_req_rsc_shift <= sig_req_rsc_shift - 1;
                                    sig_rsc_drift     <= sig_rsc_drift - 1;
                                else
                                    sig_trk_state <= s_trk_complete;
                                    sig_trk_pll_start_reconfig <= '0';
                                end if;
                            else
                                sig_trk_pll_inc_dec_n <= sig_trk_pll_inc_dec_n; -- maintain current value
                            end if;

                            if abs(sig_rsc_drift) = c_max_rsc_drift_in_phases then
                                report dgrb_report_prefix & " a maximum absolute change in resync_clk of " & integer'image(sig_rsc_drift) & " phases has " & LF &
                                                            " occurred (since read resynch phase calibration) during tracking" severity cal_fail_sev_level;
                                sig_trk_err    <= '1';
                                sig_trk_result <= std_logic_vector(to_unsigned(C_ERR_MAX_TRK_SHFT_EXCEEDED, sig_trk_result'length));
                            end if;

                            if sig_phs_shft_start = '1' then
                                sig_trk_pll_start_reconfig <= '0';
                            end if;

                            if sig_phs_shft_end = '1' then
                                sig_trk_state <= s_trk_complete;
                            end if;


                        when s_trk_complete =>
                            sig_trk_ack <= '1';

                    end case;

                    sig_trk_last_state <= sig_trk_state;
                else
                    sig_trk_state      <= s_trk_idle;
                    sig_trk_last_state <= s_trk_idle;
                end if;
            end if;

        end process;


        rsc_drift: process (sig_rsc_drift)
        begin
            sig_trk_rsc_drift <= sig_rsc_drift;  -- communicate tracking shift to rsc process
        end process;


    end block;  -- tracking signals

    -- ------------------------------------------------------------------
    -- write-datapath (WDP) ` and on-chip-termination (OCT) signal
    -- ------------------------------------------------------------------
    wdp_oct : process(clk,rst_n)
    begin
        if rst_n = '0' then
            seq_oct_value   <= c_set_oct_to_rs;
            dgrb_wdp_ovride <= '0';
        elsif rising_edge(clk) then
            if ((sig_dgrb_state = s_idle) or (EN_OCT = 0)) then
                seq_oct_value   <= c_set_oct_to_rs;
                dgrb_wdp_ovride <= '0';
            else
                seq_oct_value   <= c_set_oct_to_rt;
                dgrb_wdp_ovride <= '1';
            end if;
        end if;
    end process;


    -- ------------------------------------------------------------------
    -- handles muxing of error codes to the control block
    -- ------------------------------------------------------------------
    ac_handshake_proc : process(rst_n, clk)
    begin
        if rst_n = '0' then
            dgrb_ctrl          <= defaults;
        elsif rising_edge(clk) then
            dgrb_ctrl          <= defaults;

            if sig_dgrb_state = s_wait_admin and sig_dgrb_last_state = s_idle then
                dgrb_ctrl.command_ack <= '1';
            end if;


            case sig_dgrb_state is
                when s_seek_cdvw =>
                    dgrb_ctrl.command_err       <= sig_rsc_err;
                    dgrb_ctrl.command_result    <= sig_rsc_result;
                when s_track =>
                    dgrb_ctrl.command_err       <= sig_trk_err;
                    dgrb_ctrl.command_result    <= sig_trk_result;
                when others =>  -- from main state machine
                    dgrb_ctrl.command_err       <= sig_cmd_err;
                    dgrb_ctrl.command_result    <= sig_cmd_result;
            end case;

            if ctrl_dgrb_r.command = cmd_read_mtp then  -- check against command because aligned with command done not command_err
                dgrb_ctrl.command_err       <= '0';
                dgrb_ctrl.command_result    <= std_logic_vector(to_unsigned(sig_cdvw_state.largest_window_size,dgrb_ctrl.command_result'length));
            end if;

            if sig_dgrb_state = s_idle and sig_dgrb_last_state = s_release_admin then
                dgrb_ctrl.command_done <= '1';
            end if;
        end if;
    end process;


    -- ------------------------------------------------------------------
    -- address/command state machine
    -- process is commanded to begin reading training patterns.
    --
    -- implements the address/command slave state machine
    -- issues read commands to the memory relative to given calibration
    -- stage being implemented
    -- burst length is dependent on memory type
    -- ------------------------------------------------------------------
    ac_block : block

        -- override the calibration burst length for DDR3 device support
        -- (requires BL8 / on the fly setting in MR in admin block)
        function set_read_bl ( memtype: in string ) return natural is
        begin

            if memtype = "DDR3" then
                return 8;
            elsif memtype = "DDR" or memtype = "DDR2" then
                return c_cal_burst_len;
            else
                report dgrb_report_prefix & " a calibration burst length choice has not been set for memory type " & memtype severity failure;
            end if;

            return 0;

        end function;

        -- parameterisation of the read algorithm by burst length
        constant c_poa_addr_width      : natural := 6;
        constant c_cal_read_burst_len  : natural := set_read_bl(MEM_IF_MEMTYPE);
        constant c_bursts_per_btp      : natural := c_cal_mtp_len / c_cal_read_burst_len;
        constant c_read_burst_t        : natural := c_cal_read_burst_len / DWIDTH_RATIO;
        constant c_max_rdata_valid_lat : natural := 50*(c_cal_read_burst_len / DWIDTH_RATIO); -- maximum latency that rdata_valid can ever have with respect to doing_rd
        constant c_rdv_ones_rd_clks    : natural := (c_max_rdata_valid_lat + c_read_burst_t) / c_read_burst_t;  -- number of cycles to read ones for before a pulse of zeros

        -- array of burst training pattern addresses
        -- here the MTP is used in this addressing
        subtype t_btp_addr    is natural range 0 to 2 ** MEM_IF_ADDR_WIDTH - 1;
        type t_btp_addr_array is array (0 to c_bursts_per_btp - 1) of t_btp_addr;

        -- default values
        function defaults return t_btp_addr_array is
            variable v_btp_array : t_btp_addr_array;
        begin
            for i in 0 to c_bursts_per_btp - 1 loop
                v_btp_array(i) := 0;
            end loop;
            return v_btp_array;
        end function;

        -- load btp array addresses
        -- Note: this scales to burst lengths of 2, 4 and 8
        --       the settings here are specific to the choice of training pattern and need updating if the pattern changes
        function set_btp_addr (mtp_almt : natural ) return t_btp_addr_array is
            variable v_addr_array : t_btp_addr_array;
        begin
            for i in 0 to 8/c_cal_read_burst_len - 1 loop

                -- set addresses for xF5 data
                v_addr_array((c_bursts_per_btp - 1) - i) := MEM_IF_CAL_BASE_COL + c_cal_ofs_xF5 + i*c_cal_read_burst_len;

                -- set addresses for x30 data (based on mtp alignment)
                if mtp_almt = 0 then
                    v_addr_array((c_bursts_per_btp - 1) - (8/c_cal_read_burst_len + i)) := MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_0 + i*c_cal_read_burst_len;
                else
                    v_addr_array((c_bursts_per_btp - 1) - (8/c_cal_read_burst_len + i)) := MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_1 + i*c_cal_read_burst_len;
                end if;

            end loop;

            return v_addr_array;

        end function;


        function find_poa_cycle_period return natural is
            -- Returns the period over which the postamble reads
            -- repeat in c_read_burst_t units.
            variable v_num_bursts : natural;
        begin
            v_num_bursts := 2 ** c_poa_addr_width / c_read_burst_t;
            if v_num_bursts * c_read_burst_t < 2**c_poa_addr_width then
                v_num_bursts := v_num_bursts + 1;
            end if;

            v_num_bursts := v_num_bursts + c_bursts_per_btp + 1;

            return v_num_bursts;
        end function;


        function get_poa_burst_addr(burst_count : in natural; mtp_almt : in natural) return t_btp_addr is
            variable v_addr : t_btp_addr;
        begin
            if burst_count = 0 then
                if mtp_almt = 0 then
                    v_addr := c_cal_ofs_x30_almt_1;
                elsif mtp_almt = 1 then
                    v_addr := c_cal_ofs_x30_almt_0;
                else
                    report "Unsupported mtp_almt " & natural'image(mtp_almt) severity failure;
                end if;

                -- address gets incremented by four if in burst-length four.
                v_addr := v_addr + (8 - c_cal_read_burst_len);
            else
                v_addr := c_cal_ofs_zeros;
            end if;

            return v_addr;
        end function;


        signal btp_addr_array          : t_btp_addr_array;  -- burst training pattern addresses

        signal sig_addr_cmd_state      : t_ac_state;
        signal sig_addr_cmd_last_state : t_ac_state;

        signal sig_doing_rd_count : integer range 0 to c_read_burst_t - 1;
        signal sig_count       : integer range 0 to 2**8 - 1;
        signal sig_setup       : integer range c_max_read_lat downto 0;
        signal sig_burst_count : integer range 0 to c_read_burst_t;

    begin
        -- handles counts for when to begin burst-reads (sig_burst_count)
        -- sets sig_dimm_driving_dq
        -- sets dgrb_ac_access_req
        dimm_driving_dq_proc : process(rst_n, clk)
        begin
            if rst_n = '0' then
                sig_dimm_driving_dq <= '1';
                sig_setup           <= c_max_read_lat;
                sig_burst_count     <= 0;
                dgrb_ac_access_req  <= '0';
                sig_ac_even         <= '0';
            elsif rising_edge(clk) then
                sig_dimm_driving_dq <= '0';

                if sig_addr_cmd_state /= s_ac_idle and sig_addr_cmd_state /= s_ac_relax then
                    dgrb_ac_access_req <= '1';
                else
                    dgrb_ac_access_req <= '0';
                end if;

                case sig_addr_cmd_state is
                    when s_ac_read_mtp | s_ac_read_rdv | s_ac_read_wd_lat | s_ac_read_poa_mtp =>
                        sig_ac_even <= not sig_ac_even;

                        -- a counter that keeps track of when we are ready
                        -- to issue a burst read.  Issue burst read eigvery
                        -- time we are at zero.
                        if sig_burst_count = 0 then
                            sig_burst_count <= c_read_burst_t - 1;
                        else
                            sig_burst_count <= sig_burst_count - 1;
                        end if;


                        if dgrb_ac_access_gnt /= '1' then
                            sig_setup <= c_max_read_lat;
                        else
                            -- primes reads
                            -- signal that dimms are driving dq pins after
                            -- at least c_max_read_lat clock cycles have passed.
                            --
                            if sig_setup = 0 then
                                sig_dimm_driving_dq <= '1';
                            elsif dgrb_ac_access_gnt = '1' then
                                sig_setup <= sig_setup - 1;
                            end if;
                        end if;


                    when s_ac_relax =>
                        sig_dimm_driving_dq <= '1';
                        sig_burst_count <= 0;
                        sig_ac_even <= '0';


                    when others =>
                        sig_burst_count <= 0;
                        sig_ac_even <= '0';

                end case;
            end if;
        end process;


        ac_proc : process(rst_n, clk)
        begin
            if rst_n = '0' then
                sig_count               <= 0;
                sig_addr_cmd_state      <= s_ac_idle;
                sig_addr_cmd_last_state <= s_ac_idle;
                sig_doing_rd_count      <= 0;

                sig_addr_cmd            <= reset(c_seq_addr_cmd_config);

                btp_addr_array           <= defaults;
                sig_doing_rd             <= (others => '0');

            elsif rising_edge(clk) then
                assert c_cal_mtp_len mod c_cal_read_burst_len = 0 report dgrb_report_prefix & "burst-training pattern length must be a multiple of burst-length." severity failure;
                assert MEM_IF_CAL_BANK < 2**MEM_IF_BANKADDR_WIDTH report dgrb_report_prefix & "MEM_IF_CAL_BANK out of range." severity failure;
                assert MEM_IF_CAL_BASE_COL < 2**MEM_IF_ADDR_WIDTH - 1 - C_CAL_DATA_LEN report dgrb_report_prefix & "MEM_IF_CAL_BASE_COL out of range." severity failure;

                sig_addr_cmd   <= deselect(c_seq_addr_cmd_config, sig_addr_cmd);

                if sig_ac_req /= sig_addr_cmd_state and sig_addr_cmd_state /= s_ac_idle then
                -- and dgrb_ac_access_gnt = '1'
                    sig_addr_cmd_state <= s_ac_relax;
                else
                    sig_addr_cmd_state <= sig_ac_req;
                end if;

                if sig_doing_rd_count /= 0 then
                    sig_doing_rd <= (others => '1');
                    sig_doing_rd_count <= sig_doing_rd_count - 1;
                else
                    sig_doing_rd <= (others => '0');
                end if;

                case sig_addr_cmd_state is
                    when s_ac_idle =>
                        sig_addr_cmd   <= defaults(c_seq_addr_cmd_config);


                    when s_ac_relax =>
                        -- waits at least c_max_read_lat before returning to s_ac_idle state
                        if sig_addr_cmd_state /= sig_addr_cmd_last_state then
                            sig_count <= c_max_read_lat;
                        else
                            if sig_count = 0 then
                                sig_addr_cmd_state <= s_ac_idle;
                            else
                                sig_count <= sig_count - 1;
                            end if;
                        end if;

                    when s_ac_read_mtp =>
                        -- reads 'more'-training pattern
                        -- issue read commands for proper addresses

                        -- set burst training pattern (mtp in this case) addresses
                        btp_addr_array <= set_btp_addr(current_mtp_almt);

                        if sig_addr_cmd_state /= sig_addr_cmd_last_state then
                            sig_count <= c_bursts_per_btp - 1;  -- counts number of bursts in a training pattern
                        else
                            sig_doing_rd <= (others => '1');

                            -- issue a read command every c_read_burst_t clock cycles
                            if sig_burst_count = 0 then

                                -- decide which read command to issue
                                for i in 0 to c_bursts_per_btp - 1 loop

                                    if sig_count = i then

                                        sig_addr_cmd <= read(c_seq_addr_cmd_config, -- configuration
                                            sig_addr_cmd,                           -- previous value
                                            MEM_IF_CAL_BANK,                        -- bank
                                            btp_addr_array(i),                      -- column address
                                            2**current_cs,                          -- rank
                                            c_cal_read_burst_len,                   -- burst length
                                            false);
                                    end if;

                                end loop;

                                -- Set next value of count
                                if sig_count = 0 then
                                    sig_count <= c_bursts_per_btp - 1;
                                else
                                    sig_count <= sig_count - 1;
                                end if;

                            end if;

                        end if;

                    when s_ac_read_poa_mtp =>
                        -- Postamble rdata/rdata_valid Activity:
                        --
                        --
                        --                   (0)       (1)                           (2)
                        --                    ;         ;                             ;         ;
                        --               _________   __   ____________  _____________   _______   _________
                        --                        \ /  \ /            \ \            \ /       \ /
                        -- (a)  rdata[0] 00000000  X 11 X  0000000000 / / 0000000000  X   MTP   X  00000000
                        --               _________/ \__/ \____________\ \____________/ \_______/ \_________
                        --                    ;         ;                             ;         ;
                        --                    ;         ;                             ;         ;
                        --                     _________              / /              _________
                        --   rdata_valid  ____|         |_____________\ \_____________|         |__________
                        --
                        --                    ;<- (b) ->;<------------(c)------------>;         ;
                        --                    ;         ;                             ;         ;
                        --
                        --
                        --   This block must issue reads and drive doing_rd to place the above pattern on
                        -- the rdata and rdata_valid ports.  MTP will most likely come back corrupted but
                        -- the postamble block (poa_block) will make the necessary adjustments to improve
                        -- matters.
                        --
                        --   (a) Read zeros followed by two ones.  The two will be at the end of a burst.
                        --      Assert rdata_valid only during the burst containing the ones.
                        --   (b) c_read_burst_t clock cycles.
                        --   (c) Must be greater than but NOT equal to maximum postamble latency clock
                        --      cycles. Another way: c_min = (max_poa_lat + 1) phy clock cycles.  This
                        --      must also be long enough to allow the postamble block to respond to a
                        --      the seq_poa_lat_dec_1x signal, but this requirement is less stringent
                        --      than the first so that we can ignore it.
                        --
                        --   The find_poa_cycle_period function should return (b+c)/c_read_burst_t
                        -- rounded up to the next largest integer.
                        --
                        -- #pb_del (2008-11-24) -ktc
                        --

                        -- set burst training pattern (mtp in this case) addresses
                        btp_addr_array <= set_btp_addr(current_mtp_almt);

                        -- issue read commands for proper addresses
                        if sig_addr_cmd_state /= sig_addr_cmd_last_state then
                            sig_count <= find_poa_cycle_period - 1; -- length of read patter in bursts.
                        elsif dgrb_ac_access_gnt = '1' then
                            -- only begin operation once dgrb_ac_access_gnt has been issued
                            -- otherwise rdata_valid may be asserted when rdasta is not
                            -- valid.
                            --
                            -- *** WARNING: BE SAFE.  DON'T LET THIS HAPPEN TO YOU: ***
                            --
                            --#pb_del Ascii SillyScope:
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ; _______ ;         ; _______ ;         ; _______
                            --               XXXXX /       \ XXXXXXXXX /       \ XXXXXXXXX /       \ XXXXXXXXX
                            --      addr/cmd XXXXXX   READ  XXXXXXXXXXX   READ  XXXXXXXXXXX   READ  XXXXXXXXXXX
                            --               XXXXX \_______/ XXXXXXXXX \_______/ XXXXXXXXX \_______/ XXXXXXXXX
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ;         ;         ;         ;         ;         ; _______
                            --               XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX /       \
                            --         rdata XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   MTP   X
                            --               XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \_______/
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ;         ;         ;         ;         ;         ;
                            --                     _________           _________           _________
                            --      doing_rd  ____|         |_________|         |_________|         |__________
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ;         ;         ;         ;         ;         ;
                            --                               __________________________________________________
                            -- ac_accesss_gnt ______________|
                            --                    ;         ;         ;         ;         ;         ;
                            --                    ;         ;         ;         ;         ;         ;
                            --                                                   _________           _________
                            --    rdata_valid __________________________________|         |_________|         |
                            --                    ;         ;         ;         ;         ;         ;
                            --
                            --                   (0)       (1)                 (2)
                            --
                            --
                            --   Cmmand and doing_rd issued at (0).  The doing_rd signal enters the
                            -- rdata_valid pipe here so that it will return on rdata_valid with the
                            -- expected latency (at this point in calibration, rdata_valid and adv_rd_lat
                            -- should be properly calibrated).  Unlike doing_rd, since ac_access_gnt is not
                            -- asserted the READ command at (0) is never actually issued.  This results
                            -- in the situation at (2) where rdata is undefined yet rdata_valid indicates
                            -- valid data.  The moral of this story is to wait for ac_access_gnt = '1'
                            -- before issuing commands when it is important that rdata_valid be accurate.
                            --
                            --
                            -- #pb_del -ktc (2008-11-18)
                            --
                            --

                            -- #pb_del TODO: we may see BL8 funnies here for DDR3
                            if sig_burst_count = 0 then
                                sig_addr_cmd <= read(c_seq_addr_cmd_config, -- configuration
                                    sig_addr_cmd,                           -- previous value
                                    MEM_IF_CAL_BANK,                        -- bank
                                    get_poa_burst_addr(sig_count, current_mtp_almt),-- column address
                                    2**current_cs,                          -- rank
                                    c_cal_read_burst_len,                   -- burst length
                                    false);


                                -- Set doing_rd
                                if sig_count = 0 then
                                    sig_doing_rd <= (others => '1');
                                    sig_doing_rd_count <= c_read_burst_t - 1; -- Extend doing_rd pulse by this many phy_clk cycles.
                                end if;


                                -- Set next value of count
                                if sig_count = 0 then
                                    sig_count <= find_poa_cycle_period - 1;  -- read for one period then relax (no read) for same time period
                                else
                                    sig_count <= sig_count - 1;
                                end if;
                            end if;
                        end if;


                    when s_ac_read_rdv =>
                        assert c_max_rdata_valid_lat mod c_read_burst_t = 0 report dgrb_report_prefix & "c_max_rdata_valid_lat must be a multiple of c_read_burst_t." severity failure;

                        if sig_addr_cmd_state /= sig_addr_cmd_last_state then
                            sig_count <= c_rdv_ones_rd_clks - 1;
                        else
                            if sig_burst_count = 0 then
                                if sig_count = 0 then
                                    -- expecting to read ZEROS
                                    sig_addr_cmd <= read(c_seq_addr_cmd_config, -- configuration
                                        sig_addr_cmd,                           -- previous valid
                                        MEM_IF_CAL_BANK,                        -- bank
                                        MEM_IF_CAL_BASE_COL + C_CAL_OFS_ZEROS,  -- column
                                        2**current_cs,                          -- rank
                                        c_cal_read_burst_len,                   -- burst length
                                        false);

                                else
                                    -- expecting to read ONES
                                    sig_addr_cmd <= read(c_seq_addr_cmd_config, -- configuration
                                        sig_addr_cmd,                           -- previous value
                                        MEM_IF_CAL_BANK,                        -- bank
                                        MEM_IF_CAL_BASE_COL + C_CAL_OFS_ONES,   -- column address
                                        2**current_cs,                          -- rank
                                        c_cal_read_burst_len,                   -- op length
                                        false);
                                end if;

                                if sig_count = 0 then
                                    sig_count <= c_rdv_ones_rd_clks - 1;
                                else
                                    sig_count <= sig_count - 1;
                                end if;
                            end if;

                            if (sig_count = c_rdv_ones_rd_clks - 1 and sig_burst_count = 1) or
                               (sig_count = 0 and c_read_burst_t = 1) then
                                -- the last burst read- that was issued was supposed to read only zeros
                                -- a burst read command will be issued on the next clock cycle
                                --
                                -- A long (>= maximim rdata_valid latency) series of burst reads are
                                -- issued for ONES.
                                -- Into this stream a single burst read for ZEROs is issued.  After
                                -- the ZERO read command is issued, rdata_valid needs to come back
                                -- high one clock cycle before the next read command (reading ONES
                                -- again) is issued.  Since the rdata_valid is just a delayed
                                -- version of doing_rd, doing_rd needs to exhibit the same behaviour.
                                --
                                -- for FR (burst length 4): require that doing_rd high 1 clock cycle after cs_n is low
                                --               ____      ____      ____      ____      ____      ____      ____      ____      ____
                                -- clk      ____|    |____|    |____|    |____|    |____|    |____|    |____|    |____|    |____|
                                --
                                --          ___             _______             _______             _______             _______
                                --             \ XXXXXXXXX /       \ XXXXXXXXX /       \ XXXXXXXXX /       \ XXXXXXXXX /       \ XXXX
                                -- addr         XXXXXXXXXXX  ONES   XXXXXXXXXXX  ONES   XXXXXXXXXXX  ZEROS  XXXXXXXXXXX  ONES   XXXXX--> Repeat
                                --          ___/ XXXXXXXXX \_______/ XXXXXXXXX \_______/ XXXXXXXXX \_______/ XXXXXXXXX \_______/ XXXX
                                --
                                --               _________           _________           _________           _________           ____
                                -- cs_n     ____|         |_________|         |_________|         |_________|         |_________|
                                --
                                --                                                                           _________
                                -- doing_rd ________________________________________________________________|         |______________
                                --
                                --
                                -- for HR: require that doing_rd high in the same clock cycle as cs_n is low
                                --
                                -- #pb_del NOTE: for quarter rate this needs consideration depending on the relationship of cs_n to doing_rd signal
                                -- #pb_del -ktc

                                sig_doing_rd(MEM_IF_DQS_WIDTH*(DWIDTH_RATIO/2-1)) <= '1';

                            end if;
                        end if;


                    when s_ac_read_wd_lat =>
                        -- continuously issues reads on the memory locations
                        -- containing write latency addr=[2*c_cal_burst_len - (3*c_cal_burst_len - 1)]

                        if sig_addr_cmd_state /= sig_addr_cmd_last_state then
                            -- no initialization required here.  Must still wait
                            -- a clock cycle before beginning operations so that
                            -- we are properly synchronized with
                            -- dimm_driving_dq_proc.
                        else
                            if sig_burst_count = 0 then
                                if sig_dimm_driving_dq = '1' then
                                    sig_doing_rd <= (others => '1');
                                end if;

                                sig_addr_cmd <= read(c_seq_addr_cmd_config,     -- configuration
                                    sig_addr_cmd,                               -- previous value
                                    MEM_IF_CAL_BANK,                            -- bank
                                    MEM_IF_CAL_BASE_COL + c_cal_ofs_wd_lat,     -- column
                                    2**current_cs,                              -- rank
                                    c_cal_read_burst_len,
                                    false);
                            end if;
                        end if;


                    when others =>
                        report dgrb_report_prefix & "undefined state in addr_cmd_proc" severity error;
                        sig_addr_cmd_state <= s_ac_idle;
                end case;

                -- mask odt signal
                for i in 0 to (DWIDTH_RATIO/2)-1 loop
                    sig_addr_cmd(i).odt <= odt_settings(current_cs).read;
                end loop;

                sig_addr_cmd_last_state <= sig_addr_cmd_state;
            end if;

        end process;

    end block ac_block;

end architecture struct;

