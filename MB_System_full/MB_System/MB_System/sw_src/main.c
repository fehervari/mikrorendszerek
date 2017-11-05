#include <xparameters.h>
#include <xintc_l.h>
#include <xtmrctr_l.h>
#include <mb_interface.h>


//*****************************************************************************
//* Makr�k a mem�ria �r�s�hoz �s olvas�s�hoz.                                 *
//*****************************************************************************
#define MEM8(addr)   (*(volatile unsigned char *)(addr))
#define MEM16(addr)  (*(volatile unsigned short *)(addr))
#define MEM32(addr)  (*(volatile unsigned long *)(addr))


//*****************************************************************************
//* Defin�ci�k a folyad�kszint jelz� perif�ri�hoz.                            *
//*****************************************************************************
//St�tusz regiszter: 32 bites, csak olvashat�
#define LVL_STATUS_REG				0x00
//Megszak�t�s enged�lyez� regiszter: 32 bites, �rhat�/olvashat�
#define LVL_IE_REG					0x04
//Megszak�t�s flag regiszter: 32 bites, olvashat�  �s '1' be�r�ssal t�r�lhet�
#define LVL_IF_REG					0x08

//A folyad�kszint jelz� perif�ria megszak�t�s esem�nyei.
#define LVL_FULL_IRQ				(1 << 0)
#define LVL_EMPTY_IRQ				(1 << 1)
#define LVL_ERROR_IRQ				(1 << 2)


//*****************************************************************************
//* Defin�ci�k a SIMPLEIO perif�ri�hoz.                                       *
//*****************************************************************************
//LED regiszter: 8 bites, �rhat�/olvashat�
#define SIMPLEIO_LED_REG			0x00
//DISP1 regiszter: 8 bites, �rhat�/olvashat�
#define SIMPLEIO_DISP1_REG			0x01
//DISP1 regiszter: 8 bites, �rhat�/olvashat�
#define SIMPLEIO_DISP2_REG			0x02
//GPIO adatregiszter: 16 bites, �rhat�/olvashat�
#define SIMPLEIO_GPIO_DATA_REG		0x04
//DIP kapcsol� regiszter: 8 bites, csak olvashat�
#define SIMPLEIO_DIPSW_REG			0x06
//GPIO ir�nyregiszter: 16 bites, �rhat�/olvashat�
#define SIMPLEIO_GPIO_DIR_REG		0x08
//Navig�ci�s kapcsol� �s nyom�gomb regiszter: 8 bites, csak olvashat�
#define SIMPLEIO_NAVSW_BTN_REG		0x0a
//Megszak�t�s enged�lyez� regiszter: 8 bites, �rhat�/olvashat�
#define SIMPLEIO_IE_REG				0x0c
//Megszak�t�s flag regiszter: 8 bites, olvashat� �s '1' be�r�ssal t�r�lhet�
#define SIMPLEIO_IF_REG				0x0d

//A SIMPLEIO perif�ria megszak�t�s esem�nyei.
#define SIMPLEIO_DIPSW_CHANGED_IRQ	(1 << 0)
#define SIMPLEIO_NAVSW_CHANGED_IRQ	(1 << 1)
#define SIMPLEIO_BTN_CHANGED_IRQ	(1 << 2)
#define SIMPLEIO_GPIO_CHANGED_IRQ	(1 << 3)


//*****************************************************************************
//* F�program.                                                                *
//*****************************************************************************
int main()
{
	return 0;
}



