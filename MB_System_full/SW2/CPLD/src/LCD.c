# include "LCD.h"

struct LCD_STATUS {
	Xuint8		INVERSE;
	Xuint8		FULL;// forgalomszab�lyz�s
};

//static Xuint8 speedRate[4]= {16,8,4,1};
static Xuint8 convert[8] = {0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80};

static struct LCD_STATUS LCD;

void itit_LCD(Xuint8 inverseEn){/* TODO */
	LCD.INVERSE = inverseEn;
	LCD.FULL = 0;

	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_STATUS_REG_OFFSET,LCD_SCREEN_ENABLE_MASK | LCD_SCREEN_IRQ_ENABLE_MASK);

	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET,0xE2);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET,0x40);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET,0xA0);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET,0xC8);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET,0xA4);

	if(LCD.INVERSE)
		sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0xA7);
	else
		sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0xA6);

	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0xA2);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0x2F);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0x27);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0x81);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0x10);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0xFA);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0x90);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, 0xAF);

}

void clear_LCD(void){ // lapok [0 ... 7] oszlopok [30 ... 131]
	Xuint8 page, colL, colH;
	Xuint8 i,j;
	Xuint32 data = 0x100;
	for (i = 0; i < 8; i++){ // lapok
		for(j = 0x1E; j < 0x84; j++){ // sorok
			page = 0xB0 + i; //lapc�m
			colH = 0x10 + (j >> 4); // oszlop fels�
			colL = j & 0x0F; // oszlop als�
			sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, page);
			sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, colH);
			sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, colL);
			sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, data);
		}
	}
}

void write_Pixel(Xuint8 x, Xuint8 y){ // x [1 : 102] y [1 : 64]
	Xuint8 Page_addr = 0xB0 + (y >> 3); // lapc�m
	Xuint8 Col_addr = (x + 0x1E); //oszlopc�m
	Xuint8 Col_addrH = 0x10 + (Col_addr >> 4);
	Xuint8 Col_addrL = Col_addr & 0x0F;
	Xuint16 Row_addr = (y & 0x07);// sorc�m
	Row_addr = convert[Row_addr];
	Row_addr += 0x10F;
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Page_addr);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrH);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrL);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Row_addr);
}
/*
void write_Memory(Xuint8 page, Xuint8 addr, Xuint8 data){
	Xuint8 Page_addr = 0xB0 + page; //lapc�m
	Xuint8 Col_addrH = 0x10 + (addr >> 4);
	Xuint8 Col_addrL = addr & 0x0F;
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Page_addr);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrH);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrL);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, data);
}*/
void write_Memory(Xuint8 page, Xuint8 col,  Xuint8 data){ // x [1 : 102] y [1 : 64]
	Xuint8 Page_addr = 0xB0 + page; // lapc�m
	Xuint8 Col_addr = (col + 0x1E); //oszlopc�m
	Xuint8 Col_addrH = 0x10 + (Col_addr >> 4);
	Xuint8 Col_addrL = Col_addr & 0x0F;
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Page_addr);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrH);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, Col_addrL);
	sendData16(LCD_SCREEN_BASEADDR + LCD_SCREEN_FIFO_OFFSET, data | 0x100);
}

void sendData16(Xuint32 addr, Xuint16 data){
	Xuint8 i;
	while(LCD.FULL); // forgalomszab�lyz�s
	MEM16(addr) = data;
}

void lcd_IT_handler(void *instancePtr){
	Xuint16 ifr;
	ifr = MEM16(LCD_SCREEN_STATUS_REG_OFFSET);
	if(ifr & LCD_SCREEN_FULL_FIFO_EVENT)// ha tele a fifo akkor
		LCD.FULL = 1;
	else if(ifr & LCD_SCREEN_EMPTY_FIFO_EVENT)
		LCD.FULL = 0;
}

