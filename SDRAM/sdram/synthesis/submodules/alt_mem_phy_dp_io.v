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
  Title           : Datapath IO elements

  File:  $RCSfile : alt_mem_phy_dp_io.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : NewPhy Datapath IO atoms.  This block shall connect to both
                    the read and write datapath blocks, abstracting the I/O
                    elements from the remainder of the circuit.  This file
                    instances atoms specific to Cyclone III.
////////////////////////////////////////////////////////////////////////////-*/

`include "alt_mem_phy_defines.iv"

//#mw_insert_dq_group_assignments ()

//#mw_prefix ("alt_mem_phy_dp_io")
module alt_mem_phy_dp_io (
//#end
                                reset_resync_clk_2x_n,
                                resync_clk_2x,
                                mem_clk_2x,
                                write_clk_2x,
                                mem_dm,
                                mem_dq,
                                mem_dqs,
                                dio_rdata_h_2x,
                                dio_rdata_l_2x,
                                wdp_dm_h_2x,
                                wdp_dm_l_2x,
                                wdp_wdata_h_2x,
                                wdp_wdata_l_2x,
                                wdp_wdata_oe_2x,
                                wdp_wdqs_2x,
                                wdp_wdqs_oe_2x
                              );

parameter MEM_IF_CLK_PS             =           4000;
parameter MEM_IF_BANKADDR_WIDTH     =              3;
parameter MEM_IF_CS_WIDTH           =              2;
parameter MEM_IF_DWIDTH             =             64;
parameter MEM_IF_DM_PINS_EN         =              1;
parameter MEM_IF_DM_WIDTH           =              8;
parameter MEM_IF_DQ_PER_DQS         =              8;
parameter MEM_IF_DQS_CAPTURE_EN     =              0;
parameter MEM_IF_DQS_WIDTH          =              8;
parameter MEM_IF_ROWADDR_WIDTH      =             13;
parameter DLL_DELAY_BUFFER_MODE     =         "HIGH";
parameter DQS_OUT_MODE              = "DELAY_CHAIN2";
parameter DQS_PHASE                 =             72;


input  wire                                             reset_resync_clk_2x_n;
input  wire                                             resync_clk_2x;
input  wire                                             mem_clk_2x;
input  wire                                             write_clk_2x;
output wire [MEM_IF_DM_WIDTH - 1 : 0]                   mem_dm;
inout  wire [MEM_IF_DWIDTH - 1 : 0]                     mem_dq;
inout  wire [MEM_IF_DWIDTH / MEM_IF_DQ_PER_DQS - 1 : 0] mem_dqs;
(* preserve *) output reg [MEM_IF_DWIDTH - 1 : 0]       dio_rdata_h_2x;
(* preserve *) output reg [MEM_IF_DWIDTH - 1 : 0]       dio_rdata_l_2x;
input  wire [MEM_IF_DM_WIDTH -1 : 0]                    wdp_dm_h_2x;
input  wire [MEM_IF_DM_WIDTH -1 : 0]                    wdp_dm_l_2x;
input  wire [MEM_IF_DWIDTH - 1 : 0]                     wdp_wdata_h_2x;
input  wire [MEM_IF_DWIDTH - 1 : 0]                     wdp_wdata_l_2x;
input  wire [MEM_IF_DWIDTH - 1 : 0]                     wdp_wdata_oe_2x;
input  wire [(MEM_IF_DQS_WIDTH) - 1 : 0]                wdp_wdqs_2x;
input  wire [(MEM_IF_DQS_WIDTH) - 1 : 0]                wdp_wdqs_oe_2x;

(* altera_attribute=" -name FAST_OUTPUT_ENABLE_REGISTER ON" *) reg [MEM_IF_DWIDTH - 1 : 0] wdp_wdata_oe_2x_r;

wire [MEM_IF_DWIDTH - 1 : 0]                            rdata_n_captured;
wire [MEM_IF_DWIDTH - 1 : 0]                            rdata_p_captured;
                                                       
(* preserve *) wire [(MEM_IF_DQS_WIDTH) - 1 : 0]        wdp_wdqs_oe_2x_r;
 
(* preserve *) reg  [MEM_IF_DWIDTH - 1 : 0]             rdata_n_ams;
(* preserve *) reg  [MEM_IF_DWIDTH - 1 : 0]             rdata_p_ams;

// Use DQS clock to register DQ read data
wire [(MEM_IF_DQS_WIDTH) - 1 : 0]                       dqs_clk;
wire [(MEM_IF_DQS_WIDTH) - 1 : 0]                       dq_capture_clk;

wire                                                    reset_resync_clk_2x;


wire [MEM_IF_DWIDTH - 1 : 0]                            dq_ddio_dataout;
wire [MEM_IF_DWIDTH - 1 : 0]                            dq_datain;
wire [MEM_IF_DWIDTH - 1 : 0]                            dm_ddio_dataout;
wire [MEM_IF_DWIDTH / MEM_IF_DQ_PER_DQS - 1 : 0]        dqs_ddio_dataout;


genvar i,j;


// Create non-inverted reset for pads :
assign reset_resync_clk_2x = ~reset_resync_clk_2x_n;

// Read datapath functionality :


// synchronise to the resync_clk_2x_domain

always @(posedge resync_clk_2x)
begin

    // Resynchronise :
            
    // The comparison to 'X' is performed to prevent X's being captured in non-DQS mode
    // and propagating into the sequencer's control logic.  This can only occur when a Verilog SIMGEN
    // model of the sequencer is being used :
    if (|rdata_p_captured === 1'bX) 
        rdata_p_ams <= {MEM_IF_DWIDTH{1'b0}};  
    else
        rdata_p_ams <= rdata_p_captured; // 'captured' is from the IOEs
        
     if (|rdata_n_captured === 1'bX) 
        rdata_n_ams <= {MEM_IF_DWIDTH{1'b0}};  
    else
        rdata_n_ams <= rdata_n_captured; // 'captured' is from the IOEs
    
    // Output registers :
    dio_rdata_h_2x <= rdata_p_ams;
    dio_rdata_l_2x <= rdata_n_ams;

end


// Either use the DQS clock to capture, or the resync clock:

generate

    if (MEM_IF_DQS_CAPTURE_EN == 1)
        assign dq_capture_clk = ~dqs_clk;
    else
        assign dq_capture_clk = {MEM_IF_DQS_WIDTH{resync_clk_2x}};

endgenerate


// DQ pins and their logic

generate

// First generate each DQS group :
for (i=0; i<MEM_IF_DQS_WIDTH ; i=i+1)
begin : dqs_group

    // Then generate DQ pins for each group :
    for (j=0; j<MEM_IF_DQ_PER_DQS ; j=j+1)
    begin : dq
            
        // DDIO out :
        cycloneiii_ddio_out # (
            .power_up("low"),
            .async_mode("none"),
            .sync_mode("none"),
            .lpm_type("cycloneiii_ddio_out"),
            .use_new_clocking_model("true")            
        ) dq_ddio_out ( 
            .datainlo(wdp_wdata_l_2x[j+(i*MEM_IF_DQ_PER_DQS)]),
            .datainhi(wdp_wdata_h_2x[j+(i*MEM_IF_DQ_PER_DQS)]),
            .clkhi(write_clk_2x),
            .clklo(write_clk_2x),
            .clk(),
            .muxsel(write_clk_2x),
            .ena(1'b1),
            .areset(),
            .sreset(),
            .dataout(dq_ddio_dataout[j+(i*MEM_IF_DQ_PER_DQS)]),
            .dfflo(),
            .dffhi(),
            .devpor(),
            .devclrn()
        );
     
        // Need to register OE :
        always @(posedge write_clk_2x)
        begin        
            wdp_wdata_oe_2x_r[j+(i*MEM_IF_DQ_PER_DQS)] <= wdp_wdata_oe_2x[j+(i*MEM_IF_DQ_PER_DQS)]; 
        end       
        
        //The buffer itself (output side) :
        cycloneiii_io_obuf dq_obuf (
            .i(dq_ddio_dataout[j+(i*MEM_IF_DQ_PER_DQS)]),
            .oe(wdp_wdata_oe_2x_r[j+(i*MEM_IF_DQ_PER_DQS)]),  
            .seriesterminationcontrol(),
            .devoe(),
            .o(mem_dq[j+(i*MEM_IF_DQ_PER_DQS)]), //pad
            .obar()
        );
            
        //The buffer itself (input side) :
                
        //#pb_del Addition for SPR#245073, prevents problems with simulation : 
        cycloneiii_io_ibuf # (
            .simulate_z_as("gnd")
        ) dq_ibuf (
            .i(mem_dq[j+(i*MEM_IF_DQ_PER_DQS)]),//pad
            .ibar(),
            .o(dq_datain[j+(i*MEM_IF_DQ_PER_DQS)])
        );

        // Read data input DDIO path :
        altddio_in #( .intended_device_family ("Cyclone III"),
            .lpm_hint      ("UNUSED"),
            .lpm_type      ("altddio_in"),
            .power_up_high ("OFF"),
            .width         (1)
        ) dqi (            
            .aclr          (reset_resync_clk_2x),
            .aset          (),
            .sset          (),
            .sclr          (),
            .datain        (dq_datain[j+(i*MEM_IF_DQ_PER_DQS)]),
            .dataout_h     (rdata_n_captured[j+(i*MEM_IF_DQ_PER_DQS)]),
            .dataout_l     (rdata_p_captured[j+(i*MEM_IF_DQ_PER_DQS)]),
            .inclock       (dq_capture_clk[i]),
            .inclocken     (1'b1)
        );
        
    end

end

endgenerate



//////////////////////////////////////////////////////////////////////////////-
// DM Pin and its logic
//////////////////////////////////////////////////////////////////////////////-


generate

if (MEM_IF_DM_PINS_EN)
begin

    for (i=0; i<MEM_IF_DM_WIDTH; i=i+1)
    begin : dm
      
    	cycloneiii_ddio_out # (
    	    .power_up("low"),
    	    .async_mode("none"),
    	    .sync_mode("none"),
    	    .lpm_type("cycloneiii_ddio_out"),
    	    .use_new_clocking_model("true")	     
    	) dm_ddio_out ( 
    	    .datainlo(wdp_dm_l_2x[i]),
    	    .datainhi(wdp_dm_h_2x[i]),
    	    .clkhi(write_clk_2x),
    	    .clklo(write_clk_2x),
    	    .clk(),
    	    .muxsel(write_clk_2x),
    	    .ena(1'b1),
    	    .areset(),
    	    .sreset(),
    	    .dataout(dm_ddio_dataout[i]),
    	    .dfflo(),
    	    .dffhi(),
    	    .devpor(),
    	    .devclrn()
    	);
    		
    	cycloneiii_io_obuf dm_obuf (
    	    .i(dm_ddio_dataout[i]),
    	    .oe(1'b1),  
    	    .seriesterminationcontrol(),
    	    .devoe(),
    	    .o(mem_dm[i]), //pad
    	    .obar()
    	);
    	     
    end

end

endgenerate



// Note that for CIII DQS-capture mode is unsupported, and so DQS is only used
// as an output :
generate

for (i=0; i<(MEM_IF_DQS_WIDTH); i=i+1)
begin : dqs

    cycloneiii_ddio_out # (
         .power_up("low"),
         .async_mode("none"),
         .sync_mode("none"),
         .lpm_type("cycloneiii_ddio_out"),
         .use_new_clocking_model("true")            
     ) dqs_ddio_out ( 
         .datainlo(1'b0),
         .datainhi(wdp_wdqs_2x[i]),
         .clkhi(mem_clk_2x),
         .clklo(mem_clk_2x),
         .clk(),
         .muxsel(mem_clk_2x),
         .ena(1'b1),
         .areset(),
         .sreset(),
         .dataout(dqs_ddio_dataout[i]),
         .dfflo(),
         .dffhi(),
         .devpor(),
         .devclrn()
     );
              
    // NB. Invert the OE input, as Quartus requires us to invert
    // the OE input on the OBUF :
    cycloneiii_ddio_oe # (
         .power_up("low"),
         .async_mode("none"),
         .sync_mode("none"),
         .lpm_type("cycloneiii_ddio_oe")
     ) dqsoe_ddio_oe ( 
         .oe(~wdp_wdqs_oe_2x[i]),
         .clk(mem_clk_2x),
         .ena(1'b1),
         .areset(),
         .sreset(),
         .dataout(wdp_wdqs_oe_2x_r[i]),
         .dfflo(),
         .dffhi(),
         .devpor(),
         .devclrn()
     );    
          
     // Output buffer itself :
     // OE input is active HIGH
     cycloneiii_io_obuf dqs_obuf (
         .i(dqs_ddio_dataout[i]),
         .oe(~wdp_wdqs_oe_2x_r[i]),  
         .seriesterminationcontrol(),
         .devoe(),
         .o(mem_dqs[i]), 
         .obar()
     );         

end

endgenerate


endmodule
