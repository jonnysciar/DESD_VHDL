ROOT := $(CURDIR)
BUILD_DIR := $(ROOT)/build
SCRIPT_DIR := $(ROOT)/scripts

PRJ_NAME := prj

# Vivado command line arguments
VIVADO := vivado -mode batch -notrace

# Time in seconds for recording audio
t ?= 10

.PHONY: project bitstream program record clean

all: project bitstream

project:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_project.tcl -tclargs --origin_dir $(ROOT) --project_name $(PRJ_NAME)

bitstream:
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/generate_bitstream.tcl

record:
	cd $(ROOT)/sw && python3 record.py -t $(t)

clean:
	rm -rf $(BUILD_DIR)
