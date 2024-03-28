
gen_ip:
	cd ./ip/clk_gen && rm -rf clk_wiz_* vivado*  && /home/huangzhe/lab/Xilinx/Vivado/2021.1/bin/vivado -mode batch -source run.tcl
	cd ./ip/ila     && rm -rf ila_*     vivado*  && /home/huangzhe/lab/Xilinx/Vivado/2021.1/bin/vivado -mode batch -source run.tcl

fpga:clean
	/home/huangzhe/lab/Xilinx/Vivado/2021.1/bin/vivado -mode batch -source run.tcl

clean:
	rm -rf *.log
	rm -rf vivado*
	rm -rf usage_*
	rm -rf *.txt
	rm -rf output/
	rm -rf .Xil/
	rm -rf .cache/
