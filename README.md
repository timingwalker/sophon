# Sophon

Sophon is a time-repeatable and low-latency architecture based on RISC-V. The essential part is a tiny and flexible RISC-V core that supporting the following features:
- RV32I + custom instructions
- Enhanced ISA extension interface (EEI interface)
- Configurable external interfaces


# Configurations

Features are defined in the following file:
> design/config/config_feature.sv

Configurable parameters:
> - SOPHON_EXT_INST: enable the external instruction interface of the Sophon core
> - SOPHON_EXT_DATA: enable the external data interface of the Sophon core
> - SOPHON_EXT_ACCESS: enable the external access interface so the external masters can access the L1 inst/data memories of the Sophon core
> - SOPHON_CLIC: enable the RISC-V CLIC extension
> - SOPHON_EEI: enable the EEI interface to support custom instructions


# Integration

The Sophon core can be reused in different levels:

1. Sophon core

This is the simplest form of the Sophon core which exposing its original interfaces.

2. SOPHON_AXI_TOP

An AXI wrapper is provided to make it easier to be integrated to an AXI-based system. The L1 instruction/data memories are also provided in this level.

3. CORE_COMPLEX

Complete form of the Sophon architecture. You can use it as a stand-alone RISC-V cores or a co-processor in tandem with an application core.

<img src="docs/img/sophon_overview.png"/>


# Quick start

> Requirements
> - Verilator (version above 4.200)
> - GTKWave

1. Checkout the repository
```sh
git clone https://github.com/timingwalker/sophon.git
```

2. Build the design and run a test case
```sh
cd vrf/sophon/
make build_sim
```

3. Open the waveform
```sh
gtkwave wave.vcd
```

The following script can be used to run regression tests:
```sh
./run_regress.py
```


# FPGA

Currently the Sophon core is supported on the Genesys 2 board. A pre-build bitstream can be found in the release pages.

You can also build a new bitstream by yourself:
```sh
cd fpga
make gen_ip
make fpga
```

Once the bitstream is downloaded to the Genesys 2 board, you can run some tests, such as the RISC-V debug test:
```sh
cd vrf/riscv-tests/debug
./gdbserver.py targets/RISC-V/sophon.py
```


# Issues

If you find any problems with Sophon, please report it by creating a new issue.

