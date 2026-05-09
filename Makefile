ROOT := $(CURDIR)
BUILD_DIR := $(ROOT)/build
SCRIPT_DIR := $(ROOT)/scripts

# Vivado command line arguments
VIVADO := vivado -mode batch -notrace

.PHONY: all project bitstream open_gui clean

all: project bitstream

project:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/build_project.tcl -tclargs --origin_dir $(ROOT)

bitstream:
	cd $(BUILD_DIR)/lab_solution && $(VIVADO) -source $(SCRIPT_DIR)/generate_bitstream.tcl

open_gui:
	cd $(BUILD_DIR)/lab_solution && vivado lab_solution.xpr

clean:
	rm -rf $(BUILD_DIR)