
# (C) 2001-2024 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 22.1 915 win32 2024.07.08.10:57:39
# ----------------------------------------
# Auto-generated simulation script rivierapro_setup.tcl
# ----------------------------------------
# This script provides commands to simulate the following IP detected in
# your Quartus project:
#     ed_sim
# 
# Altera recommends that you source this Quartus-generated IP simulation
# script from your own customized top-level script, and avoid editing this
# generated script.
# 
# To write a top-level script that compiles Altera simulation libraries and
# the Quartus-generated IP in your project, along with your design and
# testbench files, copy the text from the TOP-LEVEL TEMPLATE section below
# into a new file, e.g. named "aldec.do", and modify the text as directed.
# 
# ----------------------------------------
# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator.
# #
# set QSYS_SIMDIR <script generation output directory>
# #
# # Source the generated IP simulation script.
# source $QSYS_SIMDIR/aldec/rivierapro_setup.tcl
# #
# # Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
# #
# # Call command to compile the Quartus EDA simulation library.
# dev_com
# #
# # Call command to compile the Quartus-generated IP simulation files.
# com
# #
# # Add commands to compile all design files and testbench files, including
# # the top level. (These are all the files required for simulation other
# # than the files compiled by the Quartus-generated IP simulation script)
# #
# vlog -sv2k5 <your compilation options> <design and testbench files>
# #
# # Set the top-level simulation or testbench module/entity name, which is
# # used by the elab command to elaborate the top level.
# #
# set TOP_LEVEL_NAME <simulation top>
# #
# # Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
# #
# # Call command to elaborate your design and testbench.
# elab
# #
# # Run the simulation.
# run
# #
# # Report success to the shell.
# exit -code 0
# #
# # TOP-LEVEL TEMPLATE - END
# ----------------------------------------
# 
# IP SIMULATION SCRIPT
# ----------------------------------------
# If ed_sim is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "ed_sim"
}

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
}

if ![info exists QUARTUS_INSTALL_DIR] { 
  set QUARTUS_INSTALL_DIR "D:/fpga/quartus/"
}

if ![info exists USER_DEFINED_COMPILE_OPTIONS] { 
  set USER_DEFINED_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_VHDL_COMPILE_OPTIONS] { 
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_VERILOG_COMPILE_OPTIONS] { 
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_ELAB_OPTIONS] { 
  set USER_DEFINED_ELAB_OPTIONS ""
}

# ----------------------------------------
# Initialize simulation properties - DO NOT MODIFY!
set ELAB_OPTIONS ""
set SIM_OPTIONS ""
if ![ string match "*-64 vsim*" [ vsim -version ] ] {
} else {
}

set Aldec "Riviera"
if { [ string match "*Active-HDL*" [ vsim -version ] ] } {
  set Aldec "Active"
}

if { [ string match "Active" $Aldec ] } {
  scripterconf -tcl
  createdesign "$TOP_LEVEL_NAME"  "."
  opendesign "$TOP_LEVEL_NAME"
}

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries     
ensure_lib      ./libraries/work
vmap       work ./libraries/work
ensure_lib                  ./libraries/altera_ver      
vmap       altera_ver       ./libraries/altera_ver      
ensure_lib                  ./libraries/lpm_ver         
vmap       lpm_ver          ./libraries/lpm_ver         
ensure_lib                  ./libraries/sgate_ver       
vmap       sgate_ver        ./libraries/sgate_ver       
ensure_lib                  ./libraries/altera_mf_ver   
vmap       altera_mf_ver    ./libraries/altera_mf_ver   
ensure_lib                  ./libraries/altera_lnsim_ver
vmap       altera_lnsim_ver ./libraries/altera_lnsim_ver
ensure_lib                  ./libraries/cycloneive_ver  
vmap       cycloneive_ver   ./libraries/cycloneive_ver  
ensure_lib                  ./libraries/altera          
vmap       altera           ./libraries/altera          
ensure_lib                  ./libraries/lpm             
vmap       lpm              ./libraries/lpm             
ensure_lib                  ./libraries/sgate           
vmap       sgate            ./libraries/sgate           
ensure_lib                  ./libraries/altera_mf       
vmap       altera_mf        ./libraries/altera_mf       
ensure_lib                  ./libraries/altera_lnsim    
vmap       altera_lnsim     ./libraries/altera_lnsim    
ensure_lib                  ./libraries/cycloneive      
vmap       cycloneive       ./libraries/cycloneive      
ensure_lib                           ./libraries/altera_common_sv_packages
vmap       altera_common_sv_packages ./libraries/altera_common_sv_packages
ensure_lib                           ./libraries/traffic_generator_0      
vmap       traffic_generator_0       ./libraries/traffic_generator_0      
ensure_lib                           ./libraries/status_bridge            
vmap       status_bridge             ./libraries/status_bridge            
ensure_lib                           ./libraries/ctl                      
vmap       ctl                       ./libraries/ctl                      
ensure_lib                           ./libraries/phy                      
vmap       phy                       ./libraries/phy                      
ensure_lib                           ./libraries/tg                       
vmap       tg                        ./libraries/tg                       
ensure_lib                           ./libraries/emif                     
vmap       emif                      ./libraries/emif                     
ensure_lib                           ./libraries/global_reset             
vmap       global_reset              ./libraries/global_reset             
ensure_lib                           ./libraries/ref_clk                  
vmap       ref_clk                   ./libraries/ref_clk                  
ensure_lib                           ./libraries/mem_model                
vmap       mem_model                 ./libraries/mem_model                
ensure_lib                           ./libraries/sim_checker              
vmap       sim_checker               ./libraries/sim_checker              
ensure_lib                           ./libraries/emif_ed                  
vmap       emif_ed                   ./libraries/emif_ed                  
ensure_lib                           ./libraries/ed_sim                   
vmap       ed_sim                    ./libraries/ed_sim                   

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  eval vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"              -work altera_ver      
  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                       -work lpm_ver         
  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                          -work sgate_ver       
  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                      -work altera_mf_ver   
  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                  -work altera_lnsim_ver
  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/cycloneive_atoms.v"               -work cycloneive_ver  
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"        -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"    -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"       -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"    -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd" -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"            -work altera          
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                      -work lpm             
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                     -work lpm             
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                   -work sgate           
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                        -work sgate           
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"         -work altera_mf       
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                    -work altera_mf       
  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS      "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                  -work altera_lnsim    
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"      -work altera_lnsim    
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/cycloneive_atoms.vhd"             -work cycloneive      
  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS          "$QUARTUS_INSTALL_DIR/eda/sim_lib/cycloneive_components.vhd"        -work cycloneive      
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/verbosity_pkg.sv"                                                                  -work altera_common_sv_packages
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/driver_definitions.sv"                                -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/addr_gen.sv"                                          -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/burst_boundary_addr_gen.sv"                           -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/lfsr.sv"                                              -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/lfsr_wrapper.sv"                                      -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/rand_addr_gen.sv"                                     -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/rand_burstcount_gen.sv"                               -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/rand_num_gen.sv"                                      -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/rand_seq_addr_gen.sv"                                 -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/reset_sync.v"                                                                      -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/scfifo_wrapper.sv"                                    -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/seq_addr_gen.sv"                                      -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/template_addr_gen.sv"                                 -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/template_stage.sv"                                    -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/driver_csr.sv"                                        -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/avalon_traffic_gen_avl_use_be_avl_use_burstbegin.sv"  -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/block_rw_stage_avl_use_be_avl_use_burstbegin.sv"      -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/driver_avl_use_be_avl_use_burstbegin.sv"              -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/driver_fsm_avl_use_be_avl_use_burstbegin.sv"          -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/read_compare_avl_use_be_avl_use_burstbegin.sv"        -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/single_rw_stage_avl_use_be_avl_use_burstbegin.sv"     -l altera_common_sv_packages -work traffic_generator_0      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed_emif_status_bridge.v"                                        -work status_bridge            
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed_emif_ctl.v"                                                  -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_addr_cmd.v"                                                           -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_addr_cmd_wrap.v"                                                      -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_arbiter.v"                                                            -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_buffer.v"                                                             -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_buffer_manager.v"                                                     -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_burst_gen.v"                                                          -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_burst_tracking.v"                                                     -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_cmd_gen.v"                                                            -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_controller.v"                                                         -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_controller_st_top.v"                                                  -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_csr.v"                                                                -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_dataid_manager.v"                                                     -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ddr2_odt_gen.v"                                                       -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ddr3_odt_gen.v"                                                       -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_decoder.v"                                                        -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_decoder_32_syn.v"                                                 -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_decoder_64_syn.v"                                                 -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_encoder.v"                                                        -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_encoder_32_syn.v"                                                 -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_encoder_64_syn.v"                                                 -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_ecc_encoder_decoder_wrapper.v"                                        -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_fifo.v"                                                               -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_input_if.v"                                                           -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_list.v"                                                               -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_lpddr2_addr_cmd.v"                                                    -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_mm_st_converter.v"                                                    -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_odt_gen.v"                                                            -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_rank_timer.v"                                                         -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_rdata_path.v"                                                         -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_rdwr_data_tmg.v"                                                      -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_sideband.v"                                                           -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_tbp.v"                                                                -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_timing_param.v"                                                       -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_ddrx_wdata_path.v"                                                         -work ctl                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed_emif_phy.v"                                                  -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_ac.v"                                                                  -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_addr_cmd.v"                                                            -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_clk_reset.v"                                                           -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_delay.v"                                                               -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_dp_io.v"                                                               -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_dqs_offset.v"                                                          -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_mimic.v"                                                               -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_mimic_debug.v"                                                         -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_mux.v"                                                                 -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_pll.v"                                                                 -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_postamble.v"                                                           -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_rdata_valid.v"                                                         -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_read_dp.v"                                                             -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_read_dp_group.v"                                                       -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_reset_pipe.v"                                                          -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_seq_wrapper.v"                                                         -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_write_dp.v"                                                            -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS {\"+incdir+$QSYS_SIMDIR/simulation/submodules/\"} "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_write_dp_fr.v"                                                         -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_constants_pkg.vhd"                                                     -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_record_pkg.vhd"                                                        -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_regs_pkg.vhd"                                                          -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_addr_cmd_pkg.vhd"                                                      -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_iram_addr_pkg.vhd"                                                     -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_admin.vhd"                                                             -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_ctrl.vhd"                                                              -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_dgrb.vhd"                                                              -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_dgwb.vhd"                                                              -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_iram_ram.vhd"                                                          -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_iram.vhd"                                                              -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_mmi.vhd"                                                               -work phy                      
  eval  vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                            "$QSYS_SIMDIR/simulation/submodules/alt_mem_phy_seq.vhd"                                                               -work phy                      
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed_tg.v"                                                        -work tg                       
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed_emif.v"                                                      -work emif                     
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/altera_avalon_reset_source.sv"                        -l altera_common_sv_packages -work global_reset             
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/altera_avalon_clock_source.sv"                        -l altera_common_sv_packages -work ref_clk                  
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/alt_mem_if_ddr2_mem_model_top_mem_if_dm_pins_en.sv"   -l altera_common_sv_packages -work mem_model                
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/alt_mem_if_common_ddr_mem_model_mem_if_dm_pins_en.sv" -l altera_common_sv_packages -work mem_model                
  eval  vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                        "$QSYS_SIMDIR/simulation/submodules/altera_mem_if_checker_no_ifdef_params.sv"             -l altera_common_sv_packages -work sim_checker              
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim_emif_ed.v"                                                           -work emif_ed                  
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/submodules/ed_sim_ed_sim.v"                                                                   -work ed_sim                   
  eval  vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS                                                   "$QSYS_SIMDIR/simulation/ed_sim.v"                                                                                                                    
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim +access +r -t ps $ELAB_OPTIONS -L work -L altera_common_sv_packages -L traffic_generator_0 -L status_bridge -L ctl -L phy -L tg -L emif -L global_reset -L ref_clk -L mem_model -L sim_checker -L emif_ed -L ed_sim -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneive $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with -dbg -O2 option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -dbg -O2 +access +r -t ps $ELAB_OPTIONS -L work -L altera_common_sv_packages -L traffic_generator_0 -L status_bridge -L ctl -L phy -L tg -L emif -L global_reset -L ref_clk -L mem_model -L sim_checker -L emif_ed -L ed_sim -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneive $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -dbg -O2
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                                         -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                                           -- Compile device library files"
  echo
  echo "com                                               -- Compile the design files in correct order"
  echo
  echo "elab                                              -- Elaborate top level design"
  echo
  echo "elab_debug                                        -- Elaborate the top level design with -dbg -O2 option"
  echo
  echo "ld                                                -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                                          -- Compile all the design files and elaborate the top level design with -dbg -O2"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                                    -- Top level module name."
  echo "                                                     For most designs, this should be overridden"
  echo "                                                     to enable the elab/elab_debug aliases."
  echo
  echo "SYSTEM_INSTANCE_NAME                              -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                                       -- Platform Designer base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR                               -- Quartus installation directory."
  echo
  echo "USER_DEFINED_COMPILE_OPTIONS                      -- User-defined compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_ELAB_OPTIONS                         -- User-defined elaboration options, added to elab/elab_debug aliases."
  echo
  echo "USER_DEFINED_VHDL_COMPILE_OPTIONS                 -- User-defined vhdl compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_VERILOG_COMPILE_OPTIONS              -- User-defined verilog compile options, added to com/dev_com aliases."
}
file_copy
h
