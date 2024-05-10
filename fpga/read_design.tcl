
set_property include_dirs { \ 
"../design/open-source/axi/include/" \
"../design/open-source/common_cells/include/" \
"../design/open-source/reqrsp_interface/include/" \
} [current_fileset]

read_verilog -sv ../design/config/config_feature.sv
read_verilog -sv ../design/config/config_others.sv
read_verilog -sv ./fpga_config.sv

read_verilog -sv ../design/sophon/sophon_pkg.sv
read_verilog -sv ../design/sophon/sophon.sv
read_verilog -sv ../design/sophon/sophon_top.sv
read_verilog -sv ../design/sophon/cust.sv
read_verilog -sv ../design/sophon/fgpio.sv
read_verilog -sv ../design/sophon/snapreg.sv
read_verilog -sv ../design/sophon/inst_itf_demux.sv
read_verilog -sv ../design/sophon/inst_itf_arbiter.sv
read_verilog -sv ../design/sophon/data_itf_demux.sv
read_verilog -sv ../design/sophon/data_itf_arbiter.sv
read_verilog -sv ../design/common/std_wrap_ckinv.sv
read_verilog -sv ../design/common/std_wrap_ckand.sv
read_verilog -sv ../design/common/rst_sync.sv
read_verilog -sv ../design/common/tcm_wrap.sv
read_verilog -sv ../design/common/bw_sp_ram.sv


read_verilog -sv ../design/open-source/axi/src/axi_pkg.sv
read_verilog -sv ../design/open-source/reqrsp_interface/src/reqrsp_pkg.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dm_pkg.sv
read_verilog -sv ../design/open-source/common_cells/src/cf_math_pkg.sv
read_verilog -sv ../design/open-source/axi/src/axi_intf.sv
read_verilog -sv ../design/corecomplex/cc_itf_pkg.sv
read_verilog -sv ../design/corecomplex/cc_cfg_pkg.sv
read_verilog -sv ../design/corecomplex/sophon_axi_top.sv
read_verilog -sv ../design/corecomplex/debugger.sv
read_verilog -sv ../design/corecomplex/axi_interconnect.sv
read_verilog -sv ../design/corecomplex/core_complex.sv
read_verilog -sv ../design/corecomplex/crg.sv
read_verilog -sv ../design/corecomplex/apb_syscfg_reg.sv
read_verilog -sv ../design/corecomplex/reqrsp_to_mem.sv
read_verilog -sv ../design/open-source/reqrsp_interface/src/axi_to_reqrsp.sv
read_verilog -sv ../design/open-source/axi/src/axi_xbar.sv
read_verilog -sv ../design/open-source/axi/src/axi_to_axi_lite.sv
read_verilog -sv ../design/open-source/axi/src/axi_lite_to_apb.sv
read_verilog -sv ../design/open-source/axi/src/axi_dw_converter.sv
read_verilog -sv ../design/open-source/axi/src/axi_dw_downsizer.sv
read_verilog -sv ../design/open-source/axi/src/axi_dw_upsizer.sv
read_verilog -sv ../design/open-source/axi/src/axi_atop_filter.sv
read_verilog -sv ../design/open-source/axi/src/axi_burst_splitter.sv
read_verilog -sv ../design/open-source/common_cells/src/fifo_v3.sv
read_verilog -sv ../design/open-source/common_cells/src/rr_arb_tree.sv
read_verilog -sv ../design/open-source/common_cells/src/addr_decode.sv
read_verilog -sv ../design/open-source/common_cells/src/lzc.sv
read_verilog -sv ../design/open-source/common_cells/src/id_queue.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_register.sv
read_verilog -sv ../design/open-source/common_cells/src/counter.sv
read_verilog -sv ../design/open-source/common_cells/src/delta_counter.sv
read_verilog -sv ../design/open-source/common_cells/src/onehot_to_bin.sv
read_verilog -sv ../design/open-source/common_cells/src/fall_through_register.sv
read_verilog -sv ../design/open-source/axi/src/axi_demux.sv
read_verilog -sv ../design/open-source/axi/src/axi_err_slv.sv
read_verilog -sv ../design/open-source/axi/src/axi_mux.sv
read_verilog -sv ../design/open-source/axi/src/axi_id_prepend.sv
read_verilog -sv ../design/open-source/axi_adapter.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dm_top.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dm_csrs.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dm_mem.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dm_sba.sv
read_verilog -sv ../design/open-source/axi2mem.sv
read_verilog -sv ../design/open-source/common_cells/src/deprecated/fifo_v2.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dmi_jtag.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dmi_jtag_tap.sv
read_verilog -sv ../design/open-source/riscv_dbg/src/dmi_cdc.sv
read_verilog -sv ../design/open-source/common_cells/src/cdc_2phase_clearable.sv
read_verilog -sv ../design/open-source/common_cells/src/cdc_reset_ctrlr_pkg.sv
read_verilog -sv ../design/open-source/common_cells/src/cdc_reset_ctrlr.sv
read_verilog -sv ../design/open-source/common_cells/src/sync.sv
read_verilog -sv ../design/open-source/common_cells/src/cdc_4phase.sv
read_verilog -sv ../design/open-source/tech_cells_generic/src/deprecated/pulp_clk_cells.sv
read_verilog -sv ../design/open-source/tech_cells_generic/src/rtl/tc_clk.sv
read_verilog -sv ../design/open-source/riscv_dbg/debug_rom/debug_rom_one_scratch.sv
read_verilog -sv ../design/open-source/reqrsp_interface/src/reqrsp_mux.sv
read_verilog -sv ../design/open-source/reqrsp_interface/src/reqrsp_iso.sv
read_verilog -sv ../design/open-source/reqrsp_interface/src/reqrsp_to_axi.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_mux.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_fork.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_fifo.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_join.sv
read_verilog -sv ../design/open-source/common_cells/src/stream_fork_dynamic.sv
read_verilog -sv ../design/open-source/common_cells/src/spill_register.sv
read_verilog -sv ../design/open-source/common_cells/src/spill_register_flushable.sv
read_verilog -sv ../design/open-source/common_cells/src/isochronous_spill_register.sv
read_verilog -sv ../design/open-source/apb_uart_sv/apb_uart_sv.sv
read_verilog -sv ../design/open-source/apb_uart_sv/uart_rx.sv
read_verilog -sv ../design/open-source/apb_uart_sv/uart_tx.sv
read_verilog -sv ../design/open-source/apb_uart_sv/uart_interrupt.sv
read_verilog -sv ../design/open-source/apb_uart_sv/io_generic_fifo.sv


read_verilog -sv SOPHON_FPGA_TOP.sv
