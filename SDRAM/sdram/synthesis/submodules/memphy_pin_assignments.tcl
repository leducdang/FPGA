# (C) 2001-2022 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License Subscription 
# Agreement, Intel FPGA IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Intel and sold by 
# Intel or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


# -------------------------------------------------------------------------
#
# ALTMEMPHY v18.1 DDR2 SDRAM pin constraints script for amp
#
# Please run this script before compiling your design
#
# Directions: If your top level pin names do not match the default names, 
#             you should change the variables below to make the constraints 
#             match the specific pin names in your top level design.
#
# --------------------------------------------------------------------------

set available_options {
	{ c.arg "#_ignore_#" "Option to specify the revision name" }
}
package require cmdline

set script_dir [file dirname [info script]]

set tag_name "memphy_pin_assignments"

#################
#               #
# SETUP SECTION #
#               #
#################

# Check arguments
# Need to define argv for the cmdline package to work
global options
set argument_list $quartus(args)
set argv0 "quartus_sta -t [info script]"
set usage "\[<options>\] <project_name>:"

# Use cmdline package to parse options
if [catch {array set options [cmdline::getoptions argument_list $::available_options]} result] {
	if {[llength $argument_list] > 0 } {
		# This is not a simple -? or -help but an actual error condition
		post_message -type error "Illegal Options"
		post_message -type error  [::cmdline::usage $::available_options $usage]
		qexit -error
	} else {
		post_message -type info  "Usage:"
		post_message -type info  [::cmdline::usage $::available_options $usage]
		qexit -success
	}
}
if {$options(c) != "#_ignore_#"} {
	if [string compare [file extension $options(c)] ""] {
		set options(c) [file rootname $options(c)]
	}
}

# cmdline::getoptions is going to modify the argument_list.
# Note however that the function will ignore any positional arguments
# We are only expecting one and only one positional argument (the project)
# so give an error if the list has more than one element
if {[llength $argument_list] == 1 } {
	# The first argument MUST be the project name
	set options(project_name) [lindex $argument_list 0]

	if [string compare [file extension $options(project_name)] ""] {
		set project_name [file rootname $options(project_name)]
	}

	set project_name [file normalize $options(project_name)]

} elseif { [llength $argument_list] == 2 } {
	# The first argument MUST be the project name
	set options(project_name) [lindex $argument_list 0]
	set options(rev)          [lindex $argument_list 1]

	if [string compare [file extension $options(project_name)] ""] {
		set project_name [file rootname $options(project_name)]
	}
	if [string compare [file extension $options(c)] ""] {
		set revision_name [file rootname $options(c)]
	}

	set project_name [file normalize $options(project_name)]
	set revision_name [file normalize $options(rev)]

} elseif { [ is_project_open ] } {
	set project_name $::quartus(project)
	set options(rev) $::quartus(settings)

} else {
	post_message -type error "Project name is missing"
	post_message -type info [::cmdline::usage $::available_options $usage]
	post_message -type info "For more details, use \"quartus_sta --help\""
	qexit -error
}

# If this script is called from outside quartus_sta, it will re-launch itself in quartus_sta
if { ![info exists quartus(nameofexecutable)] || $quartus(nameofexecutable) != "quartus_sta" } {
	post_message -type info "Restarting in quartus_sta..."

	set cmd quartus_sta
	if { [info exists quartus(binpath)] } {
		set cmd [file join $quartus(binpath) $cmd]
	}

	if { [ is_project_open ] } {
		set project_name [ get_current_revision ]
	} elseif { ! [ string compare $project_name "" ] } {
		post_message -type error "Missing project_name argument"

		return 1
	}

	set output [ exec $cmd -t [ info script ] $project_name ]

	foreach line [split $output \n] {
		set type info
		set matched_line [ regexp {^\W*(Info|Extra Info|Warning|Critical Warning|Error): (.*)$} $line x type msg ]
		regsub " " $type _ type

		if { $matched_line } {
			post_message -type $type $msg
		} else {
			puts "$line"
		}
	}

	return 0
}

source "$script_dir/memphy_pins.tcl"
source "$script_dir/params.tcl"

if { ! [ is_project_open ] } {
	if { ! [ string compare $project_name "" ] } {
		post_message -type error "Missing project_name argument"

		return 1
	}

	if {$options(c) == "#_ignore_#"} {
		project_open $project_name
	} else {
		project_open $project_name -revision $options(c)
	}

}

##############################
# Clean up stale assignments #
##############################
post_message -type info "Cleaning up stale assignments..."

set asgn_types [ list IO_STANDARD INPUT_TERMINATION OUTPUT_TERMINATION CURRENT_STRENGTH_NEW DQ_GROUP TERMINATION_CONTROL_BLOCK ]
foreach asgn_type $asgn_types {
	remove_all_instance_assignments -tag __$tag_name -name $asgn_type
}

#if { ! [ timing_netlist_exist ] } {
#	create_timing_netlist -post_map
#}

#######################
#                     #
# ASSIGNMENTS SECTION #
#                     #
#######################

# Change sopc_mode value from NO to YES to create assignments that match the
# SOPC Builder top level pin names
if {![info exists sopc_mode]} {set sopc_mode NO}

# This is the name of your controller instance
set instance_name ""

# This is the prefix for all pin names. Change it if you wish to choose
# a prefix other than mem_mem_
if {![info exists pin_prefix]} {set pin_prefix "mem_mem_"}

# In SOPC builder, the pin names will be expanded as follow:
#    Example: mem_cs_n_from_the_<your instance name>
#
# In standalone mode, the pin names will be expanded as follow:
#    Example: mem_cs_n[0]

set mem_odt_pin_name ${pin_prefix}odt
set mem_odt_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_odt_IO_STANDARD "SSTL-18 CLASS I"

set mem_clk_pin_name ${pin_prefix}ck
set mem_clk_CURRENT_STRENGTH_NEW "12MA"
set mem_clk_PAD_TO_CORE_DELAY "0"
set mem_clk_IO_STANDARD "SSTL-18 CLASS I"

set mem_clk_n_pin_name ${pin_prefix}ck_n
set mem_clk_n_CURRENT_STRENGTH_NEW "12MA"
set mem_clk_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_cs_n_pin_name ${pin_prefix}cs_n
set mem_cs_n_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_cs_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_cke_pin_name ${pin_prefix}cke
set mem_cke_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_cke_IO_STANDARD "SSTL-18 CLASS I"

set mem_addr_pin_name ${pin_prefix}a
set mem_addr_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_addr_IO_STANDARD "SSTL-18 CLASS I"

set mem_ba_pin_name ${pin_prefix}ba
set mem_ba_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_ba_IO_STANDARD "SSTL-18 CLASS I"

set mem_ras_n_pin_name ${pin_prefix}ras_n
set mem_ras_n_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_ras_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_cas_n_pin_name ${pin_prefix}cas_n
set mem_cas_n_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_cas_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_we_n_pin_name ${pin_prefix}we_n
set mem_we_n_CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"
set mem_we_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_dq_pin_name ${pin_prefix}dq
set mem_dq_CURRENT_STRENGTH_NEW "12MA"
set mem_dq_IO_STANDARD "SSTL-18 CLASS I"

set mem_dqs_pin_name ${pin_prefix}dqs
set mem_dqs_CURRENT_STRENGTH_NEW "12MA"
set mem_dqs_IO_STANDARD "SSTL-18 CLASS I"

set mem_dqs_n_pin_name ${pin_prefix}dqs_n
set mem_dqs_n_CURRENT_STRENGTH_NEW "12MA"
set mem_dqs_n_IO_STANDARD "SSTL-18 CLASS I"

set mem_dm_pin_name ${pin_prefix}dm
set mem_dm_CURRENT_STRENGTH_NEW "12MA"
set mem_dm_IO_STANDARD "SSTL-18 CLASS I"

# Do not make any changes after this line
# ------------------------------------------------

# This single_bit variable is to define whether a [0] index will be added at the end of a single-bit bus pin name
# To not have indexing, replace [0] by "".
set single_bit {}

switch $sopc_mode {
  YES {
    set output_suffix _from_the_${instance_name}
    set bidir_suffix _to_and_from_the_${instance_name}
    set input_suffix _to_the_${instance_name}
  }
  default {
    set output_suffix ""
    set bidir_suffix ""
    set input_suffix ""
  }
}

set delay_chain_config "Flexible_timing"

if {![info exists ::ppl_instance_name]} {set ::ppl_instance_name {}}

set mem_odt_pin_name ${::ppl_instance_name}${mem_odt_pin_name}${output_suffix}
set mem_clk_pin_name ${::ppl_instance_name}${mem_clk_pin_name}${bidir_suffix}
set mem_clk_n_pin_name ${::ppl_instance_name}${mem_clk_n_pin_name}${bidir_suffix}
set mem_cs_n_pin_name ${::ppl_instance_name}${mem_cs_n_pin_name}${output_suffix}
set mem_cke_pin_name ${::ppl_instance_name}${mem_cke_pin_name}${output_suffix}
set mem_addr_pin_name ${::ppl_instance_name}${mem_addr_pin_name}${output_suffix}
set mem_ba_pin_name ${::ppl_instance_name}${mem_ba_pin_name}${output_suffix}
set mem_ras_n_pin_name ${::ppl_instance_name}${mem_ras_n_pin_name}${output_suffix}
set mem_cas_n_pin_name ${::ppl_instance_name}${mem_cas_n_pin_name}${output_suffix}
set mem_we_n_pin_name ${::ppl_instance_name}${mem_we_n_pin_name}${output_suffix}
set mem_dq_pin_name ${::ppl_instance_name}${mem_dq_pin_name}${bidir_suffix}
set mem_dqs_pin_name ${::ppl_instance_name}${mem_dqs_pin_name}${bidir_suffix}
set mem_dqs_n_pin_name ${::ppl_instance_name}${mem_dqs_n_pin_name}${bidir_suffix}
set mem_dm_pin_name ${::ppl_instance_name}${mem_dm_pin_name}${output_suffix}



set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[0]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[0]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[1]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[1]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[2]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[2]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[3]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[3]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[4]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[4]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[5]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[5]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[6]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[6]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[7]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[7]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[8]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[8]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[9]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[9]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[10]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[10]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[11]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[11]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_addr_IO_STANDARD}" -to ${mem_addr_pin_name}[12]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_addr_CURRENT_STRENGTH_NEW}" -to ${mem_addr_pin_name}[12]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_ba_IO_STANDARD}" -to ${mem_ba_pin_name}[0]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_ba_CURRENT_STRENGTH_NEW}" -to ${mem_ba_pin_name}[0]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_ba_IO_STANDARD}" -to ${mem_ba_pin_name}[1]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_ba_CURRENT_STRENGTH_NEW}" -to ${mem_ba_pin_name}[1]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_cs_n_IO_STANDARD}" -to ${mem_cs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_cs_n_CURRENT_STRENGTH_NEW}" -to ${mem_cs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_odt_IO_STANDARD}" -to ${mem_odt_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_odt_CURRENT_STRENGTH_NEW}" -to ${mem_odt_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_cke_IO_STANDARD}" -to ${mem_cke_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_cke_CURRENT_STRENGTH_NEW}" -to ${mem_cke_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_ras_n_IO_STANDARD}" -to ${mem_ras_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_ras_n_CURRENT_STRENGTH_NEW}" -to ${mem_ras_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_cas_n_IO_STANDARD}" -to ${mem_cas_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_cas_n_CURRENT_STRENGTH_NEW}" -to ${mem_cas_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_we_n_IO_STANDARD}" -to ${mem_we_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_we_n_CURRENT_STRENGTH_NEW}" -to ${mem_we_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[0]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[0]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[0]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[0]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[1]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[1]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[1]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[1]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[2]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[2]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[2]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[2]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[3]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[3]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[3]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[3]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[4]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[4]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[4]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[4]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[5]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[5]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[5]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[5]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[6]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[6]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[6]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[6]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dq_IO_STANDARD}" -to ${mem_dq_pin_name}[7]
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dq_CURRENT_STRENGTH_NEW}" -to ${mem_dq_pin_name}[7]
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dq_pin_name}[7]
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dq_pin_name}[7]
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dm_IO_STANDARD}" -to ${mem_dm_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dm_CURRENT_STRENGTH_NEW}" -to ${mem_dm_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dm_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dm_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dqs_IO_STANDARD}" -to ${mem_dqs_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dqs_CURRENT_STRENGTH_NEW}" -to ${mem_dqs_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dqs_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dqs_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_dqs_n_IO_STANDARD}" -to ${mem_dqs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_dqs_n_CURRENT_STRENGTH_NEW}" -to ${mem_dqs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name MEM_INTERFACE_DELAY_CHAIN_CONFIG "${delay_chain_config}" -to ${mem_dqs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name OUTPUT_ENABLE_GROUP "96708" -to ${mem_dqs_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_clk_IO_STANDARD}" -to ${mem_clk_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_clk_CURRENT_STRENGTH_NEW}" -to ${mem_clk_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name PAD_TO_CORE_DELAY "${mem_clk_PAD_TO_CORE_DELAY}" -to ${mem_clk_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CKN_CK_PAIR ON -from ${mem_clk_n_pin_name}${single_bit} -to ${mem_clk_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name IO_STANDARD "${mem_clk_n_IO_STANDARD}" -to ${mem_clk_n_pin_name}${single_bit}
set_instance_assignment -tag __$tag_name -name CURRENT_STRENGTH_NEW "${mem_clk_n_CURRENT_STRENGTH_NEW}" -to ${mem_clk_n_pin_name}${single_bit}

unset pin_prefix
