FPGA_CONFIG := fpga_config.sv
FPGA_TARGETS := $(shell awk '/^[ \t]*`define[ \t]+(ARTY_A7_35T|ARTY_A7_100T|GENESYS2|TANG_NANO_9K)([ \t]|$$)/ {print $$2}' $(FPGA_CONFIG))
FPGA_TARGET_COUNT := $(words $(FPGA_TARGETS))
FPGA_TARGET := $(firstword $(FPGA_TARGETS))

ifeq ($(FPGA_TARGET),TANG_NANO_9K)
	FPGA_FLOW := gaoyun
else
	FPGA_FLOW := xilinx
endif

.PHONY: fpga clean clean_all gen_ip clean_ip check_target

check_target:
	@if [ "$(FPGA_TARGET_COUNT)" -eq 0 ]; then \
		echo "ERROR: No FPGA target is defined in $(FPGA_CONFIG)."; \
		exit 1; \
	fi
	@if [ "$(FPGA_TARGET_COUNT)" -ne 1 ]; then \
		echo "ERROR: Multiple FPGA targets are defined in $(FPGA_CONFIG): $(FPGA_TARGETS)"; \
		exit 1; \
	fi

fpga: check_target
	$(MAKE) -C $(FPGA_FLOW) fpga

clean: check_target
	$(MAKE) -C $(FPGA_FLOW) clean

clean_all:
	$(MAKE) -C xilinx clean
	$(MAKE) -C gaoyun clean

gen_ip:
	$(MAKE) -C xilinx gen_ip

clean_ip:
	$(MAKE) -C xilinx clean_ip
