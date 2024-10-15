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
  Title           : Clock and Reset

  File:  $RCSfile : alt_mem_phy_clk_reset.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : NewPhy Clocking and reset block.  This block receives the
                    global reset and PLL reference clock and generates all the
                    required output clocks and resets.  It instances the PLL,
                    and the PLL reconfig FSM
////////////////////////////////////////////////////////////////////////////-*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_clk_reset")
module alt_mem_phy_clk_reset (
//#end
                               pll_ref_clk,
                               global_reset_n,
                               soft_reset_n,
                               seq_rdp_reset_req_n,

                               ac_clk_2x,
                               measure_clk_2x,
                               mem_clk_2x,
                               mem_clk,
                               mem_clk_n,
                               phy_clk_1x,
                               resync_clk_2x,
                               cs_n_clk_2x,
                               write_clk_2x,
                               half_rate_clk,

                               reset_ac_clk_2x_n,
                               reset_measure_clk_2x_n,
                               reset_mem_clk_2x_n,
                               reset_phy_clk_1x_n,
                               reset_resync_clk_2x_n,
                               reset_write_clk_2x_n,
                               reset_cs_n_clk_2x_n,
                               reset_rdp_phy_clk_1x_n,
                               mem_reset_n,

                               reset_request_n, // new output

                               phs_shft_busy,

                               seq_pll_inc_dec_n,
                               seq_pll_select,
                               seq_pll_start_reconfig,

                               mimic_data_2x,

                               seq_clk_disable,
                               ctrl_clk_disable

                              ) /* synthesis altera_attribute="SUPPRESS_DA_RULE_INTERNAL=\"R101,C104\"" */;

// Note the peculiar ranging below is necessary to use a generated CASE statement
// later in the code :
parameter       AC_PHASE                     =      "MEM_CLK";
parameter       CLOCK_INDEX_WIDTH            =              3;
parameter [0:0] CAPTURE_MIMIC_PATH           =              0;
parameter [0:0] DDR_MIMIC_PATH_EN            =              1;
parameter [0:0] DEDICATED_MEMORY_CLK_EN      =              0;
parameter       DLL_EXPORT_IMPORT            =         "NONE";
parameter       DWIDTH_RATIO                 =              4;
parameter       LOCAL_IF_CLK_PS              =           4000;
parameter       MEM_IF_CLK_PAIR_COUNT        =              3;
parameter       MEM_IF_CLK_PS                =           4000;
parameter       MEM_IF_CS_WIDTH              =              2;
parameter       MEM_IF_DQ_PER_DQS            =              8;
parameter       MEM_IF_DQS_WIDTH             =              8;
parameter       MEM_IF_DWIDTH                =             64;
parameter       MIF_FILENAME                 =      "PLL.MIF";
parameter       PLL_EXPORT_IMPORT            =         "NONE";
parameter       PLL_REF_CLK_PS               =           4000;
parameter       PLL_TYPE                     =     "ENHANCED";
parameter       SPEED_GRADE                  =           "C3";
parameter       DLL_DELAY_BUFFER_MODE        =         "HIGH";
parameter       DLL_DELAY_CHAIN_LENGTH       =             10;
parameter       DQS_OUT_MODE                 = "DELAY_CHAIN2";
parameter       DQS_PHASE                    =             72;
parameter       SCAN_CLK_DIVIDE_BY           =              2;
parameter       USE_MEM_CLK_FOR_ADDR_CMD_CLK =              1;

// Parameters for the PLL:
parameter       PLL_CLK0_DIVIDE_BY           =                 1;
parameter       PLL_CLK0_MULTIPLY_BY         =                 1;
parameter       PLL_CLK0_PHASE_SHIFT_PS      =                 0;
parameter       PLL_CLK1_DIVIDE_BY           =                 1;
parameter       PLL_CLK1_MULTIPLY_BY         =                 2;
parameter       PLL_CLK1_PHASE_SHIFT_PS      =                 0;
parameter       PLL_CLK2_DIVIDE_BY           =                 1;
parameter       PLL_CLK2_MULTIPLY_BY         =                 2;
parameter       PLL_CLK2_PHASE_SHIFT_PS      =             -1250;
parameter       PLL_CLK3_DIVIDE_BY           =                 1;
parameter       PLL_CLK3_MULTIPLY_BY         =                 2;
parameter       PLL_CLK3_PHASE_SHIFT_PS      =                 0;
parameter       PLL_CLK4_DIVIDE_BY           =                 1;
parameter       PLL_CLK4_MULTIPLY_BY         =                 2;
parameter       PLL_CLK4_PHASE_SHIFT_PS      =                 0;
parameter       PLL_INCLK0_PERIOD_PS         =             10000;
parameter       PLL_INTENDED_DEVICE_FAMILY   =   "Cyclone IV GX";
parameter       PLL_VCO_PHASE_SHIFT_STEP     =               104;

// Clock/reset inputs :
input  wire                                                               global_reset_n;
input  wire                                                               pll_ref_clk;
input  wire                                                               soft_reset_n;
input  wire                                                               seq_rdp_reset_req_n;

// Clock/reset outputs :
(* altera_attribute = "-name global_signal   global_clock" *) output wire ac_clk_2x;
(* altera_attribute = "-name global_signal regional_clock" *) output wire measure_clk_2x;
(* altera_attribute = "-name global_signal   global_clock" *) output wire mem_clk_2x;
inout wire [MEM_IF_CLK_PAIR_COUNT - 1 : 0]                                mem_clk;
inout wire [MEM_IF_CLK_PAIR_COUNT - 1 : 0]                                mem_clk_n;
(* altera_attribute = "-name global_signal   global_clock" *) output wire phy_clk_1x;
(* altera_attribute = "-name global_signal regional_clock" *) output wire resync_clk_2x;
(* altera_attribute = "-name global_signal   global_clock" *) output wire cs_n_clk_2x;
(* altera_attribute = "-name global_signal   global_clock" *) output wire write_clk_2x;
output wire                                                               half_rate_clk;

output wire                                                               reset_ac_clk_2x_n;
output wire                                                               reset_measure_clk_2x_n;
output wire                                                               reset_mem_clk_2x_n;
output  reg                                                               reset_phy_clk_1x_n;
output wire                                                               reset_resync_clk_2x_n;
output wire                                                               reset_write_clk_2x_n;
output wire                                                               reset_cs_n_clk_2x_n;
output wire                                                               reset_rdp_phy_clk_1x_n;
output wire                                                               mem_reset_n;

// This is the PLL locked signal :
output wire                                                               reset_request_n;

// Misc I/O :
output reg                                                                phs_shft_busy;

input  wire                                                               seq_pll_inc_dec_n;
input  wire [CLOCK_INDEX_WIDTH - 1 : 0 ]                                  seq_pll_select;
input  wire                                                               seq_pll_start_reconfig;

output wire                                                               mimic_data_2x;

input wire                                                                seq_clk_disable;
input wire [MEM_IF_CLK_PAIR_COUNT - 1 : 0]                                ctrl_clk_disable;



(*preserve*) reg                                                          seq_pll_start_reconfig_ams;
(*preserve*) reg                                                          seq_pll_start_reconfig_r;
(*preserve*) reg                                                          seq_pll_start_reconfig_2r;
(*preserve*) reg                                                          seq_pll_start_reconfig_3r;

wire                                                                      pll_scanclk;
wire                                                                      pll_scanread;
wire                                                                      pll_scanwrite;
wire                                                                      pll_scandata;
wire                                                                      pll_scandone;
wire                                                                      pll_scandataout;

reg                                                                       pll_new_dir;
reg [2:0]                                                                 pll_new_phase;
wire                                                                      pll_phase_auto_calibrate_pulse;

reg [`CLK_PLL_RECONFIG_FSM_WIDTH-1:0]                                     pll_reconfig_state;

reg                                                                       pll_reconfig_initialised;
reg [CLOCK_INDEX_WIDTH - 1 : 0 ]                                          pll_current_phase;
reg                                                                       pll_current_dir;

reg [`CLK_PLL_RECONFIG_FSM_WIDTH-1:0]                                     next_pll_reconfig_state;

reg                                                                       next_pll_reconfig_initialised;
reg [CLOCK_INDEX_WIDTH - 1 : 0 ]                                          next_pll_current_phase;
reg                                                                       next_pll_current_dir;

(*preserve*) reg                                                          pll_reprogram_request_pulse;   // 1 scan clk cycle long
(*preserve*) reg                                                          pll_reprogram_request_pulse_r;
(*preserve*) reg                                                          pll_reprogram_request_pulse_2r;
wire                                                                      pll_reprogram_request_long_pulse; // 3 scan clk cycles long
(*preserve*) reg                                                          pll_reprogram_request;

wire                                                                      pll_reconfig_busy;
reg                                                                       pll_reconfig;
reg                                                                       pll_reconfig_write_param;
reg [3:0]                                                                 pll_reconfig_counter_type;
reg [8:0]                                                                 pll_reconfig_data_in;

wire                                                                      pll_locked;


wire                                                                      phy_internal_reset_n;
wire                                                                      pll_reset;

(*preserve*) reg                                                          global_pre_clear;
wire                                                                      global_or_soft_reset_n;

(*preserve*) reg                                                          clk_div_reset_ams_n   = 1'b0;
(*preserve*) reg                                                          clk_div_reset_ams_n_r = 1'b0;

(*preserve*) reg                                                          pll_reconfig_reset_ams_n   = 1'b0;
(*preserve*) reg                                                          pll_reconfig_reset_ams_n_r = 1'b0;

(*preserve*) reg                                                          reset_master_ams;

wire [MEM_IF_CLK_PAIR_COUNT - 1 : 0]                                      mimic_data_2x_internal;

// Create the scan clock.  This is a divided-down version of the PLL reference clock.
// The scan chain will have an Fmax of around 100MHz, and so initially the scan clock is
// created by a divide-by 4 circuit to allow plenty of margin with the expected reference
// clock frequency of 100MHz.  This may be changed via the parameter.

reg [2:0]                                                                 divider  = 3'h0;
(*preserve*) reg                                                          scan_clk = 1'b0;


(*preserve*) reg                                                          global_reset_ams_n   = 1'b0;
(*preserve*) reg                                                          global_reset_ams_n_r = 1'b0;


wire                                                                      pll_phase_done;

(*preserve*) reg [2:0]                                                    seq_pll_start_reconfig_ccd_pipe;

(*preserve*) reg                                                          seq_pll_inc_dec_ccd;
(*preserve*) reg [CLOCK_INDEX_WIDTH - 1 : 0]                              seq_pll_select_ccd ;

wire                                                                      pll_reconfig_reset_n;

wire                                                                      clk_divider_reset_n;


// Output the PLL locked signal to be used as a reset_request_n - IE. reset when the PLL loses
// lock :
assign reset_request_n = pll_locked;



// Reset the scanclk clock divider if we either have a global_reset or the PLL loses lock
assign pll_reconfig_reset_n = global_reset_n && pll_locked;


// Clock divider circuit reset generation.
always @(posedge phy_clk_1x or negedge pll_reconfig_reset_n)
begin

    if (pll_reconfig_reset_n == 1'b0)
    begin
        clk_div_reset_ams_n   <= 1'b0;
        clk_div_reset_ams_n_r <= 1'b0;
    end

    else
    begin
        clk_div_reset_ams_n   <= 1'b1;
        clk_div_reset_ams_n_r <= clk_div_reset_ams_n;
    end

end

// PLL reconfig and synchronisation circuit reset generation.
always @(posedge scan_clk or negedge pll_reconfig_reset_n)
begin

    if (pll_reconfig_reset_n == 1'b0)
    begin
        pll_reconfig_reset_ams_n   <= 1'b0;
        pll_reconfig_reset_ams_n_r <= 1'b0;
    end

    else
    begin
        pll_reconfig_reset_ams_n   <= 1'b1;
        pll_reconfig_reset_ams_n_r <= pll_reconfig_reset_ams_n;
    end

end

// Create the scan clock.  Used for PLL reconfiguring in this block.

// Clock divider reset is the direct output of the AMS flops :
assign clk_divider_reset_n = clk_div_reset_ams_n_r;

generate

    if (SCAN_CLK_DIVIDE_BY == 1)
    begin : no_scan_clk_divider

        always @(phy_clk_1x)
        begin
            scan_clk = phy_clk_1x;
        end

    end

    else
    begin : gen_scan_clk

        always @(posedge phy_clk_1x or negedge clk_divider_reset_n)
        begin

            if (clk_divider_reset_n == 1'b0)
            begin
                scan_clk  <= 1'b0;
                divider   <= 3'h0;
            end

            else
            begin

                // This method of clock division does not require "divider" to be used
                // as an intermediate clock:
                if (divider == (SCAN_CLK_DIVIDE_BY / 2 - 1))
                begin
                    scan_clk <= ~scan_clk; // Toggle
                    divider  <= 3'h0;
                end

                else
                begin
                    scan_clk <= scan_clk; // Do not toggle
                    divider  <= divider + 3'h1;
                end

            end

        end

    end

endgenerate




// NB. This lookup table shall be different for CIII/SIII
// The PLL phasecounterselect is 3 bits wide, therefore hardcode the output to 3 bits :
function [2:0] lookup;

input [CLOCK_INDEX_WIDTH-1:0] seq_num;
begin
    casez (seq_num)
    3'b000  : lookup = 3'b010; // legal code
    3'b001  : lookup = 3'b011; // legal code
    3'b010  : lookup = 3'b111; // illegal - return code 3'b111
    3'b011  : lookup = 3'b100; // legal code
    3'b100  : lookup = 3'b110; // legal code
    3'b101  : lookup = 3'b101; // legal code
    3'b110  : lookup = 3'b111; // illegal - return code 3'b111
    3'b111  : lookup = 3'b111; // illegal - return code 3'b111
    default : lookup = 3'bxxx; // X propagation
    endcase
end

endfunction



// Metastable-harden seq_pll_start_reconfig signal (from the phy clock domain). NB:
// by double-clocking this signal, it is not necessary to double-clock the
// seq_pll_inc_dec_n and seq_pll_select signals - since they will only get
// used on a positive edge of the metastable-hardened seq_pll_start_reconfig signal (so
// should be stable by that point).

always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

    if (reset_phy_clk_1x_n == 1'b0)
    begin
        seq_pll_inc_dec_ccd             <= 1'b0;
        seq_pll_select_ccd              <= {CLOCK_INDEX_WIDTH{1'b0}};
        seq_pll_start_reconfig_ccd_pipe <= 3'b000;
    end

    // Generate 'ccd' Cross Clock Domain signals :
    else
    begin

        seq_pll_start_reconfig_ccd_pipe <= {seq_pll_start_reconfig_ccd_pipe[1:0], seq_pll_start_reconfig};

        if (seq_pll_start_reconfig == 1'b1 && seq_pll_start_reconfig_ccd_pipe[0] == 1'b0)
        begin
            seq_pll_inc_dec_ccd <= seq_pll_inc_dec_n;
            seq_pll_select_ccd  <= seq_pll_select;
        end

    end

end


always @(posedge scan_clk or negedge pll_reconfig_reset_ams_n_r)
begin

    if (pll_reconfig_reset_ams_n_r == 1'b0)
    begin
        seq_pll_start_reconfig_ams     <= 1'b0;
        seq_pll_start_reconfig_r       <= 1'b0;
        seq_pll_start_reconfig_2r      <= 1'b0;
        seq_pll_start_reconfig_3r      <= 1'b0;

        pll_reprogram_request_pulse    <= 1'b0;
        pll_reprogram_request_pulse_r  <= 1'b0;
        pll_reprogram_request_pulse_2r <= 1'b0;
        pll_reprogram_request          <= 1'b0;
    end

    else
    begin
        seq_pll_start_reconfig_ams     <= seq_pll_start_reconfig_ccd_pipe[2];
        seq_pll_start_reconfig_r       <= seq_pll_start_reconfig_ams;
        seq_pll_start_reconfig_2r      <= seq_pll_start_reconfig_r;
        seq_pll_start_reconfig_3r      <= seq_pll_start_reconfig_2r;

        pll_reprogram_request_pulse    <= pll_phase_auto_calibrate_pulse;
        pll_reprogram_request_pulse_r  <= pll_reprogram_request_pulse;
        pll_reprogram_request_pulse_2r <= pll_reprogram_request_pulse_r;
        pll_reprogram_request          <= pll_reprogram_request_long_pulse;

    end

end



// Rising-edge detect to generate a single phase shift step
assign pll_phase_auto_calibrate_pulse = ~seq_pll_start_reconfig_3r && seq_pll_start_reconfig_2r;

// extend the phase shift request pulse to be 3 scan clk cycles long.
assign pll_reprogram_request_long_pulse = pll_reprogram_request_pulse || pll_reprogram_request_pulse_r || pll_reprogram_request_pulse_2r;



// Register the Phase step settings
always @(posedge scan_clk or negedge pll_reconfig_reset_ams_n_r)
begin
    if (pll_reconfig_reset_ams_n_r == 1'b0)
    begin
        pll_new_dir   <= 1'b0;
        pll_new_phase <= 3'h0; // CIII PLL has 3bit phase select
    end

    else
    begin

        if (pll_phase_auto_calibrate_pulse)
        begin
            pll_new_dir   <= seq_pll_inc_dec_ccd;
            pll_new_phase <= lookup(seq_pll_select_ccd);
        end

    end
end



// generate the busy signal - just the inverse of the done o/p from the pll OR'd with the reprogram request (in case the done o/p is missed).
always @(posedge scan_clk or negedge pll_reconfig_reset_ams_n_r)
begin

    if (pll_reconfig_reset_ams_n_r == 1'b0)
        phs_shft_busy <= 1'b0;

    else
        phs_shft_busy <= pll_reprogram_request || ~pll_phase_done;

end




// Gate the soft reset input (from SOPC builder for example) with the PLL
// locked signal :
assign global_or_soft_reset_n  = soft_reset_n && global_reset_n;

// Create the PHY internal reset signal :
assign phy_internal_reset_n = pll_locked && global_or_soft_reset_n;

// The PLL resets only on a global reset :
assign pll_reset = !global_reset_n;


generate

    // Half-rate mode :
    if (DWIDTH_RATIO == 4)
    begin

        // #pb_del in half-rate case, the phy_clk_1x_int comes from port c0 of the pll, and is
        // #pb_del a half-rate clock.

        //#mw_prefix ("alt_mem_phy_pll")
        alt_mem_phy_pll #(
            .CLK0_DIVIDE_BY (PLL_CLK0_DIVIDE_BY),
            .CLK0_MULTIPLY_BY (PLL_CLK0_MULTIPLY_BY),
            .CLK0_PHASE_SHIFT_PS (PLL_CLK0_PHASE_SHIFT_PS),
            .CLK1_DIVIDE_BY (PLL_CLK1_DIVIDE_BY),
            .CLK1_MULTIPLY_BY (PLL_CLK1_MULTIPLY_BY),
            .CLK1_PHASE_SHIFT_PS (PLL_CLK1_PHASE_SHIFT_PS),
            .CLK2_DIVIDE_BY (PLL_CLK2_DIVIDE_BY),
            .CLK2_MULTIPLY_BY (PLL_CLK2_MULTIPLY_BY),
            .CLK2_PHASE_SHIFT_PS (PLL_CLK2_PHASE_SHIFT_PS),
            .CLK3_DIVIDE_BY (PLL_CLK3_DIVIDE_BY),
            .CLK3_MULTIPLY_BY (PLL_CLK3_MULTIPLY_BY),
            .CLK3_PHASE_SHIFT_PS (PLL_CLK3_PHASE_SHIFT_PS),
            .CLK4_DIVIDE_BY (PLL_CLK4_DIVIDE_BY),
            .CLK4_MULTIPLY_BY (PLL_CLK4_MULTIPLY_BY),
            .CLK4_PHASE_SHIFT_PS (PLL_CLK4_PHASE_SHIFT_PS),
            .INCLK0_PERIOD_PS (PLL_INCLK0_PERIOD_PS),
            .INTENDED_DEVICE_FAMILY (PLL_INTENDED_DEVICE_FAMILY),
            .VCO_PHASE_SHIFT_STEP (PLL_VCO_PHASE_SHIFT_STEP)
        ) pll (
        //#end
            .areset(pll_reset),
            .inclk0(pll_ref_clk),
            .phasecounterselect(pll_new_phase),
            .phasestep(pll_reprogram_request),
            .phaseupdown(pll_new_dir),
            .scanclk(scan_clk),
            .c0(phy_clk_1x),
            .c1(mem_clk_2x),
            .c2(write_clk_2x),
            .c3(resync_clk_2x),
            .c4(measure_clk_2x),
            .locked(pll_locked),
            .phasedone(pll_phase_done)
        );

        assign half_rate_clk = phy_clk_1x;

    end

    // Full-rate mode :
    else
    begin

        // #pb_del in full-rate case, phy_clk_1x_int is assigned the value of mem_clk_2x_int
        // #pb_del (ie. full-rate) and the pll connection for c0 is left open.

        //#mw_prefix ("alt_mem_phy_pll")
        alt_mem_phy_pll #(
            .CLK0_DIVIDE_BY (PLL_CLK0_DIVIDE_BY),
            .CLK0_MULTIPLY_BY (PLL_CLK0_MULTIPLY_BY),
            .CLK0_PHASE_SHIFT_PS (PLL_CLK0_PHASE_SHIFT_PS),
            .CLK1_DIVIDE_BY (PLL_CLK1_DIVIDE_BY),
            .CLK1_MULTIPLY_BY (PLL_CLK1_MULTIPLY_BY),
            .CLK1_PHASE_SHIFT_PS (PLL_CLK1_PHASE_SHIFT_PS),
            .CLK2_DIVIDE_BY (PLL_CLK2_DIVIDE_BY),
            .CLK2_MULTIPLY_BY (PLL_CLK2_MULTIPLY_BY),
            .CLK2_PHASE_SHIFT_PS (PLL_CLK2_PHASE_SHIFT_PS),
            .CLK3_DIVIDE_BY (PLL_CLK3_DIVIDE_BY),
            .CLK3_MULTIPLY_BY (PLL_CLK3_MULTIPLY_BY),
            .CLK3_PHASE_SHIFT_PS (PLL_CLK3_PHASE_SHIFT_PS),
            .CLK4_DIVIDE_BY (PLL_CLK4_DIVIDE_BY),
            .CLK4_MULTIPLY_BY (PLL_CLK4_MULTIPLY_BY),
            .CLK4_PHASE_SHIFT_PS (PLL_CLK4_PHASE_SHIFT_PS),
            .INCLK0_PERIOD_PS (PLL_INCLK0_PERIOD_PS),
            .INTENDED_DEVICE_FAMILY (PLL_INTENDED_DEVICE_FAMILY),
            .VCO_PHASE_SHIFT_STEP (PLL_VCO_PHASE_SHIFT_STEP)
        ) pll (
        //#end
            .areset(pll_reset),
            .inclk0(pll_ref_clk),
            .phasecounterselect(pll_new_phase),
            .phasestep(pll_reprogram_request),
            .phaseupdown(pll_new_dir),
            .scanclk(scan_clk),
            .c0(half_rate_clk),
            .c1(mem_clk_2x),
            .c2(write_clk_2x),
            .c3(resync_clk_2x),
            .c4(measure_clk_2x),
            .locked(pll_locked),
            .phasedone(pll_phase_done)
        );

        // NB. phy_clk_1x is now full-rate, despite the "1x" naming convention :
        assign phy_clk_1x = mem_clk_2x;

    end

endgenerate



generate

    if (USE_MEM_CLK_FOR_ADDR_CMD_CLK == 1)
    begin

        assign ac_clk_2x   = mem_clk_2x;
        assign cs_n_clk_2x = mem_clk_2x;

    end

    else
    begin

        assign ac_clk_2x   = write_clk_2x;
        assign cs_n_clk_2x = write_clk_2x;

    end

endgenerate



//NB. cannot use altddio_out instantiations, as need the combout and regout outputs for mimic path.
generate
genvar clk_pair;

    case ({DDR_MIMIC_PATH_EN, CAPTURE_MIMIC_PATH, DEDICATED_MEMORY_CLK_EN})

    // Mimic path option 1 - this is the default configuration
    default :
    begin

    for (clk_pair = 0 ; clk_pair < MEM_IF_CLK_PAIR_COUNT; clk_pair = clk_pair + 1)
    begin : DDR_CLK_OUT

        // Instance "mem_clk" output pad, with appropriate mimic path connections :
        altddio_bidir   #(
            .extend_oe_disable ("UNUSED"),
            .implement_input_in_lcell ("UNUSED"),
            .intended_device_family ("Cyclone III"),
            .invert_output ("OFF"),
            .lpm_type ("altddio_bidir"),
            .oe_reg ("UNUSED"),
            .power_up_high ("OFF"),
            .width (1)

        )ddr_clk_out_p (
            .padio (mem_clk[clk_pair]),
            .outclock (~mem_clk_2x),
            .inclock (measure_clk_2x),
            .oe (1'b1),
            .datain_h (1'b0),
            .datain_l (1'b1),
            .dataout_h (mimic_data_2x_internal[clk_pair]),
            .dataout_l (),
            .aclr (seq_clk_disable || ctrl_clk_disable[clk_pair]),
            .aset (),
            .combout (),
            .dqsundelayedout (),
            .inclocken (),
            .oe_out (),
            .outclocken (1'b1),
            .sclr (1'b0),
            .sset (1'b0)
        );

        // Instance "mem_clk_n" output pad, no mimic connections made as these are on the
        // 'mem_clk' :
        altddio_bidir   #(
            .extend_oe_disable ("UNUSED"),
            .implement_input_in_lcell ("UNUSED"),
            .intended_device_family ("Cyclone III"),
            .invert_output ("OFF"),
            .lpm_type ("altddio_bidir"),
            .oe_reg ("UNUSED"),
            .power_up_high ("OFF"),
            .width (1)
        )ddr_clk_out_n (
            .padio (mem_clk_n[clk_pair]),
            .outclock (mem_clk_2x),
            .inclock (),
            .oe (1'b1),
            .datain_h (1'b0),
            .datain_l (1'b1),
            .dataout_h (),
            .dataout_l (),
            .aclr (seq_clk_disable || ctrl_clk_disable[clk_pair]),
            .aset (),
            .combout (),
            .dqsundelayedout (),
            .inclocken (),
            .oe_out (),
            .outclocken (1'b1),
            .sclr (1'b0),
            .sset (1'b0)
        );


    end //for

    // Pick off the mimic data from the first internal mimic_data signal :
    assign mimic_data_2x = mimic_data_2x_internal[0];

    end // caseitem

    endcase

endgenerate



//#pb_del Note that all reset flops contain the 'ams' string (Anti-metastabilty) such that
//#pb_del in timing analysis timing violations may be ignored.  reset recovery/removal violations
//#pb_del are to be expected, but as both D and Q pins of the flops in question are at logic 1
//#pb_del a metastable state is not entered.

//#pb_del See http://i.cmpnet.com/deepchip/downloads/cliff_resets.zip for detailed analysis of this
//#pb_del type of reset circuit.

// Master reset generation :
always @(posedge phy_clk_1x or negedge phy_internal_reset_n)
begin

    if (phy_internal_reset_n == 1'b0)
    begin
        reset_master_ams   <= 1'b0;
        global_pre_clear    <= 1'b0;
    end

    else
    begin
        reset_master_ams   <= 1'b1;
        global_pre_clear    <= reset_master_ams;
    end

end


// phy_clk reset generation :
always @(posedge phy_clk_1x or negedge global_pre_clear)
begin

    if (global_pre_clear == 1'b0)
    begin
        reset_phy_clk_1x_n <= 1'b0;
    end

    else
    begin
        reset_phy_clk_1x_n <= global_pre_clear;
    end

end




// NB. phy_clk reset is generated above.


// phy_clk reset generation for read datapaths :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (2) ) reset_rdp_phy_clk_pipe(
//#end
     .clock     (phy_clk_1x),
     .pre_clear (seq_rdp_reset_req_n && global_pre_clear),
     .reset_out (reset_rdp_phy_clk_1x_n)
);


// mem_clk reset generation :

//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (2) ) mem_pipe (
//#end
    .clock     (mem_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (mem_reset_n)
);

// ac_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (2) ) ac_clk_pipe_2x (
//#end
    .clock     (ac_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (reset_ac_clk_2x_n)
);

// measure_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (2) ) measure_clk_pipe (
//#end
    .clock     (measure_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (reset_measure_clk_2x_n)
);

// mem_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (4) ) mem_clk_pipe(
//#end
    .clock     (mem_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (reset_mem_clk_2x_n)
);



// resync_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (2) ) resync_clk_pipe(
//#end
    .clock     (resync_clk_2x),
    .pre_clear (seq_rdp_reset_req_n && global_pre_clear),
    .reset_out (reset_resync_clk_2x_n)
);

// write_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (4) ) write_clk_pipe(
//#end
    .clock     (write_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (reset_write_clk_2x_n)
);

// cs_clk_2x reset generation :
//#mw_prefix ("alt_mem_phy_reset_pipe")
alt_mem_phy_reset_pipe # (.PIPE_DEPTH (4) ) cs_n_clk_pipe_2x(
//#end
    .clock     (cs_n_clk_2x),
    .pre_clear (global_pre_clear),
    .reset_out (reset_cs_n_clk_2x_n)
);


endmodule
