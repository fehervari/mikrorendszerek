#include <xparameters.h>
#include <xintc_l.h>
#include <xtmrctr_l.h>
#include <mb_interface.h>


//*****************************************************************************
//* Makrók a memória írásához és olvasásához.                                 *
//*****************************************************************************
#define MEM8(addr)   (*(volatile unsigned char *)(addr))
#define MEM16(addr)  (*(volatile unsigned short *)(addr))
#define MEM32(addr)  (*(volatile unsigned long *)(addr))


//*****************************************************************************
//* Definíciók a folyadékszint jelzõ perifériához.                            *
//*****************************************************************************
//Státusz regiszter: 32 bites, csak olvasható
#define LVL_STATUS_REG				0x00
//Megszakítás engedélyezõ regiszter: 32 bites, írható/olvasható
#define LVL_IE_REG					0x04
//Megszakítás flag regiszter: 32 bites, olvasható  és '1' beírással törölhetõ
#define LVL_IF_REG					0x08

//A folyadékszint jelzõ periféria megszakítás eseményei.
#define LVL_FULL_IRQ				(1 << 0)
#define LVL_EMPTY_IRQ				(1 << 1)
#define LVL_ERROR_IRQ				(1 << 2)


//*****************************************************************************
//* Definíciók a SIMPLEIO perifériához.                                       *
//*****************************************************************************
//LED regiszter: 8 bites, írható/olvasható
#define SIMPLEIO_LED_REG			0x00
//DISP1 regiszter: 8 bites, írható/olvasható
#define SIMPLEIO_DISP1_REG			0x01
//DISP1 regiszter: 8 bites, írható/olvasható
#define SIMPLEIO_DISP2_REG			0x02
//GPIO adatregiszter: 16 bites, írható/olvasható
#define SIMPLEIO_GPIO_DATA_REG		0x04
//DIP kapcsoló regiszter: 8 bites, csak olvasható
#define SIMPLEIO_DIPSW_REG			0x06
//GPIO irányregiszter: 16 bites, írható/olvasható
#define SIMPLEIO_GPIO_DIR_REG		0x08
//Navigációs kapcsoló és nyomógomb regiszter: 8 bites, csak olvasható
#define SIMPLEIO_NAVSW_BTN_REG		0x0a
//Megszakítás engedélyezõ regiszter: 8 bites, írható/olvasható
#define SIMPLEIO_IE_REG				0x0c
//Megszakítás flag regiszter: 8 bites, olvasható és '1' beírással törölhetõ
#define SIMPLEIO_IF_REG				0x0d

//A SIMPLEIO periféria megszakítás eseményei.
#define SIMPLEIO_DIPSW_CHANGED_IRQ	(1 << 0)
#define SIMPLEIO_NAVSW_CHANGED_IRQ	(1 << 1)
#define SIMPLEIO_BTN_CHANGED_IRQ	(1 << 2)
#define SIMPLEIO_GPIO_CHANGED_IRQ	(1 << 3)


//*****************************************************************************
//* Fõprogram.                                                                *
//*****************************************************************************
int main()
{
	return 0;
}



