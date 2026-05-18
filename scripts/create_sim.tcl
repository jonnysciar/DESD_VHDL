# create_sim.tcl
# Minimal Vivado Tcl script to create a simulation project

set origin_dir "."
set target ""

if { $::argc > 0 } {
    for {set i 0} {$i < $::argc} {incr i} {
        set option [string trim [lindex $::argv $i]]
        switch -regexp -- $option {
            "--origin_dir" { incr i; set origin_dir [lindex $::argv $i] }
            "--target" { incr i; set target [lindex $::argv $i] }
            default {
                if { [regexp {^-} $option] } {
                    puts "ERROR: Unknown option '$option' specified."
                    return 1
                }
            }
        }
    }
}

set build_dir "${origin_dir}/build"

# Create the project in the build directory
create_project -force ${target} ${build_dir}/${target} -part xc7a35tcpg236-1

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "digilentinc.com:basys3:part0:1.2" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj

# Add DUT design files
add_files -norecurse "${origin_dir}/hdl/ours/${target}.vhd"
set_property file_type VHDL [get_files "${origin_dir}/hdl/ours/${target}.vhd"]

# Add reference design files
add_files -norecurse "${origin_dir}/hdl/${target}.vhd"
set_property file_type VHDL [get_files "${origin_dir}/hdl/${target}.vhd"]

# Add the testbench file
# Note: we add it directly to the simulation fileset (sim_1)
add_files -fileset sim_1 -norecurse "${origin_dir}/hdl/tb/${target}_tb.vhd"
set_property file_type VHDL [get_files "${origin_dir}/hdl/tb/${target}_tb.vhd"]

# Set top entity for simulation
set_property top ${target}_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Simulation project created successfully in ${build_dir}/${target}"
