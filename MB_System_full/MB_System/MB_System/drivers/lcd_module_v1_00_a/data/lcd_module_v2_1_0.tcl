##############################################################################
## Filename:          F:\curr_ISE_proj\mikrorendszerek\MB_System_full\MB_System/drivers/lcd_module_v1_00_a/data/lcd_module_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Fri Oct 27 23:50:52 2017 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "lcd_module" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
