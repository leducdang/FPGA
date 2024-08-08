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

  File:  $RCSfile : alt_mem_phy_read_dp.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : Read datapath.  This block is designed to interface to a
                    family specific I/O block, such as alt_mem_phy_dp_io_sii.
                    It then handles any required rate converstion and pipelining.
                    It handles the entire read datapath width.
////////////////////////////////////////////////////////////////////////////-*/
//#end

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_read_dp")
module alt_mem_phy_read_dp ( phy_clk_1x,
//#end
                             resync_clk_2x,
                             reset_phy_clk_1x_n,
                             reset_resync_clk_2x_n,
                             seq_rdp_dec_read_lat_1x,
                             seq_rdp_dmx_swap,
                             seq_rdp_inc_read_lat_1x,
                             dio_rdata_h_2x,
                             dio_rdata_l_2x,
                             ctl_mem_rdata
                            );

parameter ADDR_COUNT_WIDTH         =               4;
parameter BIDIR_DPINS              =               1; // 0 for QDR only.
parameter DWIDTH_RATIO             =               4;
parameter MEM_IF_CLK_PS            =            4000;
parameter FAMILY                   =    "Stratix II";
parameter LOCAL_IF_DWIDTH          =             256;
parameter MEM_IF_DQ_PER_DQS        =               8;
parameter MEM_IF_DQS_WIDTH         =               8;
parameter MEM_IF_DWIDTH            =              64;
parameter MEM_IF_PHY_NAME          = "STRATIXII_DQS";
parameter RDP_INITIAL_LAT          =               6;
parameter RDP_RESYNC_LAT_CTL_EN    =               0;
parameter RESYNC_PIPELINE_DEPTH    =               1;

localparam NUM_DQS_PINS            = MEM_IF_DQS_WIDTH;

input  wire                         phy_clk_1x;
input  wire                         resync_clk_2x;
input  wire                         reset_phy_clk_1x_n;
input  wire                         reset_resync_clk_2x_n;
input  wire                         seq_rdp_dec_read_lat_1x;
input  wire                         seq_rdp_dmx_swap;
input  wire                         seq_rdp_inc_read_lat_1x;
input  wire [MEM_IF_DWIDTH-1 : 0]   dio_rdata_h_2x;
input  wire [MEM_IF_DWIDTH-1 : 0]   dio_rdata_l_2x;
output wire [LOCAL_IF_DWIDTH-1 : 0] ctl_mem_rdata;

// concatonated read data :
wire [(2*MEM_IF_DWIDTH)-1 : 0]      dio_rdata_2x;
reg  [ADDR_COUNT_WIDTH - DWIDTH_RATIO/2 : 0]     rd_ram_rd_addr;   
reg  [ADDR_COUNT_WIDTH - 1 : 0]     rd_ram_wr_addr;
wire [(2*MEM_IF_DWIDTH)-1 : 0]      rd_data_piped_2x;



reg                                 inc_read_lat_sync_r;
reg                                 dec_read_lat_sync_r;

// Optional AMS registers :
reg                                 inc_read_lat_ams;  
reg                                 inc_read_lat_sync;  
                                                         
reg                                 dec_read_lat_ams;  
reg                                 dec_read_lat_sync;  
                                                         
reg                                 state;
reg                                 dmx_swap_ams;
reg                                 dmx_swap_sync;
reg                                 dmx_swap_sync_r;

wire                                wr_addr_toggle_detect;
wire                                wr_addr_stall;
wire                                wr_addr_double_inc;

wire                                rd_addr_stall;
wire                                rd_addr_double_inc;

// Read data from ram, prior to mapping/re-ordering :
wire [LOCAL_IF_DWIDTH-1 : 0]        ram_rdata_1x;

////////////////////////////////////////////////////////////////////////////////
//                          Write Address block
////////////////////////////////////////////////////////////////////////////////


// 'toggle detect' logic :
assign wr_addr_toggle_detect = !dmx_swap_sync_r && dmx_swap_sync;

// 'stall' logic :
assign wr_addr_stall      = !(~state && wr_addr_toggle_detect);

// 'double_inc' logic :
assign wr_addr_double_inc = state && wr_addr_toggle_detect;

// Write address generation
// When no demux toggle - increment every clock cycle
// When demux toggle is detected,invert addr_stall
// if addr_stall is 1 then do nothing to address, else double increment this cycle.
always@ (posedge resync_clk_2x or negedge reset_resync_clk_2x_n)
begin

   if (reset_resync_clk_2x_n == 0)
   begin
       rd_ram_wr_addr  <= RDP_INITIAL_LAT[3:0];
       state           <= 1'b0;
       dmx_swap_ams    <= 1'b0;
       dmx_swap_sync   <= 1'b0;
       dmx_swap_sync_r <= 1'b0;
   end

   else
   begin

       // Synchronise dmx_swap :
       dmx_swap_ams    <= seq_rdp_dmx_swap;
       dmx_swap_sync   <= dmx_swap_ams;
       dmx_swap_sync_r <= dmx_swap_sync;

       // RAM write address :
       if (wr_addr_stall == 1'b1)
       begin
           rd_ram_wr_addr <= rd_ram_wr_addr + 1'b1 + wr_addr_double_inc;
       end

       // Maintain single bit state :
       if (wr_addr_toggle_detect == 1'b1)
       begin
           state <= ~state;
       end

   end

end



////////////////////////////////////////////////////////////////////////////////
//                          Pipeline registers
////////////////////////////////////////////////////////////////////////////////


// Concatenate the input read data taking note of ram input datawidths
// This is concatenating rdata_p and rdata_n from a DQS group together so that the rest
// of the pipeline can use a single vector:
generate

genvar dqs_group_num;

    for (dqs_group_num = 0; dqs_group_num < NUM_DQS_PINS ; dqs_group_num  = dqs_group_num + 1)
    begin : ddio_remap

        assign dio_rdata_2x[2*MEM_IF_DQ_PER_DQS*dqs_group_num + 2*MEM_IF_DQ_PER_DQS-1: 2*MEM_IF_DQ_PER_DQS*dqs_group_num]

         = {  dio_rdata_l_2x[MEM_IF_DQ_PER_DQS*dqs_group_num + MEM_IF_DQ_PER_DQS-1: MEM_IF_DQ_PER_DQS*dqs_group_num],
              dio_rdata_h_2x[MEM_IF_DQ_PER_DQS*dqs_group_num + MEM_IF_DQ_PER_DQS-1: MEM_IF_DQ_PER_DQS*dqs_group_num]
            };
    end

endgenerate


// Generate appropriate pipeline depth

generate
genvar i;

    if (RESYNC_PIPELINE_DEPTH > 0) 
    begin : resync_pipeline_gen

    // Declare pipeline registers
    reg  [(2*MEM_IF_DWIDTH)-1 : 0 ] pipeline_delay [0 : RESYNC_PIPELINE_DEPTH - 1] ;

        for (i=0; i< RESYNC_PIPELINE_DEPTH; i = i + 1)
        begin : PIPELINE

            //#pb_del reset removed on consultation with PW & PC to ease fitting :
            always @(posedge resync_clk_2x)
            begin                

                if (i==0)
                    pipeline_delay[i] <= dio_rdata_2x;
                else
                    pipeline_delay[i] <= pipeline_delay[i-1];               
               
            end //always

        end //for

        assign rd_data_piped_2x = pipeline_delay[RESYNC_PIPELINE_DEPTH-1];

    end

    // If pipeline registers are not configured, pass-thru :
    else
    begin : no_resync_pipe_gen

        assign rd_data_piped_2x = dio_rdata_2x;

    end

endgenerate





////////////////////////////////////////////////////////////////////////////////
//         Instantiate the read_dp dpram
////////////////////////////////////////////////////////////////////////////////

generate

    if (DWIDTH_RATIO == 4)
    begin : half_rate_ram_gen
    
        altsyncram #(
             .address_reg_b             ("CLOCK1"),
             .clock_enable_input_a      ("BYPASS"),
             .clock_enable_input_b      ("BYPASS"),
             .clock_enable_output_b     ("BYPASS"),
             .intended_device_family    (FAMILY),
             .lpm_type                  ("altsyncram"),
             .numwords_a                ((2**ADDR_COUNT_WIDTH )),
             .numwords_b                ((2**ADDR_COUNT_WIDTH )/2),
             .operation_mode            ("DUAL_PORT"),
             .outdata_aclr_b            ("NONE"),
             .outdata_reg_b             ("CLOCK1"),
             .power_up_uninitialized    ("FALSE"),
             .widthad_a                 (ADDR_COUNT_WIDTH),
             .widthad_b                 (ADDR_COUNT_WIDTH - 1),
             .width_a                   (MEM_IF_DWIDTH*2),
             .width_b                   (MEM_IF_DWIDTH*4),
             .width_byteena_a           (1)
        ) altsyncram_component (
             .wren_a            (1'b1),
             .clock0            (resync_clk_2x),
             .clock1            (phy_clk_1x),
             .address_a         (rd_ram_wr_addr),
             .address_b         (rd_ram_rd_addr),
             .data_a            (rd_data_piped_2x),
             .q_b               (ram_rdata_1x),
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
             .data_b            ({(MEM_IF_DWIDTH*4){1'b1}}),
             .q_a               (),
             .rden_b            (1'b1),
             .rden_a            (),
             .wren_b            (1'b0),
             .eccstatus         ()
        );

        // Read data mapping :
        genvar dqs_group_num_b;

        for (dqs_group_num_b = 0; dqs_group_num_b < NUM_DQS_PINS ; dqs_group_num_b  = dqs_group_num_b + 1)
        begin : remap_logic
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 0 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 0 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS +     MEM_IF_DQ_PER_DQS - 1 :                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS                     ];
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 1 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 1 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + 2 * MEM_IF_DQ_PER_DQS - 1 :                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS ];
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 2 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 2 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [ MEM_IF_DWIDTH * 2 + dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS +     MEM_IF_DQ_PER_DQS - 1 : MEM_IF_DWIDTH * 2 + dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS                     ];
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 3 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 3 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [ MEM_IF_DWIDTH * 2 + dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + 2 * MEM_IF_DQ_PER_DQS - 1 : MEM_IF_DWIDTH * 2 + dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS ];
        end

     end // block: half_rate_dp
   
endgenerate

// full-rate
   
generate

    if (DWIDTH_RATIO == 2)
    begin : full_rate_ram_gen
    
        altsyncram #(
             .address_reg_b             ("CLOCK1"),
             .clock_enable_input_a      ("BYPASS"),
             .clock_enable_input_b      ("BYPASS"),
             .clock_enable_output_b     ("BYPASS"),
             .intended_device_family    (FAMILY),
             .lpm_type                  ("altsyncram"),
             .numwords_a                ((2**ADDR_COUNT_WIDTH )),
             .numwords_b                ((2**ADDR_COUNT_WIDTH )),
             .operation_mode            ("DUAL_PORT"),
             .outdata_aclr_b            ("NONE"),
             .outdata_reg_b             ("CLOCK1"),
             .power_up_uninitialized    ("FALSE"),
             .widthad_a                 (ADDR_COUNT_WIDTH),
             .widthad_b                 (ADDR_COUNT_WIDTH),
             .width_a                   (MEM_IF_DWIDTH*2),
             .width_b                   (MEM_IF_DWIDTH*2),
             .width_byteena_a           (1)
        ) altsyncram_component(
             .wren_a            (1'b1),
             .clock0            (resync_clk_2x),
             .clock1            (phy_clk_1x),
             .address_a         (rd_ram_wr_addr),
             .address_b         (rd_ram_rd_addr),
             .data_a            (rd_data_piped_2x),
             .q_b               (ram_rdata_1x),
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
             .data_b            ({(MEM_IF_DWIDTH*2){1'b1}}),
             .q_a               (),
             .rden_b            (1'b1),
             .rden_a            (),
             .wren_b            (1'b0),
             .eccstatus         ()             
        );

        // Read data mapping :
        genvar dqs_group_num_b;

        for (dqs_group_num_b = 0; dqs_group_num_b < NUM_DQS_PINS ; dqs_group_num_b  = dqs_group_num_b + 1)
        begin : remap_logic
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 0 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 0 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS +     MEM_IF_DQ_PER_DQS - 1 :                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS                     ];
            assign ctl_mem_rdata [MEM_IF_DWIDTH * 1 + dqs_group_num_b * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS -1 : MEM_IF_DWIDTH * 1 + dqs_group_num_b * MEM_IF_DQ_PER_DQS ] = ram_rdata_1x [                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + 2 * MEM_IF_DQ_PER_DQS - 1 :                     dqs_group_num_b * 2 * MEM_IF_DQ_PER_DQS + MEM_IF_DQ_PER_DQS ];

        end
              
     end // block: half_rate_dp
   
endgenerate

   

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
       rd_ram_rd_addr  <= { ADDR_COUNT_WIDTH - DWIDTH_RATIO/2 {1'b0} };      
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
