
MEM_MODE := TCM

TC_TYPE := isa
#TC := rv32ui-p-addi
TC := rv32ui-p-sw

# TC_TYPE := benchmarks
# # TC := towers
# TC := multiply

# TC_TYPE := sanity-tests
# TC := clic_shv
# # TC := fgpio
# # TC := clic_no_shv
# # TC := clic_no_shv_snapreg

# TC_TYPE := app
# TC := fgpio_uart


TC_DIR := ../../sw/build
ifeq ($(TC_TYPE), sanity-tests)
	TC_HEX := $(TC_DIR)/$(TC_TYPE)/$(TC)/$(TC).hex
else ifeq ($(TC_TYPE), isa)
	TC_HEX := $(TC_DIR)/$(TC_TYPE)/$(TC).hex
else ifeq ($(TC_TYPE), benchmarks)
	TC_HEX := $(TC_DIR)/$(TC_TYPE)/$(TC).riscv.hex
else ifeq ($(TC_TYPE), app)
	TC_HEX := $(TC_DIR)/$(TC)/$(TC).hex
endif

# isa/benchmarks can use external memory if it is enabled
ifeq ($(TC_TYPE), isa)
	ifeq ($(MEM_MODE), EXT)
		LDS_FILE := ./../env/p/link_ext_mem.ld
	endif
endif
ifeq ($(TC_TYPE), benchmarks)
	ifeq ($(MEM_MODE), EXT)
		LDS_FILE := ./common/link_ext_mem.ld
	endif
endif


CMP_OPTIONS += -full64 -sverilog +v2k
CMP_OPTIONS += +libext+.v+.V+.sv+.svh 
CMP_OPTIONS += -kdb -lca
CMP_OPTIONS += -debug_all  +nbaopt +nospecify +notimingcheck  
CMP_OPTIONS += +acc 
CMP_OPTIONS += +vpi 
CMP_OPTIONS += -assert svaext 
CMP_OPTIONS += +vcs+lic+wait 
CMP_OPTIONS += -Mdir=csrc 
CMP_OPTIONS += -timescale=1ns/1ps 
CMP_OPTIONS += -P /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/novas_new_dumper.tab /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/pli.a 
CMP_OPTIONS += +vcsd 
CMP_OPTIONS += -l ./log/compile.log 
CMP_OPTIONS += -o simv 
CMP_OPTIONS += -j128 
# avoid spurious warnings of unique case(1'b1)
CMP_OPTIONS += -xlrm uniq_prior_final
CMP_DEBUG_OPTIONS += ./tb/jtag/SimJTAG.v
CMP_DEBUG_OPTIONS += ./tb/jtag/SimJTAG.cc
CMP_DEBUG_OPTIONS += ./tb/jtag/remote_bitbang.cc
CMP_DEBUG_OPTIONS += +define+DBG_ENABLE

SIM_OPTIONS += +vpi 
SIM_OPTIONS	+= +FSDB 
SIM_OPTIONS	+= +fsdb+struct 
SIM_OPTIONS	+= +MEM_MODE=$(MEM_MODE) 
SIM_OPTIONS	+= +TC_TYPE=$(TC_TYPE) 
SIM_OPTIONS	+= +TC_HEX=$(TC_HEX) 
SIM_OPTIONS	+= +TC=$(TC) 
SIM_OPTIONS	+= -l ./log/sim.log 



ifeq ($(TC_TYPE), app)
	SW_TARGET := $(TC)
else 
	SW_TARGET := $(TC_TYPE)
endif
compile_sw:
	$(MAKE) -C ../../sw clean_$(SW_TARGET)
	$(MAKE) -C ../../sw $(SW_TARGET) LDS_FILE=$(LDS_FILE)

compile_rtl:clean
	vcs  $(CMP_OPTIONS) -top tb -f ./tb.f 

compile_rtl_sw:compile_sw compile_rtl

sim:
	./simv $(SIM_OPTIONS)

vcs:compile_rtl_sw
	./simv $(SIM_OPTIONS)

debug:clean compile_sw
	vcs  $(CMP_OPTIONS) $(CMP_DEBUG_OPTIONS) -top tb -f ./tb.f 
	./simv $(SIM_OPTIONS)

clean:
	rm -rf csrc simv simv.daidir ucli.key vc_hdrs.h novas_dump.log *.fsdb novas* verdiLog signal.rc ./log/*.log stdout_uart

verdi:
	verdi -dbdir simv.daidir -ssf test.fsdb -sswr sophon.rc

regress_sw:
	cd ./regress && ./run_regress_sw.py

regress_hw:
	cd ./regress && ./run_regress_hw.py

regress_clean:
	rm -rf ./regress/log/* && rm -rf ./regress/*.result

help:                                    
	@echo   ===============================================================================
	@echo   " ------------------ Command -------------------------------------------------"
	@echo   " make compile_sw         : compile software                                  "
	@echo   " make compile_rtl        : compile rtl design                                "
	@echo   " make compile_rtl_sw     : compile software & rtl design                     "
	@echo   " make vcs                : compile software/rtl and run simulation           "
	@echo   " make debug              : compile with debug files and run simulation       "
	@echo   " make verdi              : check waveform                                    "
	@echo   " make regress_sw         : run regress test with current hw parameters       "
	@echo   " make regress_hw         : run regress test with each hw parameters          "
	@echo   " make regress_clean      : clean regress test log                            "
	@echo   " ------------------ Parameter -----------------------------------------------"
	@echo   " MEM_MODE = EXT | TCM    													  "
	@echo   "   >> compile/preload software with external memory or TCM memory            "
	@echo   ===============================================================================
	
.PHONY: compile_rtl compile_rtl_sw vcs debug clean verdi help
