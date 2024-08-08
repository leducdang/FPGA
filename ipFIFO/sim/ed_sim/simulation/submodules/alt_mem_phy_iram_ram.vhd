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
--  Title           : iRAM ram block

--  File:  $RCSfile : alt_mem_phy_iram_ram.v,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $
--
-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : inferred ram for the non-levelling AFI PHY sequencer
--                    The inferred ram is used in the iram block to store
--                    debug information about the sequencer. It is variable in
--                    size based on the IRAM_AWIDTH generic and is of size
--                    32 * (2 ** IRAM_ADDR_WIDTH) bits
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

--#mw_prefix ("alt_mem_phy_iram_ram")
entity alt_mem_phy_iram_ram IS
--#end
    generic (
        IRAM_AWIDTH     : natural
   );
    port (
        clk              :  in   std_logic;
        rst_n            :  in   std_logic;

        -- ram ports
        addr             :  in   unsigned(IRAM_AWIDTH-1 downto 0);
        wdata            :  in   std_logic_vector(31 downto 0);
        write            :  in   std_logic;
        rdata            : out   std_logic_vector(31 downto 0)
    );
end entity;

--#mw_prefix ("alt_mem_phy_iram_ram")
architecture struct of alt_mem_phy_iram_ram is
--#end

-- infer ram

    constant c_max_ram_address : natural := 2**IRAM_AWIDTH -1;

    -- registered ram signals
    signal addr_r  : unsigned(IRAM_AWIDTH-1 downto 0);
    signal wdata_r : std_logic_vector(31 downto 0);
    signal write_r : std_logic;
    signal rdata_r : std_logic_vector(31 downto 0);

    -- ram storage array
    type   t_iram is array (0 to c_max_ram_address) of std_logic_vector(31 downto 0);
    signal iram_ram            : t_iram;
    attribute altera_attribute : string;
    attribute altera_attribute of iram_ram : signal is "-name ADD_PASS_THROUGH_LOGIC_TO_INFERRED_RAMS ""OFF""";

begin  -- architecture struct

    -- inferred ram instance - standard ram logic
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            rdata_r <= (others => '0');

        elsif rising_edge(clk) then
            if write_r = '1' then
                iram_ram(to_integer(addr_r)) <= wdata_r;
            end if;

            rdata_r  <= iram_ram(to_integer(addr_r));
        end if;

    end process;

    -- register i/o for speed
    process (clk, rst_n)
    begin
        if rst_n = '0' then

            rdata   <= (others => '0');
            write_r <= '0';
            addr_r  <= (others => '0');
            wdata_r <= (others => '0');

        elsif rising_edge(clk) then

            rdata   <= rdata_r;
            write_r <= write;
            addr_r  <= addr;
            wdata_r <= wdata;

        end if;
    end process;

end architecture struct;
