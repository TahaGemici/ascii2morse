set top_module_name "morse_axi4lite"


# ==============================================================================
# PART 1: Scan and Add RTL Files
# ==============================================================================

set script_dir [file dirname [file normalize [info script]]]
cd $script_dir
puts "Working directory set to: $script_dir"

set rtl_dir "../rtl"
set project_name "test"
set project_dir "./vivado_project"
set part "xcku5p-ffvb676-2-e"
set board_part "xilinx.com:kcu116:part0:1.5"

if {[file exists $project_dir]} {
    puts "Removing existing project directory: $project_dir"
    file delete -force $project_dir
}

file mkdir $project_dir

create_project $project_name $project_dir -part $part -force
set_property board_part $board_part [current_project]

proc get_recursive_files { dir pattern } {
    # Find files in the current directory matching the pattern
    set files [glob -nocomplain -directory $dir -types f $pattern]
    
    # Find all subdirectories
    foreach subdir [glob -nocomplain -directory $dir -types d *] {
        # Recursively call this function for each subdirectory
        set files [concat $files [get_recursive_files $subdir $pattern]]
    }
    return $files
}

puts "--- Recursively scanning directory: $rtl_dir ---"

if {[file exists $rtl_dir]} {
    # Scan for .v and .sv files recursively
    set v_files  [get_recursive_files $rtl_dir "*.v"]
    set sv_files [get_recursive_files $rtl_dir "*.sv"]
    
    # Combine lists
    set all_files [concat $v_files $sv_files "testbench.sv"]

    if {[llength $all_files] > 0} {
        puts "Found [llength $all_files] files."
        
        # Add the found files to the project
        add_files $all_files
        
        # Refresh hierarchy
        update_compile_order -fileset sources_1
    } else {
        puts "WARNING: No .v or .sv files found in $rtl_dir or its subdirectories."
    }
} else {
    puts "ERROR: Directory $rtl_dir does not exist."
}

set_property top testbench [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# ==============================================================================
# PART 2: Build the VIP Block Design
# ==============================================================================

# 1. Create a new Block Design
create_bd_design "vip_test_system"

# 2. Add your RTL Module
# Now that files are added, Vivado can find '$top_module_name'
create_bd_cell -type module -reference $top_module_name dut

# 3. Add the AXI Verification IP (VIP)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_0

# 4. Configure the VIP: AXI4-Lite Protocol, Master Mode
set_property -dict [list \
  CONFIG.PROTOCOL {AXI4LITE} \
  CONFIG.INTERFACE_MODE {MASTER} \
] [get_bd_cells axi_vip_0]

# 5. Connect VIP Master to Slave
connect_bd_intf_net [get_bd_intf_pins axi_vip_0/M_AXI] [get_bd_intf_pins dut/interface_aximm]

# 6. Make Ports External
make_bd_pins_external [get_bd_pins axi_vip_0/aclk]
make_bd_pins_external [get_bd_pins axi_vip_0/aresetn]

# 7. Wire Clocks
connect_bd_net [get_bd_ports aclk_0] [get_bd_pins dut/aclk]
connect_bd_net [get_bd_ports aresetn_0] [get_bd_pins dut/aresetn]

# 8. Assign Address and Save
assign_bd_address
regenerate_bd_layout
validate_bd_design
save_bd_design

puts "--- Generating Output Products for Block Design ---"

# This generates the actual SystemVerilog files for the VIP that define the _pkg
generate_target simulation [get_files *.bd]

# This ensures the files are registered in the simulation fileset
export_ip_user_files -of_objects [get_files *.bd] -no_script -sync -force -quiet

puts "-----------------------------------------------------"
puts "SUCCESS: Files added from '../rtl' and Block Design created."
puts "-----------------------------------------------------"

# ==============================================================================
# PART 3: Generate the HDL Wrapper
# ==============================================================================
puts "--- Generating HDL Wrapper for Block Design ---"

# 1. Generate the wrapper file
make_wrapper -files [get_files */vip_test_system.bd] -top

# 2. Add the wrapper to the project so the simulation can find it
set wrapper_path "${project_dir}/${project_name}.gen/sources_1/bd/vip_test_system/hdl/vip_test_system_wrapper.v"

# 3. Add the file (with error checking)
if {[file exists $wrapper_path]} {
    add_files -norecurse $wrapper_path
    puts "SUCCESS: Added wrapper file: $wrapper_path"
} else {
    puts "ERROR: Could not find wrapper at $wrapper_path"
    # Fallback: Try to find it anywhere in the project directory
    set fallback_search [glob -nocomplain -directory $project_dir -types f "**/vip_test_system_wrapper.v"]
    if {[llength $fallback_search] > 0} {
         add_files -norecurse [lindex $fallback_search 0]
         puts "SUCCESS: Found and added wrapper via fallback search."
    }
}

# 4. Update hierarchy to set the wrapper as Top
update_compile_order -fileset sources_1
set_property top vip_test_system_wrapper [current_fileset]
update_compile_order -fileset sim_1
close_bd_design [get_bd_designs vip_test_system]
launch_simulation
if {[file exists "testbench.wcfg"]} {
    open_wave_config "testbench.wcfg"
}
run all