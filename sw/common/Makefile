NAME ?= NONE


COM_DIR   = .
SW_DIR    = ../$(NAME)
BUILD_DIR = ../build/$(NAME)

COM_SRC = $(wildcard $(COM_DIR)/*.c)
COM_ASM = $(wildcard $(COM_DIR)/*.S)
SW_SRC  ?= $(wildcard $(SW_DIR)/*.c)
SW_ASM  = $(wildcard $(SW_DIR)/*.s)

COM_OBJC = $(COM_SRC:.c=.com.c.o)
COM_OBJS = $(COM_ASM:.S=.com.s.o)
SW_OBJC  = $(SW_SRC:.c=.sw.c.o)
SW_OBJS  = $(SW_ASM:.s=.sw.s.o)
OBJ = $(notdir $(COM_OBJC) $(COM_OBJS) $(SW_OBJC) $(SW_OBJS))


CC      = riscv64-unknown-elf-gcc
CFLAGS  = -march=rv32i_zicsr -mabi=ilp32 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns -I $(COM_DIR)
LDFLAGS = -static -nostdlib -nostartfiles -lm -lgcc 
LINKER  = ../../common/link.ld
# CFLAGS  = -march=rv32i -mabi=ilp32 -static -O2 -g -mcmodel=medany -ffunction-sections -fdata-sections \
# 		  --specs=nano.specs -DMTIME_RATE_HZ_DEF=32768 -DSLEN=512 -DVLEN=512
# LDFLAGS = -Wl,--gc-sections -Wl,-Map,psv.map -nostartfiles -nostdlib -lm -lc -lgcc


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

%.sw.s.o: $(SW_DIR)/%.s init
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
 
all: $(NAME).hex $(NAME).dump $(NAME).bin $(NAME).elf 

debug:
	echo $(OBJ)
