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

  File:  $RCSfile : alt_mem_phy_read_dp_group.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : Read datapath.  This block is designed to interface to a
                    family specific I/O block, such as alt_mem_phy_dp_io_siii.
                    It then handles any required rate conversion and pipelining.
                    It is instanced once per DQ group.
////////////////////////////////////////////////////////////////////////////-*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_read_dp_group")
module alt_mem_phy_read_dp_group ( phy_clk_1x,
//#end
                                  resync_clk_1x,
                                  reset_phy_clk_1x_n,
                                  reset_resync_clk_1x_n,
                                  seq_rdp_dec_read_lat_1x,
                                  seq_rdp_inc_read_lat_1x,
                                  dio_rdata3_1x,
                                  dio_rdata2_1x,
                                  dio_rdata1_1x,
                                  dio_rdata0_1x,
                                  ctl_mem_rdata
                                 );

parameter ADDR_COUNT_WIDTH         =               4;
parameter BIDIR_DPINS              =               1; // 0 for QDR only.
parameter DWIDTH_RATIO             =               4;
parameter MEM_IF_CLK_PS            =            4000;
parameter FAMILY                   =     "STRATIXII";
parameter MEM_IF_DQ_PER_DQS        =               8;
parameter RDP_INITIAL_LAT          =               6;
parameter RDP_RESYNC_LAT_CTL_EN    =               0;
parameter RESYNC_PIPELINE_DEPTH    =               1; // No pipelining in the FD spec.

input  wire                                                 phy_clk_1x;
input  wire                                                 resync_clk_1x;
input  wire                                                 reset_phy_clk_1x_n;
input  wire                                                 reset_resync_clk_1x_n;
input  wire                                                 seq_rdp_dec_read_lat_1x;
input  wire                                                 seq_rdp_inc_read_lat_1x;
input  wire [MEM_IF_DQ_PER_DQS-1 : 0]                       dio_rdata0_1x;
input  wire [MEM_IF_DQ_PER_DQS-1 : 0]                       dio_rdata1_1x;
input  wire [MEM_IF_DQ_PER_DQS-1 : 0]                       dio_rdata2_1x;
input  wire [MEM_IF_DQ_PER_DQS-1 : 0]                       dio_rdata3_1x;
output wire [DWIDTH_RATIO*MEM_IF_DQ_PER_DQS-1 : 0]          ctl_mem_rdata;


// concatonated read data :
wire [(DWIDTH_RATIO*MEM_IF_DQ_PER_DQS)-1 : 0]               dio_rdata;
reg  [ADDR_COUNT_WIDTH - 1 : 0]                             rd_ram_rd_addr;
reg  [ADDR_COUNT_WIDTH - 1 : 0]                             rd_ram_wr_addr;

reg                                                         inc_read_lat_sync_r;
reg                                                         dec_read_lat_sync_r;

// Optional AMS registers :
reg                                                         inc_read_lat_ams ;
reg                                                         inc_read_lat_sync;

reg                                                         dec_read_lat_ams ;
reg                                                         dec_read_lat_sync;

wire                                                        rd_addr_stall;
wire                                                        rd_addr_double_inc;

////////////////////////////////////////////////////////////////////////////////
//                          Write Address block
////////////////////////////////////////////////////////////////////////////////


always@ (posedge resync_clk_1x or negedge reset_resync_clk_1x_n)
begin

   if (reset_resync_clk_1x_n == 0)
   begin
       rd_ram_wr_addr  <= RDP_INITIAL_LAT[ADDR_COUNT_WIDTH - 1 : 0];
   end

   else
   begin
       rd_ram_wr_addr <= rd_ram_wr_addr + 1'b1;
   end

end



////////////////////////////////////////////////////////////////////////////////
//                          Pipeline registers
////////////////////////////////////////////////////////////////////////////////


// Concatenate the input read data :
generate
if (DWIDTH_RATIO ==4)
begin
assign dio_rdata = {dio_rdata3_1x, dio_rdata2_1x, dio_rdata1_1x, dio_rdata0_1x};
end
else
begin
    assign dio_rdata = {dio_rdata1_1x, dio_rdata0_1x};
end
endgenerate





////////////////////////////////////////////////////////////////////////////////
//         Instantiate the read_dp dpram
////////////////////////////////////////////////////////////////////////////////


    altsyncram #(
                 .address_reg_b             ("CLOCK1"),
                 .clock_enable_input_a      ("BYPASS"),
                 .clock_enable_input_b      ("BYPASS"),
                 .clock_enable_output_b     ("BYPASS"),
                 .intended_device_family    (FAMILY),
                 .lpm_type                  ("altsyncram"),
                 .numwords_a                (2**ADDR_COUNT_WIDTH),
                 .numwords_b                (2**ADDR_COUNT_WIDTH),
                 .operation_mode            ("DUAL_PORT"),
                 .outdata_aclr_b            ("NONE"),
                 .outdata_reg_b             ("CLOCK1"),
                 .power_up_uninitialized    ("FALSE"),
                 .ram_block_type            ("MLAB"),
                 .widthad_a                 (ADDR_COUNT_WIDTH),
                 .widthad_b                 (ADDR_COUNT_WIDTH),
                 .width_a                   (DWIDTH_RATIO*MEM_IF_DQ_PER_DQS),
                 .width_b                   (DWIDTH_RATIO*MEM_IF_DQ_PER_DQS),
                 .width_byteena_a           (1)
                )
    ram (
         .wren_a            (1'b1),
         .clock0            (resync_clk_1x),
         .clock1            (phy_clk_1x),
         .address_a         (rd_ram_wr_addr),
         .address_b         (rd_ram_rd_addr),
         .data_a            (dio_rdata),
         .q_b               (ctl_mem_rdata),
         .aclr0             (1'b0),
         .aclr1             (1'b0),
         .addressstall_a    (1'b0),
         .addressstall_b    (1'b0),
         .byteena_a         (1'b1),
         .byteena_b         (1'b1),
         .clocken0          (1'b1),
         .clocken1          (1'b1),
         .data_b            ({(DWIDTH_RATIO*MEM_IF_DQ_PER_DQS){1'b1}}),
         .q_a               (),
         .rden_b            (1'b1),
         .wren_b            (1'b0),
         .eccstatus         (),
         .clocken3          (),
         .clocken2          (),
         .rden_a            ()
    );





////////////////////////////////////////////////////////////////////////////////
//                          Read Address block
////////////////////////////////////////////////////////////////////////////////


// Optional Anti-metastability flops :
generate

    if (RDP_RESYNC_LAT_CTL_EN == 1)

    always@ (posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
    begin : rd_addr_ams

        if (reset_phy_clk_1x_n == 1'b0)
        begin

            inc_read_lat_ams    <= 1'b0;
            inc_read_lat_sync   <= 1'b0;
            inc_read_lat_sync_r <= 1'b0;

            // Synchronise rd_lat_inc_1x :
            dec_read_lat_ams    <= 1'b0;
            dec_read_lat_sync   <= 1'b0;
            dec_read_lat_sync_r <= 1'b0;

        end

        else
        begin

            // Synchronise rd_lat_inc_1x :
            inc_read_lat_ams    <= seq_rdp_inc_read_lat_1x;
            inc_read_lat_sync   <= inc_read_lat_ams;
            inc_read_lat_sync_r <= inc_read_lat_sync;

            // Synchronise rd_lat_inc_1x :
            dec_read_lat_ams    <= seq_rdp_dec_read_lat_1x;
            dec_read_lat_sync   <= dec_read_lat_ams;
            dec_read_lat_sync_r <= dec_read_lat_sync;

        end

    end // always

    // No anti-metastability protection required :
    else

    always@ (posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
    begin

        if (reset_phy_clk_1x_n == 1'b0)
        begin
            inc_read_lat_sync_r    <= 1'b0;
            dec_read_lat_sync_r   <= 1'b0;
        end

        else
        begin
            // No need to re-synchronise, just register for edge detect :
            inc_read_lat_sync_r <= seq_rdp_inc_read_lat_1x;
            dec_read_lat_sync_r <= seq_rdp_dec_read_lat_1x;
        end

    end

endgenerate




generate

    if (RDP_RESYNC_LAT_CTL_EN == 1)
    begin : lat_ctl_en_gen

        // 'toggle detect' logic :
        //assign rd_addr_double_inc =    !inc_read_lat_sync_r && inc_read_lat_sync;
        assign rd_addr_double_inc =    ( !dec_read_lat_sync_r && dec_read_lat_sync );
        // 'stall' logic :
       // assign rd_addr_stall      = !( !dec_read_lat_sync_r && dec_read_lat_sync );
        assign rd_addr_stall      =  !inc_read_lat_sync_r && inc_read_lat_sync;
    end

    else
    begin : no_lat_ctl_en_gen
        // 'toggle detect' logic :
        //assign rd_addr_double_inc =    !inc_read_lat_sync_r && seq_rdp_inc_read_lat_1x;
        assign rd_addr_double_inc =   ( !dec_read_lat_sync_r && seq_rdp_dec_read_lat_1x );
        // 'stall' logic :
        //assign rd_addr_stall      = !( !dec_read_lat_sync_r && seq_rdp_dec_read_lat_1x );
        assign rd_addr_stall      = !inc_read_lat_sync_r && seq_rdp_inc_read_lat_1x;
    end

endgenerate



always@ (posedge phy_clk_1x or negedge reset_phy_clk_1x_n)
begin

   if (reset_phy_clk_1x_n == 0)
   begin
       rd_ram_rd_addr  <= { ADDR_COUNT_WIDTH {1'b0} };
   end

   else
   begin

       // RAM read address :
       if (rd_addr_stall == 1'b0)
       begin
           rd_ram_rd_addr <= rd_ram_rd_addr + 1'b1 + rd_addr_double_inc;
       end

   end

end


endmodule
