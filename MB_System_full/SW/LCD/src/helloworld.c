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
#include <malloc.h>
#include "Tile.h"

#define X  8
#define Y  8
#define MAXFOOD X*Y
#define HEAD 'X'
#define TAIL 'O'
#define EMPTY ' '
#define FOOD '+'

static Xuint8 const BUTTON_SPACE = 32;
static Xuint8 const BUTTON_W = 119;
static Xuint8 const BUTTON_A = 97;
static Xuint8 const BUTTON_S = 115;
static Xuint8 const BUTTON_D = 100;

static Xuint8 const UP = 1;
static Xuint8 const DOWN = 2;
static Xuint8 const LEFT = 3;
static Xuint8 const RIGHT = 4;


struct Tile* headTile = NULL;

Tile* row[X][Y];
Tile* col[Y][X];

Xuint8 snakemap [X/8*Y];

void print(char *str);
void initMap();
void connectRow();
void makesnakemap();
void printsnake();

Xuint8 dir;
Xuint8 prevDir;
Xuint8 a;

int main()
{
	xil_printf("\033c");
	volatile Xuint8 i, j, k;
    init_platform();

	XIntc_RegisterHandler( XPAR_INTC_0_BASEADDR, XPAR_MICROBLAZE_0_INTC_LCD_SCREEN_0_IRQ_INTR, lcd_IT_handler,NULL);

	XIntc_MasterEnable(XPAR_INTC_0_BASEADDR);
	XIntc_EnableIntr(XPAR_INTC_0_BASEADDR, XPAR_LCD_SCREEN_0_IRQ_MASK);
		//MEM32(XPAR_LVL_INDICATOR_0_BASEADDR + LVL_IE_REG) = LVL_ERROR_IRQ ;
	microblaze_enable_interrupts();
    itit_LCD(0);
    clear_LCD();

    xil_printf("Hello vilag");
    initMap();
	headTile = row[0][0];
	Tile_changeType(headTile, HEAD);
	Tile_changeType(row[1][2], FOOD);
	Tile_changeType(row[2][1], FOOD);
	//printsnake();

	for(i = 0; i< 8; i++){
		for(j=0; j<102; j++){
			write_Memory(i,j,snake[i*102 + j]);
		}
	}

	//for(i = 0; i< X/8*Y-3; i++) snakemap[i]= 0xff;
	//for(i = 0; i< X/8*Y; i++) xil_printf("\r\nfirst: %d", snakemap[i]);


		//write_Memory(i,j,snake[i*102 + j]);
		//write_Pixel(j,i);


	makesnakemap();
	write_Area(1 ,8, X/8, Y, snakemap);
	//clear_Area(3,8,1,8);

    xil_printf("Vege vilag");


    while (1) {

    		printsnake();
    		makesnakemap();
    		write_Area(1 ,8, X/8, Y, snakemap);

    		dir = RIGHT;
    		prevDir = dir;
    		a = 'd';

    		if(a == 'w' || a == 's' || a == 'a' || a == 'd')
    		{

    			Tile* headTileCandidate = NULL;

    			dir = prevDir;

    			if (dir == RIGHT) {
    				if (prevDir == LEFT) {
    					continue;
    				}
    				if (prevDir == UP) {
    					headTileCandidate = headTile->front;
    				}
    				else if (prevDir == DOWN) {
    					headTileCandidate = headTile->front;
    				}
    				else if (prevDir == RIGHT) {
    					headTileCandidate = headTile->front;
    				}
    			}

    			else if (dir == DOWN) {
    				if (prevDir == UP) {
    					continue;
    				}
    				if (prevDir == DOWN) {
    					headTileCandidate = headTile->right;
    				}
    				else if (prevDir == LEFT) {
    					headTileCandidate = headTile->right;
    				}
    				else if (prevDir == RIGHT) {
    					headTileCandidate = headTile->right;
    				}
    			}

    			else if (dir == LEFT) {
    				if (prevDir == RIGHT) {
    					continue;
    				}
    				if (prevDir == UP) {
    					headTileCandidate = headTile->back;
    				}
    				else if (prevDir == DOWN) {
    					headTileCandidate = headTile->back;
    				}
    				else if (prevDir == LEFT) {
    					headTileCandidate = headTile->back;
    				}

    			}

    			else if (dir == UP) {
    				if (prevDir == DOWN) {
    					continue;
    				}
    				if (prevDir == UP) {
    					headTileCandidate = headTile->left;
    				}
    				else if (prevDir == LEFT) {
    					headTileCandidate = headTile->left;
    				}
    				else if (prevDir == RIGHT) {
    					headTileCandidate = headTile->left;
    				}
    			}

    			if (headTileCandidate->type == TAIL) {

    				if (headTileCandidate->prevTile == NULL)
    				{
    					Tile* headTileTemp = headTile;
    					while (headTileTemp->prevTile != NULL)
    					{
    						if (headTileTemp->prevTile->prevTile == NULL)
    						{
    							headTileTemp->prevTile = NULL;
    							headTileCandidate->prevTile = headTile;
    							Tile_changeType(headTileCandidate, HEAD);
    							Tile_changeType(headTile, TAIL);


    						}
    						else
    						{
    							headTileTemp = headTileTemp->prevTile;
    							Tile_changeType(headTileTemp, TAIL);
    						}

    					}

    					headTile = headTileCandidate;
    				}

    				else if (headTileCandidate->prevTile != NULL)
    				{
    					while (1){
    						printsnake();
    						xil_printf("\nGAME OVER!\n");
    						xil_printf("Magadba mentel!\n\n");
    						xil_printf("Again? Press 'r' button!\n");
    						xil_printf("Quit? Press 'q' button!");

    					}
    				}



    			}

    			if (headTileCandidate->type == FOOD)
    			{
    				headTileCandidate->prevTile = headTile;
    				headTileCandidate->prevTile->type = TAIL;
    				headTile = headTileCandidate;
    				Tile_changeType(headTile, HEAD);
    			}

    			else if (headTileCandidate->type == EMPTY)
    			{
    				headTileCandidate->prevTile = headTile;
    				Tile_changeType(headTile, TAIL);
    				Tile* headTileTemp = headTileCandidate;
    				while (headTileTemp->prevTile != NULL)
    				{
    					if (headTileTemp->prevTile->prevTile == NULL)
    					{
    						Tile_changeType(headTileTemp->prevTile, EMPTY);
    						headTileTemp->prevTile = NULL;

    					}
    					else
    					{
    						headTileTemp = headTileTemp->prevTile;
    					}

    				}

    				headTile = headTileCandidate;
    				Tile_changeType(headTile, HEAD);

    			}
    		}
    	}
    return 0;
}


void initMap(){

	Xuint8 i,j;
	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			row[i][j] = Tile_create();
		}
	}

	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			Tile_changeType(row[i][j], EMPTY);
		}
	}


	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			col[j][i] = row[i][j];
		}
	}
	connectRow();

}

void connectRow() {
	Xuint8 i,j;

	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			row[i][j]->front = row[i][(j + 1) % Y];
		}
	}
	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			row[i][j]->back= row[i][(j + Y - 1) % Y];
		}
	}

	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			row[i][j]->left = row[(i + X -1) % X][j];
		}
	}

	for (i = 0; i < X; i++) {
		for (j = 0; j < Y; j++) {
			row[i][j]->right = row[(i + 1) % X][j];
		}
	}
}

/*
void makemap(){
	Xuint8 temp = 0, i, j;
	for(i = 0; i < 8; i ++){
		temp = 0;
		if(row[i][0]->type != EMPTY )
			temp = temp | 0x01;
		if(row[i][1]->type != EMPTY )
			temp = temp | 0x02;
		if(row[i][2]->type != EMPTY )
			temp = temp | 0x04;
		if(row[i][3]->type != EMPTY )
			temp = temp | 0x08;
		if(row[i][4]->type != EMPTY )
			temp = temp | 0x10;
		write_Memory(1,i+3,temp);
		//xil_printf("%d: %d\r\n" ,i, temp);
	}
}*/


void printsnake() {

	Xuint8 i, j;

	//xil_printf("\033[H");
	xil_printf("\033c");
	xil_printf("\r\n");
	xil_printf("+");
	for (i = 0; i < Y; i++) xil_printf("-");
	xil_printf("+\r\n");

	for (i = 0; i < X; i++) {
		xil_printf("|");
		for (j = 0; j < Y; j++) {
			xil_printf("%c", row[i][j]->type);
		}
		xil_printf("|\r\n");
	}
	xil_printf("+");
	for (i = 0; i < Y; i++) xil_printf("-");
	xil_printf("+\r\n");
	xil_printf("\r\n");
}

void makesnakemap(){
	Xuint8 temp = 0, i, j;
	for(i = 0; i < X/8; i ++){
		for(j = 0; j < Y ; j++){
			temp = 0;
			if(row[0+i][j]->type != EMPTY )
				temp = temp | 0x01;
			if(row[1+i][j]->type != EMPTY )
				temp = temp | 0x02;
			if(row[2+i][j]->type != EMPTY )
				temp = temp | 0x04;
			if(row[3+i][j]->type != EMPTY )
				temp = temp | 0x08;
			if(row[4+i][j]->type != EMPTY )
				temp = temp | 0x10;
			if(row[5+i][j]->type != EMPTY )
				temp = temp | 0x20;
			if(row[6+i][j]->type != EMPTY )
				temp = temp | 0x40;
			if(row[7+i][j]->type != EMPTY )
				temp = temp | 0x80;
			//xil_printf("\r\n %d %d %d make %d" ,i,j,i*j + j, temp);
			snakemap[i*j + j] = temp;
		}

	}
}

















