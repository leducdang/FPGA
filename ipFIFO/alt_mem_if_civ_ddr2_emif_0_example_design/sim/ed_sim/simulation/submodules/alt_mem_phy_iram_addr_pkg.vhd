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
--  Title           : iram address package

--  File:  $RCSfile : alt_mem_phy_seq_record_pkg.vhd,v $

--  Last Modified   : $Date: 2018/07/18 $

--  Revision        : $Revision: #1 $

-------------------------------------------------------------------------------*/
--#end

-- -----------------------------------------------------------------------------
--  Abstract        : iram addressing package for the non-levelling AFI PHY sequencer
--                    The iram address package (alt_mem_phy_iram_addr_pkg) is
--                    used to define the base addresses used for iram writes
--                    during calibration.
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
package alt_mem_phy_iram_addr_pkg IS
--#end

    constant c_ihi_size           : natural := 8;

    -- #pb_del no ranging required below because this type is only used as a constant
    type t_base_hdr_addresses is record
        base_hdr           : natural;
        rrp                : natural;
        safe_dummy         : natural;
        required_addr_bits : natural;
    end record;

    function defaults return t_base_hdr_addresses;

    function rrp_pll_phase_mult (dwidth_ratio : in natural;
                                 dqs_capture  : in natural
                                )
                                return natural;

    function iram_wd_for_full_rrp ( dwidth_ratio  : in natural;
                                    pll_phases    : in natural;
                                    dq_pins       : in natural;
                                    dqs_capture   : in natural
                                  )
                                  return natural;

    function iram_wd_for_one_pin_rrp ( dwidth_ratio  : in natural;
                                       pll_phases    : in natural;
                                       dq_pins       : in natural;
                                       dqs_capture   : in natural
                                     )
                                     return natural;

    function calc_iram_addresses ( dwidth_ratio : in natural;
                                   pll_phases   : in natural;
                                   dq_pins      : in natural;
                                   num_ranks    : in natural;
                                   dqs_capture  : in natural
                                 )
                                 return t_base_hdr_addresses;

--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
end alt_mem_phy_iram_addr_pkg;
--#end

--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
package body alt_mem_phy_iram_addr_pkg IS
--#end

    -- set some safe default values
    function defaults return t_base_hdr_addresses is
        variable temp : t_base_hdr_addresses;
    begin
        temp.base_hdr           := 0;
        temp.rrp                := 0;
        temp.safe_dummy         := 0;
        temp.required_addr_bits := 1;
        return temp;
    end function;

    -- this function determines now many times the PLL phases are swept through per pin
    -- i.e. an n * 360 degree phase sweep
    function rrp_pll_phase_mult (dwidth_ratio : in natural;
                                 dqs_capture  : in natural
                                )
                                return natural
    is
        variable v_output : natural;
    begin

        if dwidth_ratio = 2 and dqs_capture = 1 then

            v_output := 2;  -- if dqs_capture then a 720 degree sweep needed in FR

        else

            v_output := (dwidth_ratio/2);

        end if;

        return v_output;

    end function;

    -- function to calculate how many words are required for a rrp sweep over all pins
    function iram_wd_for_full_rrp ( dwidth_ratio  : in natural;
                                    pll_phases    : in natural;
                                    dq_pins       : in natural;
                                    dqs_capture   : in natural
                                  )
                                  return natural
    is
        variable v_output    : natural;
        variable v_phase_mul : natural;
    begin
        -- determine the n * 360 degrees of sweep required
        v_phase_mul := rrp_pll_phase_mult(dwidth_ratio, dqs_capture);

        -- calculate output size
        v_output := dq_pins * (((v_phase_mul * pll_phases) + 31) / 32);

        return v_output;

    end function;

    -- function to calculate how many words are required for a rrp sweep over all pins
    function iram_wd_for_one_pin_rrp ( dwidth_ratio  : in natural;
                                       pll_phases    : in natural;
                                       dq_pins       : in natural;
                                       dqs_capture   : in natural
                                     )
                                     return natural
    is
        variable v_output : natural;
        variable v_phase_mul : natural;
    begin
        -- determine the n * 360 degrees of sweep required
        v_phase_mul := rrp_pll_phase_mult(dwidth_ratio, dqs_capture);

        -- calculate output size
        v_output := ((v_phase_mul * pll_phases) + 31) / 32;

        return v_output;

    end function;

    -- return iram addresses
    function calc_iram_addresses ( dwidth_ratio : in natural;
                                   pll_phases   : in natural;
                                   dq_pins      : in natural;
                                   num_ranks    : in natural;
                                   dqs_capture  : in natural
                                 )
                                 return t_base_hdr_addresses
    is
        variable working               : t_base_hdr_addresses;
        variable temp                  : natural;

        variable v_required_words      : natural;

    begin

        working.base_hdr               := 0;
        working.rrp                    := working.base_hdr + c_ihi_size;

        -- work out required number of address bits

        -- + for 1 full rrp calibration
        v_required_words               := iram_wd_for_full_rrp(dwidth_ratio, pll_phases, dq_pins, dqs_capture) + 2; -- +2 for header + footer

        -- * loop per cs
        v_required_words               := v_required_words * num_ranks;

        -- + for 1 rrp_seek result
        v_required_words               := v_required_words + 3; -- 1 header, 1 word result, 1 footer

        -- + 2 mtp_almt passes
        v_required_words               := v_required_words + 2 * (iram_wd_for_one_pin_rrp(dwidth_ratio, pll_phases, dq_pins, dqs_capture) + 2);

        -- + for 2 read_mtp result calculation
        v_required_words               := v_required_words + 3*2; -- 1 header, 1 word result, 1 footer

        -- * possible dwidth_ratio/2 iterations for different ac_nt settings
        v_required_words               := v_required_words * (dwidth_ratio / 2);

        working.safe_dummy             := working.rrp + v_required_words;

        temp                           := working.safe_dummy;
        working.required_addr_bits     := 0;

        while (temp >= 1) loop
            working.required_addr_bits := working.required_addr_bits + 1;
            temp                       := temp /2;
        end loop;

        return working;

    end function calc_iram_addresses;

--#mw_prefix ("alt_mem_phy_iram_addr_pkg")
END alt_mem_phy_iram_addr_pkg;
--#end
