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
  Title           : Write datapath
  File:  $RCSfile : ddr2_write_datapath.vhd,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : Write datapath (Full rate)
-----------------------------------------------------------------------------*/
//#end

// Note, this write datapath logic matches both the spec, and what was done in
// the beta project.

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_write_dp_fr")
module alt_mem_phy_write_dp_fr(
//#end
                                // clocks
                                phy_clk_1x,            // full-rate clock
                                mem_clk_2x,            // full-rate clock
                                write_clk_2x,          // full-rate clock

                                // active-low resets, sync'd to clock domain
                                reset_phy_clk_1x_n,
                                reset_mem_clk_2x_n,
                                reset_write_clk_2x_n,

                                // control i/f inputs
                                ctl_mem_be,
                                ctl_mem_dqs_burst,
                                ctl_mem_wdata,
                                ctl_mem_wdata_valid,

                                // seq i/f inputs :
                                seq_be,
                                seq_dqs_burst,
                                seq_wdata,
                                seq_wdata_valid,

                                seq_ctl_sel,

                                // outputs to IOEs
                                wdp_wdata_h_2x,
                                wdp_wdata_l_2x,
                                wdp_wdata_oe_2x,
                                wdp_wdqs_2x,
                                wdp_wdqs_oe_2x,
                                wdp_dm_h_2x,
                                wdp_dm_l_2x
                                );

// parameter declarations
parameter BIDIR_DPINS        = 1;
parameter LOCAL_IF_DRATE     = "FULL";
parameter LOCAL_IF_DWIDTH    = 256;
parameter MEM_IF_DM_WIDTH    = 8;
parameter MEM_IF_DQ_PER_DQS  = 8;
parameter MEM_IF_DQS_WIDTH   = 8;
parameter GENERATE_WRITE_DQS = 1;
parameter MEM_IF_DWIDTH      = 64;
parameter DWIDTH_RATIO       = 2;
parameter MEM_IF_DM_PINS_EN  = 1;


// "internal" parameter, not to get propagated from higher levels...
parameter NUM_DUPLICATE_REGS = 4;             // 1 per nibble to save registers


// clocks
input wire                                                   phy_clk_1x;          // half-rate system clock
input wire                                                   mem_clk_2x;          // full-rate memory clock
input wire                                                   write_clk_2x;        // full-rate write clock

// resets, async assert, de-assert is sync'd to each clock domain
input wire                                                   reset_phy_clk_1x_n;
input wire                                                   reset_mem_clk_2x_n;
input wire                                                   reset_write_clk_2x_n;

// control i/f inputs
input wire [MEM_IF_DM_WIDTH  * DWIDTH_RATIO - 1 : 0]         ctl_mem_be;           // byte enable == ~data mask
input wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0]       ctl_mem_dqs_burst;    // dqs burst indication
input wire [MEM_IF_DWIDTH*DWIDTH_RATIO - 1 : 0]              ctl_mem_wdata;        // write data
input wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0]       ctl_mem_wdata_valid;  // write data valid indication

// seq i/f inputs
input wire [MEM_IF_DM_WIDTH  * DWIDTH_RATIO   - 1 : 0]       seq_be;
input wire [MEM_IF_DWIDTH    * DWIDTH_RATIO   - 1 : 0]       seq_wdata;
input wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0]       seq_dqs_burst;
input wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0]       seq_wdata_valid;

input wire                                                   seq_ctl_sel;

//#pb_del Preserves should prevent these registers being drawn in to the IOE itself.
//#pb_del This is desirable because when this happens the timing scripts break.
(*preserve*) output reg  [MEM_IF_DWIDTH - 1 : 0]             wdp_wdata_h_2x;      // wdata_h to IOE
(*preserve*) output reg  [MEM_IF_DWIDTH - 1 : 0]             wdp_wdata_l_2x;      // wdata_l to IOE
output wire [MEM_IF_DWIDTH - 1 : 0]                          wdp_wdata_oe_2x;     // OE to DQ pin
output reg  [(MEM_IF_DQS_WIDTH) - 1 : 0]                     wdp_wdqs_2x;         // DQS to IOE
output reg  [(MEM_IF_DQS_WIDTH) - 1 : 0]                     wdp_wdqs_oe_2x;      // OE to DQS pin

//#pb_del Preserves should prevent these registers being drawn in to the IOE itself.
//#pb_del This is desirable because when this happens the timing scripts break.
(*preserve*) output reg [MEM_IF_DM_WIDTH -1 : 0]                 wdp_dm_h_2x;         // dm_h to IOE
(*preserve*) output reg [MEM_IF_DM_WIDTH -1 : 0]                 wdp_dm_l_2x;         // dm_l to IOE

// internal reg declarations

// registers (on a per- DQS group basis) which sync the dqs_burst_1x to phy_clk or mem_clk_2x.
// They are used to generate the DQS signal and its OE.
(*preserve*) reg [MEM_IF_DQS_WIDTH -1 : 0]                   dqs_burst_1x_r;
(*preserve*) reg [MEM_IF_DQS_WIDTH -1 : 0]                   dqs_burst_2x_r1;
(*preserve*) reg [MEM_IF_DQS_WIDTH -1 : 0]                   dqs_burst_2x_r2;
(*preserve*) reg [MEM_IF_DQS_WIDTH -1 : 0]                   dqs_burst_2x_r3;

// registers to generate the dq_oe, on a per nibble basis, to save registers.
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_valid_1x_r1;   // wdata_valid_1x, retimed in phy_clk_1x
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_valid_1x_r2;   // wdata_valid_1x_r1, retimed in phy_clk_1x

(* preserve, altera_attribute = "-name ADV_NETLIST_OPT_ALLOWED \"NEVER ALLOW\"" *) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] dq_oe_2x;            // 1 per nibble, to save registers

             reg [MEM_IF_DWIDTH - 1 : 0]                    wdp_wdata_oe_2x_int; // intermediate output, gets assigned to o/p signal

             reg [LOCAL_IF_DWIDTH -1 : 0]                   mem_wdata_r1;     // mem_wdata, retimed in phy_clk_1x
             reg [LOCAL_IF_DWIDTH -1 : 0]                   mem_wdata_r2;     // mem_wdata_r1, retimed in phy_clk_1x

// registers used to generate the mux select signal for wdata.
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_valid_1x_r;    // 1 per nibble, to save registers
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_valid_2x_r1;   // 1 per nibble, to save registers
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_valid_2x_r2;   // 1 per nibble, to save registers
(*preserve*) reg [MEM_IF_DWIDTH/NUM_DUPLICATE_REGS -1 : 0 ] wdata_sel;           // 1 per nibble, to save registers

// registers used to generate the dm mux select and dm signals
             reg [MEM_IF_DM_WIDTH*DWIDTH_RATIO - 1 : 0]     mem_dm_r1;
             reg [MEM_IF_DM_WIDTH*DWIDTH_RATIO - 1 : 0]     mem_dm_r2;
(*preserve*) reg                                            wdata_dm_1x_r;       // preserved, to stop merge with wdata_valid_1x_r
(*preserve*) reg                                            wdata_dm_2x_r1;      // preserved, to stop merge with wdata_valid_2x_r1
(*preserve*) reg                                            wdata_dm_2x_r2;      // preserved, to stop merge with wdata_valid_2x_r2
(*preserve*) reg                                            dm_sel;              // preserved, to stop merge with wdata_sel

// MUX outputs....
reg [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0] mem_dqs_burst  ;
reg [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0] mem_wdata_valid;
reg [MEM_IF_DM_WIDTH  * DWIDTH_RATIO   - 1 : 0] mem_be         ;
reg [MEM_IF_DWIDTH    * DWIDTH_RATIO   - 1 : 0] mem_wdata      ;

wire [MEM_IF_DQS_WIDTH - 1 : 0]                             wdp_wdqs_oe_2x_int;


always @*
begin

    // Select controller or sequencer according to the select signal :
    if (seq_ctl_sel)
    begin
        mem_be            = seq_be;
        mem_wdata         = seq_wdata;
        mem_wdata_valid   = seq_wdata_valid;
        mem_dqs_burst     = seq_dqs_burst;
    end


    else
    begin
        mem_be            = ctl_mem_be;
        mem_wdata         = ctl_mem_wdata;
        mem_wdata_valid   = ctl_mem_wdata_valid;
        mem_dqs_burst     = ctl_mem_dqs_burst;
    end

end

genvar  a, b, c, d; // variable for generate statement
integer j;          // variable for loop counters

/////////////////////////////////////////////////////////////////////////
// generate the following write DQS logic on a per DQS group basis.
// wdp_wdqs_2x and wdp_wdqs_oe_2x get output to the IOEs.
////////////////////////////////////////////////////////////////////////

generate
if (GENERATE_WRITE_DQS == 1)
begin

    for (a=0; a<MEM_IF_DQS_WIDTH; a = a+1)
    begin : gen_loop_dqs

        always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
        begin
            if (reset_phy_clk_1x_n == 1'b0)
            begin
                wdp_wdqs_2x[a]     <= 0;
                wdp_wdqs_oe_2x[a]  <= 0;
            end
            else
            begin
                wdp_wdqs_2x[a]     <= wdp_wdqs_oe_2x[a];
                wdp_wdqs_oe_2x[a]  <= mem_dqs_burst;
            end
        end
    end
end
endgenerate

///////////////////////////////////////////////////////////////////
// Generate the write DQ logic.
// These are internal registers which will be used to assign to:
// wdp_wdata_h_2x, wdp_wdata_l_2x, wdp_wdata_oe_2x
// (these get output to the IOEs).
//////////////////////////////////////////////////////////////////

// number of times to replicate mem_wdata_valid bits
parameter DQ_OE_REPS = MEM_IF_DQ_PER_DQS/NUM_DUPLICATE_REGS;

generate
for (a=0; a<MEM_IF_DWIDTH/MEM_IF_DQ_PER_DQS; a=a+1)
begin : gen_dq_oe_2x
    always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
    begin

        if (reset_phy_clk_1x_n == 1'b0)
        begin
            dq_oe_2x[DQ_OE_REPS*(a+1)-1:DQ_OE_REPS*a] <= {(DQ_OE_REPS){1'b0}};
        end
        else

        begin
            dq_oe_2x[DQ_OE_REPS*(a+1)-1:DQ_OE_REPS*a] <= {(DQ_OE_REPS){mem_wdata_valid[a]}};
        end

    end
end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// fanout the dq_oe_2x, which has one register per NUM_DUPLICATE_REGS
// (to save registers), to each bit of wdp_wdata_oe_2x_int and then
// assign to the output wire wdp_wdata_oe_2x( ie one oe for each DQ "pin").
////////////////////////////////////////////////////////////////////////////////

always @(dq_oe_2x)
begin

    for (j=0; j<MEM_IF_DWIDTH; j=j+1)
    begin
        wdp_wdata_oe_2x_int[j] = dq_oe_2x[(j/NUM_DUPLICATE_REGS)];
    end

end

assign wdp_wdata_oe_2x = wdp_wdata_oe_2x_int;


//////////////////////////////////////////////////////////////////////
// Write DQ mapping from mem_wdata to wdata_l_2x, wdata_h_2x
//////////////////////////////////////////////////////////////////////

generate
for (c=0; c<MEM_IF_DWIDTH; c=c+1)
begin : gen_wdata

    always @(posedge phy_clk_1x)
    begin
            wdp_wdata_l_2x[c] <= mem_wdata[c +   MEM_IF_DWIDTH];
            wdp_wdata_h_2x[c] <= mem_wdata[c                  ];

    end
end
endgenerate



///////////////////////////////////////////////////////
// Conditional generation of DM logic, based on generic
///////////////////////////////////////////////////////

generate
if (MEM_IF_DM_PINS_EN == 1'b1)
begin : dm_logic_enabled


    ///////////////////////////////////////////////////////////////////
    // Write DM logic: assignment to wdp_dm_h_2x, wdp_dm_l_2x
    ///////////////////////////////////////////////////////////////////



    // for loop inside a generate statement, but outside a procedural block
    // is treated as a nested generate

    for (d=0; d<MEM_IF_DM_WIDTH; d=d+1)
    begin : gen_dm

        always @(posedge phy_clk_1x)
        begin

            if (mem_wdata_valid[d] == 1'b1) // nb might need to duplicate to meet timing
            begin
                wdp_dm_l_2x[d] <= mem_be[d+MEM_IF_DM_WIDTH];
                wdp_dm_h_2x[d] <= mem_be[d];
            end

            //#pb_del fix for SPR #240899 :
            // To support writes of less than the burst length, mask data when invalid :
            else
            begin
                wdp_dm_l_2x[d] <= 1'b1;
                wdp_dm_h_2x[d] <= 1'b1;
            end




        end
    end // block: gen_dm


end // block: dm_logic_enabled


endgenerate


endmodule


