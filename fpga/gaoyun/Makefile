GOWIN_HOME ?= /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA
GOWIN      ?= $(GOWIN_HOME)/IDE/bin/gw_sh

export DYLD_LIBRARY_PATH := $(GOWIN_HOME)/IDE/lib:$(DYLD_LIBRARY_PATH)
export DYLD_FRAMEWORK_PATH := $(GOWIN_HOME)/IDE/lib:$(DYLD_FRAMEWORK_PATH)

.PHONY: fpga clean

fpga:
	$(GOWIN) run.tcl
	$(GOWIN) build.tcl

clean:
	rm -rf output impl project 0_gowin_config.sv build_config.tcl *.log *.jou *.fs *.bin *.gprj *.gprj.user
