NAME ?= FreeRTOS

LDS_FilE ?= link.ld

COM_DIR   = ../common
SW_DIR    = .
BUILD_DIR = ../build/$(NAME)

# ------------------------------------------------
#  Source files
# ------------------------------------------------
COM_SRC  = $(wildcard $(COM_DIR)/*.c)
COM_ASM  = $(wildcard $(COM_DIR)/*.S)
COM_OBJC = $(COM_SRC:.c=.com.c.o)
COM_OBJS = $(COM_ASM:.S=.com.s.o)

SW_SRC   = $(wildcard $(SW_DIR)/*.c) \
           $(wildcard $(SW_DIR)/Source/*.c) \
           $(wildcard $(SW_DIR)/Source/portable/GCC/RISC-V/*.c) \
           $(SW_DIR)/Source/portable/MemMang/heap_4.c
SW_ASM   = $(wildcard $(SW_DIR)/*.S) \
           $(wildcard $(SW_DIR)/Source/portable/GCC/RISC-V/*.S)
SW_OBJC  = $(SW_SRC:.c=.sw.c.o)
SW_OBJS  = $(SW_ASM:.S=.sw.s.o)

OBJ 	 = $(notdir $(COM_OBJC) $(COM_OBJS) $(SW_OBJC) $(SW_OBJS))

INCLUDE_DIRS = -I $(COM_DIR) \
               -I $(SW_DIR) \
               -I $(SW_DIR)/Source/include \
               -I $(SW_DIR)/Source/portable/GCC/RISC-V \
               -I $(SW_DIR)/Source/portable/GCC/RISC-V/chip_specific_extensions/RISCV_MTIME_CLINT_no_extensions

# ------------------------------------------------
#  Compiler
# ------------------------------------------------
CC      = riscv64-unknown-elf-gcc
CFLAGS  = -march=rv32ia -mabi=ilp32 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns $(INCLUDE_DIRS) 
LDFLAGS = -static -nostdlib -nostartfiles -lm -lgcc
# in BUILD_DIR
LINKER  = ../../common/$(LDS_FilE)

# ------------------------------------------------
#  Target
# ------------------------------------------------
default:all

all: $(NAME).hex $(NAME).dump $(NAME).bin $(NAME).elf 

init:
	test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)
	cp $(SW_SRC) $(BUILD_DIR)
	cp $(SW_ASM) $(BUILD_DIR)


%.com.c.o: $(COM_DIR)/%.c 
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.com.s.o: $(COM_DIR)/%.S 
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.sw.c.o: $(BUILD_DIR)/%.c 
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.sw.s.o: $(BUILD_DIR)/%.S 
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.elf: $(OBJ)
	cd $(BUILD_DIR) && \
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS) -T $(LINKER) 

%.bin: %.elf
	cd $(BUILD_DIR) && \
	riscv64-unknown-elf-objcopy -O binary $^ $@

%.dump: %.elf
	cd $(BUILD_DIR) && \
	riscv64-unknown-elf-objdump --source --all-headers --demangle --line-numbers --wide $^ >$@
	#riscv64-unknown-elf-objdump -D $^ >$@

%.hex: %.elf
	cd $(BUILD_DIR) && \
	riscv64-unknown-elf-objcopy -O verilog $^ $@ &&\
	sed -i 's/@800/@000/g' $@

clean:
	rm -rf $(BUILD_DIR)

debug:
	echo $(SW_SRC)
	echo $(SW_ASM)
	echo $(OBJ)
