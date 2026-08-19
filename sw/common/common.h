#ifndef _COMMON_H
#define _COMMON_H

typedef unsigned int __u32;
typedef __u32 u32;

#define _REG32(p, i) (*(volatile uint32_t *)((p) + (i)))

#define __raw_writel(v,a)	(*(volatile u32 *)(a) = ((u32)v))
#define writel	__raw_writel

#define __raw_readl(a)		(*(volatile u32 *)(a))
#define readl	__raw_readl


#define UART0_BASE          0x06004000

#define CLINT_BASE          0x06005000
#define CLINT_MTIME         0x00
#define CLINT_MTIMECMP      0x04
#define CLINT_MSIP          0x08

#define PLIC_BASE           0x07040000
#define PLIC_IE_0           0x2000
#define PLIC_PRIO_0         0x4
#define PLIC_CLAIM_COMPLET  0x200004



// ── custom0: opcode=0x0B ──
#define CUSTOM0_R(funct3, funct7, rd,  rs1, rs2)  \
        __asm__ volatile(                         \
        ".insn r 0x0B, " #funct3 ", " #funct7     \
        ", x" #rd ", x" #rs1 ", x" #rs2           \
    )
// ── custom1: opcode=0x2B ──
#define CUSTOM1_R(funct3, funct7, rd,  rs1, rs2)  \
        __asm__ volatile(                         \
        ".insn r 0x2B, " #funct3 ", " #funct7     \
        ", x" #rd ", x" #rs1 ", x" #rs2           \
    )

#define IO_IN_RAW(rd, rs1, rs2)   CUSTOM0_R(0, 0x0, rd,  rs1, rs2)
#define IO_IN_BIT(rd, rs1, rs2)   CUSTOM0_R(0, 0x1, rd,  rs1, rs2)
#define IO_OUT_RAW(rd, rs1, rs2)  CUSTOM0_R(0, 0x40, rd,  rs1, rs2)
#define IO_OUT_BIT(rd, rs1, rs2)  CUSTOM0_R(0, 0x41, rd,  rs1, rs2)
#define IO_CFG_REG(rd, rs1, rs2)  CUSTOM0_R(0, 0x7F, rd,  rs1, rs2)

#define SREG_SAVE(rd, rs1, rs2)    CUSTOM1_R(0, 0x0, rd,  rs1, rs2)
#define SREG_RECOVER(rd, rs1, rs2) CUSTOM1_R(0, 0x40, rd,  rs1, rs2)

#define VSM_START(rd, rs1, rs2)   CUSTOM0_R(1, 0x0, rd,  rs1, rs2)
#define VSM_STOP(rd, rs1, rs2)   CUSTOM0_R(1, 0x1, rd,  rs1, rs2)
#define VSM_SET_CMP(rd, rs1, rs2)   CUSTOM0_R(1, 0x2, rd,  rs1, rs2)
#define VSM_SET_SM(rd, rs1, rs2)   CUSTOM0_R(1, 0x3, rd,  rs1, rs2)



int printf(const char* fmt, ...);
void usleep(uint32_t us);
static inline uint64_t get_mcycle(void) {
    uint32_t lo, hi;

    asm volatile (
        "1:\n"
        "csrr %0, mcycleh\n"
        "csrr %1, mcycle\n"
        "csrr t0, mcycleh\n"
        "bne  %0, t0, 1b\n"
        : "=r"(hi), "=r"(lo)
        :
        : "t0"
    );

    return ((uint64_t)hi << 32) | lo;
}

#define HWINFO_EXT_INST   0
#define HWINFO_EXT_DATA   1
#define HWINFO_EXT_ACCESS 2
#define HWINFO_RVE        3 
#define HWINFO_CLINT      4 
#define HWINFO_CLIC       5 
#define HWINFO_RVDEBUG    6 
#define HWINFO_EEI_SREG   7 
#define HWINFO_EEI_GPIO   8 


#endif 
