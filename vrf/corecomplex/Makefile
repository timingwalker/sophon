
#TC := rv32ui-p-addi
#TC := tc_clint
TC := median

MEM_MODE  ?= TCM
LDS_FILE  ?= link.ld
MARCH     ?= rv32ia
MABI      ?= ilp32
SW_DEFINE ?= -D__RV32E=0


ifneq ($(filter rv32%,$(TC)),)
    TC_TYPE := isa
    TC_HEX  := ../../sw/build/isa/$(TC).hex
else
    TC_TYPE := app
    TC_HEX  := ../../sw/build/$(TC)/$(TC).hex
endif

# ----------------------------------------------------------------------
#  read hardware parameter
# ----------------------------------------------------------------------
CFG_FILE := ../../design/config/config_feature.sv

SOPHON_CLIC     := NONE
SOPHON_RVE      := NONE
SOPHON_ZICSR    := NONE

SOPHON_EEI      := NONE
SOPHON_EEI_GPIO := NONE
SOPHON_EEI_SREG := NONE

ifneq ($(shell grep "^[\ ]*\`define SOPHON_CLIC[\ ]*$$" $(CFG_FILE)),)
    SOPHON_CLIC := YES
endif
ifneq ($(shell grep "^[\ ]*\`define SOPHON_RVE[\ ]*$$" $(CFG_FILE)),)
    SOPHON_RVE := YES
endif
ifneq ($(shell grep "^[\ ]*\`define SOPHON_ZICSR[\ ]*$$" $(CFG_FILE)),)
    SOPHON_ZICSR := YES
endif
ifneq ($(shell grep "^[\ ]*\`define SOPHON_EEI[\ ]*$$" $(CFG_FILE)),)
    SOPHON_EEI := YES
endif
ifneq ($(shell grep "^[\ ]*\`define SOPHON_EEI_GPIO[\ ]*$$" $(CFG_FILE)),)
    SOPHON_EEI_GPIO := YES
endif
ifneq ($(shell grep "^[\ ]*\`define SOPHON_EEI_SREG[\ ]*$$" $(CFG_FILE)),)
    SOPHON_EEI_SREG := YES
endif

print_hw_para:
	@echo SOPHON_EEI=$(SOPHON_EEI)
	@echo SOPHON_EEI_GPIO=$(SOPHON_EEI_GPIO)
	@echo SOPHON_EEI_SREG=$(SOPHON_EEI_SREG)
	@echo SOPHON_CLIC=$(SOPHON_CLIC)
	@echo SOPHON_RVE=$(SOPHON_RVE)
	@echo SOPHON_ZICSR=$(SOPHON_ZICSR)
	@echo SW_DEFINE=$(SW_DEFINE)
.PHONY: print_hw_para

# ----------------------------------------------------------------------
#  check testcase requirements
# ----------------------------------------------------------------------
TC_SKIP   := 0
SKIP_INFO := "TC SKIP!"

ifeq ($(TC),tc_fgpio)
    ifneq ($(SOPHON_EEI), YES)
        TC_SKIP   := 1
        SKIP_INFO := "TC SKIP! Check hardware parameter SOPHON_EEI!"
    endif
    ifneq ($(SOPHON_EEI_GPIO), YES)
        TC_SKIP   := 1
        SKIP_INFO += "TC SKIP! Check hardware parameter SOPHON_EEI_GPIO!"
    endif
endif

ifeq ($(TC),tc_clic)
    ifneq ($(SOPHON_EEI), YES)
        TC_SKIP   := 1
        SKIP_INFO := "TC SKIP! Check hardware parameter SOPHON_EEI!"
    endif
    ifneq ($(SOPHON_CLIC), YES)
        TC_SKIP   := 1
        SKIP_INFO += "TC SKIP! Check hardware parameter SOPHON_CLIC!"
    endif
    ifneq ($(SOPHON_EEI_SREG), YES)
        TC_SKIP   := 1
        SKIP_INFO += "TC SKIP! Check hardware parameter SOPHON_EEI_SREG!"
    endif
endif


# ----------------------------------------------------------------------
#  compile software
# ----------------------------------------------------------------------
ifeq ($(MEM_MODE), EXT)
    LDS_FILE := link_ext_mem.ld
endif

ifeq ($(SOPHON_RVE), YES)
    MARCH     := rv32e
    MABI      := ilp32e 
    SW_DEFINE := -D__RV32E=1
endif
ifeq ($(SOPHON_ZICSR), YES)
    SW_DEFINE += -D__RVZICSR=1
endif

ifeq ($(TC_TYPE), app)
    SW_TARGET := $(TC)
else 
    SW_TARGET := $(TC_TYPE)
endif
compile_sw:
	$(MAKE) -C ../../sw clean_$(SW_TARGET)
	$(MAKE) -C ../../sw $(SW_TARGET) LDS_FILE=$(LDS_FILE) MARCH=$(MARCH) MABI=$(MABI) DEFINE="$(SW_DEFINE)"

# ----------------------------------------------------------------------
#  compile rtl
# ----------------------------------------------------------------------
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
CMP_OPTIONS += -xlrm uniq_prior_final
CMP_DEBUG_OPTIONS += ./tb/jtag/SimJTAG.v
CMP_DEBUG_OPTIONS += ./tb/jtag/SimJTAG.cc
CMP_DEBUG_OPTIONS += ./tb/jtag/remote_bitbang.cc
CMP_DEBUG_OPTIONS += +define+DBG_ENABLE

compile_rtl:clean
	vcs  $(CMP_OPTIONS) -top tb -f ./tb.f 
	#vcs  $(CMP_OPTIONS) -top SOPHON_TOP -f ../../flist/sophon_top.f
	#vcs  $(CMP_OPTIONS) -top SOPHON_AXI_TOP -f ../../flist/sophon_axi_top.f

# ----------------------------------------------------------------------
#  simulation
# ----------------------------------------------------------------------

compile_rtl_sw:compile_sw compile_rtl

SIM_OPTIONS += +vpi 
SIM_OPTIONS	+= +FSDB 
SIM_OPTIONS	+= +fsdb+struct 
SIM_OPTIONS	+= +MEM_MODE=$(MEM_MODE) 
SIM_OPTIONS	+= +TC_TYPE=$(TC_TYPE) 
SIM_OPTIONS	+= +TC_HEX=$(TC_HEX) 
SIM_OPTIONS	+= +TC=$(TC) 
SIM_OPTIONS	+= -l ./log/sim.log 

ifeq ($(TC_SKIP),1)
sim:
	@echo $(SKIP_INFO) | tee ./log/sim.log
vcs:
	@echo $(SKIP_INFO) | tee ./log/sim.log
else
sim:
	@echo "TC RUN!"; 
	./simv $(SIM_OPTIONS)
vcs:compile_rtl_sw
	@echo "TC RUN!"; 
	./simv $(SIM_OPTIONS)
endif

debug:clean compile_sw
	vcs  $(CMP_OPTIONS) $(CMP_DEBUG_OPTIONS) -top tb -f ./tb.f 
	./simv $(SIM_OPTIONS)

verdi:
	verdi -dbdir simv.daidir -ssf test.fsdb -sswr sophon.rc

# ----------------------------------------------------------------------
#  regress test
# ----------------------------------------------------------------------
regress_sw:
	cd ./regress && ./run_regress_sw.py

regress_hw:
	cd ./regress && ./run_regress_hw.py

# ----------------------------------------------------------------------
#  clean
# ----------------------------------------------------------------------
regress_clean:
	rm -rf ./regress/log/* && rm -rf ./regress/*.result

clean:
	rm -rf csrc simv simv.daidir ucli.key vc_hdrs.h novas_dump.log *.fsdb novas* verdiLog signal.rc ./log/*.log stdout_uart

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
