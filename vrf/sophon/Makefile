
TEST := isa
CC0 := ../../sw/build/$(TEST)/rv32ui-p-beq.hex


sw_compile:
	$(MAKE) -C ../../sw clean
	$(MAKE) -C ../../sw $(TEST)

compile:clean
	verilator -cc -exe -Wall --trace --top-module tb -f ../../flist/sophon_top_rtl.f tb.sv sim_main.cpp -Wno-fatal

build:compile
	make -j -C obj_dir -f Vtb.mk Vtb

sim:
	./obj_dir/Vtb +CC0=$(CC0)

build_sim:sw_compile
	rm -rf obj_dir wave.vcd* log
	verilator -cc -exe -Wall --trace --top-module tb -f ../../flist/sophon_top_rtl.f tb.sv sim_main.cpp -Wno-fatal
	make -j -C obj_dir -f Vtb.mk Vtb
	./obj_dir/Vtb +CC0=$(CC0)

regress:
	./run_regress.py
	#cat ./regress/regress.result

clean:
	rm -rf obj_dir wave.vcd* log


help:                                    
	@echo   ===============================================================================
	@echo   " ------------------ build and run a test case -------------------------------"
	@echo   " make build_sim                                                              "
	@echo   " ------------------ run regress test ----------------------------------------"
	@echo   " make regress                                                                "
	@echo   ===============================================================================


.PHONY: sw_compile compile sim build_sim regress clea
