PROGRAM    ?= NONE
SIMPLE_CRT ?= NO
MARCH      ?= rv32ia
MABI       ?= ilp32
DEFINE     ?= -D__RV32E=0
LDS_FILE   ?= link.ld

# ----------------------------------------------------------------------
#  Parameters
# ----------------------------------------------------------------------
COM_DIR     = .
SW_DIR      = ../$(PROGRAM)
BUILD_DIR   = ../build/$(PROGRAM)

ifeq ($(SIMPLE_CRT), YES)
	COM_SRC = syscalls_simple.c
else 
	COM_SRC = $(filter-out syscalls_simple.c, $(wildcard $(COM_DIR)/*.c))
endif
COM_ASM  = $(wildcard $(COM_DIR)/*.S)

SW_SRC  ?= $(wildcard $(SW_DIR)/*.c)
SW_ASM  ?= $(wildcard $(SW_DIR)/*.S)

COM_OBJC = $(COM_SRC:.c=.com.c.o)
COM_OBJS = $(COM_ASM:.S=.com.s.o)
SW_OBJC  = $(SW_SRC:.c=.sw.c.o)
SW_OBJS  = $(SW_ASM:.S=.sw.s.o) 
OBJ      = $(notdir $(COM_OBJC) $(COM_OBJS) $(SW_OBJC) $(SW_OBJS))

CC       = riscv64-unknown-elf-gcc
CFLAGS   = -march=$(MARCH) -mabi=$(MABI) -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns -I $(COM_DIR) $(DEFINE)
LDFLAGS  = -static -nostdlib -nostartfiles -lm -lgcc 
LINKER   = ../../common/$(LDS_FILE)

# ----------------------------------------------------------------------
#  Target
# ----------------------------------------------------------------------
default:all

init:
	test -d $(BUILD_DIR) || mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

%.com.c.o: $(COM_DIR)/%.c init
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.sw.c.o: $(SW_DIR)/%.c init
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.com.s.o: $(COM_DIR)/%.S init
	$(CC) $(CFLAGS) -c $< -o $(BUILD_DIR)/$@

%.sw.s.o: $(SW_DIR)/%.S init
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
 
all: $(PROGRAM).hex $(PROGRAM).dump $(PROGRAM).bin $(PROGRAM).elf 

debug:
	echo $(OBJ)
