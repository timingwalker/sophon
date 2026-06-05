include common/toolchain.mk

LDS_FILE      ?= link.ld
SW_SIMPLE_CRT ?= NO
SW_RVE        ?= NO
SOPHON_STACK_SHIFT ?=


# ----------------------------------------------------------------------
#  bootrom
# ----------------------------------------------------------------------
bootrom:
	$(MAKE) -C bootrom
clean_bootrom:
	[ ! -d build/bootrom ]     || rm -rf ./build/bootrom


# ----------------------------------------------------------------------
#  universial application, uses common/Makefile
# ----------------------------------------------------------------------
subfold    = $(shell find * -maxdepth 0 -type d)
MAKE_APP  := $(filter-out common build bootrom,$(subfold))
CLEAN_APP := $(addprefix clean_,$(filter-out common build bootrom,$(subfold)))

$(MAKE_APP): %: clean_%
	$(MAKE) -C common PROGRAM=$* MARCH=$(MARCH) MABI=$(MABI) LDS_FILE=$(LDS_FILE) SW_SIMPLE_CRT=$(SW_SIMPLE_CRT) SW_RVE=$(SW_RVE) SW_ZICSR=$(SW_ZICSR) SOPHON_STACK_SHIFT=$(SOPHON_STACK_SHIFT)

$(CLEAN_APP): clean_%:
	rm -rf ./build/$*

app       : $(MAKE_APP)
clean_app : $(CLEAN_APP)

.PHONY: $(subfold) $(CLEAN_APP) $(MAKE_APP)

# ----------------------------------------------------------------------
#  riscv-test: vrf/riscv-tests
# ----------------------------------------------------------------------
ISA_SRC_DIR    := ../vrf/riscv-tests/isa
BMARKS_SRC_DIR := ../vrf/riscv-tests/benchmarks


# ------------------------------------------------
#  benchmarks, uses common/Makefile
# ------------------------------------------------
bmark_subfold = $(notdir $(shell find $(BMARKS_SRC_DIR)/* -maxdepth 0 -type d))
MAKE_BMARK   := $(filter-out common mm mt-% vec-%,$(bmark_subfold))
CLEAN_BMARK  := $(addprefix clean_,$(MAKE_BMARK))

dhrystone_CFLAGS_EXTRA := -Wno-error=implicit-int -Wno-error=implicit-function-declaration

$(MAKE_BMARK): %: clean_%
	$(MAKE) -C common PROGRAM=$* SW_DIR=../$(BMARKS_SRC_DIR)/$* MARCH=$(MARCH) MABI=$(MABI) LDS_FILE=$(LDS_FILE) SOPHON_STACK_SHIFT=$(SOPHON_STACK_SHIFT) CFLAGS_EXTRA="$($*_CFLAGS_EXTRA)"

$(CLEAN_BMARK): clean_%:
	rm -rf ./build/$*

benchmarks       : $(MAKE_BMARK)
clean_benchmarks : $(CLEAN_BMARK)


# ------------------------------------------------
#  isa, uses makefile in vrf/riscv-tests/isa
# ------------------------------------------------
rv32ui:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui lds_dir=../../../sw/common/$(LDS_FILE) SED=$(SED)
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa/

isa:rv32ui

clean_isa:
	[ ! -d build/isa ]          || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa

# ----------------------------------------------------------------------
#  TBD coremark
# ----------------------------------------------------------------------
# CM_SRC_DIR     := ./coremark
# 
# coremark:
# 	mkdir -p build/coremark/
# 	cd $(CM_SRC_DIR) && $(MAKE) PORT_DIR=./sophon compile ITERATIONS=10
# 	mv $(CM_SRC_DIR)/coremark.elf build/coremark/coremark.riscv
# 	riscv64-unknown-elf-objdump -D build/coremark/coremark.riscv >> build/coremark/coremark.dump
# 	riscv64-unknown-elf-objcopy -O verilog build/coremark/coremark.riscv build/coremark/coremark.hex
# 	sed -i 's/@800/@000/g' build/coremark/coremark.hex
# 
# clean_coremark:
# 	[ ! -d build/coremark ]     || rm -rf ./build/coremark

# ----------------------------------------------------------------------
#  clean
# ----------------------------------------------------------------------
clean: clean_app clean_benchmarks clean_isa clean_bootrom
