/*
 * Copyright (c) 2009-2012 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "snake2.h"

#include "xbasic_types.h"
#include "lcd.h"
#include <xintc_l.h>




void print(char *str);

int main()
{
	Xuint8 i,k, j, pagepixel;
    init_platform();

	XIntc_RegisterHandler( XPAR_INTC_0_BASEADDR, XPAR_MICROBLAZE_0_INTC_LCD_SCREEN_0_IRQ_INTR, lcd_IT_handler,NULL);

	XIntc_MasterEnable(XPAR_INTC_0_BASEADDR);
	XIntc_EnableIntr(XPAR_INTC_0_BASEADDR, XPAR_LCD_SCREEN_0_IRQ_MASK);
		//MEM32(XPAR_LVL_INDICATOR_0_BASEADDR + LVL_IE_REG) = LVL_ERROR_IRQ ;
	microblaze_enable_interrupts();
    itit_LCD(0);
    clear_LCD();


    for(k=0 ;k<8;k++)
	for(i= 1; i < 102; ++i)
	{
		write_Memory(k,i,snake3[k*102 + i]);
	}

    return 0;
}
