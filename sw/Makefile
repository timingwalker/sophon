
RISCV_PREFIX   ?= riscv64-unknown-elf

RISCV_GCC      := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP  := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY  := $(RISCV_PREFIX)-objcopy

MARCH    ?= rv32ia
MABI     ?= ilp32
LDS_FILE ?= link.ld


# ----------------------------------------------------------------------
#  universial application, uses common/Makefile
# ----------------------------------------------------------------------
subfold    = $(shell find * -maxdepth 0 -type d)
MAKE_APP  := $(filter-out common build FreeRTOS,$(subfold))
CLEAN_APP := $(addprefix clean_,$(filter-out common,$(subfold)))

$(MAKE_APP): %: clean_%
	$(MAKE) -C common PROGRAM=$* MARCH=$(MARCH) MABI=$(MABI) LDS_FILE=$(LDS_FILE)

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

$(MAKE_BMARK): %: clean_%
	$(MAKE) -C common PROGRAM=$* SW_DIR=../$(BMARKS_SRC_DIR)/$* MARCH=$(MARCH) MABI=$(MABI) LDS_FILE=$(LDS_FILE)

$(CLEAN_BMARK): clean_%:
	rm -rf ./build/$*

benchmarks       : $(MAKE_BMARK)
clean_benchmarks : $(CLEAN_BMARK)

# ------------------------------------------------
#  isa, uses makefile in vrf/riscv-tests/isa
# ------------------------------------------------
rv32ui:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui lds_dir=../../../sw/common/$(LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa/

# rv32si:
# 	mkdir -p build/isa/
# 	$(MAKE) -C $(ISA_SRC_DIR) rv32si lds_dir=../../../sw/common/$(LDS_FILE)
# 	mv $(ISA_SRC_DIR)/rv32si-* build/isa/

#isa:rv32ui rv32si

isa:rv32ui 

clean_isa:
	[ ! -d build/isa ]          || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa

# ----------------------------------------------------------------------
# TBD: Others software
# ----------------------------------------------------------------------
CM_SRC_DIR     := ./coremark

FreeRTOS: clean_FreeRTOS
	cd FreeRTOS &&\
	make init &&\
	make LINKER=$(APP_LDS_FILE)

coremark:
	mkdir -p build/coremark/
	cd $(CM_SRC_DIR) && $(MAKE) PORT_DIR=./sophon compile ITERATIONS=10
	mv $(CM_SRC_DIR)/coremark.elf build/coremark/coremark.riscv
	riscv64-unknown-elf-objdump -D build/coremark/coremark.riscv >> build/coremark/coremark.dump
	riscv64-unknown-elf-objcopy -O verilog build/coremark/coremark.riscv build/coremark/coremark.hex
	sed -i 's/@800/@000/g' build/coremark/coremark.hex

clean_coremark:
	[ ! -d build/coremark ]     || rm -rf ./build/coremark

# ----------------------------------------------------------------------
#  clean
# ----------------------------------------------------------------------
clean: clean_app clean_benchmarks clean_isa clean_coremark  clean_FreeRTOS


