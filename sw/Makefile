
RISCV_PREFIX ?= riscv64-unknown-elf

RISCV_GCC     := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY := $(RISCV_PREFIX)-objcopy

ISA_SRC_DIR := ./testcase/riscv-tests/isa
BMARKS_SRC_DIR := ./testcase/riscv-tests/benchmarks

LDS_FILE := ./../env/p/link.ld

rv32ui:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui lds_dir=$(LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa/


benchmarks:
	mkdir -p build/benchmarks/
	$(MAKE) -C $(BMARKS_SRC_DIR) all lds_dir=./common/test_cc0.ld
	mv $(BMARKS_SRC_DIR)/*.riscv* build/benchmarks/

isa:rv32ui



clean: clean_benchmarks clean_isa 

clean_benchmarks:
	[ ! -d build/benchmarks ]     || $(MAKE) -C $(BMARKS_SRC_DIR)  clean ; rm -rf ./build/benchmarks
	
clean_isa:
	[ ! -d build/isa ]    || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa



subfold=$(shell find * -maxdepth 0 -type d)
.PHONY: $(subfold)
$(subfold): %:
	mkdir -p build/$*/ 
	$(MAKE) -C $* FILENAME=$*
	mv $*/*.elf     build/$*/
	mv $*/*.dump    build/$*/
	mv $*/*.bin     build/$*/
	mv $*/*.verilog build/$*/

echo:
	echo $(subfold)

