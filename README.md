# Sophon

Sophon is a time-repeatable and low-latency architecture based on RISC-V. The essential part is a tiny and flexible RISC-V core that supporting the following features:
- RV32I + custom instructions
- Enhanced ISA extension interface (EEI)
- Configurable external interfaces

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

The following script can be used to run regression tst:
```sh
./run_regress.py
```

# Issues

If you find any problems with Sophon, please report it by creating a new issue.

