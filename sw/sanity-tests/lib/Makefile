
FILENAME ?= NONE
INCLUDES = -I./
LINKER = -T linker.ld

SRC = $(wildcard ./*.c)
ASM = $(wildcard ./*.s)
OBJC = $(SRC:.c=.c.o)
OBJS = $(ASM:.s=.s.o)
OBJ = $(notdir $(OBJC) $(OBJS))
CFLAGS = -march=rv32im -mabi=ilp32 -mcmodel=medany -ffunction-sections -fdata-sections --specs=nano.specs -DMTIME_RATE_HZ_DEF=32768 -O0 -g -DSLEN=512 -DVLEN=512
#CFLAGS = -march=rv32e -mabi=ilp32e -mcmodel=medany -ffunction-sections -fdata-sections --specs=nano.specs -DMTIME_RATE_HZ_DEF=32768 -O0 -g -DSLEN=512 -DVLEN=512
LDFLAGS= -Wl,--gc-sections -Wl,-Map,psv.map -nostartfiles -nostdlib


default: all

%.c.o: %.c 
	riscv64-unknown-elf-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

%.s.o: %.s 
	riscv64-unknown-elf-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

%.elf: $(OBJ)
	riscv64-unknown-elf-gcc $(CFLAGS) $(LDFLAGS) $(LINKER) $(INCLUDES) $^ -o $@

%.bin: %.elf
	riscv64-unknown-elf-objcopy -O binary $^ $@

%.dump: %.elf
	riscv64-unknown-elf-objdump -D $^ >$@
	# riscv64-unknown-elf-objdump --source --all-headers --demangle --line-numbers --wide $^ >$@
	#riscv64-unknown-elf-objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data --section=.bss --section=.rodata $^ >$@

%.hex: %.elf
	riscv64-unknown-elf-objcopy -O verilog $^ $@
	sed -i 's/@800/@000/g' $@

all: $(FILENAME).hex $(FILENAME).dump $(FILENAME).bin $(FILENAME).elf 

