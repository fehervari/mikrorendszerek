##############################################################################
## Filename:          F:\curr_ISE_proj\mikrorendszerek\SP6BoardLinuxAXI_14_7\SP6BoardLinuxAXI/drivers/cpld_if_v1_00_a/data/cpld_if_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Fri Oct 27 12:47:54 2017 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "cpld_if" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
