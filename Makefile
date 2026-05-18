ROOT := $(CURDIR)
BUILD_DIR := $(ROOT)/build
SCRIPT_DIR := $(ROOT)/scripts

# Vivado command line arguments
VIVADO := vivado -mode batch -notrace

MODULES := $(shell cat module_config)

# Target DUT name for simulation flow (empty by default — must be provided when running)
TARGET ?=

# Time in seconds for recording audio
t ?= 10

.PHONY: all project bitstream open_gui sim record clean

all: project bitstream

test:
	@for MODULE in $(MODULES); do \
		cp hdl/ours/$$MODULE.vhd $(BUILD_DIR)/hdl
	done

project:
	mkdir -p $(BUILD_DIR)/hdl/tb
	cp hdl/archive_project_summary.txt $(BUILD_DIR)/hdl
	cp hdl/*.vhd $(BUILD_DIR)/hdl

	@for MODULE in $(MODULES); do \
		cp hdl/ours/$$MODULE.vhd $(BUILD_DIR)/hdl
	done
	
	cp hdl/tb/*.vhd $(BUILD_DIR)/hdl/tb
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_project.tcl -tclargs --origin_dir $(ROOT)

bitstream:
	cd $(BUILD_DIR)/lab_solution && $(VIVADO) -source $(SCRIPT_DIR)/generate_bitstream.tcl

open_gui:
	@if [ -z "$(TARGET)" ]; then \
		echo "Error: TARGET is not set. Run 'make open_gui TARGET=<name>'"; \
		exit 1; \
	fi; \
	if [ -d "$(BUILD_DIR)/$(TARGET)" ]; then \
		cd $(BUILD_DIR)/$(TARGET) && vivado $(TARGET).xpr; \
	else \
		echo "Error: $(BUILD_DIR)/$(TARGET) does not exist"; \
		exit 1; \
	fi

record:
	cd $(ROOT)/sw && python3 record.py -t $(t)

sim:
	@if [ -z "$(TARGET)" ]; then \
		echo "Error: TARGET is not set. Run 'make sim TARGET=<name>'"; \
		exit 1; \
	fi; \
	cd $(BUILD_DIR) && $(VIVADO) -source $(SCRIPT_DIR)/create_sim.tcl -tclargs --origin_dir $(ROOT) --target $(TARGET)

clean:
	rm -rf $(BUILD_DIR)
