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
--  Title           : iram

--  File:  $RCSfile : alt_mem_phy_dgwb.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $

-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : data gatherer (write bias) [dgwb] block for the non-levelling
--                    AFI PHY sequencer
--                    #pb_del: TODO: Keegan insert a small description of the
--                    #pb_del        block here
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

--#mw_prefix ("alt_mem_phy_dgwb")
entity alt_mem_phy_dgwb is
--#end
    generic (
        -- Physical IF width definitions
        MEM_IF_DQS_WIDTH               : natural;
        MEM_IF_DQ_PER_DQS              : natural;
        MEM_IF_DWIDTH                  : natural;
        MEM_IF_DM_WIDTH                : natural;
        DWIDTH_RATIO                   : natural;
        MEM_IF_ADDR_WIDTH              : natural;
        MEM_IF_BANKADDR_WIDTH          : natural;
        MEM_IF_NUM_RANKS               : natural; -- The sequencer outputs memory control signals of width num_ranks
        MEM_IF_MEMTYPE                 : string;
        ADV_LAT_WIDTH                  : natural;
        MEM_IF_CAL_BANK                : natural; -- Bank to which calibration data is written
        -- Base column address to which calibration data is written.
        -- Memory at MEM_IF_CAL_BASE_COL - MEM_IF_CAL_BASE_COL + C_CAL_DATA_LEN - 1
        -- is assumed to contain the proper data.
        MEM_IF_CAL_BASE_COL            : natural
    );
    port (
        -- CLK Reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        parameterisation_rec           : in    t_algm_paramaterisation;

        -- Control interface :
        dgwb_ctrl                      : out   t_ctrl_stat;
        ctrl_dgwb                      : in    t_ctrl_command;

        -- iRAM 'push' interface :
        dgwb_iram                      : out   t_iram_push;
        iram_push_done                 : in    std_logic;

        -- Admin block req/gnt interface.
        dgwb_ac_access_req             : out   std_logic;
        dgwb_ac_access_gnt             : in    std_logic;

        -- WDP interface
        dgwb_dqs_burst                 : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_DQS_WIDTH      - 1 downto 0);
        dgwb_wdata_valid               : out   std_logic_vector((DWIDTH_RATIO/2) * MEM_IF_DQS_WIDTH      - 1 downto 0);
        dgwb_wdata                     : out   std_logic_vector( DWIDTH_RATIO    * MEM_IF_DWIDTH         - 1 downto 0);
        dgwb_dm                        : out   std_logic_vector( DWIDTH_RATIO    * MEM_IF_DM_WIDTH       - 1 downto 0);
        dgwb_dqs                       : out   std_logic_vector( DWIDTH_RATIO                            - 1 downto 0);
        dgwb_wdp_ovride                : out   std_logic;

        -- addr/cmd output for write commands.
        dgwb_ac                        : out t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);

        bypassed_rdata                 : in    std_logic_vector(MEM_IF_DWIDTH-1 downto 0);

        -- odt settings per chip select
        odt_settings                   : in    t_odt_array(0 to MEM_IF_NUM_RANKS-1)

    );

end entity;

library work;

-- The constant package (alt_mem_phy_constants_pkg) contains global 'constants' which are fixed
-- thoughout the sequencer and will not change (for constants which may change between sequencer
-- instances generics are used)
--#mw_prefix ("alt_mem_phy_constants_pkg")
    use work.alt_mem_phy_constants_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_dgwb")
architecture rtl of alt_mem_phy_dgwb is
--#end

    type t_dgwb_state is (
        s_idle,
        s_wait_admin,

        s_write_btp,      -- Writes bit-training pattern
        s_write_ones,     -- Writes ones
        s_write_zeros,    -- Writes zeros
        s_write_mtp,      -- Write more training patterns (requires read to check allignment)
        s_write_01_pairs, -- Writes 01 pairs
        s_write_1100_step,-- Write step function (half zeros, half ones)
        s_write_0011_step,-- Write reversed step function (half ones, half zeros)
        s_write_wlat,     -- Writes the write latency into a memory address.

        s_release_admin
    );

    constant c_seq_addr_cmd_config  : t_addr_cmd_config_rec        := set_config_rec(MEM_IF_ADDR_WIDTH, MEM_IF_BANKADDR_WIDTH, MEM_IF_NUM_RANKS, DWIDTH_RATIO, MEM_IF_MEMTYPE);

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant dgwb_report_prefix     : string  := "alt_mem_phy_seq (dgwb) : ";
--#end

    function dqs_pattern return std_logic_vector is
        variable dqs : std_logic_vector( DWIDTH_RATIO - 1 downto 0);
    begin
        if DWIDTH_RATIO = 2 then
            dqs := "10";
        elsif DWIDTH_RATIO = 4 then
            dqs := "1100";
        else
            report dgwb_report_prefix & "unsupported DWIDTH_RATIO in function dqs_pattern." severity failure;
        end if;
        return dqs;
    end;

    signal sig_addr_cmd             : t_addr_cmd_vector(0 to (DWIDTH_RATIO/2)-1);

    signal sig_dgwb_state           : t_dgwb_state;
    signal sig_dgwb_last_state      : t_dgwb_state;
    signal access_complete          : std_logic;

    signal generate_wdata           : std_logic;  -- for s_write_wlat only

    -- current chip select being processed
    signal current_cs               : natural range 0 to MEM_IF_NUM_RANKS-1;

begin
    dgwb_ac <= sig_addr_cmd;

    -- Set IRAM interface to defaults
    dgwb_iram <= defaults;

    -- Master state machine.  Generates state transitions.
    master_dgwb_state_block : if True generate
        signal sig_ctrl_dgwb : t_ctrl_command; -- registers ctrl_dgwb input.
    begin
	    -- generate the current_cs signal to track which cs accessed by PHY at any instance
	    current_cs_proc : process (clk, rst_n)
	    begin
	        if rst_n = '0' then
	            current_cs <= 0;
	        elsif rising_edge(clk) then
	            if sig_ctrl_dgwb.command_req = '1' then
	                current_cs <= sig_ctrl_dgwb.command_op.current_cs;
	            end if;
	        end if;
	    end process;


        master_dgwb_state_proc : process(rst_n, clk)
        begin
            if rst_n = '0' then
                sig_dgwb_state      <= s_idle;
                sig_dgwb_last_state <= s_idle;
                sig_ctrl_dgwb       <= defaults;
            elsif rising_edge(clk) then
                case sig_dgwb_state is
                    when s_idle =>
                        if sig_ctrl_dgwb.command_req = '1' then
                            if (curr_active_block(sig_ctrl_dgwb.command) = dgwb) then
                                sig_dgwb_state <= s_wait_admin;
                            end if;
                        end if;


                    when s_wait_admin =>
                        case sig_ctrl_dgwb.command is
                            when cmd_write_btp => sig_dgwb_state <= s_write_btp;
                            when cmd_write_mtp => sig_dgwb_state <= s_write_mtp;
                            when cmd_was       => sig_dgwb_state <= s_write_wlat;

                            when others        =>
                                report dgwb_report_prefix & "unknown command" severity error;
                        end case;

                        if dgwb_ac_access_gnt /= '1' then
                            sig_dgwb_state <= s_wait_admin;
                        end if;


                    when s_write_btp =>
                        sig_dgwb_state <= s_write_zeros;


                    when s_write_zeros =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_write_ones;
                        end if;


                    when s_write_ones =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_release_admin;
                        end if;


                    when s_write_mtp =>
                        sig_dgwb_state <= s_write_01_pairs;


                    when s_write_01_pairs =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_write_1100_step;
                        end if;

                    when s_write_1100_step =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_write_0011_step;
                        end if;


                    when s_write_0011_step =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_release_admin;
                        end if;


                    when s_write_wlat =>
                        if sig_dgwb_state = sig_dgwb_last_state and access_complete = '1' then
                            sig_dgwb_state <= s_release_admin;
                        end if;


                    when s_release_admin =>
                        if dgwb_ac_access_gnt = '0' then
                            sig_dgwb_state <= s_idle;
                        end if;


                    when others =>
                        report dgwb_report_prefix & "undefined state in addr_cmd_proc" severity error;
                        sig_dgwb_state <= s_idle;
                end case;

                sig_dgwb_last_state <= sig_dgwb_state;
                sig_ctrl_dgwb       <= ctrl_dgwb;
            end if;
        end process;
    end generate;


    -- Generates writes
    ac_write_block : if True generate

        constant C_BURST_T    : natural := C_CAL_BURST_LEN / DWIDTH_RATIO;  -- Number of phy-clock cycles per burst
        constant C_MAX_WLAT   : natural := 2**ADV_LAT_WIDTH-1;  -- Maximum latency in clock cycles
        constant C_MAX_COUNT  : natural := C_MAX_WLAT + C_BURST_T + 4*12 - 1;  -- up to 12 consecutive writes at 4 cycle intervals

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
            report dgwb_report_prefix & "the specified maximum write latency cannot be fully represented in the given number of DQ pins" & LF &
                                        "** NOTE: This may cause overflow when setting ctl_wlat signal" severity warning;
            return MEM_IF_DQ_PER_DQS;
        end function;

        constant C_WLAT_DQ_REP_WIDTH : natural := set_wlat_dq_rep_width;

        signal sig_count      : natural range 0 to 2**8 - 1;
    begin
        ac_write_proc : process(rst_n, clk)
        begin
            if rst_n = '0' then
                dgwb_wdp_ovride  <= '0';
                dgwb_dqs         <= (others => '0');
                dgwb_dm          <= (others => '1');
                dgwb_wdata       <= (others => '0');
                dgwb_dqs_burst   <= (others => '0');
                dgwb_wdata_valid <= (others => '0');
                generate_wdata   <= '0';  -- for s_write_wlat only
                sig_count        <= 0;
                sig_addr_cmd     <= int_pup_reset(c_seq_addr_cmd_config);
                access_complete  <= '0';

            elsif rising_edge(clk) then
                dgwb_wdp_ovride  <= '0';
                dgwb_dqs         <= (others => '0');
                dgwb_dm          <= (others => '1');
                dgwb_wdata       <= (others => '0');
                dgwb_dqs_burst   <= (others => '0');
                dgwb_wdata_valid <= (others => '0');
                sig_addr_cmd     <= deselect(c_seq_addr_cmd_config, sig_addr_cmd);
                access_complete  <= '0';
                generate_wdata   <= '0';  -- for s_write_wlat only

                case sig_dgwb_state is

                    when s_idle =>
                        sig_addr_cmd     <= defaults(c_seq_addr_cmd_config);

                    -- require ones in locations:
                    --  1. c_cal_ofs_ones (8 locations)
                    --  2. 2nd half of location c_cal_ofs_xF5 (4 locations)
                    when s_write_ones =>
                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');

                        -- Write ONES to DQ pins
                        dgwb_wdata       <= (others => '1');
                        dgwb_wdata_valid <= (others => '1');

                        -- Issue write command
                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_count <= 0;
                        else

                            -- ensure safe intervals for DDRx memory writes (min 4 mem clk cycles between writes for BC4 DDR3)
                            if sig_count = 0 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                        -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_ones,   -- address
                                                2**current_cs,                          -- rank
                                                4,                                      -- burst length (fixed at BC4)
                                                false);                                 -- auto-precharge
                            elsif sig_count = 4 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                          -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_ones + 4, -- address
                                                2**current_cs,                            -- rank
                                                4,                                        -- burst length (fixed at BC4)
                                                false);                                   -- auto-precharge
                            elsif sig_count = 8 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                          -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_xF5 + 4,  -- address
                                                2**current_cs,                            -- rank
                                                4,                                        -- burst length (fixed at BC4)
                                                false);                                   -- auto-precharge
                            end if;
                            sig_count <= sig_count + 1;
                        end if;

                        if sig_count = C_MAX_COUNT - 1 then
                            access_complete <= '1';
                        end if;

                    -- require zeros in locations:
                    --  1. c_cal_ofs_zeros (8 locations)
                    --  2. 1st half of c_cal_ofs_x30_almt_0 (4 locations)
                    --  3. 1st half of c_cal_ofs_x30_almt_1 (4 locations)
                    when s_write_zeros =>
                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');

                        -- Write ZEROS to DQ pins
                        dgwb_wdata       <= (others => '0');
                        dgwb_wdata_valid <= (others => '1');

                        -- Issue write command
                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_count <= 0;
                        else

                            if sig_count = 0 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                    sig_addr_cmd,
                                                    MEM_IF_CAL_BANK,                            -- bank
                                                    MEM_IF_CAL_BASE_COL + c_cal_ofs_zeros,      -- address
                                                    2**current_cs,                              -- rank
                                                    4,                                          -- burst length (fixed at BC4)
                                                    false);                                     -- auto-precharge
                            elsif sig_count = 4 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                    sig_addr_cmd,
                                                    MEM_IF_CAL_BANK,                            -- bank
                                                    MEM_IF_CAL_BASE_COL + c_cal_ofs_zeros + 4,  -- address
                                                    2**current_cs,                              -- rank
                                                    4,                                          -- burst length (fixed at BC4)
                                                    false);                                     -- auto-precharge
                            elsif sig_count = 8 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                    sig_addr_cmd,
                                                    MEM_IF_CAL_BANK,                            -- bank
                                                    MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_0, -- address
                                                    2**current_cs,                              -- rank
                                                    4,                                          -- burst length (fixed at BC4)
                                                    false);                                     -- auto-precharge
                            elsif sig_count = 12 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                    sig_addr_cmd,
                                                    MEM_IF_CAL_BANK,                            -- bank
                                                    MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_1, -- address
                                                    2**current_cs,                              -- rank
                                                    4,                                          -- burst length (fixed at BC4)
                                                    false);                                     -- auto-precharge
                            end if;
                            sig_count <= sig_count + 1;
                        end if;


                        if sig_count = C_MAX_COUNT - 1 then
                            access_complete <= '1';
                        end if;

                    -- require 0101 pattern in locations:
                    --  1. 1st half of location c_cal_ofs_xF5 (4 locations)
                    when s_write_01_pairs =>
                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');

                        dgwb_wdata_valid <= (others => '1');

                        -- Issue write command
                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_count <= 0;
                        else
                            if sig_count = 0 then
                                sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                       -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_xF5,   -- address
                                                2**current_cs,                         -- rank
                                                4,                                     -- burst length
                                                false);                                -- auto-precharge
                            end if;
                            sig_count <= sig_count + 1;
                        end if;


                        if sig_count = C_MAX_COUNT - 1 then
                            access_complete <= '1';
                        end if;

                        -- Write 01 to pairs of memory addresses
                        for i in 0 to dgwb_wdata'length / MEM_IF_DWIDTH - 1 loop
                            if i mod 2 = 0 then
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '1');
                            else
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '0');
                            end if;
                        end loop;

                    -- require pattern "0011" (or "1100") in locations:
                    --  1. 2nd half of c_cal_ofs_x30_almt_0 (4 locations)
                    when s_write_0011_step =>
                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');

                        dgwb_wdata_valid <= (others => '1');

                        -- Issue write command
                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                                -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_0 + 4, -- address
                                                2**current_cs,                                  -- rank
                                                4,                                              -- burst length
                                                false);                                         -- auto-precharge
                            sig_count <= 0;
                        else
                            sig_count <= sig_count + 1;
                        end if;


                        if sig_count = C_MAX_COUNT - 1 then
                            access_complete <= '1';
                        end if;

                        -- Write 0011 step to column addresses.  Note that
                        -- it cannot be determined which at this point.  The
                        -- strategy is to write both alignments and see which
                        -- one is correct later on.

                        -- this calculation has 2 parts:
                        -- a) sig_count mod C_BURST_T is a timewise iterator of repetition of the pattern
                        -- b) i represents the temporal iterator of the pattern
                        -- it is required to sum a and b and switch the pattern between 0 and 1 every 2 locations in each dimension
                        -- Note: the same formulae is used below for the 1100 pattern

                        for i in 0 to dgwb_wdata'length / MEM_IF_DWIDTH - 1 loop
                            if ((sig_count mod C_BURST_T) + (i/2)) mod 2 = 0 then
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '0');
                            else
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '1');
                            end if;
                        end loop;

                    -- require pattern "1100" (or "0011") in locations:
                    --  1. 2nd half of c_cal_ofs_x30_almt_1 (4 locations)
                    when s_write_1100_step =>
                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');

                        dgwb_wdata_valid <= (others => '1');

                        -- Issue write command
                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_addr_cmd <= write(c_seq_addr_cmd_config,
                                                sig_addr_cmd,
                                                MEM_IF_CAL_BANK,                                -- bank
                                                MEM_IF_CAL_BASE_COL + c_cal_ofs_x30_almt_1 + 4, -- address
                                                2**current_cs,                                  -- rank
                                                4,                                              -- burst length
                                                false);                                         -- auto-precharge
                            sig_count <= 0;
                        else
                            sig_count <= sig_count + 1;
                        end if;


                        if sig_count = C_MAX_COUNT - 1 then
                            access_complete <= '1';
                        end if;

                        -- Write 1100 step to column addresses.  Note that
                        -- it cannot be determined which at this point.  The
                        -- strategy is to write both alignments and see which
                        -- one is correct later on.
                        for i in 0 to dgwb_wdata'length / MEM_IF_DWIDTH - 1 loop
                            if ((sig_count mod C_BURST_T) + (i/2)) mod 2 = 0 then
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '1');
                            else
                                dgwb_wdata((i+1)*MEM_IF_DWIDTH - 1 downto i*MEM_IF_DWIDTH) <= (others => '0');
                            end if;
                        end loop;


                    when s_write_wlat =>
                        -- Effect:
                        --   *Writes the memory latency to an array formed
                        --   from memory addr=[2*C_CAL_BURST_LEN-(3*C_CAL_BURST_LEN-1)].
                        --   The write latency is written to pairs of addresses
                        --   across the given range.
                        --
                        --   Example
                        --   C_CAL_BURST_LEN = 4
                        --   addr 8  -  9 [WLAT]  size = 2*MEM_IF_DWIDTH bits
                        --   addr 10 - 11 [WLAT]  size = 2*MEM_IF_DWIDTH bits
                        --

                        dgwb_wdp_ovride  <= '1';
                        dgwb_dqs         <= dqs_pattern;
                        dgwb_dm          <= (others => '0');
                        dgwb_wdata       <= (others => '0');
                        dgwb_dqs_burst   <= (others => '1');
                        dgwb_wdata_valid <= (others => '1');

                        if sig_dgwb_state /= sig_dgwb_last_state then
                            sig_addr_cmd <= write(c_seq_addr_cmd_config,    -- A/C configuration
                                sig_addr_cmd,
                                MEM_IF_CAL_BANK,                            -- bank
                                MEM_IF_CAL_BASE_COL + c_cal_ofs_wd_lat,     -- address
                                2**current_cs,                              -- rank
                                8,                                          -- burst length (8 for DDR3 and 4 for DDR/DDR2)
                                false);                                     -- auto-precharge
                            sig_count <= 0;
                        else
                            -- hold wdata_valid and wdata 2 clock cycles
                            -- 1 - because ac signal registered at top level of sequencer
                            -- 2 - because want time to dqs_burst edge which occurs 1 cycle earlier
                            --     than wdata_valid in an AFI compliant controller
                            generate_wdata <= '1';
                        end if;

                        if generate_wdata = '1' then
                            for i in 0 to dgwb_wdata'length/C_WLAT_DQ_REP_WIDTH - 1 loop
                                dgwb_wdata((i+1)*C_WLAT_DQ_REP_WIDTH - 1 downto i*C_WLAT_DQ_REP_WIDTH) <= std_logic_vector(to_unsigned(sig_count, C_WLAT_DQ_REP_WIDTH));
                            end loop;

                            -- delay by 1 clock cycle to account for 1 cycle discrepancy
                            -- between dqs_burst and wdata_valid
                            if sig_count = C_MAX_COUNT then
                                access_complete   <= '1';
                            end if;

                            sig_count <= sig_count + 1;
                        end if;

                    when others =>
                        null;
                end case;

                -- mask odt signal
                for i in 0 to (DWIDTH_RATIO/2)-1 loop
                    sig_addr_cmd(i).odt <= odt_settings(current_cs).write;
                end loop;

            end if;
        end process;
    end generate;


    -- Handles handshaking for access to address/command
    ac_handshake_proc : process(rst_n, clk)
    begin
        if rst_n = '0' then
            dgwb_ctrl          <= defaults;
            dgwb_ac_access_req <= '0';
        elsif rising_edge(clk) then
            dgwb_ctrl          <= defaults;
            dgwb_ac_access_req <= '0';

            if sig_dgwb_state /= s_idle and sig_dgwb_state /= s_release_admin then
                dgwb_ac_access_req <= '1';
            elsif sig_dgwb_state = s_idle or sig_dgwb_state = s_release_admin then
                dgwb_ac_access_req <= '0';
            else
                report dgwb_report_prefix & "unexpected state in ac_handshake_proc so haven't requested access to address/command." severity warning;
            end if;

            if sig_dgwb_state = s_wait_admin and sig_dgwb_last_state = s_idle then
                dgwb_ctrl.command_ack <= '1';
            end if;

            if sig_dgwb_state = s_idle and sig_dgwb_last_state = s_release_admin then
                dgwb_ctrl.command_done <= '1';
            end if;
        end if;
    end process;

end architecture rtl;
