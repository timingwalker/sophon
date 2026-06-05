GOWIN_HOME ?= /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA
GOWIN      ?= $(GOWIN_HOME)/IDE/bin/gw_sh

export DYLD_LIBRARY_PATH := $(GOWIN_HOME)/IDE/lib:$(DYLD_LIBRARY_PATH)
export DYLD_FRAMEWORK_PATH := $(GOWIN_HOME)/IDE/lib:$(DYLD_FRAMEWORK_PATH)

.PHONY: fpga smoke clean

fpga:
	$(GOWIN) run.tcl
	$(GOWIN) build.tcl

smoke:
	$(GOWIN) smoke.tcl

clean:
	rm -rf sophon_gaoyun_top impl project *.log *.jou *.fs *.bin *.gprj *.gprj.user
