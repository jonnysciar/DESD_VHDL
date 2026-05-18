ROOT := $(CURDIR)
BUILD_DIR := $(ROOT)/build
SCRIPT_DIR := $(ROOT)/scripts

# Vivado command line arguments
VIVADO := vivado -mode batch -notrace

# Target DUT name for simulation flow
TARGET ?= led_level_controller

# Time in seconds for recording audio
t ?= 10

.PHONY: all project bitstream open_gui sim record clean

all: project bitstream

project:
	mkdir -p $(BUILD_DIR)/hdl/tb
	cp hdl/archive_project_summary.txt $(BUILD_DIR)/hdl
	cp hdl/*.vhd $(BUILD_DIR)/hdl
	cp hdl/ours/*.vhd $(BUILD_DIR)/hdl
	cp hdl/tb/*.vhd $(BUILD_DIR)/hdl/tb
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_project.tcl -tclargs --origin_dir $(ROOT)

bitstream:
	cd $(BUILD_DIR)/lab_solution && $(VIVADO) -source $(SCRIPT_DIR)/generate_bitstream.tcl

open_gui:
	cd $(BUILD_DIR)/$(TARGET) && vivado $(TARGET).xpr

record:
	cd $(ROOT)/sw && python3 record.py -t $(t)

sim:
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_sim.tcl -tclargs --origin_dir $(ROOT) --target $(TARGET)

clean:
	rm -rf $(BUILD_DIR)
