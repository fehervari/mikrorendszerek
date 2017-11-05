#include "cpld.h"

struct CPLD {
	Xuint8		SEGs;
	Xuint8		LEDs
};
//connect mb mdm -cable type xilinx_platformusb
static struct CPLD CPLD;

void CPLD_init(void){
	CPLD.LEDs = 0;
	CPLD.SEGs = 0;
}

Xuint8 read_CPLD_nav(void){
	Xuint16 data;
	data = (MEM16(CPLD_BASE_ADDR + CPLD_IN_OFFSET));
	data = data >> 8;
	return (Xuint8)data;
}
Xuint8 read_CPLD_dip(void){
	Xuint8 data;
	data = (MEM16(CPLD_BASE_ADDR + CPLD_IN_OFFSET) & 0x00FF);
	return data;
}
void write_CPLD_seg(Xuint8 data){
	CPLD.SEGs = data;
	Xuint16 out = ((Xuint16)CPLD.LEDs << 8) | data;
	MEM16(CPLD_BASE_ADDR + CPLD_OUT_OFFSET) = out;
}
void write_CPLD_led(Xuint8 data){
	CPLD.LEDs = data;
	Xuint16 out = ((Xuint16)data << 8) | CPLD.SEGs;
	MEM16(CPLD_BASE_ADDR + CPLD_OUT_OFFSET) = out;
}
