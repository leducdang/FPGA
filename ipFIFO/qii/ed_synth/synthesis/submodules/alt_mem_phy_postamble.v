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
  Title           : Postamble

  File:  $RCSfile : alt_mem_phy_postamble.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : NewPhy Postamble.  This block generates the postamble enable
                    outputs which go to the DQS pins in alt_mem_phy_dp_io_sii.
                    The control for these comes from the sequencer, and this block
                    wnsures that the correct numbers of postamble preset signals
                    are generated and factors in any required bit-ordering or
                    extra 'Half T' delay.
-----------------------------------------------------------------------------*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif


//#mw_prefix ("alt_mem_phy_postamble")
module alt_mem_phy_postamble ( // inputs
//#end
                               phy_clk_1x,
                               postamble_clk_2x,
                               reset_phy_clk_1x_n,
                               reset_poa_clk_2x_n,
                               seq_poa_lat_inc_1x,
                               seq_poa_lat_dec_1x,
                               seq_poa_protection_override_1x,

                               // for 2T / 2N addr/CMD drive both of these with the same value.
                               ctl_doing_rd_beat1_1x,
                               ctl_doing_rd_beat2_1x ,

                               // outputs
                               poa_postamble_en_preset_2x
                              ) /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL = \"R105\"" */ ;

parameter FAMILY                       = "Stratix II";
parameter POSTAMBLE_INITIAL_LAT        = 16;
parameter POSTAMBLE_RESYNC_LAT_CTL_EN  = 0;  // 0 means false, 1 means true
parameter POSTAMBLE_AWIDTH             = 6;
parameter POSTAMBLE_HALFT_EN           = 0;  // 0 means false, 1 means true
parameter MEM_IF_POSTAMBLE_EN_WIDTH    = 8;
parameter DWIDTH_RATIO                 = 4;

// clocks
input  wire phy_clk_1x;
input  wire postamble_clk_2x;

// resets
input  wire reset_phy_clk_1x_n;
input  wire reset_poa_clk_2x_n;

// control signals from sequencer
input  wire seq_poa_lat_inc_1x;
input  wire seq_poa_lat_dec_1x;
input  wire seq_poa_protection_override_1x;
input  wire ctl_doing_rd_beat1_1x;
input  wire ctl_doing_rd_beat2_1x ;

// output to IOE
output wire [MEM_IF_POSTAMBLE_EN_WIDTH - 1 : 0]    poa_postamble_en_preset_2x;

// internal wires/regs
reg  [POSTAMBLE_AWIDTH - 1 : 0]                    rd_addr_2x;
reg  [POSTAMBLE_AWIDTH - 1 : 0]                    wr_addr_1x;
reg  [POSTAMBLE_AWIDTH - 1 : 0]                    next_wr_addr_1x;
reg  [1:0]                                         wr_data_1x;
wire                                               wr_en_1x;
                                                   
reg                                                sync_seq_poa_lat_inc_1x;
reg                                                sync_seq_poa_lat_dec_1x;
                                                   
reg                                                seq_poa_lat_inc_1x_1t;
reg                                                seq_poa_lat_dec_1x_1t;
reg                                                ctl_doing_rd_beat2_1x_r1;
                                                   
wire                                               postamble_en_2x;

// #pb_del No preserve is used for postamble_en_pos_2x, as it may be optimised
// #pb_del away in full-rate mode :
reg [MEM_IF_POSTAMBLE_EN_WIDTH-1 : 0]              postamble_en_pos_2x;
reg [MEM_IF_POSTAMBLE_EN_WIDTH-1 : 0]              delayed_postamble_en_pos_2x;
reg [MEM_IF_POSTAMBLE_EN_WIDTH-1 : 0]              postamble_en_pos_2x_vdc;


(*preserve*) reg [MEM_IF_POSTAMBLE_EN_WIDTH-1 : 0] postamble_en_2x_r;

reg                                                bit_order_1x;
reg                                                ams_inc;
reg                                                ams_dec;


// loop variables
genvar i;



////////////////////////////////////////////////////////////////////////////////
//       Generate Statements to synchronise controls if necessary
////////////////////////////////////////////////////////////////////////////////


generate
if (POSTAMBLE_RESYNC_LAT_CTL_EN == 0)
begin : sync_lat_controls
    always @* // combinational logic sensitivity
    begin

        sync_seq_poa_lat_inc_1x = seq_poa_lat_inc_1x;
        sync_seq_poa_lat_dec_1x = seq_poa_lat_dec_1x;

    end

end
endgenerate


generate
if (POSTAMBLE_RESYNC_LAT_CTL_EN == 1)
begin : resynch_lat_controls

    always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
    begin
        if (reset_phy_clk_1x_n == 1'b0)
        begin
            sync_seq_poa_lat_inc_1x <= 1'b0;
            sync_seq_poa_lat_dec_1x <= 1'b0;
            ams_inc                 <= 1'b0;
            ams_dec                 <= 1'b0;
        end

        else
        begin
            sync_seq_poa_lat_inc_1x <= ams_inc;
            sync_seq_poa_lat_dec_1x <= ams_dec;
            ams_inc                 <= seq_poa_lat_inc_1x;
            ams_dec                 <= seq_poa_lat_dec_1x;
        end

    end

end
endgenerate


////////////////////////////////////////////////////////////////////////////////
//          write address controller
////////////////////////////////////////////////////////////////////////////////

// seq_poa_protection_override_1x is used to overide the write data
// Otherwise use bit_order_1x to choose how word is written into RAM.

always @*  
begin

    if (seq_poa_protection_override_1x == 1'b1)
    begin
        wr_data_1x  = `POA_OVERRIDE_VAL;
    end

    else if (bit_order_1x == 1'b0)
    begin
        wr_data_1x  = {ctl_doing_rd_beat2_1x, ctl_doing_rd_beat1_1x};
    end

    else
    begin
        wr_data_1x  = {ctl_doing_rd_beat1_1x, ctl_doing_rd_beat2_1x_r1};
    end

end


always @*
begin

    next_wr_addr_1x = wr_addr_1x + 1'b1;

    if (sync_seq_poa_lat_dec_1x == 1'b1 && seq_poa_lat_dec_1x_1t == 1'b0)
    begin

        if ((bit_order_1x == 1'b0) || (DWIDTH_RATIO == 2))
        begin
            next_wr_addr_1x = wr_addr_1x;
        end

    end

    else if (sync_seq_poa_lat_inc_1x == 1'b1 && seq_poa_lat_inc_1x_1t == 1'b0)
    begin

        if ((bit_order_1x == 1'b1) || (DWIDTH_RATIO ==2))
        begin
            next_wr_addr_1x = wr_addr_1x + 2'b10;
        end

    end

end

always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

    if (reset_phy_clk_1x_n == 1'b0)
    begin
        wr_addr_1x <= POSTAMBLE_INITIAL_LAT[POSTAMBLE_AWIDTH - 1 : 0];
    end

    else
    begin
        wr_addr_1x <= next_wr_addr_1x;
    end

end



always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

    if (reset_phy_clk_1x_n == 1'b0)
    begin
        ctl_doing_rd_beat2_1x_r1 <= 1'b0;
        seq_poa_lat_inc_1x_1t    <= 1'b0;
        seq_poa_lat_dec_1x_1t    <= 1'b0;
        bit_order_1x             <= 1'b0;
    end

    else
    begin
        ctl_doing_rd_beat2_1x_r1 <= ctl_doing_rd_beat2_1x;
        seq_poa_lat_inc_1x_1t    <= sync_seq_poa_lat_inc_1x;
        seq_poa_lat_dec_1x_1t    <= sync_seq_poa_lat_dec_1x;

        if (DWIDTH_RATIO == 2)
            bit_order_1x <= 1'b0;		 
        else if (sync_seq_poa_lat_dec_1x == 1'b1 && seq_poa_lat_dec_1x_1t == 1'b0)
        begin
            bit_order_1x <=  ~bit_order_1x;
        end

        else if (sync_seq_poa_lat_inc_1x == 1'b1 && seq_poa_lat_inc_1x_1t == 1'b0)
        begin
            bit_order_1x <= ~bit_order_1x;
        end

    end

end


///////////////////////////////////////////////////////////////////////////////////
//         Instantiate the postamble dpram
///////////////////////////////////////////////////////////////////////////////////

assign wr_en_1x = 1'b1;  


generate

    // Half-rate mode :
    if (DWIDTH_RATIO == 4) 
    begin : half_rate_ram_gen
    
        altsyncram #(
            .address_reg_b             ("CLOCK1"),
            .clock_enable_input_a      ("BYPASS"),
            .clock_enable_input_b      ("BYPASS"),
            .clock_enable_output_b     ("BYPASS"),
            .intended_device_family    (FAMILY),
            .lpm_type                  ("altsyncram"),
            .numwords_a                ((2**POSTAMBLE_AWIDTH )/2),
            .numwords_b                ((2**POSTAMBLE_AWIDTH )),
            .operation_mode            ("DUAL_PORT"),
            .outdata_aclr_b            ("NONE"),
            .outdata_reg_b             ("CLOCK1"),
            .power_up_uninitialized    ("FALSE"),
            .widthad_a                 (POSTAMBLE_AWIDTH - 1),
            .widthad_b                 (POSTAMBLE_AWIDTH),
            .width_a                   (2),
            .width_b                   (1),
            .width_byteena_a           (1)
        ) altsyncram_inst (
            .wren_a            (wr_en_1x),
            .clock0            (phy_clk_1x),
            .clock1            (postamble_clk_2x),
            .address_a         (wr_addr_1x[POSTAMBLE_AWIDTH - 2 : 0]),
            .address_b         (rd_addr_2x),
            .data_a            (wr_data_1x),
            .q_b               (postamble_en_2x),
            .aclr0             (1'b0),
            .aclr1             (1'b0),
            .addressstall_a    (1'b0),
            .addressstall_b    (1'b0),
            .byteena_a         (1'b1),
            .byteena_b         (1'b1),
            .clocken0          (1'b1),
            .clocken1          (1'b1),
            .clocken2          (),
            .clocken3          (),
            .data_b            (1'b1),
            .q_a               (),
            .rden_a            (),
            .rden_b            (1'b1),
            .wren_b            (1'b0),
            .eccstatus         ()
        );
   
    end
    
    // Full-rate mode :
    else
    begin : full_rate_ram_gen
   
        altsyncram #(
            .address_reg_b             ("CLOCK1"),
            .clock_enable_input_a      ("BYPASS"),
            .clock_enable_input_b      ("BYPASS"),
            .clock_enable_output_b     ("BYPASS"),
            .intended_device_family    (FAMILY),
            .lpm_type                  ("altsyncram"),
            .numwords_a                (2**POSTAMBLE_AWIDTH ),
            .numwords_b                (2**POSTAMBLE_AWIDTH ),
            .operation_mode            ("DUAL_PORT"),
            .outdata_aclr_b            ("NONE"),
            .outdata_reg_b             ("UNREGISTERED"),
            .power_up_uninitialized    ("FALSE"),
            .widthad_a                 (POSTAMBLE_AWIDTH),
            .widthad_b                 (POSTAMBLE_AWIDTH),
            .width_a                   (1),
            .width_b                   (1),
            .width_byteena_a           (1)
        ) altsyncram_inst (
            .wren_a            (wr_en_1x),
            .clock0            (phy_clk_1x),
            .clock1            (postamble_clk_2x),
            .address_a         (wr_addr_1x),
            .address_b         (rd_addr_2x),
            .data_a            (wr_data_1x[0]),
            .q_b               (postamble_en_2x),
            .aclr0             (1'b0),
            .aclr1             (1'b0),
            .addressstall_a    (1'b0),
            .addressstall_b    (1'b0),
            .byteena_a         (1'b1),
            .byteena_b         (1'b1),
            .clocken0          (1'b1),
            .clocken1          (1'b1),
            .clocken2          (),
            .clocken3          (),
            .data_b            (1'b1),
            .q_a               (),
            .rden_b            (1'b1),
            .rden_a            (),
            .wren_b            (1'b0),
            .eccstatus         ()            
        );    
           
    end
    
endgenerate

///////////////////////////////////////////////////////////////////////////////////
//     read address generator : just a free running counter.
///////////////////////////////////////////////////////////////////////////////////

always @(posedge postamble_clk_2x or negedge reset_poa_clk_2x_n)
begin

    if (reset_poa_clk_2x_n == 1'b0)
    begin
        rd_addr_2x <= {POSTAMBLE_AWIDTH{1'b0}};
    end

    else
    begin
        rd_addr_2x <= rd_addr_2x + 1'b1;     //inc address, can wrap
    end

end


///////////////////////////////////////////////////////////////////////////////////
// generate the poa_postamble_en_preset_2x signal, 2 generate statements dependent
// on generics - both contained within another generate to produce output of
// appropriate width
///////////////////////////////////////////////////////////////////////////////////


generate
for (i=0; i<MEM_IF_POSTAMBLE_EN_WIDTH; i=i+1)
begin : postamble_output_gen

    always @(posedge postamble_clk_2x or negedge reset_poa_clk_2x_n)
    begin :pipeline_ram_op

        if (reset_poa_clk_2x_n == 1'b0)
        begin
            postamble_en_2x_r[i] <= 1'b0;
        end

        else
        begin
            postamble_en_2x_r[i] <= postamble_en_2x;
        end

    end

    always @(posedge postamble_clk_2x or negedge reset_poa_clk_2x_n)
    begin

        if (reset_poa_clk_2x_n == 1'b0)
        begin
            postamble_en_pos_2x[i] <=  1'b0;
        end

        else
        begin
            postamble_en_pos_2x[i] <= postamble_en_2x_r[i];
        end

    end

//#pb_del SPR249037 fix :    
    
`ifdef QUARTUS__SIMGEN
`else
//synopsys translate_off
`endif    

    // Introduce 180degrees to model postamble insertion delay :
    always @(negedge postamble_clk_2x or negedge reset_poa_clk_2x_n)
    begin

        if (reset_poa_clk_2x_n == 1'b0)
        begin
            postamble_en_pos_2x_vdc[i] <=  1'b0;
        end

        else
        begin
            postamble_en_pos_2x_vdc[i] <= postamble_en_pos_2x[i];
        end

    end

`ifdef QUARTUS__SIMGEN
`else
//synopsys translate_on
`endif


    always @*
    begin
    
        delayed_postamble_en_pos_2x[i] = postamble_en_pos_2x[i];
        
`ifdef QUARTUS__SIMGEN
`else
    //synopsys translate_off
`endif

        delayed_postamble_en_pos_2x[i] = postamble_en_pos_2x_vdc[i];

`ifdef QUARTUS__SIMGEN
`else
    //synopsys translate_on
`endif

    end    
    
    case (POSTAMBLE_HALFT_EN)
        1: begin : half_t_output

            (* preserve *) reg [MEM_IF_POSTAMBLE_EN_WIDTH - 1 : 0] postamble_en_neg_2x;

            always @(negedge postamble_clk_2x or negedge reset_poa_clk_2x_n)
            begin

                if (reset_poa_clk_2x_n == 1'b0)
                begin
                    postamble_en_neg_2x[i] <=  1'b0;
                end

                else
                begin
                    postamble_en_neg_2x[i] <= postamble_en_pos_2x[i];
                end

            end

            assign poa_postamble_en_preset_2x[i] = postamble_en_pos_2x[i] && postamble_en_neg_2x[i];

        end

        0: begin : one_t_output

              assign poa_postamble_en_preset_2x[i] = delayed_postamble_en_pos_2x[i];
 
        end
    endcase

end
endgenerate



endmodule
