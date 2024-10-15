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
  Title           : Address and Command IO atoms

  File:  $RCSfile : alt_mem_phy_ac.v,v $

  Last Modified   : $Date: 2018/07/18 $

  Revision        : $Revision: #1 $

  Abstract        : Address and Command IO atoms for AFI PHY.  This block is instanced
                    by the alt_mem_phy_addr_cmd.v address and command block.
                    It instances one double data rate IO element together with
                    any required registering/delay for '1T' mode etc.
-----------------------------------------------------------------------------*/
//#end

`default_nettype none

`ifdef ALT_MEM_PHY_DEFINES
`else
`include "alt_mem_phy_defines.iv"
`endif

//#mw_prefix ("alt_mem_phy_ac")
module alt_mem_phy_ac (
//#end
                            clk_2x,
                            reset_2x_n,
                            phy_clk_1x,
                            ctl_add_1t_ac_lat,
                            ctl_negedge_en,
                            ctl_add_intermediate_regs,
                            period_sel,
                            seq_ac_sel,
                            ctl_ac_h,
                            ctl_ac_l,
                            seq_ac_h,
                            seq_ac_l,
                            mem_ac );
parameter POWER_UP_HIGH = 1;
parameter DWIDTH_RATIO  = 4;

// NB. clk_2x could be either ac_clk_2x or cs_n_clk_2x :
input wire   clk_2x;
input wire   reset_2x_n;
input wire   phy_clk_1x;

input wire   ctl_add_1t_ac_lat;
input wire   ctl_negedge_en;
input wire   ctl_add_intermediate_regs;
input wire   period_sel;
input wire   seq_ac_sel;
             
input wire   ctl_ac_h;
input wire   ctl_ac_l;
             
input wire   seq_ac_h;
input wire   seq_ac_l;

output wire  mem_ac;

(* preserve *) reg  ac_h_r     = POWER_UP_HIGH[0];
(* preserve *) reg  ac_l_r     = POWER_UP_HIGH[0];
(* preserve *) reg  ac_h_2r    = POWER_UP_HIGH[0];
(* preserve *) reg  ac_l_2r    = POWER_UP_HIGH[0];
(* preserve *) reg  ac_1t      = POWER_UP_HIGH[0];
(* preserve *) reg  ac_2x      = POWER_UP_HIGH[0];
(* preserve *) reg  ac_2x_r    = POWER_UP_HIGH[0];
(* preserve *) reg  ac_2x_2r   = POWER_UP_HIGH[0];
(* preserve *) reg  ac_2x_mux  = POWER_UP_HIGH[0];

reg ac_2x_retime     = POWER_UP_HIGH[0];
reg ac_2x_retime_r   = POWER_UP_HIGH[0];
reg ac_2x_deg_choice = POWER_UP_HIGH[0];

reg ac_h;
reg ac_l;

wire reset_2x ;
assign reset_2x         = ~reset_2x_n;

generate 
    
    if (DWIDTH_RATIO == 4) //HR
    begin : hr_mux_gen
    
        // Half Rate DDR memory types require an extra cycle of latency :
        always @(posedge phy_clk_1x)
        begin
        
            casez(seq_ac_sel)
            
            1'b0 :
            begin
                ac_l <= ctl_ac_l;
                ac_h <= ctl_ac_h;
            end
            
            1'b1 :
            begin
                ac_l <= seq_ac_l;
                ac_h <= seq_ac_h;
            end
        
            endcase
            
        end //always   
        
    end
    
    else // FR
    begin : fr_passthru_gen
        
        // Note that "_h" is unused in full-rate and no latency
        // is required :
        always @*
        begin
            
            // #pb_del: the following may need to be registered for speed
            casez(seq_ac_sel)
            
            1'b0 :
            begin
                ac_l <= ctl_ac_l;
            end
            
            1'b1 :
            begin
                ac_l <= seq_ac_l;
            end
            
            endcase
             
        end
    end
    
endgenerate    

generate

    if (DWIDTH_RATIO == 4)
    begin : half_rate

        // Initial registering of inputs :
        always @(posedge phy_clk_1x)
        begin
            ac_h_r  <= ac_h;
            ac_l_r  <= ac_l;
        end


        // Select high and low phases periodically to create the _2x signal :
        always @*
        begin

            casez(period_sel)

            1'b0     : ac_2x = ac_l_2r;
            1'b1     : ac_2x = ac_h_2r;
            default  : ac_2x = 1'bx; // X propagaton

            endcase

        end
        
        always @(posedge clk_2x)
        begin

            // Second stage of registering - on clk_2x
            ac_h_2r <= ac_h_r;
            ac_l_2r <= ac_l_r;

            // 1t registering - used if ctl_add_1t_ac_lat is true
            ac_1t   <= ac_2x;

            // AC_PHASE==270 requires an extra cycle of delay :
            ac_2x_deg_choice <= ac_1t;

            // If not at AC_PHASE==270, ctl_add_intermediate_regs shall be zero :
            if (ctl_add_intermediate_regs == 1'b0)
            begin
            
                if (ctl_add_1t_ac_lat == 1'b1)
                begin
                    ac_2x_r <= ac_1t;
                end
                
                else
                begin
                    ac_2x_r <= ac_2x;
                end
                
            end
            
            // If at AC_PHASE==270, ctl_add_intermediate_regs shall be one
            // and an extra cycle delay is required :
            else
            begin
           
                if (ctl_add_1t_ac_lat == 1'b1)
                begin
                    ac_2x_r <= ac_2x_deg_choice;
                end
                
                else
                begin
                    ac_2x_r <= ac_1t;
                end            
            
            end

            // Register the above output for use when ctl_negedge_en is set :
            ac_2x_2r <= ac_2x_r;

        end


        // Determine whether to select the "_r" or "_2r" variant :
        always @*
        begin

            casez(ctl_negedge_en)

            1'b0     : ac_2x_mux = ac_2x_r;
            1'b1     : ac_2x_mux = ac_2x_2r;
            default  : ac_2x_mux = 1'bx; // X propagaton

            endcase

        end

        if (POWER_UP_HIGH == 1)
        begin

            altddio_out #(
                .extend_oe_disable      ("UNUSED"),
                .intended_device_family ("Cyclone III"),
                .lpm_hint               ("UNUSED"),
                .lpm_type               ("altddio_out"),
                .oe_reg                 ("UNUSED"),
                .power_up_high          ("ON"),
                .width                  (1)
            ) addr_pin (
                .aset                   (reset_2x),
                .datain_h               (ac_2x_mux),
                .datain_l               (ac_2x_r),
                .dataout                (mem_ac),
                .oe                     (1'b1),
                .outclock               (clk_2x),
                .outclocken             (1'b1),
                .aclr                   (),
                .sset                   (),
                .sclr                   (),
                .oe_out                 ()
            );

        end

        else
        begin

            altddio_out #(
                .extend_oe_disable      ("UNUSED"),
                .intended_device_family ("Cyclone III"),
                .lpm_hint               ("UNUSED"),
                .lpm_type               ("altddio_out"),
                .oe_reg                 ("UNUSED"),
                .power_up_high          ("OFF"),
                .width                  (1)
            ) addr_pin (
                .aclr                   (reset_2x),
                .aset                   (),
                .datain_h               (ac_2x_mux),
                .datain_l               (ac_2x_r),
                .dataout                (mem_ac),
                .oe                     (1'b1),
                .outclock               (clk_2x),
                .outclocken             (1'b1),
                .sset                   (),
                .sclr                   (),
                .oe_out                 ()
                
            );

        end

    end // Half-rate

    // full-rate
    else
    begin : full_rate
   
        always @(posedge phy_clk_1x)
        begin
        
            // 1t registering - only used if ctl_add_1t_ac_lat is true
            ac_1t <= ac_l;
        
            // add 1 addr_clock delay if "Add 1T" is set:
           if (ctl_add_1t_ac_lat == 1'b1)
               ac_2x <= ac_1t;
           else
               ac_2x <= ac_l;
        
        end
        
        always @(posedge clk_2x)
        begin
            ac_2x_deg_choice <= ac_2x;
        end   
        
        // Note this is for 270 degree operation to align it to the correct clock phase.
        always @*
        begin
            casez(ctl_add_intermediate_regs)
                1'b0     : ac_2x_r = ac_2x;
                1'b1     : ac_2x_r = ac_2x_deg_choice;
                default  : ac_2x_r = 1'bx; // X propagaton
            endcase
        end
        
        always @(posedge clk_2x)
        begin
            ac_2x_2r <= ac_2x_r;
        end
        
        // Determine whether to select the "_r" or "_2r" variant :
        always @*
        begin
            casez(ctl_negedge_en)
                1'b0     : ac_2x_mux = ac_2x_r;
                1'b1     : ac_2x_mux = ac_2x_2r;
                default  : ac_2x_mux = 1'bx; // X propagaton
            endcase
        end
                       
        if (POWER_UP_HIGH == 1)
        begin
        
            altddio_out #(
                .extend_oe_disable      ("UNUSED"),
                .intended_device_family ("Cyclone III"),
                .lpm_hint               ("UNUSED"),
                .lpm_type               ("altddio_out"),
                .oe_reg                 ("UNUSED"),
                .power_up_high          ("ON"),
                .width                  (1)
            ) addr_pin (
                .aset                   (reset_2x),
                .datain_h               (ac_2x_mux),
                .datain_l               (ac_2x_r),
                .dataout                (mem_ac),
                .oe                     (1'b1),
                .outclock               (clk_2x),
                .outclocken             (1'b1),
                .aclr                   (),
                .sclr                   (),
                .sset                   (),
                .oe_out                 ()
            );
        
        end
        
        else
        begin
        
            altddio_out #(
                .extend_oe_disable      ("UNUSED"),
                .intended_device_family ("Cyclone III"),
                .lpm_hint               ("UNUSED"),
                .lpm_type               ("altddio_out"),
                .oe_reg                 ("UNUSED"),
                .power_up_high          ("OFF"),
                .width                  (1)
            ) addr_pin (
                .aclr                   (reset_2x),
                .datain_h               (ac_2x_mux),
                .datain_l               (ac_2x_r),
                .dataout                (mem_ac),
                .oe                     (1'b1),
                .outclock               (clk_2x),
                .outclocken             (1'b1),
                .aset                   (),
                .sclr                   (),
                .sset                   (),
                .oe_out                 ()
            );
            
        end // else: !if(POWER_UP_HIGH == 1) 

    end // block: full_rate

endgenerate

endmodule

`default_nettype wire
