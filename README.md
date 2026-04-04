# Sophon - A time-repeatable RISC-V core optimized for control latency

- [English](#english)
- [中文](#中文)

# English

Sophon is a tiny RISC-V core implements the RV32I(E) instruction set. It adopts a single-cycle microarchitecture and provides a time-repeatable feature. A lightweight and efficient ISA extension interface (EEI) is provided. Up to 32 operands can be transmitted in a single custom instruction. Sophon can work in standalone mode, accesses its tightly coupled memory, and achieves a high IPC of one. It can also be used as an auxiliary core when the external access interface (EXT_ACCESS) is enabled, working in tandem with a high-performance application core. 

Typical applications:

#### Embedded real-time system
Embedded real-time systems have strict timing requirements, where critical tasks should be completed within a given deadline. The time-repeatable and low-latency features can help to meet these constrains.

#### Domain-specific architecture
Domain-specific applications can be accelerated by developing custom execution units and connecting them to Sophon via the ISA extension interface.

#### High security application
Latency of all instructions supported by Sophon are equal, which is helpful to reduce side channel leakage when running security algorithm.

> Sophon is a 11-dimensional supercomputer contained in a proton from the science fiction The Three-Body Problem. This name is used as a metaphor for two features of this RISC-V core: 1)Tiny. 2)Scalable.


# Performance

Sophon is optimized for control latency. It achieves as low as one-cycle latency for:

#### Instruction latency

All instructions have a deterministic and repeatable one-cycle latency include:

- arithmetic instructions (e.g. add/sub/and/sll)
- transfer instructions (e.g. jal/jalr/beq)
- load/store instructions accessing TCM memory
- custom instructions

#### GPIO latency:

A fGPIO extension is developed to provide fast and accurate GPIO response. Following custom instructions can be used:

- IO.in.raw rs2,rd
- IO.in.bit rs1,rs2,rd
- IO.out.raw rs1,rs2,rd

#### Interrupt latency:

The Sophon core supports RISC-V CLIC spec v0.9-draft, which can provide a low-latency, vectored interrupt feature. Custom instructions sanpreg.save/snapreg.recover can be used to accelerate context saving and restoring.

Interrupt latency in shv/non-shv mode is 1 cycle and 6 cycles, respectively.


# Architecture

Sophon can be reused in different levels:

#### Sophon core
This is the simplest form of the Sophon core, exposing its original interfaces.

#### SOPHON_AXI_TOP
An AXI wrapper is provided to make it easier to be integrated into an AXI-based system. The tightly coupled memories are also included in this level.

#### CORE_COMPLEX
You can use it as a stand-alone RISC-V core or a co-processor directly.

< img src="docs/img/sophon_overview.png"/>

Hardware parameters are defined in the following file:
> design/config/config_feature.sv

#### SOPHON_RVE
Enable RV32E ISA, this will reduce 16 registers.

#### SOPHON_RVDEBUG
Enable RISC-V Debug mode, debugger can access Sophon through a JTAG interface.

#### SOPHON_CLIC
Enable RISC-V CLIC extension.

#### SOPHON_EEI
Enable the ISA extension interface (EEI) to support custom instructions.

#### EEI_RS_MAX / EEI_RD_MAX
Define the maximum rs/rd channel in EEI.

#### SOPHON_EXT_INST
Enable the external instruction interface.

#### SOPHON_EXT_DATA
Enable the external data interface.

#### SOPHON_EXT_ACCESS
Enable the external access interface, then external masters can access the tightly coupled memories of Sophon.


# Quick start

Requirements
- RISC-V toolchain
- Verilator (version above 4.200)
- GTKWave

1. Checkout the repository
```sh
git clone https://github.com/timingwalker/sophon.git
```

2. Build the design and run a test case
```sh
cd vrf/sophon/
make build_sim
```

3. Check the waveform
```sh
gtkwave wave.vcd
```

4. Run a regression test
```sh
make regress
```


# FPGA

Currently the Sophon core is supported on the Genesys 2 board. A pre-build bitstream can be found in the release page.

You can also build a new bitstream by yourself:
```sh
cd fpga
make gen_ip
make fpga
```

Once the bitstream is downloaded to the FPGA, you can test if the design is correct:
```sh
cd vrf/riscv-tests/debug
./gdbserver.py targets/RISC-V/sophon.py
```

You can also download your programe with OpenOCD and gdb:

1. OpenOCD
```sh
openocd -f ./sw/common/sophon.cfg
```

2. gdb
```sh
target remote localhost:3333
file ./sw/build/$(your_program)/$(your_program).elf
load
c
```


# software

You can compile your software and run it in the FPGA platform.

1. copy software template
```sh
cd sw
cp hello yourapp
```

2. Compile
```sh
make yourapp
```

The generated files are stored in sw/build/yourapp. You can download it (yourapp.elf) to the FPGA using Openocd/gdb. The Openocd configuration file is:
```sh
sw/common/sophon.cfg
```


# Publication

If you are interested in Sophon and use it in your work, please cite:

#### Sophon: A time-repeatable and low-latency architecture for embedded real-time systems based on RISC-V

> NOTE: Several latencies are further optimized after this paper is published:
> - Latency of load/store instruction accessing TCM is reduced from 2 cycles to 1 cycle.
> - Interrupt latency in CLIC shv mode is reduced from 3 cycles to 1 cycle.
> - Interrupt latency in CLIC non-shv mode with snapreg instruction is reduced from 7 cycles to 6 cycle.


# Issues

If you find any problems, please report it by creating a new issue.


# 中文

# FPGA

Release页面提供预编译好的.bit/.mcs文件，可以直接烧写到FPGA开发板。

### ARTY A7-35T开发板

1. 只需要连接开发板左侧的USB线，就可以同时完成供电/位流文件烧写/软件下载/串口输出的功能。
2. FPGA烧写成功之后，下方的LED灯点亮。
3. 右上角的复位键可以用来复位Sophon内核。

根据实际需要，还可以连接开发板上方的Pmod接口：
1. Pmod JA是JTAG调试接口，如果RTL设计中使能了RVDEBUG功能，可以将JTAG调试器连接到该接口上，然后使用openocd/gdb对软件进行调试。
2. Pmod JB、JC、JD为GPIO接口，可以根据实际需求使用。

![Arty](docs/img/ARTY-A7-35T.jpeg)

### FPGA编译

在改动硬件设计之后，可以在FPGA目录下重新编译：
```sh
cd fpga
make gen_ip
make fpga
```

# 软件

### 软件编译

可以在sw目录下新增并编译软件代码：
```sh
cd sw
cp hello yourapp
make yourapp
（yourapp 替换为用户程序的名称）
```

### UART下载

在没有软件调试需求的情况下，推荐使用UART下载程序。

正确编译软件后，在sw/build/yourapp目录下会出现yourapp.itcm.bin和yourapp.dtcm.bin两个文件，分别对应itcm/dtcm的数据。

下载流程：

1. 按下右上方的复位按钮，使RISC-V内核从bootrom启动并进入下载软件流程。正确操作的情况下，串口上会持续输出字符“C”
2. 使用支持XModem协议的串口调试软件，如UartAssist，先下载yourapp.itcm.bin文件。
3. 下载itcm成功后，串口输出“-d”字符，然后持续输出“C”字符，等待下载dtcm文件。
4. 继续使用串口调试软件下载yourapp.dtcm.bin文件。
5. 下载dtcm成功之后，串口输出“j”字符，之后跳转执行yourapp中的软件代码。

注意：
1. 软件下载成功后，再次按下复位键，bootrom会跳过下载流程，直接跳转到ITCM执行用户代码。
2. 如果需要再次下载软件，需要对开发板重新上电（即：插拔一次USB线）。

下图是串口调试软件中的设置：

![uart](docs/img/uart-download.png)

下载hello例程之后，串口会输出硬件配置信息。

### JTAG下载

通过JTAG下载并调试软件的前提是：RTL设计中开启了RVDebug功能（ 即：打开宏定义SOPHON_RVDEBUG），并正确连接开发板上的JTAG接口。

之后，可以使用Openocd/gdb下载并调试软件，Openocd配置文件参考：
```sh
sw/common/sophon.cfg
```
