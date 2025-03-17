#ifndef _COMMON_H
#define _COMMON_H

typedef unsigned int __u32;
typedef __u32 u32;

#define _REG32(p, i) (*(volatile uint32_t *)((p) + (i)))

#define __raw_writel(v,a)	(*(volatile u32 *)(a) = ((u32)v))
#define writel	__raw_writel

#define __raw_readl(a)		(*(volatile u32 *)(a))
#define readl	__raw_readl


#define UART0_BASE     0x06004000
#define CLINT_BASE     0x06005000
#define CLINT_MTIME    0x00
#define CLINT_MTIMECMP 0x04
#define CLINT_MSIP     0x08


// regular EEI instructions
#define io_in_raw(rd,rs1,rs2)           ".insn r 0x0b,0,0b0000000,"#rd","#rs1","#rs2
#define io_in_bit(rd,rs1,rs2)       ".insn r 0x0b,0,0b0000001,"#rd","#rs1","#rs2
#define io_out_raw(rd,rs1,rs2)          ".insn r 0x0b,0,0b1000000,"#rd","#rs1","#rs2
#define io_out_bit(rd,rs1,rs2)      ".insn r 0x0b,0,0b1000001,"#rd","#rs1","#rs2
#define io_cfg_reg(rd,rs1,rs2)         ".insn r 0x0b,0,0b1111111,"#rd","#rs1","#rs2
// enhanced EEI instructions
#define io_out_batch(rd,rs1,rs2)        ".insn r 0x2b,0,0b1100000,"#rd","#rs1","#rs2
#define io_in_batch(rd,rs1,rs2)         ".insn r 0x2b,0,0b1100001,"#rd","#rs1","#rs2

#define snapreg_save(rd,rs1,rs2)         ".insn r 0x2b,0b001,0b0000000,"#rd","#rs1","#rs2
#define snapreg_recover(rd,rs1,rs2)         ".insn r 0x2b,0b001,0b1000000,"#rd","#rs1","#rs2

int printf(const char* fmt, ...);


#endif 
