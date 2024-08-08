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
--  Title           : iram block

--  File:  $RCSfile : alt_mem_phy_iram.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : iram block for the non-levelling AFI PHY sequencer
--                    This block is an optional storage of debug information for
--                    the sequencer. In the current form the iram stores header
--                    information about the arrangement of the sequencer and pass/
--                    fail information for per-delay/phase/pin sweeps for the
--                    read resynch phase calibration stage. Support for debug of
--                    additional commands can be added at a later date
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

-- The altmemphy iram ram (alt_mem_phy_iram_ram) is an inferred ram memory to implement the debug
-- iram ram block
--#mw_prefix ("alt_mem_phy_iram_ram")
use work.alt_mem_phy_iram_ram;
--#end

--#mw_prefix ("alt_mem_phy_iram")
entity alt_mem_phy_iram is
--#end
    generic (
        -- physical interface width definitions
        MEM_IF_MEMTYPE                 : string;
        FAMILYGROUP_ID                 : natural;
        MEM_IF_DQS_WIDTH               : natural;
        MEM_IF_DQ_PER_DQS              : natural;
        MEM_IF_DWIDTH                  : natural;
        MEM_IF_DM_WIDTH                : natural;
        MEM_IF_NUM_RANKS               : natural;
        IRAM_AWIDTH                    : natural;
        REFRESH_COUNT_INIT             : natural;
        PRESET_RLAT                    : natural;
        PLL_STEPS_PER_CYCLE            : natural;
        CAPABILITIES                   : natural;
        IP_BUILDNUM                    : natural
   );
    port (
        -- clk / reset
        clk                            : in    std_logic;
        rst_n                          : in    std_logic;

        -- read interface from mmi block:
        mmi_iram                       : in    t_iram_ctrl;
        mmi_iram_enable_writes         : in    std_logic;

        --iram status signal (includes read data from iram)
        iram_status                    : out   t_iram_stat;
        iram_push_done                 : out   std_logic;

        -- from ctrl block
        ctrl_iram                      : in    t_ctrl_command;

        -- from dgrb block
        dgrb_iram                      : in    t_iram_push;

        -- from admin block
        admin_regs_status_rec          : in    t_admin_stat;

        -- current write position in the iram
        ctrl_idib_top                  : in    natural range 0 to 2 ** IRAM_AWIDTH - 1;

        ctrl_iram_push                 : in    t_ctrl_iram;

        -- the following signals are unused and reserved for future use
        dgwb_iram                      : in    t_iram_push
    );
end entity;

library work;

-- The registers package (alt_mem_phy_regs_pkg) is used to combine the definition of the
-- registers for the mmi status registers and functions/procedures applied to the registers
--#mw_prefix ("alt_mem_phy_regs_pkg")
use work.alt_mem_phy_regs_pkg.all;
--#end

--#mw_prefix ("alt_mem_phy_iram")
architecture struct of alt_mem_phy_iram is
--#end

-- -------------------------------------------
-- IHI fields
-- -------------------------------------------

    -- memory type , Quartus Build No., Quartus release, sequencer architecture version :
    -- #pb_del TODO: tbd need a pragma here that sticks @project.version@ and @project.build_number@ in the word below:
    signal   memtype                : std_logic_vector(7 downto 0);
    signal   ihi_self_description   : std_logic_vector(31 downto 0);

    -- #pb_del NOTE: swapped REFRESH_COUNT_INIT for MEM_IF_NUM_RANKS below because REFRESH_COUNT_INIT unused in non-levelling PHY
    signal   ihi_self_description_extra : std_logic_vector(31 downto 0);

    -- for iram address generation:
    signal   curr_iram_offset       : natural range 0 to 2 ** IRAM_AWIDTH - 1;

    -- set read latency for iram_rdata_valid signal control:
    constant c_iram_rlat            : natural := 3; -- iram read latency (increment if read pipelining added

    -- for rdata valid generation:
    signal   read_valid_ctr         : natural range 0 to c_iram_rlat;
    signal   iram_addr_r            : unsigned(IRAM_AWIDTH downto 0);

    constant c_ihi_phys_if_desc     : std_logic_vector(31 downto 0) := std_logic_vector (to_unsigned(MEM_IF_NUM_RANKS,8) & to_unsigned(MEM_IF_DM_WIDTH,8) & to_unsigned(MEM_IF_DQS_WIDTH,8) & to_unsigned(MEM_IF_DWIDTH,8));
    constant c_ihi_timing_info      : std_logic_vector(31 downto 0) := X"DEADDEAD";

    -- #pb_del: TODO: v needs a value
    constant c_ihi_ctrl_ss_word2    : std_logic_vector(31 downto 0) := std_logic_vector (to_unsigned(PRESET_RLAT,16) & X"0000");

    -- IDIB header codes
    constant c_idib_header_code0    : std_logic_vector(7 downto 0)  := X"4A";
    constant c_idib_footer_code     : std_logic_vector(7 downto 0)  := X"5A";

    -- encoded Quartus version
    -- #pb_del NOTE LEAVE PREVIOUS VERISONS HERE FOR DEBUGABILITY!!!!
    -- constant c_quartus_version : natural := 0;  -- Quartus 7.2
    -- constant c_quartus_version : natural := 1;  -- Quartus 8.0
    --constant c_quartus_version  : natural := 2;  -- Quartus 8.1
    --constant c_quartus_version  : natural := 3;  -- Quartus 9.0
    --constant c_quartus_version  : natural := 4;  -- Quartus 9.0sp2
    --constant c_quartus_version  : natural := 5;  -- Quartus 9.1
    --constant c_quartus_version  : natural := 6;  -- Quartus 9.1sp1?
    --constant c_quartus_version  : natural := 7;  -- Quartus 9.1sp2?
    constant c_quartus_version  : natural := 8;  -- Quartus 10.0
    -- constant c_quartus_version : natural := 114;   -- reserved

    -- allow for different variants for debug i/f
    constant c_dbg_if_version   : natural := 2;

    -- sequencer type 1 for levelling, 2 for non-levelling
    constant c_sequencer_type   : natural := 2;
    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant iram_report_prefix     : string  := "alt_mem_phy_seq (iram) : ";
--#end

-- -------------------------------------------
-- signal and type declarations
-- -------------------------------------------

    type t_iram_state is ( s_reset,                 -- system reset
                           s_pre_init_ram,          -- identify pre-initialisation
                           s_init_ram,              -- zero all locations
                           s_idle,                  -- default state
                           s_word_access_ram,       -- mmi access to the iram (post-calibration)
                           s_word_fetch_ram_rdata,  -- sample read data from RAM
                           s_word_fetch_ram_rdata_r,-- register the sampling of data from RAM (to improve timing)
                           s_word_complete,         -- finalise iram ram write
                           s_idib_header_write,     -- when starting a command
                           s_idib_header_inc_addr,  -- address increment
                           s_idib_footer_write,     -- unique footer to indicate end of data
                           s_cal_data_read,         -- read RAM location (read occurs continuously from idle state)
                           s_cal_data_read_r,
                           s_cal_data_modify,       -- modify RAM location (read occurs continuously)
                           s_cal_data_write,        -- write modified value back to RAM
                           s_ihi_header_word0_wr,   -- from 0 to 6 writing iram header info
                           s_ihi_header_word1_wr,
                           s_ihi_header_word2_wr,
                           s_ihi_header_word3_wr,
                           s_ihi_header_word4_wr,
                           s_ihi_header_word5_wr,
                           s_ihi_header_word6_wr,
                           s_ihi_header_word7_wr-- end writing iram header info
                           );

    signal state              : t_iram_state;

    signal contested_access   : std_logic;
    signal idib_header_count  : std_logic_vector(7 downto 0);

    -- register a new cmd request
    signal new_cmd            : std_logic;
    signal cmd_processed      : std_logic;

    -- signals to control dgrb writes
    signal iram_modified_data : std_logic_vector(31 downto 0);          -- scratchpad memory for read-modify-write

-- -------------------------------------------
-- physical ram connections
-- -------------------------------------------

-- Note that the iram_addr here is created IRAM_AWIDTH downto 0, and not
-- IRAM_AWIDTH-1 downto 0.  This means that the MSB is outside the addressable
-- area of the RAM.  The purpose of this is that this shall be our memory
-- overflow bit. It shall be directly connected to the iram_out_of_memory flag

    -- 32-bit interface port (read and write)
    signal iram_addr   : unsigned(IRAM_AWIDTH downto 0);
    signal iram_wdata  : std_logic_vector(31 downto 0);
    signal iram_rdata  : std_logic_vector(31 downto 0);
    signal iram_write  : std_logic;

    -- signal generated external to the iram to say when read data is valid
    signal iram_rdata_valid : std_logic;

    -- The FSM owns local storage that is loaded with the wdata/addr from the
    -- requesting sub-block, which is then fed to the iram's wdata/addr in turn
    -- until all data has gone across
    signal fsm_read    : std_logic;

-- -------------------------------------------
-- multiplexed push data
-- -------------------------------------------
    signal iram_done     : std_logic;                     -- unused
    signal iram_pushdata : std_logic_vector(31 downto 0);
    signal pending_push  : std_logic;                     -- push data to RAM
    signal iram_wordnum  : natural range 0 to 511;
    signal iram_bitnum   : natural range 0 to 31;

begin  -- architecture struct

-- -------------------------------------------
-- iram ram instantiation
-- -------------------------------------------
-- Note that the IRAM_AWIDTH is the physical number of address bits that the RAM has.
-- However, for out of range access detection purposes, an additional bit is added to
-- the various address signals. The iRAM does not register any of its inputs as the addr,
-- wdata etc are registered directly before being driven to it.

-- The dgrb accesses are of format read-modify-write to a single bit of a 32-bit word, the
-- mmi reads and header writes are in 32-bit words

    --#mw_prefix ("alt_mem_phy_iram_ram")
    ram : entity alt_mem_phy_iram_ram
    --#end
    generic map (
        IRAM_AWIDTH => IRAM_AWIDTH
    )
    port map (
        clk   => clk,
        rst_n => rst_n,
        addr  => iram_addr(IRAM_AWIDTH-1 downto 0),
        wdata => iram_wdata,
        write => iram_write,
        rdata => iram_rdata
    );

-- -------------------------------------------
-- IHI fields
-- asynchronously
-- -------------------------------------------

    -- this field identifies the type of memory
    memtype <= X"03" when (MEM_IF_MEMTYPE =  "DDR3") else
               X"02" when (MEM_IF_MEMTYPE =  "DDR2") else
               X"01" when (MEM_IF_MEMTYPE =   "DDR") else
               X"10" when (MEM_IF_MEMTYPE = "QDRII") else
               X"00" ;

    -- this field indentifies the gross level description of the sequencer
    ihi_self_description <=   memtype
                            & std_logic_vector(to_unsigned(IP_BUILDNUM,8))
                            & std_logic_vector(to_unsigned(c_quartus_version,8))
                            & std_logic_vector(to_unsigned(c_dbg_if_version,8));

    -- some extra information for the debug gui - sequencer type and familygroup
    ihi_self_description_extra <=       std_logic_vector(to_unsigned(FAMILYGROUP_ID,4))
                                    &   std_logic_vector(to_unsigned(c_sequencer_type,4))
                                    & x"000000";


-- -------------------------------------------
-- check for contested memory accesses
-- -------------------------------------------

    process(clk,rst_n)
    begin
        if rst_n = '0' then
            contested_access <= '0';
        elsif rising_edge(clk) then
            contested_access <= '0';

            if mmi_iram.read = '1' and pending_push = '1' then
                report iram_report_prefix & "contested memory accesses to the iram" severity failure;
                contested_access <= '1';
            end if;

            -- sanity checks
            if mmi_iram.write = '1' then
                report iram_report_prefix & "mmi writes to the iram unsupported for non-levelling AFI PHY sequencer" severity failure;
            end if;
            if dgwb_iram.iram_write = '1' then
                report iram_report_prefix & "dgwb writes to the iram unsupported for non-levelling AFI PHY sequencer" severity failure;
            end if;
        end if;
    end process;

-- -------------------------------------------
-- mux push data and associated signals
-- note: single bit taken for iram_pushdata because 1-bit read-modify-write to
--       a 32-bit word in the ram. This interface style is maintained for future
--       scalability / wider application of the iram block.
-- -------------------------------------------

    process(clk,rst_n)
    begin

        if rst_n = '0' then

            iram_done     <= '0';
            iram_pushdata <= (others => '0');
            pending_push  <= '0';
            iram_wordnum  <= 0;
            iram_bitnum   <= 0;

        elsif rising_edge(clk) then

            case curr_active_block(ctrl_iram.command) is

                when dgrb =>
                    iram_done        <= dgrb_iram.iram_done;
                    iram_pushdata    <= dgrb_iram.iram_pushdata;
                    pending_push     <= dgrb_iram.iram_write;
                    iram_wordnum     <= dgrb_iram.iram_wordnum;
                    iram_bitnum      <= dgrb_iram.iram_bitnum;

                when others => -- default dgrb
                    iram_done        <= dgrb_iram.iram_done;
                    iram_pushdata    <= dgrb_iram.iram_pushdata;
                    pending_push     <= dgrb_iram.iram_write;
                    iram_wordnum     <= dgrb_iram.iram_wordnum;
                    iram_bitnum      <= dgrb_iram.iram_bitnum;

                end case;
        end if;

    end process;

-- -------------------------------------------
-- generate write signal for the ram
-- -------------------------------------------

    process(clk, rst_n)
    begin

        if rst_n = '0' then
            iram_write  <= '0';

        elsif rising_edge(clk) then

            case state is

            when s_idle =>
                iram_write <= '0';

            when s_pre_init_ram |
                 s_init_ram =>
                iram_write <= '1';

            when s_ihi_header_word0_wr |
                 s_ihi_header_word1_wr |
                 s_ihi_header_word2_wr |
                 s_ihi_header_word3_wr |
                 s_ihi_header_word4_wr |
                 s_ihi_header_word5_wr |
                 s_ihi_header_word6_wr |
                 s_ihi_header_word7_wr =>
                iram_write <= '1';

            when s_idib_header_write =>
                iram_write <= '1';

            when s_idib_footer_write =>
                iram_write <= '1';

            when s_cal_data_write =>
                iram_write <= '1';

            when others =>
                iram_write <= '0'; -- default

            end case;

        end if;

    end process;

-- -------------------------------------------
-- generate wdata for the ram
-- -------------------------------------------

    process(clk, rst_n)
    variable v_current_cs    : std_logic_vector(3 downto 0);
    variable v_mtp_alignment : std_logic_vector(0 downto 0);
    variable v_single_bit    : std_logic;

    begin

        if rst_n = '0' then
            iram_wdata  <= (others => '0');

        elsif rising_edge(clk) then

            case state is

                when s_pre_init_ram |
                     s_init_ram     =>
                    iram_wdata <= (others => '0');

                when s_ihi_header_word0_wr =>
                    iram_wdata <= ihi_self_description;

                when s_ihi_header_word1_wr =>
                    iram_wdata <= c_ihi_phys_if_desc;

                when s_ihi_header_word2_wr =>
                    iram_wdata <= c_ihi_timing_info;

                when s_ihi_header_word3_wr =>
                    iram_wdata                                                <= ( others => '0');
                    iram_wdata(admin_regs_status_rec.mr0'range)               <= admin_regs_status_rec.mr0;
                    iram_wdata(admin_regs_status_rec.mr1'high + 16 downto 16) <= admin_regs_status_rec.mr1;

                when s_ihi_header_word4_wr =>
                    iram_wdata                                                <= ( others => '0');
                    iram_wdata(admin_regs_status_rec.mr2'range)               <= admin_regs_status_rec.mr2;
                    iram_wdata(admin_regs_status_rec.mr3'high + 16 downto 16) <= admin_regs_status_rec.mr3;

                when s_ihi_header_word5_wr =>
                    iram_wdata <= c_ihi_ctrl_ss_word2;

                when s_ihi_header_word6_wr =>
                    iram_wdata <= std_logic_vector(to_unsigned(IRAM_AWIDTH,32)); -- tbd write the occupancy at end of cal

                when s_ihi_header_word7_wr =>
                    iram_wdata <= ihi_self_description_extra;

                when s_idib_header_write   =>

                    -- encode command_op for current operation
                    v_current_cs    := std_logic_vector(to_unsigned(ctrl_iram.command_op.current_cs, 4));
                    v_mtp_alignment := std_logic_vector(to_unsigned(ctrl_iram.command_op.mtp_almt, 1));
                    v_single_bit    := ctrl_iram.command_op.single_bit;

                    iram_wdata <= encode_current_stage(ctrl_iram.command) & -- which command being executed (currently this should only be cmd_rrp_sweep (8 bits)
                                                             v_current_cs & -- which chip select being processed (4 bits)
                                                          v_mtp_alignment & -- currently used MTP alignment (1 bit)
                                                             v_single_bit & -- is single bit calibration selected (1 bit) - used during MTP alignment
                                                                     "00" & -- RFU
                                                        idib_header_count & -- unique ID to how many headers have been written (8 bits)
                                                       c_idib_header_code0; -- unique ID for headers (8 bits)

                when s_idib_footer_write =>

                    iram_wdata <= c_idib_footer_code & c_idib_footer_code & c_idib_footer_code & c_idib_footer_code;

                when s_cal_data_modify     =>

                    -- default don't overwrite
                    iram_modified_data <= iram_rdata;

                    -- update iram data based on packing and write modes
                    if ctrl_iram_push.packing_mode = dq_bitwise then

                        case ctrl_iram_push.write_mode is
                            when overwrite_ram =>
                                iram_modified_data(iram_bitnum) <= iram_pushdata(0);
                            when or_into_ram =>
                                iram_modified_data(iram_bitnum) <= iram_pushdata(0) or iram_rdata(0);
                            when and_into_ram =>
                                iram_modified_data(iram_bitnum) <= iram_pushdata(0) and iram_rdata(0);
                            when others =>
                                report iram_report_prefix & "unidentified write mode of " & t_iram_write_mode'image(ctrl_iram_push.write_mode) &
                                       " specified when generating iram write data" severity failure;
                        end case;

                    elsif ctrl_iram_push.packing_mode = dq_wordwise then

                        case ctrl_iram_push.write_mode is
                            when overwrite_ram =>
                                iram_modified_data <= iram_pushdata;
                            when or_into_ram =>
                                iram_modified_data <= iram_pushdata or iram_rdata;
                            when and_into_ram =>
                                iram_modified_data <= iram_pushdata and iram_rdata;
                            when others =>
                                report iram_report_prefix & "unidentified write mode of " & t_iram_write_mode'image(ctrl_iram_push.write_mode) &
                                       " specified when generating iram write data" severity failure;
                        end case;
                    else
                        report iram_report_prefix & "unidentified packing mode of " & t_iram_packing_mode'image(ctrl_iram_push.packing_mode) &
                               " specified when generating iram write data" severity failure;
                    end if;


                when s_cal_data_write      =>
                    iram_wdata <= iram_modified_data;

                when others                =>
                    iram_wdata <= (others => '0');

            end case;

        end if;

    end process;

-- -------------------------------------------
-- generate addr for the ram
-- -------------------------------------------

    process(clk, rst_n)
    begin

       if rst_n = '0' then
          iram_addr          <= (others => '0');
          curr_iram_offset   <= 0;

       elsif rising_edge(clk) then

           case (state) is

               when s_idle    =>
                   if mmi_iram.read = '1' then  -- pre-set mmi read location address

                       iram_addr  <= ('0' & to_unsigned(mmi_iram.addr,IRAM_AWIDTH)); -- Pad MSB

                   else  -- default get next push data location from iram

                       iram_addr  <= to_unsigned(curr_iram_offset + iram_wordnum, IRAM_AWIDTH+1);

                   end if;

               when s_word_access_ram =>

                   -- calculate the address
                   if mmi_iram.read = '1' then  -- mmi access
                       iram_addr  <= ('0' & to_unsigned(mmi_iram.addr,IRAM_AWIDTH)); -- Pad MSB
                   end if;


               when s_ihi_header_word0_wr =>
                   iram_addr  <= (others => '0');

               -- increment address for IHI word writes :
               when s_ihi_header_word1_wr |
                    s_ihi_header_word2_wr |
                    s_ihi_header_word3_wr |
                    s_ihi_header_word4_wr |
                    s_ihi_header_word5_wr |
                    s_ihi_header_word6_wr |
                    s_ihi_header_word7_wr =>
                   iram_addr  <=  iram_addr + 1;

               when s_idib_header_write =>
                   iram_addr  <= '0' & to_unsigned(ctrl_idib_top, IRAM_AWIDTH); -- Always write header at idib_top location

               when s_idib_footer_write =>
                   iram_addr  <= to_unsigned(curr_iram_offset + iram_wordnum, IRAM_AWIDTH+1);  -- active block communicates where to put the footer with done signal

               when s_idib_header_inc_addr =>
                   iram_addr        <= iram_addr + 1;
                   curr_iram_offset <= to_integer('0' & iram_addr) + 1;

               when s_init_ram =>

                   if iram_addr(IRAM_AWIDTH) = '1' then
                       iram_addr  <= (others => '0');  -- this prevents erroneous out-of-mem flag after initialisation
                   else
                       iram_addr  <= iram_addr + 1;
                   end if;

               when others =>
                   iram_addr  <= iram_addr;

           end case;

       end if;

    end process;

-- -------------------------------------------
-- generate new cmd signal to register the command_req signal
-- -------------------------------------------

    process(clk, rst_n)
    begin

        if rst_n = '0' then
            new_cmd <= '0';

        elsif rising_edge(clk) then

            if ctrl_iram.command_req = '1' then

                case ctrl_iram.command is

                    when cmd_rrp_sweep |  -- only prompt new_cmd for commands we wish to write headers for
                         cmd_rrp_seek  |
                         cmd_read_mtp  |
                         cmd_write_ihi =>

                        new_cmd <= '1';

                    when others =>

                        new_cmd <= '0';

                end case;

            end if;

            if cmd_processed = '1' then
                new_cmd <= '0';
            end if;

        end if;
    end process;

-- -------------------------------------------
-- generate read valid signal which takes account of pipelining of reads
-- -------------------------------------------

    process(clk, rst_n)
    begin

        if rst_n = '0' then
            iram_rdata_valid <= '0';
            read_valid_ctr   <= 0;
            iram_addr_r      <= (others => '0');

        elsif rising_edge(clk) then

            if read_valid_ctr < c_iram_rlat then
                iram_rdata_valid <= '0';
                read_valid_ctr   <= read_valid_ctr + 1;
            else
                iram_rdata_valid <= '1';
            end if;

            if to_integer(iram_addr) /= to_integer(iram_addr_r) or
               iram_write = '1' then
                read_valid_ctr   <= 0;
                iram_rdata_valid <= '0';
            end if;

            -- register iram address
            iram_addr_r  <= iram_addr;

        end if;
    end process;


-- -------------------------------------------
-- state machine
-- -------------------------------------------

    process(clk, rst_n)
    begin

        if rst_n = '0' then
           state  <= s_reset;
           cmd_processed <= '0';

        elsif rising_edge(clk) then

            cmd_processed <= '0';

            case state is

                when s_reset =>
                    state <= s_pre_init_ram;

                when s_pre_init_ram =>
                    state <= s_init_ram;

                -- remain in the init_ram state until all the ram locations have been zero'ed
                when s_init_ram =>

                    if iram_addr(IRAM_AWIDTH) = '1' then
                        state <= s_idle;
                    end if;

                -- default state after reset
                when s_idle =>

                    if pending_push = '1' then

                        state <= s_cal_data_read;

                    elsif iram_done = '1' then

                        state <= s_idib_footer_write;

                    elsif new_cmd = '1' then

                        case ctrl_iram.command is

                            when cmd_rrp_sweep |
                                 cmd_rrp_seek  |
                                 cmd_read_mtp     => state <= s_idib_header_write;

                            when cmd_write_ihi    => state <= s_ihi_header_word0_wr;

                            when others           => state <= state;

                        end case;

                        cmd_processed <= '1';

                    elsif mmi_iram.read = '1' then

                        state <= s_word_access_ram;

                    end if;

                -- mmi read accesses
                when s_word_access_ram            => state <= s_word_fetch_ram_rdata;
                when s_word_fetch_ram_rdata       => state <= s_word_fetch_ram_rdata_r;

                when s_word_fetch_ram_rdata_r     => if iram_rdata_valid = '1' then
                                                         state <= s_word_complete;
                                                     end if;

                when s_word_complete              => if iram_rdata_valid = '1' then  -- return to idle when iram_rdata stable
                                                         state <= s_idle;
                                                     end if;

                -- header write (currently only for cmp_rrp stage)
                when s_idib_header_write          => state <= s_idib_header_inc_addr;
                when s_idib_header_inc_addr       => state <= s_idle;  -- return to idle to wait for push

                when s_idib_footer_write          => state <= s_word_complete;

                -- push data accesses (only used by the dgrb block at present)
                when s_cal_data_read              => state <= s_cal_data_read_r;

                when s_cal_data_read_r            => if iram_rdata_valid = '1' then
                                                         state <= s_cal_data_modify;
                                                     end if;

                when s_cal_data_modify            => state <= s_cal_data_write;
                when s_cal_data_write             => state <= s_word_complete;

                -- IHI Header write accesses
                when s_ihi_header_word0_wr        => state <= s_ihi_header_word1_wr;
                when s_ihi_header_word1_wr        => state <= s_ihi_header_word2_wr;
                when s_ihi_header_word2_wr        => state <= s_ihi_header_word3_wr;
                when s_ihi_header_word3_wr        => state <= s_ihi_header_word4_wr;
                when s_ihi_header_word4_wr        => state <= s_ihi_header_word5_wr;
                when s_ihi_header_word5_wr        => state <= s_ihi_header_word6_wr;
                when s_ihi_header_word6_wr        => state <= s_ihi_header_word7_wr;
                when s_ihi_header_word7_wr        => state <= s_idle;

                when others => state <= state;

            end case;

        end if;

    end process;

-- -------------------------------------------
-- drive read data and responses back.
-- -------------------------------------------

    process(clk, rst_n)
    begin

        if rst_n = '0' then
            iram_status           <= defaults;
            iram_push_done        <= '0';
            idib_header_count     <= (others => '0');
            fsm_read              <= '0';

        elsif rising_edge(clk) then

            -- defaults
            iram_status       <= defaults;
            iram_status.done  <= '0';
            iram_status.rdata <= (others => '0');
            iram_push_done    <= '0';


            if state = s_init_ram then
                iram_status.out_of_mem <= '0';
            else
                iram_status.out_of_mem <= iram_addr(IRAM_AWIDTH);
            end if;

            -- register read flag for 32 bit accesses
            if state = s_idle then

                fsm_read  <= mmi_iram.read;

            end if;

            if state = s_word_complete then

                iram_status.done  <= '1';

                if fsm_read = '1' then
                    iram_status.rdata <= iram_rdata;
                else
                    iram_status.rdata <= (others => '0');
                end if;

            end if;

            -- if another access is ever presented while the FSM is busy, set the contested flag
            if contested_access = '1' then
                iram_status.contested_access <= '1';
            end if;

            -- set (and keep set) the iram_init_done output once initialisation of the RAM is complete
            if (state /= s_init_ram) and (state /= s_pre_init_ram) and (state /= s_reset) then
                iram_status.init_done <= '1';
            end if;

            if state = s_ihi_header_word7_wr then
                iram_push_done <= '1';
            end if;

            -- if completing push or footer write then acknowledge
            if state = s_cal_data_modify or state = s_idib_footer_write then
                iram_push_done <= '1';
            end if;

            -- increment IDIB header count each time a header is written
            if state = s_idib_header_write then
                idib_header_count <=  std_logic_vector(unsigned(idib_header_count) + to_unsigned(1,idib_header_count'high +1));
            end if;

        end if;

    end process;

end architecture struct;
