
gen_ip:
	cd ./ip/clk_gen && rm -rf clk_wiz_* vivado*  && vivado -mode batch -source run.tcl
	cd ./ip/ila     && rm -rf ila_*     vivado*  && vivado -mode batch -source run.tcl

fpga:clean
	vivado -mode batch -source run.tcl

clean:
	rm -rf *.log
	rm -rf vivado*
	rm -rf usage_*
	rm -rf *.txt
	rm -rf output/
	rm -rf .cache
	rm -rf .Xil

clean_ip:
	rm -rf ./ip/clk_gen/clk_wiz_*
	rm -rf ./ip/clk_gen/vivado*
	rm -rf ./ip/clk_gen/.Xil
	rm -rf ./ip/ila/ila_*
	rm -rf ./ip/ila/vivado*
	rm -rf ./ip/ila/.Xil
