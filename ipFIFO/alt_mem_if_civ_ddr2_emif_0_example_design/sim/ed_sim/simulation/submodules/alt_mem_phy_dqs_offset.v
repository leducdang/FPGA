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
  Title           : Read datapath

  File:  $RCSfile : alt_mem_phy_dqs_offset.v,v $

  Last Modified   : $Date: 2008/07/12 $

  Revision        : $Revision: #1 $

  Abstract        : DQS offset block. Calculates the offset needed to achieve a particular DQS phase                                                            
////////////////////////////////////////////////////////////////////////////-*/
//#end

//#mw_prefix ("alt_mem_phy_dqs_offset")
module alt_mem_phy_dqs_offset (dll_code,
//#end
                               dqs_offset_output_code,
                               dqs_offset_addnsub,
                               dqs_offset_out_of_range
                               );

parameter TARGETTED_PHASE        = 256;    // 0 to 1023 represents 0 - 360 degrees
parameter DLL_DELAY_CHAIN_LENGTH = 8;      // 4 to 16 DLL delay chain length
parameter DLL_DELAY_BUFFER_MODE  = "HIGH"; // high / low mode (5 / 6 bit DLL code)
parameter DQS_PHASE_SETTING      = 2;      // number of DQS taps used
parameter DLL_INTRINSIC_VALUE    = 16;     // may be speed grade dependent
parameter DBG_PRINT_OFFSET_TABLE = "TRUE"; // debug: print out the lookup table

// a prefix for all report signals to identify phy
//#mw_prefix ("alt_mem_phy")
localparam REPORT_PREFIX         = "alt_mem_phy (dqs_offset) :";
//#end
input  wire [5:0] dll_code;
output wire [5:0] dqs_offset_output_code ; // the offset code to be applied
output wire       dqs_offset_addnsub;      // 1 means add, 0 means subtract
output wire       dqs_offset_out_of_range; // for debug: '1' means code is out of range

reg [7:0] dqs_offset_lookup;               // contains {out_of_range,addnsub,output_code}

// functions to convert from gray code to binary and vice versa

function [5:0] gray2bin;

input [5:0] gray_in;
integer j;
begin

    gray2bin = gray_in;

    for (j=4; j>=0; j=j-1)
    begin
        gray2bin[j] = gray2bin[j+1] ^ gray_in[j];
    end

end

endfunction

function [5:0] bin2gray;

input [5:0] bin_in;
integer k;
begin

    bin2gray[5] = bin_in[5];

    for (k=0; k<=4; k=k+1)
    begin
        bin2gray[k] = bin_in[k] ^ bin_in[k+1];
    end

end

endfunction

// generate the lookup table
// returns {out_of_range,addnsub,code[5:0]}
function [7:0] generate_dqs_offset_lookup;

input [5:0] dll_code;

integer   v_base_delay;
reg [6:0] v_targetted_delta;
reg [5:0] v_integer_offset_value;
integer   v_calculated_offset_value; // offset value required


begin
    generate_dqs_offset_lookup = 0;
    v_base_delay      = (DQS_PHASE_SETTING * 1024) / DLL_DELAY_CHAIN_LENGTH;
    v_targetted_delta = TARGETTED_PHASE - v_base_delay;

    // check if v_targetted_delta is -ve
    if (v_targetted_delta[6] == 1'b1)
    begin
        v_targetted_delta               = v_base_delay - TARGETTED_PHASE;
        generate_dqs_offset_lookup[6]   = 1'b0;  // subtract
    end
    else
    begin
        v_targetted_delta               = v_targetted_delta;
        generate_dqs_offset_lookup[6]   = 1'b1;  // add
    end

    v_integer_offset_value = gray2bin(dll_code);

    v_calculated_offset_value = ( (DLL_INTRINSIC_VALUE + v_integer_offset_value)
                                 * DLL_DELAY_CHAIN_LENGTH
                                 * v_targetted_delta
                                ) / 512;

    generate_dqs_offset_lookup[5:0] = bin2gray((v_calculated_offset_value + 1) / 2);

    // check for sensible boundings (although this should be ok due to range checking in GUI)
    if (DLL_DELAY_BUFFER_MODE == "HIGH")
    begin
        if (v_integer_offset_value > 31)
            generate_dqs_offset_lookup[7] = 1'b1;
        else if (generate_dqs_offset_lookup[6] == 1'b1 && gray2bin(generate_dqs_offset_lookup[5:0]) + v_integer_offset_value > 31) 
            generate_dqs_offset_lookup[7] = 1'b1;
        else if (generate_dqs_offset_lookup[6] == 1'b0 && (v_integer_offset_value - gray2bin(generate_dqs_offset_lookup[5:0]) < 0))
            generate_dqs_offset_lookup[7] = 1'b1;
        else
            generate_dqs_offset_lookup[7] = 1'b0;
    end

    
    else // DLL_DELAY_BUFFER_MODE = "LOW"
    begin
        if (v_integer_offset_value > 63)
            generate_dqs_offset_lookup[7] = 1'b1;
        else if (generate_dqs_offset_lookup[6] == 1'b1 && gray2bin(generate_dqs_offset_lookup[5:0]) + v_integer_offset_value > 63) 
            generate_dqs_offset_lookup[7] = 1'b1;
        else if (generate_dqs_offset_lookup[6] == 1'b0 && (v_integer_offset_value - gray2bin(generate_dqs_offset_lookup[5:0]) < 0))
            generate_dqs_offset_lookup[7] = 1'b1;
        else
            generate_dqs_offset_lookup[7] = 1'b0;

    end 
end 

endfunction


// print the table to the screen
// synthesis translate_off
integer   i;
reg [5:0] v_temp_index;
reg [7:0] v_temp_lookup;

initial
begin
 if (DBG_PRINT_OFFSET_TABLE == "TRUE")
        begin

            for (i=0; i<=63; i=i+1)
            begin

                v_temp_index  = bin2gray(i);
                v_temp_lookup = generate_dqs_offset_lookup(v_temp_index);

                if (i==0) // display the header info as well, first time round
                begin
                	$display("%s *******************************************************************", REPORT_PREFIX);
                	$display("%s *** Printing DQS offset lookup table                            ***", REPORT_PREFIX);
                	$display("%s *******************************************************************", REPORT_PREFIX);
                	$display("%s              Natural            : Bin                : -ve          : flag   ", REPORT_PREFIX);
                	$display("%s              DLL   : offset     : dll_code : offset  : addnsub      : err    ", REPORT_PREFIX);

                    $display("%s   %d      %d           %b         %b        %b             %b     ", REPORT_PREFIX, i, gray2bin(v_temp_lookup[5:0]), v_temp_index, v_temp_lookup[5:0], v_temp_lookup[6], v_temp_lookup[7]);     
                end
                else  // display just the data
                begin   
                    $display("%s   %d      %d           %b         %b        %b             %b     ", REPORT_PREFIX, i, gray2bin(v_temp_lookup[5:0]), v_temp_index, v_temp_lookup[5:0], v_temp_lookup[6], v_temp_lookup[7]);     

                end //if
           end //for loop

end //if
end // initial
//synthesis translate_on

// do a lookup, and output the DQS offset data

// Use a combinatorial always block to improve sim time :
always @(dll_code)
    dqs_offset_lookup = generate_dqs_offset_lookup(dll_code);
// Assign the outputs :    
assign dqs_offset_out_of_range = dqs_offset_lookup[7];
assign dqs_offset_addnsub      = dqs_offset_lookup[6];
assign dqs_offset_output_code  = dqs_offset_lookup[5:0];

endmodule