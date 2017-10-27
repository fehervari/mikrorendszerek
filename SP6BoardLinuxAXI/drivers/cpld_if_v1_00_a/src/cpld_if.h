/*****************************************************************************
* Filename:          F:\curr_ISE_proj\mikrorendszerek\SP6BoardLinuxAXI_14_7\SP6BoardLinuxAXI/drivers/cpld_if_v1_00_a/src/cpld_if.h
* Version:           1.00.a
* Description:       cpld_if Driver Header File
* Date:              Fri Oct 27 12:47:54 2017 (by Create and Import Peripheral Wizard)
*****************************************************************************/

#ifndef CPLD_IF_H
#define CPLD_IF_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xil_io.h"

/************************** Constant Definitions ***************************/


/**
 * User Logic Slave Space Offsets
 * -- SLV_REG0 : user logic slave module register 0
 * -- SLV_REG1 : user logic slave module register 1
 * -- SLV_REG2 : user logic slave module register 2
 */
#define CPLD_IF_USER_SLV_SPACE_OFFSET (0x00000000)
#define CPLD_IF_SLV_REG0_OFFSET (CPLD_IF_USER_SLV_SPACE_OFFSET + 0x00000000)
#define CPLD_IF_SLV_REG1_OFFSET (CPLD_IF_USER_SLV_SPACE_OFFSET + 0x00000004)
#define CPLD_IF_SLV_REG2_OFFSET (CPLD_IF_USER_SLV_SPACE_OFFSET + 0x00000008)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a CPLD_IF register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the CPLD_IF device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void CPLD_IF_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define CPLD_IF_mWriteReg(BaseAddress, RegOffset, Data) \
 	Xil_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a CPLD_IF register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the CPLD_IF device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 CPLD_IF_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define CPLD_IF_mReadReg(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read 32 bit value to/from CPLD_IF user logic slave registers.
 *
 * @param   BaseAddress is the base address of the CPLD_IF device.
 * @param   RegOffset is the offset from the slave register to write to or read from.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note
 * C-style signature:
 * 	void CPLD_IF_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
 * 	Xuint32 CPLD_IF_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define CPLD_IF_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (CPLD_IF_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
#define CPLD_IF_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (CPLD_IF_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
#define CPLD_IF_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (CPLD_IF_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))

#define CPLD_IF_mReadSlaveReg0(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (CPLD_IF_SLV_REG0_OFFSET) + (RegOffset))
#define CPLD_IF_mReadSlaveReg1(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (CPLD_IF_SLV_REG1_OFFSET) + (RegOffset))
#define CPLD_IF_mReadSlaveReg2(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (CPLD_IF_SLV_REG2_OFFSET) + (RegOffset))

/************************** Function Prototypes ****************************/


/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the CPLD_IF instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus CPLD_IF_SelfTest(void * baseaddr_p);
/**
*  Defines the number of registers available for read and write*/
#define TEST_AXI_LITE_USER_NUM_REG 3


#endif /** CPLD_IF_H */
