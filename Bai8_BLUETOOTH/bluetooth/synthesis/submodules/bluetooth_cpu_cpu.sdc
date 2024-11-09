# Legal Notice: (C)2024 Altera Corporation. All rights reserved.  Your
# use of Altera Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any
# output files any of the foregoing (including device programming or
# simulation files), and any associated documentation or information are
# expressly subject to the terms and conditions of the Altera Program
# License Subscription Agreement or other applicable license agreement,
# including, without limitation, that your use is for the sole purpose
# of programming logic devices manufactured by Altera and sold by Altera
# or its authorized distributors.  Please refer to the applicable
# agreement for further details.

#**************************************************************
# Timequest JTAG clock definition
#   Uncommenting the following lines will define the JTAG
#   clock in TimeQuest Timing Analyzer
#**************************************************************

#create_clock -period 10MHz {altera_reserved_tck}
#set_clock_groups -asynchronous -group {altera_reserved_tck}

#**************************************************************
# Set TCL Path Variables 
#**************************************************************

set 	bluetooth_cpu_cpu 	bluetooth_cpu_cpu:*
set 	bluetooth_cpu_cpu_oci 	bluetooth_cpu_cpu_nios2_oci:the_bluetooth_cpu_cpu_nios2_oci
set 	bluetooth_cpu_cpu_oci_break 	bluetooth_cpu_cpu_nios2_oci_break:the_bluetooth_cpu_cpu_nios2_oci_break
set 	bluetooth_cpu_cpu_ocimem 	bluetooth_cpu_cpu_nios2_ocimem:the_bluetooth_cpu_cpu_nios2_ocimem
set 	bluetooth_cpu_cpu_oci_debug 	bluetooth_cpu_cpu_nios2_oci_debug:the_bluetooth_cpu_cpu_nios2_oci_debug
set 	bluetooth_cpu_cpu_wrapper 	bluetooth_cpu_cpu_debug_slave_wrapper:the_bluetooth_cpu_cpu_debug_slave_wrapper
set 	bluetooth_cpu_cpu_jtag_tck 	bluetooth_cpu_cpu_debug_slave_tck:the_bluetooth_cpu_cpu_debug_slave_tck
set 	bluetooth_cpu_cpu_jtag_sysclk 	bluetooth_cpu_cpu_debug_slave_sysclk:the_bluetooth_cpu_cpu_debug_slave_sysclk
set 	bluetooth_cpu_cpu_oci_path 	 [format "%s|%s" $bluetooth_cpu_cpu $bluetooth_cpu_cpu_oci]
set 	bluetooth_cpu_cpu_oci_break_path 	 [format "%s|%s" $bluetooth_cpu_cpu_oci_path $bluetooth_cpu_cpu_oci_break]
set 	bluetooth_cpu_cpu_ocimem_path 	 [format "%s|%s" $bluetooth_cpu_cpu_oci_path $bluetooth_cpu_cpu_ocimem]
set 	bluetooth_cpu_cpu_oci_debug_path 	 [format "%s|%s" $bluetooth_cpu_cpu_oci_path $bluetooth_cpu_cpu_oci_debug]
set 	bluetooth_cpu_cpu_jtag_tck_path 	 [format "%s|%s|%s" $bluetooth_cpu_cpu_oci_path $bluetooth_cpu_cpu_wrapper $bluetooth_cpu_cpu_jtag_tck]
set 	bluetooth_cpu_cpu_jtag_sysclk_path 	 [format "%s|%s|%s" $bluetooth_cpu_cpu_oci_path $bluetooth_cpu_cpu_wrapper $bluetooth_cpu_cpu_jtag_sysclk]
set 	bluetooth_cpu_cpu_jtag_sr 	 [format "%s|*sr" $bluetooth_cpu_cpu_jtag_tck_path]

#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_keepers *$bluetooth_cpu_cpu_oci_break_path|break_readreg*] -to [get_keepers *$bluetooth_cpu_cpu_jtag_sr*]
set_false_path -from [get_keepers *$bluetooth_cpu_cpu_oci_debug_path|*resetlatch]     -to [get_keepers *$bluetooth_cpu_cpu_jtag_sr[33]]
set_false_path -from [get_keepers *$bluetooth_cpu_cpu_oci_debug_path|monitor_ready]  -to [get_keepers *$bluetooth_cpu_cpu_jtag_sr[0]]
set_false_path -from [get_keepers *$bluetooth_cpu_cpu_oci_debug_path|monitor_error]  -to [get_keepers *$bluetooth_cpu_cpu_jtag_sr[34]]
set_false_path -from [get_keepers *$bluetooth_cpu_cpu_ocimem_path|*MonDReg*] -to [get_keepers *$bluetooth_cpu_cpu_jtag_sr*]
set_false_path -from *$bluetooth_cpu_cpu_jtag_sr*    -to *$bluetooth_cpu_cpu_jtag_sysclk_path|*jdo*
set_false_path -from sld_hub:*|irf_reg* -to *$bluetooth_cpu_cpu_jtag_sysclk_path|ir*
set_false_path -from sld_hub:*|sld_shadow_jsm:shadow_jsm|state[1] -to *$bluetooth_cpu_cpu_oci_debug_path|monitor_go
