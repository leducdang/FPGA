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

  File:  $RCSfile : alt_mem_phy_rdata_valid.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : NewPhy rdata valid signal generation.  This block generates the
                    rdata_valid signal for the sequencer and control blocks from 
                    their respective doing read signals, seq_doing_rd and 
                    ctl_doing_rd respectively.
-----------------------------------------------------------------------------*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

`default_nettype none

//#mw_prefix ("alt_mem_phy_rdata_valid")
module alt_mem_phy_rdata_valid ( // inputs
//#end
                               phy_clk_1x,
                               reset_phy_clk_1x_n,
                               seq_rdata_valid_lat_dec,
                               seq_rdata_valid_lat_inc,
                               seq_doing_rd,
                               ctl_doing_rd,
                               ctl_cal_success,
                               
                               // outputs
                               ctl_rdata_valid,
                               seq_rdata_valid
                              );

parameter FAMILY                       = "CYCLONEIII";
parameter MEM_IF_DQS_WIDTH             = 8;                              
parameter RDATA_VALID_AWIDTH           = 5;
parameter RDATA_VALID_INITIAL_LAT      = 16;
parameter DWIDTH_RATIO                 = 2;

localparam MAX_RDATA_VALID_DELAY       = 2 ** RDATA_VALID_AWIDTH;
localparam RDV_DELAY_SHR_LEN           = MAX_RDATA_VALID_DELAY*(DWIDTH_RATIO/2);

// clocks
input  wire                                              phy_clk_1x;

// resets
input  wire                                              reset_phy_clk_1x_n;

// control signals from sequencer
input  wire                                              seq_rdata_valid_lat_dec;
input  wire                                              seq_rdata_valid_lat_inc;
input  wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO / 2 -1 : 0] seq_doing_rd;
input  wire [MEM_IF_DQS_WIDTH * DWIDTH_RATIO / 2 -1 : 0] ctl_doing_rd;
input  wire                                              ctl_cal_success;

// output to IOE
output reg [DWIDTH_RATIO / 2 -1 : 0]                     ctl_rdata_valid;
output reg [DWIDTH_RATIO / 2 -1 : 0]                     seq_rdata_valid;

// Internal Signals / Variables
reg  [RDATA_VALID_AWIDTH - 1 : 0]                         rd_addr;
reg  [RDATA_VALID_AWIDTH - 1 : 0]                         wr_addr;
reg  [RDATA_VALID_AWIDTH - 1 : 0]                         next_wr_addr;
reg  [DWIDTH_RATIO/2 - 1 : 0]                             wr_data;

wire [DWIDTH_RATIO / 2 -1 : 0]                            int_rdata_valid;
reg  [DWIDTH_RATIO/2 - 1 : 0]                             rdv_pipe_ip;
reg                                                       rdv_pipe_ip_beat2_r;
reg  [MEM_IF_DQS_WIDTH * DWIDTH_RATIO/2 - 1 : 0]          merged_doing_rd;
reg                                                       seq_rdata_valid_lat_dec_1t;
reg                                                       seq_rdata_valid_lat_inc_1t;
reg                                                       bit_order_1x;

// Generate the input to the RDV delay.
// Also determine the data for the OCT control & postamble paths (merged_doing_rd)
generate
    if (DWIDTH_RATIO == 4)
    begin : merging_doing_rd_halfrate
        always @*
        begin
            merged_doing_rd = seq_doing_rd | (ctl_doing_rd & {(2 * MEM_IF_DQS_WIDTH) {ctl_cal_success}});
            rdv_pipe_ip[0]  = | merged_doing_rd[    MEM_IF_DQS_WIDTH - 1 : 0];
            rdv_pipe_ip[1]  = | merged_doing_rd[2 * MEM_IF_DQS_WIDTH - 1 : MEM_IF_DQS_WIDTH];
        end
    end
    else  // DWIDTH_RATIO == 2
    begin : merging_doing_rd_fullrate
        always @*
        begin
            merged_doing_rd = seq_doing_rd | (ctl_doing_rd & { MEM_IF_DQS_WIDTH {ctl_cal_success}});
            rdv_pipe_ip[0]  = | merged_doing_rd[MEM_IF_DQS_WIDTH - 1 : 0];
        end
    end // else: !if(DWIDTH_RATIO == 4)
endgenerate


// Register inc/dec rdata_valid signals and generate bit_order_1x
always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin
    if (reset_phy_clk_1x_n == 1'b0)
        begin
            seq_rdata_valid_lat_dec_1t <= 1'b0;
            seq_rdata_valid_lat_inc_1t <= 1'b0;
            bit_order_1x               <= 1'b1;
            
        end
    else
        begin
            rdv_pipe_ip_beat2_r <= rdv_pipe_ip[DWIDTH_RATIO/2 - 1];
            seq_rdata_valid_lat_dec_1t <= seq_rdata_valid_lat_dec;
            seq_rdata_valid_lat_inc_1t <= seq_rdata_valid_lat_inc;
            
            if (DWIDTH_RATIO == 2)
                bit_order_1x <= 1'b0;
            else if (seq_rdata_valid_lat_dec == 1'b1 && seq_rdata_valid_lat_dec_1t == 1'b0)
            begin
                bit_order_1x <=  ~bit_order_1x;
            end
            
            else if (seq_rdata_valid_lat_inc == 1'b1 && seq_rdata_valid_lat_inc_1t == 1'b0)
            begin
                bit_order_1x <= ~bit_order_1x;
            end
        end
end

// write data
generate // based on DWIDTH RATIO
  if (DWIDTH_RATIO == 4) // Half Rate
  begin : halfrate_wdata_gen
      always @* // combinational logic sensitivity
      begin

        if (bit_order_1x == 1'b0)
        begin
            wr_data  = {rdv_pipe_ip[1], rdv_pipe_ip[0]};
        end

        else
        begin
            wr_data  = {rdv_pipe_ip[0], rdv_pipe_ip_beat2_r};
        end
      end
  end
else // Full-rate
 begin : fullrate_wdata_gen

  always @* // combinational logic sensitivity
    begin
        wr_data = rdv_pipe_ip;
    end
  end
endgenerate

// write address
always @*
begin

    next_wr_addr = wr_addr + 1'b1;

    if (seq_rdata_valid_lat_dec == 1'b1 && seq_rdata_valid_lat_dec_1t == 1'b0)
    begin

        if ((bit_order_1x == 1'b0) || (DWIDTH_RATIO == 2))
        begin
            next_wr_addr = wr_addr;
        end

    end

    else if (seq_rdata_valid_lat_inc == 1'b1 && seq_rdata_valid_lat_inc_1t == 1'b0)
    begin

        if ((bit_order_1x == 1'b1) || (DWIDTH_RATIO ==2))
        begin
            next_wr_addr = wr_addr + 2'h2;
        end

    end

end


always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

    if (reset_phy_clk_1x_n == 1'b0)
    begin
        wr_addr <= RDATA_VALID_INITIAL_LAT[RDATA_VALID_AWIDTH - 1 : 0];
    end

    else
    begin
        wr_addr <= next_wr_addr;
    end

end

//     read address generator : just a free running counter.
always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

    if (reset_phy_clk_1x_n == 1'b0)
    begin
        rd_addr <= {RDATA_VALID_AWIDTH{1'b0}};
    end

    else
    begin
        rd_addr <= rd_addr + 1'b1;     //inc address, can wrap
    end

end

// altsyncram instance
altsyncram #(.
    address_aclr_b            ("NONE"),
	.address_reg_b            ("CLOCK0"),
	.clock_enable_input_a     ("BYPASS"),
	.clock_enable_input_b     ("BYPASS"),
	.clock_enable_output_b    ("BYPASS"),
	.intended_device_family   (FAMILY),
	.lpm_type                 ("altsyncram"),
	.numwords_a               (2**RDATA_VALID_AWIDTH),
	.numwords_b               (2**RDATA_VALID_AWIDTH),
	.operation_mode           ("DUAL_PORT"),
	.outdata_aclr_b           ("NONE"),
	.outdata_reg_b            ("CLOCK0"),
	.power_up_uninitialized   ("FALSE"),
	.widthad_a                (RDATA_VALID_AWIDTH),
	.widthad_b                (RDATA_VALID_AWIDTH),
	.width_a                  (DWIDTH_RATIO/2),
	.width_b                  (DWIDTH_RATIO/2),
	.width_byteena_a          (1)
) altsyncram_component (
	.wren_a                   (1'b1),
	.clock0                   (phy_clk_1x),
	.address_a                (wr_addr),
	.address_b                (rd_addr),
	.data_a                   (wr_data),
	.q_b                      (int_rdata_valid),
	.aclr0                    (1'b0),
	.aclr1                    (1'b0),
	.addressstall_a           (1'b0),
	.addressstall_b           (1'b0),
	.byteena_a                (1'b1),
	.byteena_b                (1'b1),
	.clock1                   (1'b1),
	.clocken0                 (1'b1),
	.clocken1                 (1'b1),
	.clocken2                 (1'b1),
	.clocken3                 (1'b1),
	.data_b                   ({(DWIDTH_RATIO/2){1'b1}}),
	.eccstatus                (),
	.q_a                      (),
	.rden_a                   (1'b1),
	.rden_b                   (1'b1),
	.wren_b                   (1'b0)
);

// Generate read data valid enable signals for controller and seqencer
always @(posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin
    if (reset_phy_clk_1x_n == 1'b0)
        begin
            ctl_rdata_valid <= {(DWIDTH_RATIO/2){1'b0}};
            seq_rdata_valid <= {(DWIDTH_RATIO/2){1'b0}};
        end
    else
        begin
            // shift the shift register by DWIDTH_RATIO locations
            // rdv_delay_index plus (DWIDTH_RATIO/2)-1 bits counting down
            ctl_rdata_valid <= int_rdata_valid & {(DWIDTH_RATIO/2){ctl_cal_success}};
            seq_rdata_valid <= int_rdata_valid;
        end
end
 

endmodule

`default_nettype wire
