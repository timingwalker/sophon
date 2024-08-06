
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


#endif 
