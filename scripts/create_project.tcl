# ─────────────────────────────────────────────────────────────────────────────
# Licence
# ─────────────────────────────────────────────────────────────────────────────

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "prj"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "build_project.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/"]"

# Create project
create_project ${_xil_proj_name_} ./ -part xc7a35tcpg236-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "digilentinc.com:basys3:part0:1.2" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "platform.board_id" -value "basys3" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "1" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
if { $obj != {} } {
   set_property "ip_repo_paths" "[file normalize "${origin_dir}/iprepo"]" $obj

   # Rebuild user ip_repo's index before adding any source files
   update_ip_catalog -rebuild
}

# Import local files from the original project
source "$origin_dir/scripts/modules.tcl"
import_files -fileset sources_1 $modules

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add/Import constrs file and set constrs file properties
set basys3_xdc "[file normalize ${origin_dir}/constraints/basys3_pins.xdc]"
import_files -fileset constrs_1 -force $basys3_xdc

set impl_opt_xdc "[file normalize ${origin_dir}/constraints/impl_opt.xdc]"
import_files -fileset constrs_1 -force $impl_opt_xdc

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# ─────────────────────────────────────────────────────────────────────────────
# Proc to create BD design_1
# ─────────────────────────────────────────────────────────────────────────────
proc cr_bd_design_1 { parentCell } {
  set design_name design_1

  common::send_gid_msg -ssname BD::TCL -id 2010 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  # Check IPs
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
    set list_check_ips "\ 
      DigiLAB:ip:AXI4Stream_UART:1.1\
      DigiLAB:ip:axi4stream_spi_master:1.0\
      xilinx.com:ip:axis_broadcaster:1.1\
      DigiLAB:ip:axis_dual_i2s:1.0\
      xilinx.com:ip:clk_wiz:6.0\
      xilinx.com:ip:axis_dwidth_converter:1.1\
      xilinx.com:ip:proc_sys_reset:5.0\
    "

    set list_ips_missing ""
    common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

    foreach ip_vlnv $list_check_ips {
        set ip_obj [get_ipdefs -all $ip_vlnv]
        if { $ip_obj eq "" } {
          lappend list_ips_missing $ip_vlnv
        }
    }

    if { $list_ips_missing ne "" } {
        catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
        set bCheckIPsPassed 0
    }

  }

  # Check Modules
  set bCheckModules 1
  if { $bCheckModules == 1 } {
    set list_check_mods "\ 
      binary_to_decimal\
      binary_to_decimal\
      digilent_jstk2\
      driver_4_7seg\
      effect_selector\
      led_level_controller\
      axis_fifo\
      depacketizer\
      float_compressor\
      send_controller\
      balance_controller\
      edge_detector_trigger\
      moving_average\
      output_sel\
      reverb\
      volume_controller\
    "

    set list_mods_missing ""
    common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

    foreach mod_vlnv $list_check_mods {
        if { [can_resolve_reference $mod_vlnv] == 0 } {
          lappend list_mods_missing $mod_vlnv
        }
    }

    if { $list_mods_missing ne "" } {
        catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
        common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
        set bCheckIPsPassed 0
    }
  }

  if { $bCheckIPsPassed != 1 } {
    common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  # ─────────────────────────────────────────────────────────────────────────────
  # Hierarchical Cell: reset
  # ─────────────────────────────────────────────────────────────────────────────
  proc create_hier_cell_reset { parentCell nameHier } {

    variable script_folder

    if { $parentCell eq "" || $nameHier eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_reset() - Empty argument(s)!"}
      return
    }

    # Get object for parentCell
    set parentObj [get_bd_cells $parentCell]
    if { $parentObj == "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
      return
    }

    # Make sure parentObj is hier blk
    set parentType [get_property TYPE $parentObj]
    if { $parentType ne "hier" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
      return
    }

    # Save current instance; Restore later
    set oldCurInst [current_bd_instance .]

    # Set parent object as current
    current_bd_instance $parentObj

    # Create cell and set as current instance
    set hier_obj [create_bd_cell -type hier $nameHier]
    current_bd_instance $hier_obj

    # Create interface pins

    # Create pins
    create_bd_pin -dir I -type clk clk_i2s
    create_bd_pin -dir I -type clk clk_out
    create_bd_pin -dir I -type clk clk_uart
    create_bd_pin -dir O -from 0 -to 0 -type rst i2s_aresetn
    create_bd_pin -dir I locked
    create_bd_pin -dir O -from 0 -to 0 -type rst out_aresetn
    create_bd_pin -dir I -type rst reset
    create_bd_pin -dir O -from 0 -to 0 -type rst uart_reset

    # Create instance: proc_sys_reset_clk_i2c, and set properties
    set proc_sys_reset_clk_i2c [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_clk_i2c ]
    set_property -dict [ list \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {false} \
    ] $proc_sys_reset_clk_i2c

    # Create instance: proc_sys_reset_clk_out, and set properties
    set proc_sys_reset_clk_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_clk_out ]
    set_property -dict [ list \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {false} \
    ] $proc_sys_reset_clk_out

    # Create instance: proc_sys_reset_clk_uart, and set properties
    set proc_sys_reset_clk_uart [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_clk_uart ]
    set_property -dict [ list \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {false} \
    ] $proc_sys_reset_clk_uart

    # Create port connections
    connect_bd_net -net clk_wiz_clk_i2s [get_bd_pins clk_i2s] [get_bd_pins proc_sys_reset_clk_i2c/slowest_sync_clk]
    connect_bd_net -net clk_wiz_clk_out [get_bd_pins clk_out] [get_bd_pins proc_sys_reset_clk_out/slowest_sync_clk]
    connect_bd_net -net clk_wiz_clk_uart [get_bd_pins clk_uart] [get_bd_pins proc_sys_reset_clk_uart/slowest_sync_clk]
    connect_bd_net -net clk_wiz_locked [get_bd_pins locked] [get_bd_pins proc_sys_reset_clk_i2c/dcm_locked] [get_bd_pins proc_sys_reset_clk_out/dcm_locked] [get_bd_pins proc_sys_reset_clk_uart/dcm_locked]
    connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins uart_reset] [get_bd_pins proc_sys_reset_clk_uart/peripheral_reset]
    connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins out_aresetn] [get_bd_pins proc_sys_reset_clk_out/peripheral_aresetn]
    connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins i2s_aresetn] [get_bd_pins proc_sys_reset_clk_i2c/peripheral_aresetn]
    connect_bd_net -net reset_1 [get_bd_pins reset] [get_bd_pins proc_sys_reset_clk_i2c/ext_reset_in] [get_bd_pins proc_sys_reset_clk_out/ext_reset_in] [get_bd_pins proc_sys_reset_clk_uart/ext_reset_in]

    # Restore current instance
    current_bd_instance $oldCurInst
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Hierarchical Cell: path_2
  # ─────────────────────────────────────────────────────────────────────────────
  proc create_hier_cell_path_2 { parentCell nameHier } {

    variable script_folder

    if { $parentCell eq "" || $nameHier eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_path_2() - Empty argument(s)!"}
      return
    }

    # Get object for parentCell
    set parentObj [get_bd_cells $parentCell]
    if { $parentObj == "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
      return
    }

    # Make sure parentObj is hier blk
    set parentType [get_property TYPE $parentObj]
    if { $parentType ne "hier" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
      return
    }

    # Save current instance; Restore later
    set oldCurInst [current_bd_instance .]

    # Set parent object as current
    current_bd_instance $parentObj

    # Create cell and set as current instance
    set hier_obj [create_bd_cell -type hier $nameHier]
    current_bd_instance $hier_obj

    # Create interface pins
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis


    # Create pins
    create_bd_pin -dir I -type clk aclk
    create_bd_pin -dir I -type rst aresetn
    create_bd_pin -dir I -from 9 -to 0 balance
    create_bd_pin -dir I btn_jstk
    create_bd_pin -dir I -from 9 -to 0 delay_in
    create_bd_pin -dir I enable_filter
    create_bd_pin -dir I enable_reverb
    create_bd_pin -dir I -from 9 -to 0 gain_in
    create_bd_pin -dir O -from 7 -to 0 led_b
    create_bd_pin -dir O -from 7 -to 0 led_g
    create_bd_pin -dir O -from 7 -to 0 led_r
    create_bd_pin -dir I -from 9 -to 0 volume

    # Create instance: balance_controller_0, and set properties
    set block_name balance_controller
    set block_cell_name balance_controller_0
    if { [catch {set balance_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $balance_controller_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create instance: edge_detector_trigger_0, and set properties
    set block_name edge_detector_trigger
    set block_cell_name edge_detector_trigger_0
    if { [catch {set edge_detector_trigger_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $edge_detector_trigger_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create instance: moving_average_0, and set properties
    set block_name moving_average
    set block_cell_name moving_average_0
    if { [catch {set moving_average_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $moving_average_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create instance: output_sel_0, and set properties
    set block_name output_sel
    set block_cell_name output_sel_0
    if { [catch {set output_sel_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $output_sel_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    set_property -dict [ list \
    CONFIG.LOWER_BOUND {-8388608} \
    ] $output_sel_0

    # Create instance: reverb_0, and set properties
    set block_name reverb
    set block_cell_name reverb_0
    if { [catch {set reverb_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $reverb_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    set_property -dict [ list \
    CONFIG.LOG2_DELAY_INCR {4} \
    CONFIG.LOWER_BOUND {-8388608} \
    ] $reverb_0

    # Create instance: volume_controller_0, and set properties
    set block_name volume_controller
    set block_cell_name volume_controller_0
    if { [catch {set volume_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $volume_controller_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    set_property -dict [ list \
    CONFIG.LOWER_BOUND {-8388608} \
    ] $volume_controller_0

    # Create interface connections
    connect_bd_intf_net -intf_net balance_controller_0_m_axis [get_bd_intf_pins balance_controller_0/m_axis] [get_bd_intf_pins volume_controller_0/s_axis]
    connect_bd_intf_net -intf_net moving_average_0_m_axis [get_bd_intf_pins moving_average_0/m_axis] [get_bd_intf_pins output_sel_0/s_axis]
    connect_bd_intf_net -intf_net output_sel_0_m_axis [get_bd_intf_pins balance_controller_0/s_axis] [get_bd_intf_pins output_sel_0/m_axis]
    connect_bd_intf_net -intf_net reverb_0_m_axis [get_bd_intf_pins moving_average_0/s_axis] [get_bd_intf_pins reverb_0/m_axis]
    connect_bd_intf_net -intf_net split_M00_AXIS [get_bd_intf_pins s_axis] [get_bd_intf_pins reverb_0/s_axis]
    connect_bd_intf_net -intf_net volume_controller_0_m_axis [get_bd_intf_pins m_axis] [get_bd_intf_pins volume_controller_0/m_axis]

    # Create port connections
    connect_bd_net -net clk_wiz_clk_out [get_bd_pins aclk] [get_bd_pins balance_controller_0/aclk] [get_bd_pins edge_detector_trigger_0/clk] [get_bd_pins moving_average_0/aclk] [get_bd_pins output_sel_0/aclk] [get_bd_pins reverb_0/aclk] [get_bd_pins volume_controller_0/aclk]
    connect_bd_net -net edge_detector_trigger_0_output_signal [get_bd_pins edge_detector_trigger_0/output_signal] [get_bd_pins output_sel_0/toggle]
    connect_bd_net -net effect_selector_0_balance [get_bd_pins balance] [get_bd_pins balance_controller_0/balance]
    connect_bd_net -net effect_selector_0_delay [get_bd_pins delay_in] [get_bd_pins reverb_0/delay_in]
    connect_bd_net -net effect_selector_0_gain [get_bd_pins gain_in] [get_bd_pins reverb_0/gain_in]
    connect_bd_net -net effect_selector_0_volume [get_bd_pins volume] [get_bd_pins volume_controller_0/volume]
    connect_bd_net -net enable_filter_1 [get_bd_pins enable_filter] [get_bd_pins moving_average_0/enable_filter]
    connect_bd_net -net enable_reverb_0_1 [get_bd_pins enable_reverb] [get_bd_pins reverb_0/enable_reverb]
    connect_bd_net -net input_signal_1 [get_bd_pins btn_jstk] [get_bd_pins edge_detector_trigger_0/input_signal]
    connect_bd_net -net output_sel_0_led_b [get_bd_pins led_b] [get_bd_pins output_sel_0/led_b]
    connect_bd_net -net output_sel_0_led_g [get_bd_pins led_g] [get_bd_pins output_sel_0/led_g]
    connect_bd_net -net output_sel_0_led_r [get_bd_pins led_r] [get_bd_pins output_sel_0/led_r]
    connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins balance_controller_0/aresetn] [get_bd_pins edge_detector_trigger_0/resetn] [get_bd_pins moving_average_0/aresetn] [get_bd_pins output_sel_0/aresetn] [get_bd_pins reverb_0/aresetn] [get_bd_pins volume_controller_0/aresetn]

    # Restore current instance
    current_bd_instance $oldCurInst
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Hierarchical Cell: path_1
  # ─────────────────────────────────────────────────────────────────────────────
  proc create_hier_cell_path_1 { parentCell nameHier } {

    variable script_folder

    if { $parentCell eq "" || $nameHier eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_path_1() - Empty argument(s)!"}
      return
    }

    # Get object for parentCell
    set parentObj [get_bd_cells $parentCell]
    if { $parentObj == "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
      return
    }

    # Make sure parentObj is hier blk
    set parentType [get_property TYPE $parentObj]
    if { $parentType ne "hier" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
      return
    }

    # Save current instance; Restore later
    set oldCurInst [current_bd_instance .]

    # Set parent object as current
    current_bd_instance $parentObj

    # Create cell and set as current instance
    set hier_obj [create_bd_cell -type hier $nameHier]
    current_bd_instance $hier_obj

    # Create interface pins
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis1


    # Create pins
    create_bd_pin -dir I -type clk aclk
    create_bd_pin -dir I -type rst aresetn
    create_bd_pin -dir O -from 6 -to 0 remaining_minutes
    create_bd_pin -dir O -from 6 -to 0 remaining_seconds

    # Create instance: axis_dwidth_converter_0, and set properties
    set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
    set_property -dict [ list \
    CONFIG.M_TDATA_NUM_BYTES {1} \
    ] $axis_dwidth_converter_0

    # Create instance: axis_fifo_0, and set properties
    set block_name axis_fifo
    set block_cell_name axis_fifo_0
    if { [catch {set axis_fifo_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $axis_fifo_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create instance: depacketizer_0, and set properties
    set block_name depacketizer
    set block_cell_name depacketizer_0
    if { [catch {set depacketizer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $depacketizer_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
      
    set_property -dict [ list \
    CONFIG.CLK_FREQ_HZ {200000000} \
    ] $depacketizer_0

    # Create instance: float_compressor_0, and set properties
    set block_name float_compressor
    set block_cell_name float_compressor_0
    if { [catch {set float_compressor_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $float_compressor_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create instance: send_controller_0, and set properties
    set block_name send_controller
    set block_cell_name send_controller_0
    if { [catch {set send_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $send_controller_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }
    
    # Create interface connections
    connect_bd_intf_net -intf_net AXI4Stream_UART_0_M00_AXIS_RX [get_bd_intf_pins s_axis1] [get_bd_intf_pins depacketizer_0/s_axis]
    connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins s_axis] [get_bd_intf_pins axis_fifo_0/s_axis]
    connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
    connect_bd_intf_net -intf_net float_compressor_0_m_axis [get_bd_intf_pins float_compressor_0/m_axis] [get_bd_intf_pins send_controller_0/s_axis]
    connect_bd_intf_net -intf_net send_controller_0_m_axis [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS] [get_bd_intf_pins send_controller_0/m_axis]
    connect_bd_intf_net -intf_net split_m_axis [get_bd_intf_pins axis_fifo_0/m_axis] [get_bd_intf_pins float_compressor_0/s_axis]

    # Create port connections
    connect_bd_net -net clk_wiz_clk_out [get_bd_pins aclk] [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins axis_fifo_0/aclk] [get_bd_pins depacketizer_0/aclk] [get_bd_pins float_compressor_0/aclk] [get_bd_pins send_controller_0/aclk]
    connect_bd_net -net depacketizer_0_remaining_minutes [get_bd_pins remaining_minutes] [get_bd_pins depacketizer_0/remaining_minutes]
    connect_bd_net -net depacketizer_0_remaining_seconds [get_bd_pins remaining_seconds] [get_bd_pins depacketizer_0/remaining_seconds]
    connect_bd_net -net depacketizer_0_send_audio [get_bd_pins depacketizer_0/send_audio] [get_bd_pins send_controller_0/send_audio]
    connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins axis_fifo_0/aresetn] [get_bd_pins depacketizer_0/aresetn] [get_bd_pins float_compressor_0/aresetn] [get_bd_pins send_controller_0/aresetn]

    # Restore current instance
    current_bd_instance $oldCurInst
  }

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set SPI_M_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 SPI_M_0 ]

  set usb_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart ]


  # Create ports
  set an [ create_bd_port -dir O -from 3 -to 0 an ]
  set dp [ create_bd_port -dir O dp ]
  set enable_filter [ create_bd_port -dir I enable_filter ]
  set enable_reverb [ create_bd_port -dir I enable_reverb ]
  set led [ create_bd_port -dir O -from 15 -to 0 led ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
    CONFIG.POLARITY {ACTIVE_HIGH} \
  ] $reset
  set rx_lrck_0 [ create_bd_port -dir O rx_lrck_0 ]
  set rx_mclk_0 [ create_bd_port -dir O rx_mclk_0 ]
  set rx_sclk_0 [ create_bd_port -dir O rx_sclk_0 ]
  set rx_sdin_0 [ create_bd_port -dir I rx_sdin_0 ]
  set seg [ create_bd_port -dir O -from 0 -to 6 seg ]
  set sys_clock [ create_bd_port -dir I -type clk -freq_hz 100000000 sys_clock ]
  set_property -dict [ list \
    CONFIG.PHASE {0.000} \
  ] $sys_clock
  set tx_lrck_0 [ create_bd_port -dir O tx_lrck_0 ]
  set tx_mclk_0 [ create_bd_port -dir O tx_mclk_0 ]
  set tx_sclk_0 [ create_bd_port -dir O tx_sclk_0 ]
  set tx_sdout_0 [ create_bd_port -dir O tx_sdout_0 ]

  # Create instance: AXI4Stream_UART_0, and set properties
  set AXI4Stream_UART_0 [ create_bd_cell -type ip -vlnv DigiLAB:ip:AXI4Stream_UART:1.1 AXI4Stream_UART_0 ]
  set_property -dict [ list \
    CONFIG.UART_BAUD_RATE {2000000} \
    CONFIG.UART_BOARD_INTERFACE {usb_uart} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $AXI4Stream_UART_0

  # Create instance: axi4stream_spi_master_0, and set properties
  set axi4stream_spi_master_0 [ create_bd_cell -type ip -vlnv DigiLAB:ip:axi4stream_spi_master:1.0 axi4stream_spi_master_0 ]
  set_property -dict [ list \
    CONFIG.c_clkfreq {200000000} \
    CONFIG.c_sclkfreq {5000} \
  ] $axi4stream_spi_master_0

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {0} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.M_TDATA_NUM_BYTES {3} \
    CONFIG.M_TUSER_WIDTH {0} \
    CONFIG.S_TDATA_NUM_BYTES {3} \
    CONFIG.S_TUSER_WIDTH {0} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
  ] $axis_broadcaster_0

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {0} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.M_TDATA_NUM_BYTES {3} \
    CONFIG.M_TUSER_WIDTH {0} \
    CONFIG.S_TDATA_NUM_BYTES {3} \
    CONFIG.S_TUSER_WIDTH {0} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
  ] $axis_broadcaster_1

  # Create instance: axis_dual_i2s_0, and set properties
  set axis_dual_i2s_0 [ create_bd_cell -type ip -vlnv DigiLAB:ip:axis_dual_i2s:1.0 axis_dual_i2s_0 ]

  # Create instance: binary_to_decimal_0, and set properties
  set block_name binary_to_decimal
  set block_cell_name binary_to_decimal_0
  if { [catch {set binary_to_decimal_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $binary_to_decimal_0 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }
  
  # Create instance: binary_to_decimal_1, and set properties
  set block_name binary_to_decimal
  set block_cell_name binary_to_decimal_1
  if { [catch {set binary_to_decimal_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $binary_to_decimal_1 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }
  
  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz ]
  set_property -dict [ list \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {143.752} \
    CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {64} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {178.715} \
    CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {22.579} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {114.829} \
    CONFIG.CLKOUT3_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {BUFG} \
    CONFIG.CLKOUT5_DRIVES {BUFG} \
    CONFIG.CLKOUT6_DRIVES {BUFG} \
    CONFIG.CLKOUT7_DRIVES {BUFG} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
    CONFIG.CLK_OUT1_PORT {clk_uart} \
    CONFIG.CLK_OUT2_PORT {clk_i2s} \
    CONFIG.CLK_OUT3_PORT {clk_out} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {15.625} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {44} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {5} \
    CONFIG.MMCM_COMPENSATION {ZHOLD} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $clk_wiz

  # Create instance: digilent_jstk2_0, and set properties
  set block_name digilent_jstk2
  set block_cell_name digilent_jstk2_0
  if { [catch {set digilent_jstk2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $digilent_jstk2_0 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }

  set_property -dict [ list \
    CONFIG.CLKFREQ {200000000} \
    CONFIG.SPI_SCLKFREQ {5000} \
  ] $digilent_jstk2_0

  # Create instance: driver_4_7seg_0, and set properties
  set block_name driver_4_7seg
  set block_cell_name driver_4_7seg_0
  if { [catch {set driver_4_7seg_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $driver_4_7seg_0 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }
  
  set_property -dict [ list \
    CONFIG.clock_period_ns {5} \
  ] $driver_4_7seg_0

  # Create instance: effect_selector_0, and set properties
  set block_name effect_selector
  set block_cell_name effect_selector_0
  if { [catch {set effect_selector_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $effect_selector_0 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }
  
  # Create instance: led_level_controller_0, and set properties
  set block_name led_level_controller
  set block_cell_name led_level_controller_0
  if { [catch {set led_level_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  } elseif { $led_level_controller_0 eq "" } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
    return 1
  }
  
  set_property -dict [ list \
    CONFIG.clock_period_ns {5} \
  ] $led_level_controller_0

  # Create instance: path_1
  create_hier_cell_path_1 [current_bd_instance .] path_1

  # Create instance: path_2
  create_hier_cell_path_2 [current_bd_instance .] path_2

  # Create instance: reset
  create_hier_cell_reset [current_bd_instance .] reset

  # Create interface connections
  connect_bd_intf_net -intf_net AXI4Stream_UART_0_M00_AXIS_RX [get_bd_intf_pins AXI4Stream_UART_0/M00_AXIS_RX] [get_bd_intf_pins path_1/s_axis1]
  connect_bd_intf_net -intf_net AXI4Stream_UART_0_UART [get_bd_intf_ports usb_uart] [get_bd_intf_pins AXI4Stream_UART_0/UART]
  connect_bd_intf_net -intf_net axi4stream_spi_master_0_M_AXIS [get_bd_intf_pins axi4stream_spi_master_0/M_AXIS] [get_bd_intf_pins digilent_jstk2_0/s_axis]
  connect_bd_intf_net -intf_net axi4stream_spi_master_0_SPI_M [get_bd_intf_ports SPI_M_0] [get_bd_intf_pins axi4stream_spi_master_0/SPI_M]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins path_1/s_axis]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M01_AXIS [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins axis_dual_i2s_0/s_axis]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M01_AXIS1 [get_bd_intf_pins axis_broadcaster_1/M01_AXIS] [get_bd_intf_pins led_level_controller_0/s_axis]
  connect_bd_intf_net -intf_net axis_dual_i2s_0_m_axis [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axis_dual_i2s_0/m_axis]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins AXI4Stream_UART_0/S00_AXIS_TX] [get_bd_intf_pins path_1/M_AXIS]
  connect_bd_intf_net -intf_net digilent_jstk2_0_m_axis [get_bd_intf_pins axi4stream_spi_master_0/S_AXIS] [get_bd_intf_pins digilent_jstk2_0/m_axis]
  connect_bd_intf_net -intf_net split_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins path_2/s_axis]
  connect_bd_intf_net -intf_net volume_controller_0_m_axis [get_bd_intf_pins axis_broadcaster_1/S_AXIS] [get_bd_intf_pins path_2/m_axis]

  # Create port connections
  connect_bd_net -net axis_dual_i2s_0_rx_lrck [get_bd_ports rx_lrck_0] [get_bd_pins axis_dual_i2s_0/rx_lrck]
  connect_bd_net -net axis_dual_i2s_0_rx_mclk [get_bd_ports rx_mclk_0] [get_bd_pins axis_dual_i2s_0/rx_mclk]
  connect_bd_net -net axis_dual_i2s_0_rx_sclk [get_bd_ports rx_sclk_0] [get_bd_pins axis_dual_i2s_0/rx_sclk]
  connect_bd_net -net axis_dual_i2s_0_tx_lrck [get_bd_ports tx_lrck_0] [get_bd_pins axis_dual_i2s_0/tx_lrck]
  connect_bd_net -net axis_dual_i2s_0_tx_mclk [get_bd_ports tx_mclk_0] [get_bd_pins axis_dual_i2s_0/tx_mclk]
  connect_bd_net -net axis_dual_i2s_0_tx_sclk [get_bd_ports tx_sclk_0] [get_bd_pins axis_dual_i2s_0/tx_sclk]
  connect_bd_net -net axis_dual_i2s_0_tx_sdout [get_bd_ports tx_sdout_0] [get_bd_pins axis_dual_i2s_0/tx_sdout]
  connect_bd_net -net binary_to_decimal_0_decade_digit [get_bd_pins binary_to_decimal_0/decade_digit] [get_bd_pins driver_4_7seg_0/num4]
  connect_bd_net -net binary_to_decimal_0_unit_digit [get_bd_pins binary_to_decimal_0/unit_digit] [get_bd_pins driver_4_7seg_0/num3]
  connect_bd_net -net binary_to_decimal_1_decade_digit [get_bd_pins binary_to_decimal_1/decade_digit] [get_bd_pins driver_4_7seg_0/num2]
  connect_bd_net -net binary_to_decimal_1_unit_digit [get_bd_pins binary_to_decimal_1/unit_digit] [get_bd_pins driver_4_7seg_0/num1]
  connect_bd_net -net clk_wiz_clk_i2s [get_bd_pins axis_dual_i2s_0/i2s_clk] [get_bd_pins clk_wiz/clk_i2s] [get_bd_pins reset/clk_i2s]
  connect_bd_net -net clk_wiz_clk_out [get_bd_pins AXI4Stream_UART_0/m00_axis_rx_aclk] [get_bd_pins AXI4Stream_UART_0/s00_axis_tx_aclk] [get_bd_pins axi4stream_spi_master_0/aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins axis_dual_i2s_0/aclk] [get_bd_pins binary_to_decimal_0/clk] [get_bd_pins binary_to_decimal_1/clk] [get_bd_pins clk_wiz/clk_out] [get_bd_pins digilent_jstk2_0/aclk] [get_bd_pins driver_4_7seg_0/clk] [get_bd_pins effect_selector_0/clk] [get_bd_pins led_level_controller_0/aclk] [get_bd_pins path_1/aclk] [get_bd_pins path_2/aclk] [get_bd_pins reset/clk_out]
  connect_bd_net -net clk_wiz_clk_uart [get_bd_pins AXI4Stream_UART_0/clk_uart] [get_bd_pins clk_wiz/clk_uart] [get_bd_pins reset/clk_uart]
  connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins reset/locked]
  connect_bd_net -net depacketizer_0_remaining_minutes [get_bd_pins binary_to_decimal_0/binary_num] [get_bd_pins path_1/remaining_minutes]
  connect_bd_net -net depacketizer_0_remaining_seconds [get_bd_pins binary_to_decimal_1/binary_num] [get_bd_pins path_1/remaining_seconds]
  connect_bd_net -net digilent_jstk2_0_btn_jstk [get_bd_pins digilent_jstk2_0/btn_jstk] [get_bd_pins path_2/btn_jstk]
  connect_bd_net -net digilent_jstk2_0_btn_trigger [get_bd_pins digilent_jstk2_0/btn_trigger] [get_bd_pins effect_selector_0/effect]
  connect_bd_net -net digilent_jstk2_0_jstk_x [get_bd_pins digilent_jstk2_0/jstk_x] [get_bd_pins effect_selector_0/jstck_x]
  connect_bd_net -net digilent_jstk2_0_jstk_y [get_bd_pins digilent_jstk2_0/jstk_y] [get_bd_pins effect_selector_0/jstck_y]
  connect_bd_net -net driver_4_7seg_0_an [get_bd_ports an] [get_bd_pins driver_4_7seg_0/an]
  connect_bd_net -net driver_4_7seg_0_dp [get_bd_ports dp] [get_bd_pins driver_4_7seg_0/dp]
  connect_bd_net -net driver_4_7seg_0_seg [get_bd_ports seg] [get_bd_pins driver_4_7seg_0/seg]
  connect_bd_net -net effect_selector_0_balance [get_bd_pins effect_selector_0/balance] [get_bd_pins path_2/balance]
  connect_bd_net -net effect_selector_0_delay [get_bd_pins effect_selector_0/delay] [get_bd_pins path_2/delay_in]
  connect_bd_net -net effect_selector_0_gain [get_bd_pins effect_selector_0/gain] [get_bd_pins path_2/gain_in]
  connect_bd_net -net effect_selector_0_volume [get_bd_pins effect_selector_0/volume] [get_bd_pins path_2/volume]
  connect_bd_net -net enable_filter_1 [get_bd_ports enable_filter] [get_bd_pins path_2/enable_filter]
  connect_bd_net -net enable_reverb_0_1 [get_bd_ports enable_reverb] [get_bd_pins path_2/enable_reverb]
  connect_bd_net -net led_level_controller_0_led [get_bd_ports led] [get_bd_pins led_level_controller_0/led]
  connect_bd_net -net output_sel_0_led_b [get_bd_pins digilent_jstk2_0/led_b] [get_bd_pins path_2/led_b]
  connect_bd_net -net output_sel_0_led_g [get_bd_pins digilent_jstk2_0/led_g] [get_bd_pins path_2/led_g]
  connect_bd_net -net output_sel_0_led_r [get_bd_pins digilent_jstk2_0/led_r] [get_bd_pins path_2/led_r]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins AXI4Stream_UART_0/rst] [get_bd_pins reset/uart_reset]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins AXI4Stream_UART_0/m00_axis_rx_aresetn] [get_bd_pins AXI4Stream_UART_0/s00_axis_tx_aresetn] [get_bd_pins axi4stream_spi_master_0/aresetn] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins axis_dual_i2s_0/aresetn] [get_bd_pins digilent_jstk2_0/aresetn] [get_bd_pins driver_4_7seg_0/resetn] [get_bd_pins effect_selector_0/resetn] [get_bd_pins led_level_controller_0/aresetn] [get_bd_pins path_1/aresetn] [get_bd_pins path_2/aresetn] [get_bd_pins reset/out_aresetn]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins axis_dual_i2s_0/i2s_resetn] [get_bd_pins reset/i2s_aresetn]
  connect_bd_net -net reset_2 [get_bd_ports reset] [get_bd_pins clk_wiz/reset] [get_bd_pins reset/reset]
  connect_bd_net -net rx_sdin_0_1 [get_bd_ports rx_sdin_0] [get_bd_pins axis_dual_i2s_0/rx_sdin]
  connect_bd_net -net sys_clock_1 [get_bd_ports sys_clock] [get_bd_pins clk_wiz/clk_in1]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_design_1()

cr_bd_design_1 ""
set_property REGISTERED_WITH_MANAGER "1" [get_files design_1.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files design_1.bd ] 

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part xc7a35tcpg236-1 -flow {Vivado Synthesis 2020} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2020" [get_runs synth_1]
}

set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj
# Create 'synth_1_synth_report_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0] "" ] } {
  create_report_config -report_name synth_1_synth_report_utilization_0 -report_type report_utilization:1.0 -steps synth_design -runs synth_1
}
set obj [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0]
if { $obj != "" } {

}
set obj [get_runs synth_1]
set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part xc7a35tcpg236-1 -flow {Vivado Implementation 2020} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2020" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj
# Create 'impl_1_init_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_init_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps init_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_opt_report_drc_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0] "" ] } {
  create_report_config -report_name impl_1_opt_report_drc_0 -report_type report_drc:1.0 -steps opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0]
if { $obj != "" } {

}
# Create 'impl_1_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_power_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps power_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_place_report_io_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0] "" ] } {
  create_report_config -report_name impl_1_place_report_io_0 -report_type report_io:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0]
if { $obj != "" } {

}
# Create 'impl_1_place_report_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0] "" ] } {
  create_report_config -report_name impl_1_place_report_utilization_0 -report_type report_utilization:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0]
if { $obj != "" } {

}
# Create 'impl_1_place_report_control_sets_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0] "" ] } {
  create_report_config -report_name impl_1_place_report_control_sets_0 -report_type report_control_sets:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0]
if { $obj != "" } {
set_property -name "options.verbose" -value "1" -objects $obj

}
# Create 'impl_1_place_report_incremental_reuse_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0] "" ] } {
  create_report_config -report_name impl_1_place_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_place_report_incremental_reuse_1' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1] "" ] } {
  create_report_config -report_name impl_1_place_report_incremental_reuse_1 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj

}
# Create 'impl_1_place_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_place_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps place_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_post_place_power_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_post_place_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_place_power_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_phys_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "is_enabled" -value "0" -objects $obj
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_route_report_drc_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0] "" ] } {
  create_report_config -report_name impl_1_route_report_drc_0 -report_type report_drc:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_methodology_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0] "" ] } {
  create_report_config -report_name impl_1_route_report_methodology_0 -report_type report_methodology:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_power_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0] "" ] } {
  create_report_config -report_name impl_1_route_report_power_0 -report_type report_power:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_route_status_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0] "" ] } {
  create_report_config -report_name impl_1_route_report_route_status_0 -report_type report_route_status:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_route_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0]
if { $obj != "" } {
set_property -name "options.max_paths" -value "10" -objects $obj

}
# Create 'impl_1_route_report_incremental_reuse_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0] "" ] } {
  create_report_config -report_name impl_1_route_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_clock_utilization_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0] "" ] } {
  create_report_config -report_name impl_1_route_report_clock_utilization_0 -report_type report_clock_utilization:1.0 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0]
if { $obj != "" } {

}
# Create 'impl_1_route_report_bus_skew_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0] "" ] } {
  create_report_config -report_name impl_1_route_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps route_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0]
if { $obj != "" } {
set_property -name "options.warn_on_violation" -value "1" -objects $obj

}
# Create 'impl_1_post_route_phys_opt_report_timing_summary_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0] "" ] } {
  create_report_config -report_name impl_1_post_route_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_route_phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0]
if { $obj != "" } {
set_property -name "options.max_paths" -value "10" -objects $obj
set_property -name "options.warn_on_violation" -value "1" -objects $obj

}
# Create 'impl_1_post_route_phys_opt_report_bus_skew_0' report (if not found)
if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0] "" ] } {
  create_report_config -report_name impl_1_post_route_phys_opt_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps post_route_phys_opt_design -runs impl_1
}
set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0]
if { $obj != "" } {
set_property -name "options.warn_on_violation" -value "1" -objects $obj

}
set obj [get_runs impl_1]
set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${_xil_proj_name_}"
# Create 'drc_1' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "drc_1" ] ] ""]} {
create_dashboard_gadget -name {drc_1} -type drc
}
set obj [get_dashboard_gadgets [ list "drc_1" ] ]
set_property -name "reports" -value "impl_1#impl_1_route_report_drc_0" -objects $obj

# Create 'methodology_1' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "methodology_1" ] ] ""]} {
create_dashboard_gadget -name {methodology_1} -type methodology
}
set obj [get_dashboard_gadgets [ list "methodology_1" ] ]
set_property -name "reports" -value "impl_1#impl_1_route_report_methodology_0" -objects $obj

# Create 'power_1' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "power_1" ] ] ""]} {
create_dashboard_gadget -name {power_1} -type power
}
set obj [get_dashboard_gadgets [ list "power_1" ] ]
set_property -name "reports" -value "impl_1#impl_1_route_report_power_0" -objects $obj

# Create 'timing_1' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "timing_1" ] ] ""]} {
create_dashboard_gadget -name {timing_1} -type timing
}
set obj [get_dashboard_gadgets [ list "timing_1" ] ]
set_property -name "reports" -value "impl_1#impl_1_route_report_timing_summary_0" -objects $obj

# Create 'utilization_1' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "utilization_1" ] ] ""]} {
create_dashboard_gadget -name {utilization_1} -type utilization
}
set obj [get_dashboard_gadgets [ list "utilization_1" ] ]
set_property -name "reports" -value "synth_1#synth_1_synth_report_utilization_0" -objects $obj
set_property -name "run.step" -value "synth_design" -objects $obj
set_property -name "run.type" -value "synthesis" -objects $obj

# Create 'utilization_2' gadget (if not found)
if {[string equal [get_dashboard_gadgets  [ list "utilization_2" ] ] ""]} {
create_dashboard_gadget -name {utilization_2} -type utilization
}
set obj [get_dashboard_gadgets [ list "utilization_2" ] ]
set_property -name "reports" -value "impl_1#impl_1_place_report_utilization_0" -objects $obj

move_dashboard_gadget -name {utilization_1} -row 0 -col 0
move_dashboard_gadget -name {power_1} -row 1 -col 0
move_dashboard_gadget -name {drc_1} -row 2 -col 0
move_dashboard_gadget -name {timing_1} -row 0 -col 1
move_dashboard_gadget -name {utilization_2} -row 1 -col 1
move_dashboard_gadget -name {methodology_1} -row 2 -col 1
