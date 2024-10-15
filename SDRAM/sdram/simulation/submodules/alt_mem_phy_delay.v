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


/*-----------------------------------------------------------------------------
  Title           : delay

  File:  $RCSfile : alt_mem_phy_mux.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : This block introduces a signal delay.  It is intended for use
                    to model either DQS bus insertion delays, or postamble delays
                    in order to ensure that RTL simulations work correctly.

                    The delays have been seperated out in to this block such
                    that the VHDL PHY models can be created from SIMGEN with this
                    black-boxed so that the delays still exist as required.
-----------------------------------------------------------------------------*/
//#end


`timescale 1 ps / 1 ps

//#mw_prefix ("alt_mem_phy_delay")
module alt_mem_phy_delay (
//#end
    s_in,
    s_out
);

//parameters
parameter WIDTH                        =  1;
parameter DELAY_PS                     =  10;

//ports
input  wire [WIDTH - 1 : 0]            s_in;
output reg  [WIDTH - 1 : 0]            s_out;

// synopsys translate_off
wire [WIDTH - 1 : 0] delayed_s_in;

//model the transport delay
assign #(DELAY_PS) delayed_s_in = s_in;
// synopsys translate_on

always @*
begin
    s_out = s_in;
// synopsys translate_off
    s_out = delayed_s_in;
// synopsys translate_on
end

endmodule
