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

--  File:  $RCSfile : alt_mem_phy_mmi.vhd,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : mmi block for the non-levelling AFI PHY sequencer
--                    This is an optional block with an Avalon interface and status
--                    register instantiations to enhance the debug capabilities of
--                    the sequencer. The format of the block is:
--                    a) an Avalon interface which supports different avalon and
--                       sequencer clock sources
--                    b) mmi status registers (which hold information about the
--                       successof the calibration)
--                    c) a read interface to the iram to enable debug through the
--                       avalon interface.
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

--#mw_prefix ("alt_mem_phy_mmi")
entity alt_mem_phy_mmi is
--#end
    generic (
        -- physical interface width definitions
        MEM_IF_DQS_WIDTH               : natural;
        MEM_IF_DWIDTH                  : natural;
        MEM_IF_DM_WIDTH                : natural;
        MEM_IF_DQ_PER_DQS              : natural;
        MEM_IF_DQS_CAPTURE             : natural;
        DWIDTH_RATIO                   : natural;
        CLOCK_INDEX_WIDTH              : natural;
        MEM_IF_CLK_PAIR_COUNT          : natural;
        MEM_IF_ADDR_WIDTH              : natural;
        MEM_IF_BANKADDR_WIDTH          : natural;
        MEM_IF_NUM_RANKS               : natural;
        ADV_LAT_WIDTH                  : natural;
        RESYNCHRONISE_AVALON_DBG       : natural;
        AV_IF_ADDR_WIDTH               : natural;
        MEM_IF_MEMTYPE                 : string;

        -- setup / algorithm information
        NOM_DQS_PHASE_SETTING          : natural;
        SCAN_CLK_DIVIDE_BY             : natural;
        RDP_ADDR_WIDTH                 : natural;
        PLL_STEPS_PER_CYCLE            : natural;
        IOE_PHASES_PER_TCK             : natural;
        IOE_DELAYS_PER_PHS             : natural;
        MEM_IF_CLK_PS                  : natural;

        -- initial mode register settings
        PHY_DEF_MR_1ST                 : std_logic_vector(15 downto 0);
        PHY_DEF_MR_2ND                 : std_logic_vector(15 downto 0);
        PHY_DEF_MR_3RD                 : std_logic_vector(15 downto 0);
        PHY_DEF_MR_4TH                 : std_logic_vector(15 downto 0);

        PRESET_RLAT                    : natural;  -- read latency preset value
        CAPABILITIES                   : natural;  -- sequencer capabilities flags

        USE_IRAM                       : std_logic; -- RFU

        IRAM_AWIDTH                    : natural;
        TRACKING_INTERVAL_IN_MS        : natural;

        READ_LAT_WIDTH                 : natural
    );
    port (
        -- clk / reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        --synchronous Avalon debug interface  (internally re-synchronised to input clock)
        dbg_seq_clk                    : in    std_logic;
        dbg_seq_rst_n                  : in    std_logic;
        dbg_seq_addr                   : in    std_logic_vector(AV_IF_ADDR_WIDTH -1 downto 0);
        dbg_seq_wr                     : in    std_logic;
        dbg_seq_rd                     : in    std_logic;
        dbg_seq_cs                     : in    std_logic;
        dbg_seq_wr_data                : in    std_logic_vector(31 downto 0);
        seq_dbg_rd_data                : out   std_logic_vector(31 downto 0);
        seq_dbg_waitrequest            : out   std_logic;

        -- mmi to admin interface
        regs_admin_ctrl                : out  t_admin_ctrl;
        admin_regs_status              : in   t_admin_stat;
        trefi_failure                  : in    std_logic;

        -- mmi to iram interface
        mmi_iram                       : out  t_iram_ctrl;
        mmi_iram_enable_writes         : out  std_logic;

        iram_status                    : in   t_iram_stat;

        -- mmi to control interface
        mmi_ctrl                       : out   t_mmi_ctrl;
        ctrl_mmi                       : in    t_ctrl_mmi;
        int_ac_1t                      : in    std_logic;
        invert_ac_1t                   : out   std_logic;

        -- global parameterisation record
        parameterisation_rec           : out   t_algm_paramaterisation;

        -- mmi pll interface
        pll_mmi                        : in    t_pll_mmi;
        mmi_pll                        : out   t_mmi_pll_reconfig;

        -- codvw status signals
        dgrb_mmi                       : in    t_dgrb_mmi
    );
end entity;

library work;

-- The registers package (alt_mem_phy_regs_pkg) is used to combine the definition of the
-- registers for the mmi status registers and functions/procedures applied to the registers
--#mw_prefix ("alt_mem_phy_regs_pkg")
use work.alt_mem_phy_regs_pkg.all;
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

--#mw_prefix ("alt_mem_phy_mmi")
architecture struct of alt_mem_phy_mmi IS
--#end

    -- maximum function
    function max (a, b : natural) return natural is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function;

-- -------------------------------------------
-- constant definitions
-- -------------------------------------------

    constant c_pll_360_sweeps        : natural                       := rrp_pll_phase_mult(DWIDTH_RATIO, MEM_IF_DQS_CAPTURE);

    constant c_response_lat          : natural                       := 6;
    constant c_codeword              : std_logic_vector(31 downto 0) := c_mmi_access_codeword;
    constant c_int_iram_start_size   : natural                       := max(IRAM_AWIDTH, 4);

    -- enable for ctrl state machine states
    constant c_slv_hl_stage_enable   : std_logic_vector(31 downto 0)                    := std_logic_vector(to_unsigned(CAPABILITIES, 32));
    constant c_hl_stage_enable       : std_logic_vector(c_hl_ccs_num_stages-1 downto 0) := c_slv_hl_stage_enable(c_hl_ccs_num_stages-1 downto 0);

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant mmi_report_prefix     : string  := "alt_mem_phy_seq (mmi) : ";
--#end

-- --------------------------------------------
-- internal signals
-- --------------------------------------------

    -- internal clock domain register interface signals
    signal int_wdata         : std_logic_vector(31                 downto 0);
    signal int_rdata         : std_logic_vector(31                 downto 0);
    signal int_address       : std_logic_vector(AV_IF_ADDR_WIDTH-1 downto 0);
    signal int_read          : std_logic;
    signal int_cs            : std_logic;
    signal int_write         : std_logic;
    signal waitreq_int       : std_logic;

    -- register storage
    -- contains:
       --  read only (ro_regs)
       -- read/write (rw_regs)
       -- enable_writes flag
    signal mmi_regs                   : t_mmi_regs := defaults;
    signal mmi_rw_regs_initialised    : std_logic;

    -- this counter ensures that the mmi waits for c_response_lat clocks before
    -- responding to a new Avalon request
    signal waitreq_count              : natural range 0 to 15;
    signal waitreq_count_is_zero      : std_logic;

    -- register error signals
    signal int_ac_1t_r                : std_logic;
    signal trefi_failure_r            : std_logic;

    -- iram ready - calibration complete and USE_IRAM high
    signal iram_ready                 : std_logic;

begin  -- architecture struct

   -- the following signals are reserved for future use
    invert_ac_1t <= '0';

-- #pb_del: TODO: One of the following (sync/re-sync) works in h/w and one doesn't
-- #pb_del        need to check with Kamran which is ok and which is not - btc

-- --------------------------------------------------------------
-- generate for synchronous avalon interface
-- --------------------------------------------------------------
    simply_registered_avalon : if RESYNCHRONISE_AVALON_DBG = 0 generate
    begin

        process (rst_n, clk)
        begin
            if rst_n = '0' then
                int_wdata           <= (others => '0');
                int_address         <= (others => '0');
                int_read            <= '0';
                int_write           <= '0';
                int_cs              <= '0';
            elsif rising_edge(clk) then
                int_wdata           <= dbg_seq_wr_data;
                int_address         <= dbg_seq_addr;
                int_read            <= dbg_seq_rd;
                int_write           <= dbg_seq_wr;
                int_cs              <= dbg_seq_cs;
            end if;
        end process;

        seq_dbg_rd_data     <= int_rdata;
        seq_dbg_waitrequest <= waitreq_int and (dbg_seq_rd or dbg_seq_wr) and dbg_seq_cs;

    end generate simply_registered_avalon;

-- --------------------------------------------------------------
-- clock domain crossing for asynchronous mmi interface
-- --------------------------------------------------------------
    re_synchronise_avalon : if RESYNCHRONISE_AVALON_DBG = 1 generate

        --clock domain crossing signals
        signal ccd_new_cmd            : std_logic;
        signal ccd_new_cmd_ack        : std_logic;
        signal ccd_cmd_done           : std_logic;
        signal ccd_cmd_done_ack       : std_logic;
        signal ccd_rd_data            : std_logic_vector(dbg_seq_wr_data'range);

        signal ccd_cmd_done_ack_t     : std_logic;
        signal ccd_cmd_done_ack_2t    : std_logic;
        signal ccd_cmd_done_ack_3t    : std_logic;
        signal ccd_cmd_done_t         : std_logic;
        signal ccd_cmd_done_2t        : std_logic;
        signal ccd_cmd_done_3t        : std_logic;

        signal ccd_new_cmd_t       : std_logic;
        signal ccd_new_cmd_2t      : std_logic;
        signal ccd_new_cmd_3t      : std_logic;
        signal ccd_new_cmd_ack_t   : std_logic;
        signal ccd_new_cmd_ack_2t  : std_logic;
        signal ccd_new_cmd_ack_3t  : std_logic;

        signal cmd_pending         : std_logic;

        signal seq_clk_waitreq_int : std_logic;

    begin

        process (rst_n, clk)
        begin
            if rst_n = '0' then
                int_wdata           <= (others => '0');
                int_address         <= (others => '0');
                int_read            <= '0';
                int_write           <= '0';
                int_cs              <= '0';
                ccd_new_cmd_ack     <= '0';
                ccd_new_cmd_t       <= '0';
                ccd_new_cmd_2t      <= '0';
                ccd_new_cmd_3t      <= '0';
            elsif rising_edge(clk) then

                ccd_new_cmd_t       <= ccd_new_cmd;
                ccd_new_cmd_2t      <= ccd_new_cmd_t;
                ccd_new_cmd_3t      <= ccd_new_cmd_2t;

                if ccd_new_cmd_3t = '0' and ccd_new_cmd_2t = '1' then
                    int_wdata           <= dbg_seq_wr_data;
                    int_address         <= dbg_seq_addr;
                    int_read            <= dbg_seq_rd;
                    int_write           <= dbg_seq_wr;
                    int_cs              <= '1';
                    ccd_new_cmd_ack     <= '1';

                elsif ccd_new_cmd_3t = '1' and ccd_new_cmd_2t = '0' then
                    ccd_new_cmd_ack     <= '0';
                end if;

                if int_cs = '1' and waitreq_int= '0' then
                    int_cs    <= '0';
                    int_read  <= '0';
                    int_write <= '0';
                end if;
            end if;

        end process;

        -- process to generate new cmd
        process (dbg_seq_rst_n, dbg_seq_clk)
        begin
            if dbg_seq_rst_n = '0' then
                ccd_new_cmd        <= '0';
                ccd_new_cmd_ack_t  <= '0';
                ccd_new_cmd_ack_2t <= '0';
                ccd_new_cmd_ack_3t <= '0';
                cmd_pending        <= '0';
            elsif rising_edge(dbg_seq_clk) then

                ccd_new_cmd_ack_t   <= ccd_new_cmd_ack;
                ccd_new_cmd_ack_2t  <= ccd_new_cmd_ack_t;
                ccd_new_cmd_ack_3t  <= ccd_new_cmd_ack_2t;

                if ccd_new_cmd = '0' and dbg_seq_cs = '1'  and cmd_pending = '0' then
                    ccd_new_cmd <= '1';
                    cmd_pending <= '1';
                elsif ccd_new_cmd_ack_2t = '1' and ccd_new_cmd_ack_3t = '0' then
                    ccd_new_cmd <= '0';
                end if;

                -- use falling edge of cmd_done
                if cmd_pending = '1' and ccd_cmd_done_2t = '0' and ccd_cmd_done_3t = '1' then
                    cmd_pending <= '0';
                end if;
            end if;
        end process;


        -- process to take read data back and transfer it across the clock domains
        process (rst_n, clk)
        begin
            if rst_n = '0' then
                ccd_cmd_done        <= '0';
                ccd_rd_data         <= (others => '0');
                ccd_cmd_done_ack_3t <= '0';
                ccd_cmd_done_ack_2t <= '0';
                ccd_cmd_done_ack_t  <= '0';

            elsif rising_edge(clk) then

                if ccd_cmd_done_ack_2t = '1' and ccd_cmd_done_ack_3t = '0' then
                    ccd_cmd_done <= '0';
                elsif waitreq_int = '0' then
                    ccd_cmd_done <= '1';
                    ccd_rd_data  <= int_rdata;
                end if;

                ccd_cmd_done_ack_3t <= ccd_cmd_done_ack_2t;
                ccd_cmd_done_ack_2t <= ccd_cmd_done_ack_t;
                ccd_cmd_done_ack_t  <= ccd_cmd_done_ack;
            end if;
        end process;


        process (dbg_seq_rst_n, dbg_seq_clk)
        begin
            if dbg_seq_rst_n = '0' then
                ccd_cmd_done_ack    <= '0';
                ccd_cmd_done_3t     <= '0';
                ccd_cmd_done_2t     <= '0';
                ccd_cmd_done_t      <= '0';
                seq_dbg_rd_data     <= (others => '0');
                seq_clk_waitreq_int <= '1';

            elsif rising_edge(dbg_seq_clk) then
                seq_clk_waitreq_int <= '1';

                if ccd_cmd_done_2t = '1' and ccd_cmd_done_3t = '0' then
                    seq_clk_waitreq_int <= '0';
                    ccd_cmd_done_ack    <= '1';
                    seq_dbg_rd_data     <= ccd_rd_data;  -- if read
                elsif ccd_cmd_done_2t = '0' and ccd_cmd_done_3t = '1' then
                    ccd_cmd_done_ack    <= '0';
                end if;

                ccd_cmd_done_3t <= ccd_cmd_done_2t;
                ccd_cmd_done_2t <= ccd_cmd_done_t;
                ccd_cmd_done_t  <= ccd_cmd_done;
            end if;
        end process;

        seq_dbg_waitrequest <= seq_clk_waitreq_int and (dbg_seq_rd or dbg_seq_wr) and dbg_seq_cs;

    end generate re_synchronise_avalon;


    -- register some inputs for speed.
    process (rst_n, clk)
    begin
        if rst_n = '0' then
            int_ac_1t_r     <= '0';
            trefi_failure_r <= '0';
        elsif rising_edge(clk) then
            int_ac_1t_r     <= int_ac_1t;
            trefi_failure_r <= trefi_failure;
        end if;
    end process;

    -- mmi not able to write to iram in current instance of mmi block
    mmi_iram_enable_writes <= '0';

    -- check if iram ready
    process (rst_n, clk)
    begin
        if rst_n = '0' then
            iram_ready <= '0';
        elsif rising_edge(clk) then
            if USE_IRAM = '0' then
                iram_ready <= '0';
            else
                if ctrl_mmi.ctrl_calibration_success = '1' or ctrl_mmi.ctrl_calibration_fail = '1' then
                    iram_ready <= '1';
                else
                    iram_ready <= '0';
                end if;
            end if;
        end if;
    end process;

-- --------------------------------------------------------------
--  single registered process for mmi access.
-- --------------------------------------------------------------
    process (rst_n, clk)
        variable v_mmi_regs : t_mmi_regs;
    begin
        if rst_n = '0' then

            mmi_regs                <= defaults;
            mmi_rw_regs_initialised <= '0';

            -- this register records whether the c_codeword has been written to address 0x0001
            -- once it has, then other writes are accepted.
            mmi_regs.enable_writes <= '0';

            int_rdata   <= (others => '0');
            waitreq_int <= '1';

            -- clear wait request counter
            waitreq_count <= 0;
            waitreq_count_is_zero <= '1';

            -- iram interface defaults
            mmi_iram <= defaults;

        elsif rising_edge(clk) then
            -- default assignment
            waitreq_int <= '1';

            write_clear(mmi_regs.rw_regs);

            -- only initialise rw_regs once after hard reset
            if mmi_rw_regs_initialised = '0' then

                mmi_rw_regs_initialised <= '1';

                --reset all read/write regs and read path ouput registers and apply default MRS Settings.
                mmi_regs.rw_regs <= defaults(PHY_DEF_MR_1ST,
                                             PHY_DEF_MR_2ND,
                                             PHY_DEF_MR_3RD,
                                             PHY_DEF_MR_4TH,
                                             NOM_DQS_PHASE_SETTING,
                                             PLL_STEPS_PER_CYCLE,
                                             c_pll_360_sweeps,      -- number of times 360 degrees is swept
                                             TRACKING_INTERVAL_IN_MS,
                                             c_hl_stage_enable);

            end if;

            -- bit packing input data structures into the ro_regs structure, for reading
            -- #pb_del Having ro_regs setting here will increase register and LUT count (due to rst_n condition) but will avoid
            -- #pb_del synthesis warnings due to multiple assignments to a record element.
            mmi_regs.ro_regs  <= defaults(dgrb_mmi,
                                          ctrl_mmi,
                                          pll_mmi,
                                          mmi_regs.rw_regs.rw_if_test,
                                          USE_IRAM,
                                          MEM_IF_DQS_CAPTURE,
                                          int_ac_1t_r,
                                          trefi_failure_r,
                                          iram_status,
                                          IRAM_AWIDTH);

            -- write has priority over read
            if int_write = '1' and int_cs = '1' and waitreq_count_is_zero = '1' and waitreq_int = '1' then

                -- mmi local register write
                if to_integer(unsigned(int_address(int_address'high downto 4))) = 0 then

                    v_mmi_regs := mmi_regs;

                    write(v_mmi_regs, to_integer(unsigned(int_address(3 downto 0))), int_wdata);

                    --#pb_del override for enabled high level states (one cannot enable a state disabled by the CAPABILITIES generics) - why?
                    if mmi_regs.enable_writes = '1' then
                        v_mmi_regs.rw_regs.rw_hl_css.hl_css := c_hl_stage_enable or v_mmi_regs.rw_regs.rw_hl_css.hl_css;
                    end if;

                    mmi_regs <= v_mmi_regs;

                    -- handshake for safe transactions
                    waitreq_int   <= '0';
                    waitreq_count <= c_response_lat;

                -- iram write just handshake back (no write supported)
                else

                    waitreq_int   <= '0';
                    waitreq_count <= c_response_lat;

                end if;

            elsif int_read = '1' and int_cs = '1' and waitreq_count_is_zero = '1' and waitreq_int = '1' then

                -- mmi local register read
                if to_integer(unsigned(int_address(int_address'high downto 4))) = 0 then

                    int_rdata <= read(mmi_regs, to_integer(unsigned(int_address(3 downto 0))));

                    waitreq_count <= c_response_lat;
                    waitreq_int   <= '0';  -- acknowledge read command regardless.


                -- iram being addressed
                elsif     to_integer(unsigned(int_address(int_address'high downto c_int_iram_start_size))) = 1
                      and iram_ready = '1'
                      then
                    mmi_iram.read  <= '1';
                    mmi_iram.addr  <= to_integer(unsigned(int_address(IRAM_AWIDTH -1 downto 0)));

                    if iram_status.done = '1' then
                        waitreq_int   <= '0';
                        mmi_iram.read <= '0';
                        waitreq_count <= c_response_lat;
                        int_rdata     <= iram_status.rdata;
                    end if;

                else -- respond and keep the interface from hanging
                    int_rdata     <= x"DEADBEEF";
                    waitreq_int   <= '0';
                    waitreq_count <= c_response_lat;

                end if;

            elsif waitreq_count /= 0 then
                waitreq_count <= waitreq_count -1;

                -- if performing a write, set back to defaults.  If not, default anyway
                mmi_iram <= defaults;

            end if;

            if waitreq_count = 1 or waitreq_count = 0 then
                waitreq_count_is_zero <= '1';   -- as it will be next clock cycle
            else
                waitreq_count_is_zero <= '0';
            end if;

            -- supply iram read data when ready
            if iram_status.done = '1' then
                int_rdata <= iram_status.rdata;
            end if;

        end if;

    end process;

    -- pack the registers into the output data structures
    regs_admin_ctrl                  <= pack_record(mmi_regs.rw_regs);
    parameterisation_rec             <= pack_record(mmi_regs.rw_regs);
    mmi_pll                          <= pack_record(mmi_regs.rw_regs);
    mmi_ctrl                         <= pack_record(mmi_regs.rw_regs);

end architecture struct;
