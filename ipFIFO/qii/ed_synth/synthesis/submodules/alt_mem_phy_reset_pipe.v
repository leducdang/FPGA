// (C) 2001-2022 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//#mw_delete ("")
/* Legal Notice: (C)2006 Altera Corporation. All rights reserved.  Your
   use of Altera Corporation's design tools, logic functions and other
   software and tools, and its AMPP partner logic functions, and any
   output files any of the foregoing (including device programming or
   simulation files), and any associated documentation or information are
   expressly subject to the terms and conditions of the Altera Program
   License Subscription Agreement or other applicable license agreement,
   including, without limitation, that your use is for the sole purpose
   of programming logic devices manufactured by Altera and sold by Altera
   or its authorized distributors.  Please refer to the applicable
   agreement for further details. */


/*////////////////////////////////////////////////////////////////////////////-
  Title           : Reset pipeline registers

  File:  $RCSfile : alt_mem_phy_reset_pipe.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : Part of the NewPhy reset block.  This is instanced once per
                    reset output by alt_mem_phy_clk_reset_sii.  The number of
                    pipeline registers is parameterised.
////////////////////////////////////////////////////////////////////////////-*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_reset_pipe")
module alt_mem_phy_reset_pipe (
//#end
                                input  wire clock,
                                input  wire pre_clear,
                                output wire reset_out
                              );

parameter PIPE_DEPTH = 4;

    // Declare pipeline registers.
    // #pb_del These are deliberately not 'preserved' as this then allows
    // #pb_del a 4 stage reset pipe to be tapped off at stage 2 for common
    // #pb_del clocks (for example), thus reducing routing utilisation.
    reg [PIPE_DEPTH - 1 : 0]  ams_pipe;
    integer                   i;

//    begin : RESET_PIPE
        always @(posedge clock or negedge pre_clear)
        begin

            if (pre_clear == 1'b0)
            begin
                ams_pipe <= 0;
            end

            else
            begin
               for (i=0; i< PIPE_DEPTH; i = i + 1)
               begin
                   if (i==0)
                       ams_pipe[i] <= 1'b1;
                   else
                       ams_pipe[i] <= ams_pipe[i-1];
               end
            end // if-else

        end // always
//    end

    assign reset_out = ams_pipe[PIPE_DEPTH-1];


endmodule
