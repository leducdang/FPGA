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

--#mw_delete ("")
--/*-----------------------------------------------------------------------------
--  Title           : address and command package

--  File:  $RCSfile : alt_mem_phy_addr_cmd_pkg.vhd,v $

--  Last Modified   : $Date: 2008/08/22 $

--  Revision        : $Revision: #9 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : address and command package, shared between all variations of
--                    the AFI sequencer
--                    The address and command package (alt_mem_phy_addr_cmd_pkg) is
--                    used to combine DRAM address and command signals in one record
--                    and unify the functions operating on this record.
--
--
--#pb_del    NOTES  : Some work may still be necessary to simplify ODT control.
-- -----------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
package alt_mem_phy_addr_cmd_pkg is
--#end

    -- the following are bounds on the maximum range of address and command signals
    constant c_max_addr_bits      : natural := 15;
    constant c_max_ba_bits        : natural := 3;
    constant c_max_ranks          : natural := 16;
    constant c_max_mode_reg_bit   : natural := 12;
    constant c_max_cmds_per_clk   : natural := 4;  -- quarter rate

    -- a prefix for all report signals to identify phy and sequencer block
--#mw_prefix ("alt_mem_phy_seq")
    constant ac_report_prefix     : string  := "alt_mem_phy_seq (addr_cmd_pkg) : ";
--#end

-- -------------------------------------------------------------
-- this record represents a single mem_clk command cycle
-- -------------------------------------------------------------
    type t_addr_cmd is record
        addr  : natural range 0 to 2**c_max_addr_bits - 1;
        ba    : natural range 0 to 2**c_max_ba_bits   - 1;
        cas_n : boolean;
        ras_n : boolean;
        we_n  : boolean;
        cke   : natural range 0 to 2**c_max_ranks - 1;     -- bounded max of 8 ranks
        cs_n  : natural range 2**c_max_ranks - 1 downto 0; -- bounded max of 8 ranks
        odt   : natural range 0 to 2**c_max_ranks - 1;     -- bounded max of 8 ranks
        rst_n : boolean;
    end record t_addr_cmd;

-- -------------------------------------------------------------
-- this vector is used to describe the fact that for slower clock domains
-- mutiple commands per clock can be issued and encapsulates all these options in a
-- type which can scale with rate
-- -------------------------------------------------------------
    type t_addr_cmd_vector is array (natural range <>) of t_addr_cmd;

-- -------------------------------------------------------------
-- this record is used to define the memory interface type and allow packing and checking
-- (it should be used as a generic to a entity or from a poject level constant)
-- -------------------------------------------------------------

    -- enumeration for mem_type
    type t_mem_type is
        (
            DDR,
            DDR2,
            DDR3
        );

    -- memory interface configuration parameters
    type t_addr_cmd_config_rec is record
        num_addr_bits : natural;
        num_ba_bits   : natural;
        num_cs_bits   : natural;
        num_ranks     : natural;
        cmds_per_clk  : natural range 1 to c_max_cmds_per_clk;  -- commands per clock cycle (equal to DWIDTH_RATIO/2)
        mem_type      : t_mem_type;
    end record;

-- -----------------------------------
-- the following type is used to switch between signals
-- (for example, in the mask function below)
-- -----------------------------------
    type t_addr_cmd_signals is
        (
           addr,
           ba,
           cas_n,
           ras_n,
           we_n,
           cke,
           cs_n,
           odt,
           rst_n
        );

-- -----------------------------------
-- odt record
-- to hold the odt settings
-- (an odt_record) per rank (in odt_array)
-- -----------------------------------
    type t_odt_record is record
        write : natural;
        read  : natural;
    end record t_odt_record;
    type t_odt_array is array (natural range <>) of t_odt_record;

-- -------------------------------------------------------------
-- exposed functions and procedures
--
-- these functions cover the following memory types:
-- DDR3, DDR2, DDR
--
-- and the following operations:
-- MRS, REF, PRE, PREA, ACT,
-- WR, WRS8, WRS4, WRA, WRAS8, WRAS4,
-- RD, RDS8, RDS4, RDA, RDAS8, RDAS4,
--
-- for DDR3 on the fly burst length setting for reads/writes
-- is supported
-- -------------------------------------------------------------

    function defaults               ( config_rec           : in    t_addr_cmd_config_rec
                                    ) return                       t_addr_cmd_vector;

    function reset                  ( config_rec           : in    t_addr_cmd_config_rec
                                    ) return                       t_addr_cmd_vector;

    function int_pup_reset          ( config_rec           : in    t_addr_cmd_config_rec
                                    ) return                       t_addr_cmd_vector;

    function deselect               ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector
                                    ) return                       t_addr_cmd_vector;

    function precharge_all          ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function precharge_all          ( config_rec           : in    t_addr_cmd_config_rec;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function precharge_bank         ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1;
                                      bank                 : in    natural range 0 to 2**c_max_ba_bits -1
                                    ) return                       t_addr_cmd_vector;

    function activate               ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      bank                 : in    natural range 0 to 2**c_max_ba_bits -1;
                                      row                  : in    natural range 0 to 2**c_max_addr_bits -1;
                                      ranks                : in    natural range 0 to 2**c_max_ranks - 1
                                    ) return                       t_addr_cmd_vector;

    function write                  ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      bank                 : in    natural range 0 to 2**c_max_ba_bits -1;
                                      col                  : in    natural range 0 to 2**c_max_addr_bits -1;
                                      ranks                : in    natural range 0 to 2**c_max_ranks - 1;
                                      op_length            : in    natural range 1 to 8;
                                      auto_prech           : in    boolean
                                    ) return                       t_addr_cmd_vector;

    function read                   ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      bank                 : in    natural range 0 to 2**c_max_ba_bits -1;
                                      col                  : in    natural range 0 to 2**c_max_addr_bits -1;
                                      ranks                : in    natural range 0 to 2**c_max_ranks - 1;
                                      op_length            : in    natural range 1 to 8;
                                      auto_prech           : in    boolean
                                    ) return                       t_addr_cmd_vector;

    function refresh                ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function self_refresh_entry     ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function load_mode              ( config_rec           : in    t_addr_cmd_config_rec;
                                      mode_register_num    : in    natural range 0 to 3;
                                      mode_reg_value       : in    std_logic_vector(c_max_mode_reg_bit downto 0);
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1;
                                      remap_addr_and_ba    : in    boolean
                                    ) return                       t_addr_cmd_vector;

    function dll_reset              ( config_rec           : in    t_addr_cmd_config_rec;
                                      mode_reg_val         : in    std_logic_vector;
                                      rank_num             : in    natural range 0 to 2**c_max_ranks - 1;
                                      reorder_addr_bits    : in    boolean
                                    ) return                       t_addr_cmd_vector;

    function enter_sr_pd_mode       ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function maintain_pd_or_sr      ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function exit_sr_pd_mode        ( config_rec           : in    t_addr_cmd_config_rec;
                                      previous             : in    t_addr_cmd_vector;
                                      ranks                : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function ZQCS                   ( config_rec           : in    t_addr_cmd_config_rec;
                                      rank                 : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function ZQCL                   ( config_rec           : in    t_addr_cmd_config_rec;
                                      rank                 : in    natural range 0 to 2**c_max_ranks -1
                                    ) return                       t_addr_cmd_vector;

    function all_unreversed_ranks   ( config_rec           : in    t_addr_cmd_config_rec;
                                      record_to_mask       : in    t_addr_cmd_vector;
                                      mem_ac_swapped_ranks : in    std_logic_vector
                                    ) return                       t_addr_cmd_vector;

    function all_reversed_ranks     ( config_rec           : in    t_addr_cmd_config_rec;
                                      record_to_mask       : in    t_addr_cmd_vector;
                                      mem_ac_swapped_ranks : in    std_logic_vector
                                    ) return                       t_addr_cmd_vector;
    
    function program_rdimm_register ( config_rec           : in    t_addr_cmd_config_rec;
                                      control_word_addr		 : in std_logic_vector(3 downto 0);
                                      control_word_data  	 : in std_logic_vector(3 downto 0)
                                    ) return                       t_addr_cmd_vector;

-- -------------------------------------------------------------
-- the following function sets up the odt settings
-- NOTES: currently only supports DDR/DDR2 memories
-- -------------------------------------------------------------

    -- odt setting as implemented in the altera high-performance controller for ddr2 memories
    function set_odt_values (ranks          : natural;
                             ranks_per_slot : natural;
                             mem_type      : in string
                            ) return          t_odt_array;

-- -------------------------------------------------------------
-- the following function enables assignment to the constant config_rec
-- -------------------------------------------------------------
    function set_config_rec ( num_addr_bits     : in    natural;
                              num_ba_bits       : in    natural;
                              num_cs_bits       : in    natural;
                              num_ranks         : in    natural;
                              dwidth_ratio      : in    natural range 1 to c_max_cmds_per_clk;
                              mem_type          : in    string
                              ) return                  t_addr_cmd_config_rec;
                              

-- The non-levelled sequencer doesn't make a distinction between CS_WIDTH and NUM_RANKS. In this case,
-- just set the two to be the same.
    function set_config_rec ( num_addr_bits     : in    natural;
                              num_ba_bits       : in    natural;
                              num_cs_bits       : in    natural;
                              dwidth_ratio      : in    natural range 1 to c_max_cmds_per_clk;
                              mem_type          : in    string
                              ) return                  t_addr_cmd_config_rec;


-- -------------------------------------------------------------
-- the following function and procedure unpack address and
-- command signals from the t_addr_cmd_vector format
-- -------------------------------------------------------------

    procedure unpack_addr_cmd_vector( addr_cmd_vector : in t_addr_cmd_vector;
                                      config_rec      : in t_addr_cmd_config_rec;
                                      addr            : out std_logic_vector;
                                      ba              : out std_logic_vector;
                                      cas_n           : out std_logic_vector;
                                      ras_n           : out std_logic_vector;
                                      we_n            : out std_logic_vector;
                                      cke             : out std_logic_vector;
                                      cs_n            : out std_logic_vector;
                                      odt             : out std_logic_vector;
                                      rst_n           : out std_logic_vector);


    procedure unpack_addr_cmd_vector( config_rec      : in t_addr_cmd_config_rec;
                                      addr_cmd_vector : in t_addr_cmd_vector;
                               signal addr            : out std_logic_vector;
                               signal ba              : out std_logic_vector;
                               signal cas_n           : out std_logic_vector;
                               signal ras_n           : out std_logic_vector;
                               signal we_n            : out std_logic_vector;
                               signal cke             : out std_logic_vector;
                               signal cs_n            : out std_logic_vector;
                               signal odt             : out std_logic_vector;
                               signal rst_n           : out std_logic_vector);

-- -------------------------------------------------------------
-- the following functions perform bit masking to 0 or 1 (as
-- specified by mask_value) to a chosen address/command signal (signal_name)
-- across all signal bits or to a selected bit (mask_bit)
-- -------------------------------------------------------------

    -- mask all signal bits procedure
    function mask  ( config_rec            : in    t_addr_cmd_config_rec;
                     addr_cmd_vector       : in    t_addr_cmd_vector;
                     signal_name           : in    t_addr_cmd_signals;
                     mask_value            : in    std_logic) return t_addr_cmd_vector;

    procedure mask(        config_rec      : in    t_addr_cmd_config_rec;
                    signal addr_cmd_vector : inout t_addr_cmd_vector;
                           signal_name     : in    t_addr_cmd_signals;
                           mask_value      : in    std_logic);

    -- mask signal bit (mask_bit) procedure
    function mask  ( config_rec            : in    t_addr_cmd_config_rec;
                     addr_cmd_vector       : in    t_addr_cmd_vector;
                     signal_name           : in    t_addr_cmd_signals;
                     mask_value            : in    std_logic;
                     mask_bit              : in    natural) return t_addr_cmd_vector;

--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
end alt_mem_phy_addr_cmd_pkg;
--#end


--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
package body alt_mem_phy_addr_cmd_pkg IS
--#end

-- -------------------------------------------------------------
-- Basic functions for a single command
-- -------------------------------------------------------------

    -- -------------------------------------------------------------
    -- defaults the bus                   no JEDEC abbreviated name
    -- -------------------------------------------------------------
    function defaults ( config_rec : in    t_addr_cmd_config_rec
                      ) return             t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin

        v_retval.addr  := 0;
        v_retval.ba    := 0;
        v_retval.cas_n := false;
        v_retval.ras_n := false;
        v_retval.we_n  := false;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1;
        v_retval.odt   := 0;
        v_retval.rst_n := false;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- resets the addr/cmd signal         (Same as default with cke and rst_n 0 )
    -- -------------------------------------------------------------
    function reset    ( config_rec : in    t_addr_cmd_config_rec
                      ) return             t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin

        v_retval       := defaults(config_rec);
        v_retval.cke   := 0;
        if config_rec.mem_type = DDR3 then
            v_retval.rst_n := true;
        end if;
        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues deselect (command)         JEDEC abbreviated name: DES
    -- -------------------------------------------------------------
    function deselect ( config_rec : in    t_addr_cmd_config_rec;
                        previous   : in    t_addr_cmd
                      ) return             t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin

        v_retval := previous;

        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.rst_n := false;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a precharge all command     JEDEC abbreviated name: PREA
    -- -------------------------------------------------------------
    function precharge_all( config_rec : in    t_addr_cmd_config_rec;
                            previous   : in    t_addr_cmd;
                            ranks      : in    natural range 0 to 2**c_max_ranks -1
                          ) return             t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
        variable v_addr     : unsigned( c_max_addr_bits -1 downto 0);
    begin

        v_retval       := previous;

        v_addr         := to_unsigned(previous.addr, c_max_addr_bits);
        v_addr(10)     := '1'; -- set AP bit high
        v_retval.addr  := to_integer(v_addr);

        v_retval.ras_n := true;
        v_retval.cas_n := false;
        v_retval.we_n  := true;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) - 1 - ranks;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.rst_n := false;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- precharge (close) a bank           JEDEC abbreviated name: PRE
    -- -------------------------------------------------------------
    function precharge_bank( config_rec : in    t_addr_cmd_config_rec;
                             previous   : in    t_addr_cmd;
                             ranks      : in    natural range 0 to 2**c_max_ranks -1;
                             bank       : in    natural range 0 to 2**c_max_ba_bits -1
                           ) return             t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
        variable v_addr     : unsigned( c_max_addr_bits -1 downto 0);
    begin

        v_retval       := previous;

        v_addr         := to_unsigned(previous.addr, c_max_addr_bits);
        v_addr(10)     := '0'; -- set AP bit low
        v_retval.addr  := to_integer(v_addr);

        v_retval.ba    := bank;

        v_retval.ras_n := true;
        v_retval.cas_n := false;
        v_retval.we_n  := true;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) - ranks;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.rst_n := false;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- Issues a activate (open row)       JEDEC abbreviated name: ACT
    -- -------------------------------------------------------------
    function activate (config_rec : in    t_addr_cmd_config_rec;
                       previous   : in    t_addr_cmd;
                       bank       : in    natural range 0 to 2**c_max_ba_bits - 1;
                       row        : in    natural range 0 to 2**c_max_addr_bits - 1;
                       ranks      : in    natural range 0 to 2**c_max_ranks - 1
                      ) return            t_addr_cmd
    is
        variable v_retval : t_addr_cmd;
    begin

        v_retval.addr  := row;
        v_retval.ba    := bank;
        v_retval.cas_n := false;
        v_retval.ras_n := true;
        v_retval.we_n  := false;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - ranks;
        v_retval.odt   := previous.odt;
        v_retval.rst_n := false;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- issues a write command     JEDEC abbreviated name:WR,   WRA
    --                                                   WRS4, WRAS4
    --                                                   WRS8, WRAS8
    -- has the ability to support:
    --   DDR3:
    --      BL4, BL8, fixed BL
    --      Auto Precharge (AP)
    --   DDR2, DDR:
    --      fixed BL
    --      Auto Precharge (AP)
    -- -------------------------------------------------------------
    function write    (config_rec : in    t_addr_cmd_config_rec;
                       previous   : in    t_addr_cmd;
                       bank       : in    natural range 0 to 2**c_max_ba_bits -1;
                       col        : in    natural range 0 to 2**c_max_addr_bits -1;
                       ranks      : in    natural range 0 to 2**c_max_ranks -1;
                       op_length  : in    natural range 1 to 8;
                       auto_prech : in    boolean
                      ) return            t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
        variable v_addr     : unsigned(c_max_addr_bits-1 downto 0);
    begin

        -- calculate correct address signal
        v_addr := to_unsigned(col, c_max_addr_bits);

        -- note pin A10 is used for AP, therfore shift the value from A10 onto A11.
        v_retval.addr  := to_integer(v_addr(9 downto 0));

        if v_addr(10) = '1' then
            v_retval.addr := v_retval.addr + 2**11;
        end if;

        if auto_prech = true then  -- set AP bit (A10)
            v_retval.addr := v_retval.addr + 2**10;
        end if;

        if config_rec.mem_type = DDR3 then

            if    op_length = 8 then  -- set BL_OTF sel bit (A12)
                v_retval.addr  := v_retval.addr + 2**12;
            elsif op_length = 4 then
                null;
            else
                report ac_report_prefix & "DDR3 DRAM only supports writes of burst length 4 or 8, the requested length was: " & integer'image(op_length) severity failure;
            end if;

        elsif config_rec.mem_type = DDR2 or config_rec.mem_type = DDR then

           null;

        else
            report ac_report_prefix & "only DDR memories are supported for memory writes" severity failure;
        end if;

        -- set a/c signal assignments for write
        v_retval.ba    := bank;
        v_retval.cas_n := true;
        v_retval.ras_n := false;
        v_retval.we_n  := true;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - ranks;
        --#pb_del: might need to be a bit clever here for ODT......
        v_retval.odt   := ranks;
        v_retval.rst_n := false;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a read command    JEDEC abbreviated name: RD,   RDA
    --                                                  RDS4, RDAS4
    --                                                  RDS8, RDAS8
    -- has the ability to support:
    --   DDR3:
    --      BL4, BL8, fixed BL
    --      Auto Precharge (AP)
    --   DDR2, DDR:
    --      fixed BL, Auto Precharge (AP)
    -- -------------------------------------------------------------
    function read     (config_rec : in    t_addr_cmd_config_rec;
                       previous   : in    t_addr_cmd;
                       bank       : in    natural range 0 to 2**c_max_ba_bits -1;
                       col        : in    natural range 0 to 2**c_max_addr_bits -1;
                       ranks      : in    natural range 0 to 2**c_max_ranks -1;
                       op_length  : in    natural range 1 to 8;
                       auto_prech : in    boolean
                      ) return            t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
        variable v_addr     : unsigned(c_max_addr_bits-1 downto 0);
    begin

        -- calculate correct address signal
        v_addr := to_unsigned(col, c_max_addr_bits);

        -- note pin A10 is used for AP, therfore shift the value from A10 onto A11.
        v_retval.addr  := to_integer(v_addr(9 downto 0));

        if v_addr(10) = '1' then
            v_retval.addr := v_retval.addr + 2**11;
        end if;

        if auto_prech = true then  -- set AP bit (A10)
            v_retval.addr := v_retval.addr + 2**10;
        end if;

        if config_rec.mem_type = DDR3 then

            if    op_length = 8 then  -- set BL_OTF sel bit (A12)
                v_retval.addr  := v_retval.addr + 2**12;
            elsif op_length = 4 then
                null;
            else
                report ac_report_prefix & "DDR3 DRAM only supports reads of burst length 4 or 8" severity failure;
            end if;

        elsif config_rec.mem_type = DDR2 or config_rec.mem_type = DDR then

           null;

        else
            report ac_report_prefix & "only DDR memories are supported for memory reads" severity failure;
        end if;

        -- set a/c signals for read command
        v_retval.ba    := bank;
        v_retval.cas_n := true;
        v_retval.ras_n := false;
        v_retval.we_n  := false;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - ranks;
        v_retval.odt   := 0;
        v_retval.rst_n := false;
        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a refresh command           JEDEC abbreviated name: REF
    -- -------------------------------------------------------------
    function refresh (config_rec : in    t_addr_cmd_config_rec;
                      previous   : in    t_addr_cmd;
                      ranks      : in    natural range 0 to 2**c_max_ranks -1
                     )
                     return              t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin

        v_retval := previous;

        v_retval.cas_n := true;
        v_retval.ras_n := true;
        v_retval.we_n  := false;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - ranks;
        v_retval.rst_n := false;

        -- addr, BA and ODT are don't care therfore leave as previous value

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- issues a mode register set command JEDEC abbreviated name: MRS
    -- -------------------------------------------------------------
    function load_mode ( config_rec        : in    t_addr_cmd_config_rec;
                         mode_register_num : in    natural range 0 to 3;
                         mode_reg_value    : in    std_logic_vector(c_max_mode_reg_bit downto 0);
                         ranks             : in    natural range 0 to 2**c_max_ranks -1;
                         remap_addr_and_ba : in    boolean
                       ) return                    t_addr_cmd
    is
        variable v_retval     : t_addr_cmd;
        variable v_addr_remap : unsigned(c_max_mode_reg_bit downto 0);
    begin

        v_retval.cas_n := true;
        v_retval.ras_n := true;
        v_retval.we_n  := true;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - ranks;
        v_retval.odt   := 0;
        v_retval.rst_n := false;

        v_retval.ba    := mode_register_num;
        v_retval.addr  := to_integer(unsigned(mode_reg_value));

        if remap_addr_and_ba = true then
            v_addr_remap             := unsigned(mode_reg_value);
            v_addr_remap(8 downto 7) := v_addr_remap(7) & v_addr_remap(8);
            v_addr_remap(6 downto 5) := v_addr_remap(5) & v_addr_remap(6);
            v_addr_remap(4 downto 3) := v_addr_remap(3) & v_addr_remap(4);

            v_retval.addr            := to_integer(v_addr_remap);

            v_addr_remap             := to_unsigned(mode_register_num, c_max_mode_reg_bit + 1);
            v_addr_remap(1 downto 0) := v_addr_remap(0) & v_addr_remap(1);

            v_retval.ba              := to_integer(v_addr_remap);

        end if;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- maintains SR or PD mode on slected ranks.
    -- -------------------------------------------------------------
    function maintain_pd_or_sr  (config_rec : in    t_addr_cmd_config_rec;
                                 previous   : in    t_addr_cmd;
                                 ranks      : in    natural range 0 to 2**c_max_ranks -1
                                )
                                return              t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin
        v_retval     := previous;
        v_retval.cke := (2 ** config_rec.num_ranks) - 1 - ranks;
        return v_retval;
    end function;


    -- -------------------------------------------------------------
    -- issues a ZQ cal (short)          JEDEC abbreviated name: ZQCS
    -- NOTE - can only be issued to a single RANK at a time.
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that onyla  single rank is issued this command at a time..
    -- -------------------------------------------------------------
    function ZQCS (config_rec : in    t_addr_cmd_config_rec;
                   rank       : in    natural range 0 to 2**c_max_ranks -1
                  )
                  return              t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin


        v_retval.cas_n := false;
        v_retval.ras_n := false;
        v_retval.we_n  := true;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - rank;
        v_retval.rst_n := false;

        v_retval.addr  := 0; -- clear bit 10
        v_retval.ba    := 0;
        v_retval.odt   := 0;
        return v_retval;

    end function;



    -- -------------------------------------------------------------
    -- issues a ZQ cal (long)           JEDEC abbreviated name: ZQCL
    -- NOTE - can only be issued to a single RANK at a time.
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that onyla  single rank is issued this command at a time..
    -- -------------------------------------------------------------
    function ZQCL (config_rec : in    t_addr_cmd_config_rec;
                   rank       : in    natural range 0 to 2**c_max_ranks -1
                  )
                  return              t_addr_cmd
    is
        variable v_retval   : t_addr_cmd;
    begin

        v_retval.cas_n := false;
        v_retval.ras_n := false;
        v_retval.we_n  := true;
        v_retval.cke   := (2 ** config_rec.num_ranks) -1;
        v_retval.cs_n  := (2 ** config_rec.num_cs_bits) -1 - rank;
        v_retval.rst_n := false;

        v_retval.addr  := 1024; -- set bit 10
        v_retval.ba    := 0;
        v_retval.odt   := 0;
        return v_retval;

    end function;


-- -------------------------------------------------------------
-- functions acting on all clock cycles from whatever rate
--  in halfrate clock domain issues 1 command per clock
--  in quarter rate issues 1 command per clock
--     In the above cases they will be correctly aligned using the
--       ALTMEMPHY 2T and 4T SDC
-- -------------------------------------------------------------

    -- -------------------------------------------------------------
    -- defaults the bus                   no JEDEC abbreviated name
    -- -------------------------------------------------------------
    function defaults (config_rec : in    t_addr_cmd_config_rec
                      ) return            t_addr_cmd_vector
    is
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        v_retval := (others => defaults(config_rec));

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- resets the addr/cmd signal         (same as default with cke 0)
    -- -------------------------------------------------------------
    function reset    (config_rec : in    t_addr_cmd_config_rec
                      ) return            t_addr_cmd_vector
    is
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        v_retval := (others => reset(config_rec));

        return v_retval;

    end function;

    -- #pb_del The following function is to reset address and command signals internal to the
    -- #pb_del sequencer. The application is to minimise critical warnings during synthesis.
    -- #pb_del A critical warning (from Quartus II synthesis) will remain for the rst_n signal for
    -- #pb_del projects using DDR3 devices. This is currently unavoidable and does not impact PHY operation.
    -- #pb_del Example critical warning is: "xxx will power up to high".
    function int_pup_reset (config_rec : in    t_addr_cmd_config_rec
                      ) return            t_addr_cmd_vector
    is
        variable v_addr_cmd_config_rst : t_addr_cmd_config_rec;
    begin

        v_addr_cmd_config_rst           := config_rec;
        v_addr_cmd_config_rst.num_ranks := c_max_ranks;

        return reset(v_addr_cmd_config_rst);

    end function;

    -- -------------------------------------------------------------
    -- issues a deselect command          JEDEC abbreviated name: DES
    -- -------------------------------------------------------------
    function deselect ( config_rec : in    t_addr_cmd_config_rec;
                        previous   : in    t_addr_cmd_vector
                      ) return             t_addr_cmd_vector
    is
        alias    a_previous : t_addr_cmd_vector(previous'range) is previous;
        variable v_retval   : t_addr_cmd_vector(a_previous'range);
    begin

        for rate in a_previous'range loop
            v_retval(rate) := deselect(config_rec, a_previous(a_previous'high));
        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a precharge all command     JEDEC abbreviated name: PREA
    -- -------------------------------------------------------------
    function precharge_all ( config_rec : in    t_addr_cmd_config_rec;
                             previous   : in    t_addr_cmd_vector;
                             ranks      : in    natural range 0 to 2**c_max_ranks -1
                           ) return             t_addr_cmd_vector
    is
        alias    a_previous : t_addr_cmd_vector(previous'range) is previous;
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in  a_previous'range loop

            v_retval(rate)  := precharge_all(config_rec, previous(a_previous'high), ranks);

            -- use dwidth_ratio/2 as in FR = 0 , HR = 1, and in future QR = 2 tCK setup + 1 tCK hold
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- precharge (close) a bank           JEDEC abbreviated name: PRE
    -- -------------------------------------------------------------
    function precharge_bank ( config_rec : in    t_addr_cmd_config_rec;
                              previous   : in    t_addr_cmd_vector;
                              ranks      : in    natural range 0 to 2**c_max_ranks -1;
                              bank       : in    natural range 0 to 2**c_max_ba_bits -1
                            ) return             t_addr_cmd_vector
    is
        alias    a_previous : t_addr_cmd_vector(previous'range) is previous;
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in  a_previous'range loop

            v_retval(rate)  := precharge_bank(config_rec, previous(a_previous'high), ranks, bank);

            -- use dwidth_ratio/2 as in FR = 0 , HR = 1, and in future QR = 2 tCK setup + 1 tCK hold
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a activate (open row)       JEDEC abbreviated name: ACT
    -- -------------------------------------------------------------
    function activate ( config_rec : in    t_addr_cmd_config_rec;
                        previous   : in    t_addr_cmd_vector;
                        bank       : in    natural range 0 to 2**c_max_ba_bits -1;
                        row        : in    natural range 0 to 2**c_max_addr_bits -1;
                        ranks      : in    natural range 0 to 2**c_max_ranks - 1
                      ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in previous'range loop
            v_retval(rate)  := activate(config_rec, previous(previous'high), bank, row, ranks);

            -- use dwidth_ratio/2 as in FR = 0 , HR = 1, and in future QR = 2 tCK setup + 1 tCK hold
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a write command     JEDEC abbreviated name:WR,   WRA
    --                                                   WRS4, WRAS4
    --                                                   WRS8, WRAS8
    --
    -- has the ability to support:
    --   DDR3:
    --      BL4, BL8, fixed BL
    --      Auto Precharge (AP)
    --   DDR2, DDR:
    --      fixed BL
    --      Auto Precharge (AP)
    -- -------------------------------------------------------------
    function write ( config_rec : in    t_addr_cmd_config_rec;
                     previous   : in    t_addr_cmd_vector;
                     bank       : in    natural range 0 to 2**c_max_ba_bits -1;
                     col        : in    natural range 0 to 2**c_max_addr_bits -1;
                     ranks      : in    natural range 0 to 2**c_max_ranks - 1;
                     op_length  : in    natural range 1 to 8;
                     auto_prech : in    boolean
                   ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in previous'range loop
            v_retval(rate)  := write(config_rec, previous(previous'high), bank, col, ranks, op_length, auto_prech);

            -- use dwidth_ratio/2 as in FR = 0 , HR = 1, and in future QR = 2 tCK setup + 1 tCK hold
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a read command    JEDEC abbreviated name: RD,   RDA
    --                                                  RDS4, RDAS4
    --                                                  RDS8, RDAS8
    -- has the ability to support:
    --   DDR3:
    --      BL4, BL8, fixed BL
    --      Auto Precharge (AP)
    --   DDR2, DDR:
    --      fixed BL, Auto Precharge (AP)
    -- -------------------------------------------------------------
    function read  ( config_rec : in    t_addr_cmd_config_rec;
                     previous   : in    t_addr_cmd_vector;
                     bank       : in    natural range 0 to 2**c_max_ba_bits -1;
                     col        : in    natural range 0 to 2**c_max_addr_bits -1;
                     ranks      : in    natural range 0 to 2**c_max_ranks - 1;
                     op_length  : in    natural range 1 to 8;
                     auto_prech : in    boolean
                   ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in previous'range loop
            v_retval(rate)  := read(config_rec, previous(previous'high), bank, col, ranks, op_length, auto_prech);

            -- use dwidth_ratio/2 as in FR = 0 , HR = 1, and in future QR = 2 tCK setup + 1 tCK hold
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a refresh command           JEDEC abbreviated name: REF
    -- -------------------------------------------------------------
    function refresh (config_rec : in    t_addr_cmd_config_rec;
                      previous   : in    t_addr_cmd_vector;
                      ranks      : in    natural range 0 to 2**c_max_ranks -1
                     )return             t_addr_cmd_vector
    is
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for rate in previous'range loop
            v_retval(rate) := refresh(config_rec, previous(previous'high), ranks);

            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;

        end loop;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- issues a self_refresh_entry command  JEDEC abbreviated name: SRE
    -- -------------------------------------------------------------
    function self_refresh_entry (config_rec : in    t_addr_cmd_config_rec;
                                 previous   : in    t_addr_cmd_vector;
                                 ranks      : in    natural range 0 to 2**c_max_ranks -1
                                )return             t_addr_cmd_vector
    is
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin
        v_retval := enter_sr_pd_mode(config_rec, refresh(config_rec, previous, ranks), ranks);
        return v_retval;
    end function;



    -- -------------------------------------------------------------
    -- issues a self_refresh exit or power_down exit command
    --  JEDEC abbreviated names: SRX, PDX
    -- -------------------------------------------------------------
    function exit_sr_pd_mode    ( config_rec : in    t_addr_cmd_config_rec;
                                  previous   : in    t_addr_cmd_vector;
                                  ranks      : in    natural range 0 to 2**c_max_ranks -1
                                ) return             t_addr_cmd_vector
    is
        variable v_retval          : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
        variable v_mask_workings   : std_logic_vector(config_rec.num_ranks -1 downto 0);
        variable v_mask_workings_b : std_logic_vector(config_rec.num_ranks -1 downto 0);
    begin

        v_retval := maintain_pd_or_sr(config_rec, previous, ranks);
        v_mask_workings_b := std_logic_vector(to_unsigned(ranks, config_rec.num_ranks));

        for rate in 0 to config_rec.cmds_per_clk - 1 loop

            v_mask_workings   := std_logic_vector(to_unsigned(v_retval(rate).cke, config_rec.num_ranks));

            for i in v_mask_workings_b'range loop
                v_mask_workings(i) := v_mask_workings(i) or v_mask_workings_b(i);
            end loop;

            if rate >= config_rec.cmds_per_clk / 2 then    -- maintain command but clear CS of subsequenct command slots
                v_retval(rate).cke  := to_integer(unsigned(v_mask_workings));  -- almost irrelevant. but optimises logic slightly for Quater rate
            end if;
        end loop;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- cause the selected ranks to enter Self-refresh or Powerdown mode
    --  JEDEC abbreviated names: PDE,
    --                           SRE  (if a refresh is concurrently issued to the same ranks)
    -- -------------------------------------------------------------
    function enter_sr_pd_mode   ( config_rec : in    t_addr_cmd_config_rec;
                                  previous   : in    t_addr_cmd_vector;
                                  ranks      : in    natural range 0 to 2**c_max_ranks -1
                                ) return             t_addr_cmd_vector
    is
        variable v_retval          : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
        variable v_mask_workings   : std_logic_vector(config_rec.num_ranks -1 downto 0);
        variable v_mask_workings_b : std_logic_vector(config_rec.num_ranks -1 downto 0);
    begin

        v_retval          := previous;
        v_mask_workings_b := std_logic_vector(to_unsigned(ranks, config_rec.num_ranks));

        for rate in 0 to config_rec.cmds_per_clk - 1 loop

            if rate >= config_rec.cmds_per_clk / 2 then    -- maintain command but clear CS of subsequenct command slots
                v_mask_workings   := std_logic_vector(to_unsigned(v_retval(rate).cke, config_rec.num_ranks));

                for i in v_mask_workings_b'range loop
                    v_mask_workings(i) := v_mask_workings(i) and not v_mask_workings_b(i);
                end loop;

                v_retval(rate).cke  := to_integer(unsigned(v_mask_workings));  -- almost irrelevant. but optimises logic slightly for Quater rate

            end if;

        end loop;

        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- Issues a mode register set command   JEDEC abbreviated name: MRS
    -- -------------------------------------------------------------
    function load_mode ( config_rec        : in    t_addr_cmd_config_rec;
                         mode_register_num : in    natural range 0 to 3;
                         mode_reg_value    : in    std_logic_vector(c_max_mode_reg_bit downto 0);
                         ranks             : in    natural range 0 to 2**c_max_ranks -1;
                         remap_addr_and_ba : in    boolean
                       ) return                    t_addr_cmd_vector
    is
        variable v_retval     : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        v_retval := (others => load_mode(config_rec, mode_register_num, mode_reg_value, ranks, remap_addr_and_ba));

        for rate in v_retval'range loop
            if rate /= config_rec.cmds_per_clk/2 then
                v_retval(rate).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;
        end loop;

    -- #pb_del -- NOTE: is this the place to add an assert command_logging ??
        return v_retval;

    end function;


    -- -------------------------------------------------------------
    -- maintains SR or PD mode on slected ranks.
    --    NOTE: does not affect previous command
    -- -------------------------------------------------------------
    function maintain_pd_or_sr  ( config_rec : in    t_addr_cmd_config_rec;
                                  previous   : in    t_addr_cmd_vector;
                                  ranks      : in    natural range 0 to 2**c_max_ranks -1
                                ) return             t_addr_cmd_vector
    is
        variable v_retval   : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        for command in v_retval'range loop
            v_retval(command) := maintain_pd_or_sr(config_rec, previous(command), ranks);
        end loop;
        return v_retval;
    end function;


    -- -------------------------------------------------------------
    -- issues a ZQ cal (long)           JEDEC abbreviated name: ZQCL
    -- NOTE - can only be issued to a single RANK ata a time.
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that only a single rank is issued this command at a time..
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that the memory type is DDR3 !!!
    -- -------------------------------------------------------------
    function ZQCL ( config_rec : in    t_addr_cmd_config_rec;
                    rank       : in    natural range 0 to 2**c_max_ranks -1
                  ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1) := defaults(config_rec);
    begin

        for command in v_retval'range loop
            v_retval(command) := ZQCL(config_rec, rank);
            if command * 2 /= config_rec.cmds_per_clk then
                v_retval(command).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;
        end loop;

        return v_retval;

    end function;

    -- -------------------------------------------------------------
    -- issues a ZQ cal (short)          JEDEC abbreviated name: ZQCS
    -- NOTE - can only be issued to a single RANK ata a time.
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that only a single rank is issued this command at a time..
    -- #pb_del  -- NEED TO ADD A CHECK TO ENSURE that the memory type is DDR3 !!!
    -- -------------------------------------------------------------
    function ZQCS ( config_rec : in    t_addr_cmd_config_rec;
                    rank       : in    natural range 0 to 2**c_max_ranks -1
                  ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1) := defaults(config_rec);
    begin

        for command in v_retval'range loop
            v_retval(command) := ZQCS(config_rec, rank);
            if command * 2 /= config_rec.cmds_per_clk then
                v_retval(command).cs_n  := (2 ** config_rec.num_cs_bits) -1;
            end if;
        end loop;

        return v_retval;

    end function;


-- ----------------------
-- Additional Rank manipulation functions (main use DDR3)
-- -------------

    -- -----------------------------------
    -- set the chip select for a group of ranks
    -- -----------------------------------
    function all_reversed_ranks    ( config_rec           : in    t_addr_cmd_config_rec;
                                     record_to_mask       : in    t_addr_cmd;
                                     mem_ac_swapped_ranks : in    std_logic_vector
                                   ) return                       t_addr_cmd
    is
        variable v_retval        : t_addr_cmd;
        variable v_mask_workings : std_logic_vector(config_rec.num_cs_bits-1 downto 0);
    begin
        v_retval        := record_to_mask;
        v_mask_workings := std_logic_vector(to_unsigned(record_to_mask.cs_n, config_rec.num_cs_bits));

        for i in mem_ac_swapped_ranks'range loop
            v_mask_workings(i):= v_mask_workings(i) or not mem_ac_swapped_ranks(i);
        end loop;

        v_retval.cs_n   := to_integer(unsigned(v_mask_workings));
        return v_retval;
    end function;

    -- -----------------------------------
    -- inverse of the above
    -- -----------------------------------
    function all_unreversed_ranks  ( config_rec           : in    t_addr_cmd_config_rec;
                                     record_to_mask       : in    t_addr_cmd;
                                     mem_ac_swapped_ranks : in    std_logic_vector
                                   ) return                       t_addr_cmd
    is
        variable v_retval        : t_addr_cmd;
        variable v_mask_workings : std_logic_vector(config_rec.num_cs_bits-1 downto 0);
    begin
        v_retval        := record_to_mask;
        v_mask_workings := std_logic_vector(to_unsigned(record_to_mask.cs_n, config_rec.num_cs_bits));

        for i in mem_ac_swapped_ranks'range loop
            v_mask_workings(i):= v_mask_workings(i) or mem_ac_swapped_ranks(i);
        end loop;

        v_retval.cs_n := to_integer(unsigned(v_mask_workings));
        return v_retval;
    end function;

    -- -----------------------------------
    -- set the chip select for a group of ranks in a way which handles diffrent rates
    -- -----------------------------------
    function all_unreversed_ranks   ( config_rec           : in    t_addr_cmd_config_rec;
                                      record_to_mask       : in    t_addr_cmd_vector;
                                      mem_ac_swapped_ranks : in    std_logic_vector
                                    ) return                       t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1) := defaults(config_rec);
    begin

        for command in record_to_mask'range loop
            v_retval(command) := all_unreversed_ranks(config_rec, record_to_mask(command), mem_ac_swapped_ranks);
        end loop;

        return v_retval;

    end function;

    -- -----------------------------------
    -- inverse of the above handling ranks
    -- -----------------------------------
    function all_reversed_ranks     ( config_rec           : in    t_addr_cmd_config_rec;
                                      record_to_mask       : in    t_addr_cmd_vector;
                                      mem_ac_swapped_ranks : in    std_logic_vector
                                    ) return                       t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1) := defaults(config_rec);
    begin

        for command in record_to_mask'range loop
            v_retval(command) := all_reversed_ranks(config_rec, record_to_mask(command), mem_ac_swapped_ranks);
        end loop;

        return v_retval;

    end function;
    
	-- --------------------------------------------------
	-- Program a single control word onto RDIMM.
	-- This is accomplished rather goofily by asserting all chip selects
	-- and then writing out both the addr/data of the word onto the addr/ba bus
	-- --------------------------------------------------
    
    function program_rdimm_register ( config_rec           : in    t_addr_cmd_config_rec;
                                      control_word_addr		 : in std_logic_vector(3 downto 0);
                                      control_word_data 	 : in std_logic_vector(3 downto 0)
                                    ) return                       t_addr_cmd
    is
    	variable v_retval : t_addr_cmd;
    	variable ba : std_logic_vector(2 downto 0);
    	variable addr : std_logic_vector(4 downto 0);
    begin
			v_retval := defaults(config_rec);
			v_retval.cs_n := 0;
      ba := control_word_addr(3) & control_word_data(3) & control_word_data(2);
			v_retval.ba := to_integer(unsigned(ba));
			addr := control_word_data(1) & control_word_data(0) & control_word_addr(2) &
			                 control_word_addr(1) & control_word_addr(0);
    		v_retval.addr := to_integer(unsigned(addr));		
			return v_retval;
		end function;
		
		function program_rdimm_register ( config_rec           : in    t_addr_cmd_config_rec;
                                      control_word_addr		 : in std_logic_vector(3 downto 0);
                                      control_word_data 	 : in std_logic_vector(3 downto 0)
                                    ) return                       t_addr_cmd_vector
    is
    	variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin
    	v_retval := (others => program_rdimm_register(config_rec, control_word_addr, control_word_data));
    	return v_retval;
    end function;
-- --------------------------------------------------
-- overloaded functions, to simplify use, or provide simplified functionality
-- --------------------------------------------------

    -- ----------------------------------------------------
    -- Precharge all, defaulting all bits.
    -- ----------------------------------------------------
    function precharge_all ( config_rec : in    t_addr_cmd_config_rec;
                             ranks      : in    natural range 0 to 2**c_max_ranks -1
                           ) return             t_addr_cmd_vector
    is
        variable v_retval : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1) := defaults(config_rec);
    begin

        v_retval := precharge_all(config_rec, v_retval, ranks);

        return v_retval;

    end function;


    -- ----------------------------------------------------
    -- perform DLL reset through mode registers
    -- ----------------------------------------------------
    function dll_reset (  config_rec        : in t_addr_cmd_config_rec;
                          mode_reg_val      : in std_logic_vector;
                          rank_num          : in natural range 0 to 2**c_max_ranks - 1;
                          reorder_addr_bits : in boolean
                         ) return t_addr_cmd_vector is
        variable int_mode_reg : std_logic_vector(mode_reg_val'range);
        variable output       : t_addr_cmd_vector(0 to config_rec.cmds_per_clk - 1);
    begin
        int_mode_reg    := mode_reg_val;
        int_mode_reg(8) := '1';   -- set DLL reset bit.
        output          := load_mode(config_rec, 0, int_mode_reg, rank_num, reorder_addr_bits);
        return output;
    end function;


-- -------------------------------------------------------------
-- package configuration functions
-- -------------------------------------------------------------

    -- -------------------------------------------------------------
    -- the following function sets up the odt settings
    -- NOTES: supports DDR/DDR2/DDR3 SDRAM memories
    -- -------------------------------------------------------------
    function set_odt_values (ranks          : natural;
                             ranks_per_slot : natural;
                             mem_type       : in string
                            ) return t_odt_array is

    variable v_num_slots  : natural;
    variable v_cs         : natural range 0 to ranks-1;
    variable v_odt_values : t_odt_array(0 to ranks-1);
    variable v_cs_addr    : unsigned(ranks-1 downto 0);

    begin

        if mem_type = "DDR" then

            -- ODT not supported for DDR memory so set default off
            for v_cs in 0 to ranks-1 loop
                v_odt_values(v_cs).write := 0;
                v_odt_values(v_cs).read  := 0;
            end loop;

        elsif mem_type = "DDR2" then

            -- odt setting as implemented in the altera high-performance controller for ddr2 memories
            assert (ranks rem ranks_per_slot = 0) report ac_report_prefix & "number of ranks per slot must be a multiple of number of ranks" severity failure;
            v_num_slots := ranks/ranks_per_slot;

            if v_num_slots = 1 then
                -- special condition for 1 slot (i.e. DIMM) (2^n, n=0,1,2,... ranks only)
                -- set odt on one chip for writes and no odt for reads
                for v_cs in 0 to ranks-1 loop
                    v_odt_values(v_cs).write := 2**v_cs;  -- on on the rank being written to
                    v_odt_values(v_cs).read  := 0;
                end loop;
            else
                -- if > 1 slot, set 1 odt enable on neighbouring slot for read and write
                -- as an example consider the below for 4 slots with 2 ranks per slot
                -- access to CS[0] or CS[1], enable ODT[2] or ODT[3]
                -- access to CS[2] or CS[3], enable ODT[0] or ODT[1]
                -- access to CS[4] or CS[5], enable ODT[6] or ODT[7]
                -- access to CS[6] or CS[7], enable ODT[4] or ODT[5]

                -- the logic below implements the above for varying ranks and ranks_per slot
                -- under the condition that ranks/ranks_per_slot is integer
                for v_cs in 0 to ranks-1 loop
                    v_cs_addr                    := to_unsigned(v_cs, ranks);
                    v_cs_addr(ranks_per_slot-1)  := not v_cs_addr(ranks_per_slot-1);
                    v_odt_values(v_cs).write     := 2**to_integer(v_cs_addr);
                    v_odt_values(v_cs).read      := v_odt_values(v_cs).write;
                end loop;

            end if;

        elsif mem_type = "DDR3" then

            assert (ranks rem ranks_per_slot = 0) report ac_report_prefix & "number of ranks per slot must be a multiple of number of ranks" severity failure;
            v_num_slots := ranks/ranks_per_slot;

            if v_num_slots = 1 then
                -- special condition for 1 slot (i.e. DIMM) (2^n, n=0,1,2,... ranks only)
                -- set odt on one chip for writes and no odt for reads
                for v_cs in 0 to ranks-1 loop
                    v_odt_values(v_cs).write := 2**v_cs;  -- on on the rank being written to
                    v_odt_values(v_cs).read  := 0;
                end loop;
            else
                -- if > 1 slot, set 1 odt enable on neighbouring slot for read and write
                -- as an example consider the below for 4 slots with 2 ranks per slot
                -- access to CS[0] or CS[1], enable ODT[2] or ODT[3]
                -- access to CS[2] or CS[3], enable ODT[0] or ODT[1]
                -- access to CS[4] or CS[5], enable ODT[6] or ODT[7]
                -- access to CS[6] or CS[7], enable ODT[4] or ODT[5]

                -- the logic below implements the above for varying ranks and ranks_per slot
                -- under the condition that ranks/ranks_per_slot is integer
                for v_cs in 0 to ranks-1 loop
                    v_cs_addr                    := to_unsigned(v_cs, ranks);
                    v_cs_addr(ranks_per_slot-1)  := not v_cs_addr(ranks_per_slot-1);
                    v_odt_values(v_cs).write     := 2**to_integer(v_cs_addr) + 2**(v_cs);  -- turn on a neighbouring slots cs and current rank being written to
                    v_odt_values(v_cs).read      := 2**to_integer(v_cs_addr);
                end loop;

            end if;

       else
            report ac_report_prefix & "unknown mem_type specified in the set_odt_values function in addr_cmd_pkg package" severity failure;
        end if;

        return v_odt_values;

    end function;



    -- -----------------------------------------------------------
    -- set constant values to config_rec
    -- ----------------------------------------------------------
    function set_config_rec ( num_addr_bits : in natural;
                              num_ba_bits   : in natural;
                              num_cs_bits   : in natural;
                              num_ranks     : in natural;
                              dwidth_ratio  : in natural range 1 to c_max_cmds_per_clk;
                              mem_type      : in string
                            ) return             t_addr_cmd_config_rec
    is
        variable v_config_rec : t_addr_cmd_config_rec;
    begin

        v_config_rec.num_addr_bits := num_addr_bits;
        v_config_rec.num_ba_bits   := num_ba_bits;
        v_config_rec.num_cs_bits   := num_cs_bits;
        v_config_rec.num_ranks     := num_ranks;
        v_config_rec.cmds_per_clk  := dwidth_ratio/2;

        -- #pb_del TODO: this is a hardcoded fix - need to find a better way to express strings of different lengths
        if mem_type = "DDR" then
            v_config_rec.mem_type := DDR;
        elsif mem_type = "DDR2" then
            v_config_rec.mem_type := DDR2;
        elsif mem_type = "DDR3" then
            v_config_rec.mem_type := DDR3;
        else
            report ac_report_prefix & "unknown mem_type specified in the set_config_rec function in addr_cmd_pkg package" severity failure;
        end if;

        return v_config_rec;

    end function;
    
-- The non-levelled sequencer doesn't make a distinction between CS_WIDTH and NUM_RANKS. In this case,
-- just set the two to be the same.
    function set_config_rec ( num_addr_bits : in natural;
                              num_ba_bits   : in natural;
                              num_cs_bits   : in natural;
                              dwidth_ratio  : in natural range 1 to c_max_cmds_per_clk;
                              mem_type      : in string
                            ) return             t_addr_cmd_config_rec
    is
    begin

        return set_config_rec(num_addr_bits, num_ba_bits, num_cs_bits, num_cs_bits, dwidth_ratio, mem_type);

    end function;
-- -----------------------------------------------------------
-- unpack and pack address and command signals from and to t_addr_cmd_vector
-- -----------------------------------------------------------

    -- -------------------------------------------------------------
    -- convert from t_addr_cmd_vector to expanded addr/cmd signals
    -- -------------------------------------------------------------

    -- #pb_del the procedure below is maintained for backward compatibility of the code
    procedure unpack_addr_cmd_vector( addr_cmd_vector : in t_addr_cmd_vector;
                                      config_rec      : in t_addr_cmd_config_rec;
                                      addr            : out std_logic_vector;
                                      ba              : out std_logic_vector;
                                      cas_n           : out std_logic_vector;
                                      ras_n           : out std_logic_vector;
                                      we_n            : out std_logic_vector;
                                      cke             : out std_logic_vector;
                                      cs_n            : out std_logic_vector;
                                      odt             : out std_logic_vector;
                                      rst_n           : out std_logic_vector
                                    )
    is
        variable v_mem_if_ranks : natural range 0 to 2**c_max_ranks - 1;
        variable v_vec_len      : natural range 1 to 4;

        variable v_addr  : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_addr_bits - 1 downto 0);
        variable v_ba    : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ba_bits   - 1 downto 0);
        variable v_odt   : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ranks     - 1 downto 0);
        variable v_cs_n  : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_cs_bits   - 1 downto 0);
        variable v_cke   : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ranks     - 1 downto 0);
        variable v_cas_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_ras_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_we_n  : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_rst_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);

    begin

        v_vec_len := config_rec.cmds_per_clk;
        v_mem_if_ranks := config_rec.num_ranks;

        for v_i in 0 to v_vec_len-1 loop

            assert addr_cmd_vector(v_i).addr < 2**config_rec.num_addr_bits report ac_report_prefix &
                   "value of addr exceeds range of number of address bits in unpack_addr_cmd_vector procedure"    severity failure;
            assert addr_cmd_vector(v_i).ba   < 2**config_rec.num_ba_bits   report ac_report_prefix &
                   "value of ba exceeds range of number of bank address bits in unpack_addr_cmd_vector procedure" severity failure;
            assert addr_cmd_vector(v_i).odt  < 2**v_mem_if_ranks report ac_report_prefix &
                   "value of odt exceeds range of number of ranks in unpack_addr_cmd_vector procedure"            severity failure;
            assert addr_cmd_vector(v_i).cs_n < 2**config_rec.num_cs_bits report ac_report_prefix &
                   "value of cs_n exceeds range of number of ranks in unpack_addr_cmd_vector procedure"           severity failure;
            assert addr_cmd_vector(v_i).cke  < 2**v_mem_if_ranks report ac_report_prefix &
                   "value of cke exceeds range of number of ranks in unpack_addr_cmd_vector procedure"            severity failure;

            v_addr((v_i+1)*config_rec.num_addr_bits - 1 downto v_i*config_rec.num_addr_bits) := std_logic_vector(to_unsigned(addr_cmd_vector(v_i).addr,config_rec.num_addr_bits));
            v_ba((v_i+1)*config_rec.num_ba_bits     - 1 downto v_i*config_rec.num_ba_bits)   := std_logic_vector(to_unsigned(addr_cmd_vector(v_i).ba,config_rec.num_ba_bits));
            v_cke((v_i+1)*v_mem_if_ranks            - 1 downto v_i*v_mem_if_ranks)           := std_logic_vector(to_unsigned(addr_cmd_vector(v_i).cke,v_mem_if_ranks));
            v_cs_n((v_i+1)*config_rec.num_cs_bits   - 1 downto v_i*config_rec.num_cs_bits)   := std_logic_vector(to_unsigned(addr_cmd_vector(v_i).cs_n,config_rec.num_cs_bits));
            v_odt((v_i+1)*v_mem_if_ranks            - 1 downto v_i*v_mem_if_ranks)           := std_logic_vector(to_unsigned(addr_cmd_vector(v_i).odt,v_mem_if_ranks));

            if (addr_cmd_vector(v_i).cas_n) then v_cas_n(v_i) := '0'; else v_cas_n(v_i) := '1'; end if;
            if (addr_cmd_vector(v_i).ras_n) then v_ras_n(v_i) := '0'; else v_ras_n(v_i) := '1'; end if;
            if (addr_cmd_vector(v_i).we_n)  then  v_we_n(v_i) := '0'; else  v_we_n(v_i) := '1'; end if;
            if (addr_cmd_vector(v_i).rst_n) then v_rst_n(v_i) := '0'; else v_rst_n(v_i) := '1'; end if;

        end loop;

        addr  := v_addr;
        ba    := v_ba;
        cke   := v_cke;
        cs_n  := v_cs_n;
        odt   := v_odt;
        cas_n := v_cas_n;
        ras_n := v_ras_n;
        we_n  := v_we_n;
        rst_n := v_rst_n;

    end procedure;


    procedure unpack_addr_cmd_vector( config_rec      : in t_addr_cmd_config_rec;
                                      addr_cmd_vector : in t_addr_cmd_vector;
                               signal addr            : out std_logic_vector;
                               signal ba              : out std_logic_vector;
                               signal cas_n           : out std_logic_vector;
                               signal ras_n           : out std_logic_vector;
                               signal we_n            : out std_logic_vector;
                               signal cke             : out std_logic_vector;
                               signal cs_n            : out std_logic_vector;
                               signal odt             : out std_logic_vector;
                               signal rst_n           : out std_logic_vector
                                    )
    is
        variable v_mem_if_ranks : natural range 0 to 2**c_max_ranks - 1;
        variable v_vec_len      : natural range 1 to 4;
        variable v_seq_ac_addr  : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_addr_bits - 1 downto 0);
        variable v_seq_ac_ba    : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ba_bits   - 1 downto 0);
        variable v_seq_ac_cas_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_seq_ac_ras_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_seq_ac_we_n  : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);
        variable v_seq_ac_cke   : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ranks     - 1 downto 0);
        variable v_seq_ac_cs_n  : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_cs_bits   - 1 downto 0);
        variable v_seq_ac_odt   : std_logic_vector(config_rec.cmds_per_clk * config_rec.num_ranks     - 1 downto 0);
        variable v_seq_ac_rst_n : std_logic_vector(config_rec.cmds_per_clk                            - 1 downto 0);

    begin

        unpack_addr_cmd_vector (
            addr_cmd_vector,
            config_rec,
            v_seq_ac_addr,
            v_seq_ac_ba,
            v_seq_ac_cas_n,
            v_seq_ac_ras_n,
            v_seq_ac_we_n,
            v_seq_ac_cke,
            v_seq_ac_cs_n,
            v_seq_ac_odt,
            v_seq_ac_rst_n);

        addr  <= v_seq_ac_addr;
        ba    <= v_seq_ac_ba;
        cas_n <= v_seq_ac_cas_n;
        ras_n <= v_seq_ac_ras_n;
        we_n  <= v_seq_ac_we_n;
        cke   <= v_seq_ac_cke;
        cs_n  <= v_seq_ac_cs_n;
        odt   <= v_seq_ac_odt;
        rst_n <= v_seq_ac_rst_n;

    end procedure;

-- -----------------------------------------------------------
-- function to mask each bit of signal signal_name in addr_cmd_
-- -----------------------------------------------------------
    -- -----------------------------------------------------------
    -- function to mask each bit of signal signal_name in addr_cmd_vector with mask_value
    -- -----------------------------------------------------------
    function mask ( config_rec         : in    t_addr_cmd_config_rec;
                    addr_cmd_vector    : in    t_addr_cmd_vector;
                    signal_name        : in    t_addr_cmd_signals;
                    mask_value         : in    std_logic
                  ) return t_addr_cmd_vector
    is
        variable v_i : integer;
    variable v_addr_cmd_vector :  t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        v_addr_cmd_vector := addr_cmd_vector;

        for v_i in 0 to (config_rec.cmds_per_clk)-1 loop

            case signal_name is

                when addr  => if (mask_value = '0') then v_addr_cmd_vector(v_i).addr  := 0;    else v_addr_cmd_vector(v_i).addr  := (2 ** config_rec.num_addr_bits) - 1; end if;
                when ba    => if (mask_value = '0') then v_addr_cmd_vector(v_i).ba    := 0;    else v_addr_cmd_vector(v_i).ba    := (2 ** config_rec.num_ba_bits) - 1;   end if;
                when cas_n => if (mask_value = '0') then v_addr_cmd_vector(v_i).cas_n := true; else v_addr_cmd_vector(v_i).cas_n := false;                               end if;
                when ras_n => if (mask_value = '0') then v_addr_cmd_vector(v_i).ras_n := true; else v_addr_cmd_vector(v_i).ras_n := false;                               end if;
                when we_n  => if (mask_value = '0') then v_addr_cmd_vector(v_i).we_n  := true; else v_addr_cmd_vector(v_i).we_n  := false;                               end if;
                when cke   => if (mask_value = '0') then v_addr_cmd_vector(v_i).cke   := 0;    else v_addr_cmd_vector(v_i).cke   := (2**config_rec.num_ranks) -1;        end if;
                when cs_n  => if (mask_value = '0') then v_addr_cmd_vector(v_i).cs_n  := 0;    else v_addr_cmd_vector(v_i).cs_n  := (2**config_rec.num_cs_bits) -1;      end if;
                when odt   => if (mask_value = '0') then v_addr_cmd_vector(v_i).odt   := 0;    else v_addr_cmd_vector(v_i).odt   := (2**config_rec.num_ranks) -1;        end if;
                when rst_n => if (mask_value = '0') then v_addr_cmd_vector(v_i).rst_n := true; else v_addr_cmd_vector(v_i).rst_n := false;                               end if;

                when others => report ac_report_prefix & "bit masking not supported for the given signal name" severity failure;

            end case;

        end loop;

        return v_addr_cmd_vector;

    end function;

    -- -----------------------------------------------------------
    -- procedure to mask each bit of signal signal_name in addr_cmd_vector with mask_value
    -- -----------------------------------------------------------
    procedure mask(        config_rec      : in    t_addr_cmd_config_rec;
                    signal addr_cmd_vector : inout t_addr_cmd_vector;
                           signal_name     : in    t_addr_cmd_signals;
                           mask_value      : in    std_logic
                  )
    is
        variable v_i : integer;
    begin

        for v_i in 0 to (config_rec.cmds_per_clk)-1 loop

            case signal_name is

                when addr  => if (mask_value = '0') then addr_cmd_vector(v_i).addr  <= 0;    else addr_cmd_vector(v_i).addr  <= (2 ** config_rec.num_addr_bits) - 1; end if;
                when ba    => if (mask_value = '0') then addr_cmd_vector(v_i).ba    <= 0;    else addr_cmd_vector(v_i).ba    <= (2 ** config_rec.num_ba_bits) - 1;   end if;
                when cas_n => if (mask_value = '0') then addr_cmd_vector(v_i).cas_n <= true; else addr_cmd_vector(v_i).cas_n <= false;                               end if;
                when ras_n => if (mask_value = '0') then addr_cmd_vector(v_i).ras_n <= true; else addr_cmd_vector(v_i).ras_n <= false;                               end if;
                when we_n  => if (mask_value = '0') then addr_cmd_vector(v_i).we_n  <= true; else addr_cmd_vector(v_i).we_n  <= false;                               end if;
                when cke   => if (mask_value = '0') then addr_cmd_vector(v_i).cke   <= 0;    else addr_cmd_vector(v_i).cke   <= (2**config_rec.num_ranks) -1;        end if;
                when cs_n  => if (mask_value = '0') then addr_cmd_vector(v_i).cs_n  <= 0;    else addr_cmd_vector(v_i).cs_n  <= (2**config_rec.num_cs_bits) -1;        end if;
                when odt   => if (mask_value = '0') then addr_cmd_vector(v_i).odt   <= 0;    else addr_cmd_vector(v_i).odt   <= (2**config_rec.num_ranks) -1;        end if;
                when rst_n => if (mask_value = '0') then addr_cmd_vector(v_i).rst_n <= true; else addr_cmd_vector(v_i).rst_n <= false;                               end if;

                when others => report ac_report_prefix & "masking not supported for the given signal name" severity failure;

            end case;

        end loop;

    end procedure;


    -- -----------------------------------------------------------
    -- function to mask a given bit (mask_bit) of signal signal_name in addr_cmd_vector with mask_value
    -- -----------------------------------------------------------
    function mask  ( config_rec        : in    t_addr_cmd_config_rec;
                     addr_cmd_vector   : in    t_addr_cmd_vector;
                     signal_name       : in    t_addr_cmd_signals;
                     mask_value        : in    std_logic;
                     mask_bit          : in    natural
                   ) return t_addr_cmd_vector
    is
        variable v_i       : integer;
        variable v_addr    : std_logic_vector(config_rec.num_addr_bits-1 downto 0); -- v_addr is bit vector of address
        variable v_ba      : std_logic_vector(config_rec.num_ba_bits-1 downto 0); -- v_addr is bit vector of bank address
        variable v_vec_len : natural range 0 to 4;
    variable v_addr_cmd_vector : t_addr_cmd_vector(0 to config_rec.cmds_per_clk -1);
    begin

        v_addr_cmd_vector := addr_cmd_vector;
        v_vec_len         := config_rec.cmds_per_clk;

        for v_i in 0 to v_vec_len-1 loop

            case signal_name is

                when addr =>
                    v_addr                      := std_logic_vector(to_unsigned(v_addr_cmd_vector(v_i).addr,v_addr'length));
                    v_addr(mask_bit)            := mask_value;
                    v_addr_cmd_vector(v_i).addr := to_integer(unsigned(v_addr));

                when ba =>
                    v_ba                        := std_logic_vector(to_unsigned(v_addr_cmd_vector(v_i).ba,v_ba'length));
                    v_ba(mask_bit)              := mask_value;
                    v_addr_cmd_vector(v_i).ba   := to_integer(unsigned(v_ba));

                when others =>
                    report ac_report_prefix & "bit masking not supported for the given signal name" severity failure;

            end case;

        end loop;

        return v_addr_cmd_vector;

    end function;

--#mw_prefix ("alt_mem_phy_addr_cmd_pkg")
end alt_mem_phy_addr_cmd_pkg;
--#end

