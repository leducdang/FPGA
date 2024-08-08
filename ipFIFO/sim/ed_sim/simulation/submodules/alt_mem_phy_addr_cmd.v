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
  Title           : Address and Command

  File:  $RCSfile : alt_mem_phy_addr_cmd.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : AFI PHY Address and Command.  This block instances the
                    alt_mem_phy_ac block once per address or command pin. It
                    also generates the periodical select for each group of pins
                    to ensure DDR data transfers correctly. (CIII variant)
-----------------------------------------------------------------------------*/
//#end

`default_nettype none

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_addr_cmd")
module alt_mem_phy_addr_cmd ( 
//#end
                                  ac_clk_2x,
                                  cs_n_clk_2x,
                                  phy_clk_1x,
                                  reset_ac_clk_2x_n,
                                  reset_cs_n_clk_2x_n,
                                  
                                  // Addr/cmd interface from controller
                                  ctl_add_1t_ac_lat,
                                  ctl_add_1t_odt_lat,				   
                                  ctl_add_intermediate_regs,
                                  
                                  ctl_negedge_en,
				                  ctl_mem_addr_h,
                                  ctl_mem_addr_l,
                                  ctl_mem_ba_h,
                                  ctl_mem_ba_l,
                                  ctl_mem_cas_n_h,
                                  ctl_mem_cas_n_l,
                                  ctl_mem_cke_h,
                                  ctl_mem_cke_l,
                                  ctl_mem_cs_n_h,
                                  ctl_mem_cs_n_l,
                                  ctl_mem_odt_h,
                                  ctl_mem_odt_l,
                                  ctl_mem_ras_n_h,
                                  ctl_mem_ras_n_l,
                                  ctl_mem_we_n_h,
                                  ctl_mem_we_n_l,
                                  
                                  // Interface from Sequencer, used for calibration
                                  // as the MRS registers need to be controlled :
                                  seq_addr_h,
                                  seq_addr_l,
                                  seq_ba_h,
                                  seq_ba_l,
                                  seq_cas_n_h,
                                  seq_cas_n_l,
                                  seq_cke_h,
                                  seq_cke_l,
                                  seq_cs_n_h,
                                  seq_cs_n_l,
                                  seq_odt_h,
                                  seq_odt_l,
                                  seq_ras_n_h,
                                  seq_ras_n_l,
                                  seq_we_n_h,
                                  seq_we_n_l,
                                  
                                  seq_ac_sel,
                                  
                                  mem_addr,
                                  mem_ba,
                                  mem_cas_n,
                                  mem_cke,
                                  mem_cs_n,
                                  mem_odt,
                                  mem_ras_n,
                                  mem_we_n );


parameter DWIDTH_RATIO            =           4;
parameter MEM_ADDR_CMD_BUS_COUNT  =           1;
parameter MEM_IF_BANKADDR_WIDTH   =           3;
parameter MEM_IF_CS_WIDTH         =           2;
parameter MEM_IF_MEMTYPE          =       "DDR";
parameter MEM_IF_ROWADDR_WIDTH    =          13;

input wire                                  cs_n_clk_2x;
input wire                                  ac_clk_2x;
input wire                                  phy_clk_1x;

input wire                                  reset_ac_clk_2x_n;
input wire                                  reset_cs_n_clk_2x_n;

input wire [MEM_IF_ROWADDR_WIDTH -1:0]      ctl_mem_addr_h;
input wire [MEM_IF_ROWADDR_WIDTH -1:0]      ctl_mem_addr_l;
input wire                                  ctl_add_1t_ac_lat;
input wire                                  ctl_add_1t_odt_lat;   
input wire                                  ctl_negedge_en;
input wire                                  ctl_add_intermediate_regs;    
input wire [MEM_IF_BANKADDR_WIDTH - 1:0]    ctl_mem_ba_h;
input wire [MEM_IF_BANKADDR_WIDTH - 1:0]    ctl_mem_ba_l;
input wire                                  ctl_mem_cas_n_h;
input wire                                  ctl_mem_cas_n_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_cke_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_cke_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_cs_n_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_cs_n_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_odt_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          ctl_mem_odt_l;
input wire                                  ctl_mem_ras_n_h;
input wire                                  ctl_mem_ras_n_l;
input wire                                  ctl_mem_we_n_h;
input wire                                  ctl_mem_we_n_l;

input wire [MEM_IF_ROWADDR_WIDTH -1:0]      seq_addr_h;
input wire [MEM_IF_ROWADDR_WIDTH -1:0]      seq_addr_l;
input wire [MEM_IF_BANKADDR_WIDTH - 1:0]    seq_ba_h;
input wire [MEM_IF_BANKADDR_WIDTH - 1:0]    seq_ba_l;
input wire                                  seq_cas_n_h;
input wire                                  seq_cas_n_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_cke_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_cke_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_cs_n_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_cs_n_l;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_odt_h;
input wire [MEM_IF_CS_WIDTH - 1:0]          seq_odt_l;
input wire                                  seq_ras_n_h;
input wire                                  seq_ras_n_l;
input wire                                  seq_we_n_h;
input wire                                  seq_we_n_l;

input wire                                  seq_ac_sel;

output wire [MEM_IF_ROWADDR_WIDTH - 1 : 0]  mem_addr;
output wire [MEM_IF_BANKADDR_WIDTH - 1 : 0] mem_ba;
output wire                                 mem_cas_n;
output wire [MEM_IF_CS_WIDTH - 1 : 0]       mem_cke;
output wire [MEM_IF_CS_WIDTH - 1 : 0]       mem_cs_n;
output wire [MEM_IF_CS_WIDTH - 1 : 0]       mem_odt;
output wire                                 mem_ras_n;
output wire                                 mem_we_n;


// Periodical select registers - per group of pins
reg  [`ADC_NUM_PIN_GROUPS-1:0]              count_addr = `ADC_NUM_PIN_GROUPS'b0;
reg  [`ADC_NUM_PIN_GROUPS-1:0]              count_addr_2x = `ADC_NUM_PIN_GROUPS'b0;
reg  [`ADC_NUM_PIN_GROUPS-1:0]              count_addr_2x_r = `ADC_NUM_PIN_GROUPS'b0;
reg  [`ADC_NUM_PIN_GROUPS-1:0]              period_sel_addr = `ADC_NUM_PIN_GROUPS'b0;


//#pb_del Create the periodical selects per pin group.  This duplication could
//#pb_del probably be reduced to just the final register

generate
genvar ia;

for (ia=0; ia<`ADC_NUM_PIN_GROUPS - 1; ia=ia+1)
begin : SELECTS

    always @(posedge phy_clk_1x)
    begin
        count_addr[ia] <= ~count_addr[ia];
    end

    always @(posedge ac_clk_2x)
    begin
        count_addr_2x[ia]   <= count_addr[ia];
        count_addr_2x_r[ia] <= count_addr_2x[ia];
        period_sel_addr[ia] <= ~(count_addr_2x_r[ia] ^ count_addr_2x[ia]);
    end

end

endgenerate


//now generate cs_n period sel, off the dedicated cs_n clock :
always @(posedge phy_clk_1x)
begin
    count_addr[`ADC_CS_N_PERIOD_SEL] <= ~count_addr[`ADC_CS_N_PERIOD_SEL];
end

always @(posedge cs_n_clk_2x)
begin
    count_addr_2x  [`ADC_CS_N_PERIOD_SEL] <= count_addr   [`ADC_CS_N_PERIOD_SEL];
    count_addr_2x_r[`ADC_CS_N_PERIOD_SEL] <= count_addr_2x[`ADC_CS_N_PERIOD_SEL];
    period_sel_addr[`ADC_CS_N_PERIOD_SEL] <= ~(count_addr_2x_r[`ADC_CS_N_PERIOD_SEL] ^ count_addr_2x[`ADC_CS_N_PERIOD_SEL]);
end


// Create the ADDR I/O structure :
	
generate
genvar ib;

    for (ib=0; ib<MEM_IF_ROWADDR_WIDTH; ib=ib+1)
    begin : addr

        //#mw_prefix ("alt_mem_phy_ac")
        alt_mem_phy_ac # ( 
        //#end
            .POWER_UP_HIGH (1),
            .DWIDTH_RATIO (DWIDTH_RATIO)
        ) addr_struct (
            .clk_2x                    (ac_clk_2x),
            .reset_2x_n                (1'b1),
            .phy_clk_1x                (phy_clk_1x),
            .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
            .ctl_negedge_en            (ctl_negedge_en),
            .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
            .period_sel                (period_sel_addr[`ADC_ADDR_PERIOD_SEL]),
            .seq_ac_sel                (seq_ac_sel),
            .ctl_ac_h                  (ctl_mem_addr_h[ib]),
            .ctl_ac_l                  (ctl_mem_addr_l[ib]),
            .seq_ac_h                  (seq_addr_h[ib]),
            .seq_ac_l                  (seq_addr_l[ib]),
            .mem_ac                    (mem_addr[ib])
        );
        
    end

endgenerate

// Create the BANK_ADDR I/O structure :
generate
genvar ic;

    for (ic=0; ic<MEM_IF_BANKADDR_WIDTH; ic=ic+1)
    begin : ba

        //#mw_prefix ("alt_mem_phy_ac")
        alt_mem_phy_ac #(
        //#end        
            .POWER_UP_HIGH (0),
            .DWIDTH_RATIO (DWIDTH_RATIO)
        ) ba_struct  ( 
            .clk_2x                    (ac_clk_2x),
            .reset_2x_n                (1'b1),
            .phy_clk_1x                (phy_clk_1x),
            .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
            .ctl_negedge_en            (ctl_negedge_en),
            .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
            .period_sel                (period_sel_addr[`ADC_BA_PERIOD_SEL]),
            .seq_ac_sel                (seq_ac_sel),
            .ctl_ac_h                  (ctl_mem_ba_h[ic]),
            .ctl_ac_l                  (ctl_mem_ba_l[ic]),
            .seq_ac_h                  (seq_ba_h[ic]),
            .seq_ac_l                  (seq_ba_l[ic]),
            .mem_ac                    (mem_ba[ic])
        );

    end

endgenerate

// Create the CAS_N I/O structure :
//#mw_prefix ("alt_mem_phy_ac")
alt_mem_phy_ac #( 
//#end
    .POWER_UP_HIGH (1),
    .DWIDTH_RATIO (DWIDTH_RATIO)

) cas_n_struct ( 
    .clk_2x                    (ac_clk_2x),
    .reset_2x_n                (1'b1),
    .phy_clk_1x                (phy_clk_1x),
    .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
    .ctl_negedge_en            (ctl_negedge_en),
    .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
    .period_sel                (period_sel_addr[`ADC_CAS_N_PERIOD_SEL]),
    .seq_ac_sel                (seq_ac_sel),
    .ctl_ac_h                  (ctl_mem_cas_n_h),
    .ctl_ac_l                  (ctl_mem_cas_n_l),
    .seq_ac_h                  (seq_cas_n_h),
    .seq_ac_l                  (seq_cas_n_l),
    .mem_ac                    (mem_cas_n)
);


// Create the CKE I/O structure :
generate
genvar id;

    for (id=0; id<MEM_IF_CS_WIDTH; id=id+1)
    begin : cke

        //#mw_prefix ("alt_mem_phy_ac")
        alt_mem_phy_ac # (
        //#end        
            .POWER_UP_HIGH (0),
            .DWIDTH_RATIO (DWIDTH_RATIO)
        ) cke_struct  ( 
            .clk_2x                    (ac_clk_2x),
            .reset_2x_n                (reset_ac_clk_2x_n),
            .phy_clk_1x                (phy_clk_1x),
            .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
            .ctl_negedge_en            (ctl_negedge_en),
            .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
            .period_sel                (period_sel_addr[`ADC_CKE_PERIOD_SEL]),
            .seq_ac_sel                (seq_ac_sel),
            .ctl_ac_h                  (ctl_mem_cke_h[id]),
            .ctl_ac_l                  (ctl_mem_cke_l[id]),
            .seq_ac_h                  (seq_cke_h[id]),
            .seq_ac_l                  (seq_cke_l[id]),
            .mem_ac                    (mem_cke[id])
        );

    end

endgenerate


// Create the CS_N I/O structure.  Note that the 2x clock is different.
generate
genvar ie;

    for (ie=0; ie<MEM_IF_CS_WIDTH; ie=ie+1)
    begin : cs_n

        //#mw_prefix ("alt_mem_phy_ac")
        alt_mem_phy_ac # ( 
        //#end
            .POWER_UP_HIGH (1),
            .DWIDTH_RATIO (DWIDTH_RATIO)
        ) cs_n_struct ( 
            .clk_2x                    (cs_n_clk_2x),
            .reset_2x_n                (reset_ac_clk_2x_n),
            .phy_clk_1x                (phy_clk_1x),
            .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
            .ctl_negedge_en            (ctl_negedge_en),
            .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
            .period_sel                (period_sel_addr[`ADC_CS_N_PERIOD_SEL]),
            .seq_ac_sel                (seq_ac_sel),
            .ctl_ac_h                  (ctl_mem_cs_n_h[ie]),
            .ctl_ac_l                  (ctl_mem_cs_n_l[ie]),
            .seq_ac_h                  (seq_cs_n_h[ie]),
            .seq_ac_l                  (seq_cs_n_l[ie]),
            .mem_ac                    (mem_cs_n[ie])
        );

    end

endgenerate


// Create the ODT I/O structure :

generate
genvar ig;

    if (MEM_IF_MEMTYPE != "DDR")
    begin : gen_odt
    
        for (ig=0; ig<MEM_IF_CS_WIDTH; ig=ig+1)
        begin : odt

            //#mw_prefix ("alt_mem_phy_ac")
            alt_mem_phy_ac #(
            //#end	  
        	.POWER_UP_HIGH (0),
        	.DWIDTH_RATIO (DWIDTH_RATIO)
            ) odt_struct  ( 
        	.clk_2x 		           (ac_clk_2x),
        	.reset_2x_n		           (1'b1),
        	.phy_clk_1x		           (phy_clk_1x),
        	.ctl_add_1t_ac_lat	       (ctl_add_1t_odt_lat),
        	.ctl_negedge_en 	       (ctl_negedge_en),
        	.ctl_add_intermediate_regs (ctl_add_intermediate_regs),
        	.period_sel		           (period_sel_addr[`ADC_ODT_PERIOD_SEL]),
        	.seq_ac_sel 	           (seq_ac_sel),
            .ctl_ac_h		           (ctl_mem_odt_h[ig]),
            .ctl_ac_l		           (ctl_mem_odt_l[ig]),
            .seq_ac_h		           (seq_odt_h[ig]),
            .seq_ac_l		           (seq_odt_l[ig]),
            .mem_ac 		           (mem_odt[ig])
            );

        end
	
    end
    
endgenerate


// Create the RAS_N I/O structure :
//#mw_prefix ("alt_mem_phy_ac")
alt_mem_phy_ac # (
//#end
    .POWER_UP_HIGH (1),
    .DWIDTH_RATIO (DWIDTH_RATIO)
) ras_n_struct  ( 
    .clk_2x                    (ac_clk_2x),
    .reset_2x_n                (1'b1),
    .phy_clk_1x                (phy_clk_1x),
    .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
    .ctl_negedge_en            (ctl_negedge_en),
    .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
    .period_sel                (period_sel_addr[`ADC_RAS_N_PERIOD_SEL]),
    .seq_ac_sel                (seq_ac_sel),
    .ctl_ac_h                  (ctl_mem_ras_n_h),
    .ctl_ac_l                  (ctl_mem_ras_n_l),
    .seq_ac_h                  (seq_ras_n_h),
    .seq_ac_l                  (seq_ras_n_l),
    .mem_ac                    (mem_ras_n)
);


// Create the WE_N I/O structure :
//#mw_prefix ("alt_mem_phy_ac")
alt_mem_phy_ac # (
//#end
    .POWER_UP_HIGH (1),
    .DWIDTH_RATIO (DWIDTH_RATIO)
) we_n_struct  (
    .clk_2x                    (ac_clk_2x),
    .reset_2x_n                (1'b1),
    .phy_clk_1x                (phy_clk_1x),
    .ctl_add_1t_ac_lat         (ctl_add_1t_ac_lat),
    .ctl_negedge_en            (ctl_negedge_en),
    .ctl_add_intermediate_regs (ctl_add_intermediate_regs),
    .period_sel                (period_sel_addr[`ADC_WE_N_PERIOD_SEL]),
    .seq_ac_sel                (seq_ac_sel),
    .ctl_ac_h                  (ctl_mem_we_n_h),
    .ctl_ac_l                  (ctl_mem_we_n_l),
    .seq_ac_h                  (seq_we_n_h),
    .seq_ac_l                  (seq_we_n_l),
    .mem_ac                    (mem_we_n)
);

endmodule

`default_nettype wire
