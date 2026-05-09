# Open the existing project 
open_project lab_solution.xpr

# Run Synthesis
puts "-----------------------------------------"
puts "          STARTING SYNTHESIS             "
puts "-----------------------------------------"
reset_run synth_1
# Change -jobs to the number of CPU cores you want to use
launch_runs synth_1 -jobs 4 
wait_on_run synth_1

# Check if synthesis succeeded before continuing
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed. Check the logs."
    exit 1
}

# Run Implementation and Bitstream Generation
puts "-----------------------------------------"
puts "   STARTING IMPLEMENTATION & BITSTREAM   "
puts "-----------------------------------------"
# The -to_step flag tells it to run all implementation steps AND generate the .bit file
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check if implementation succeeded
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation or Bitstream generation failed. Check the logs."
    exit 1
}

puts "-----------------------------------------"
puts "     BITSTREAM GENERATED SUCCESSFULLY!   "
puts "-----------------------------------------"
exit 0