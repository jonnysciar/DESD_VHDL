ROOT := $(CURDIR)
BUILD_DIR := $(ROOT)/build
SCRIPT_DIR := $(ROOT)/scripts

# Vivado command line arguments
VIVADO := vivado -mode batch -notrace

# Time in seconds for recording audio
t ?= 10

.PHONY: project bitstream program record clean

all: project bitstream

project:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_project.tcl -tclargs --origin_dir $(ROOT)

bitstream:
	cd $(BUILD_DIR)/lab_solution && $(VIVADO) -source $(SCRIPT_DIR)/generate_bitstream.tcl

program:
	@echo "Scanning for connect Basys3 boards..."
	@echo "Programming the bitstream. Do not disconnect the device."

record:
	cd $(ROOT)/sw && python3 record.py -t $(t)

clean:
	rm -rf $(BUILD_DIR)
