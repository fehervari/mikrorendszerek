#include "xparameters.h"
#include "xbasic_types.h"

# define CPLD_BASE_ADDR 0x44000000
# define CPLD_STATUS_REG_OFFSET 0x0
# define CPLD_IN_OFFSET   		0x4
# define CPLD_OUT_OFFSET  		0x8

#ifndef MEM_OPERATION
	#define MEM8(addr)   (*(volatile unsigned char *)(addr))
	#define MEM16(addr)  (*(volatile Xuint16 *)(addr))
	#define MEM32(addr)  (*(volatile unsigned long *)(addr))
#endif

void CPLD_init(void);

Xuint8 read_CPLD_nav(void);
Xuint8 read_CPLD_dip(void);
void write_CPLD_seg(Xuint8 data);
void write_CPLD_led(Xuint8 data);
