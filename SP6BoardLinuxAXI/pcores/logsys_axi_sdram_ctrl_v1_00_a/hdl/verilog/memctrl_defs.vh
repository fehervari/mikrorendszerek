//******************************************************************************
//* Constant definitions for the memory controller.                            *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 2.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************

//******************************************************************************
//* Value to be loaded into the SDRAM mode register.                           *
//******************************************************************************
//Burst length: 1         (000) -------------------------\
//              2         (001)                          |
//              4         (010)                          |
//              8         (011)                          |
//              full page (111)                          |
//Access type : sequential  (0) ---------------------\   |
//              interleaved (1)                      |   |
//CAS latency : 2 (010)         -------------------\ |   |
//              3 (011)                            | |   |
//Operation   : standard (00)   ---------------\   | |   |
//Write mode  : burst  (0)      ------------\  |   | |   |
//              single (1)                  |  |   | |   |
//                                          |  |   | |   |
//                                          V  V   V V   V
localparam SDRAM_MREG_VALUE_CL2 = 15'b00000_0_00_010_0_001;
localparam SDRAM_MREG_VALUE_CL3 = 15'b00000_0_00_011_0_001;


//******************************************************************************
//* SDRAM commands.                                                            *
//******************************************************************************
//SDRAM A[10] --------------------------------------\
//SDRAM WEn   ------------------------------------\ |
//SDRAM CASn  ---------------------------------\  | |
//SDRAM RASn  ------------------------------\  |  | |
//SDRAM CSn   ---------------------------\  |  |  | |
//                                       |  |  |  | |
//                                       V  V  V  V V
localparam CMD_SDRAM_DESELECT      = 9'b11_11_11_11_0;
localparam CMD_SDRAM_NOP           = 9'b10_11_11_11_0;
localparam CMD_SDRAM_ACTIVATE_ROW  = 9'b10_10_11_11_0;
localparam CMD_SDRAM_READ_CL2      = 9'b10_11_10_11_0;
localparam CMD_SDRAM_READ_AP_CL2   = 9'b10_11_10_11_1;
localparam CMD_SDRAM_READ_CL3      = 9'b01_11_01_11_0;
localparam CMD_SDRAM_READ_AP_CL3   = 9'b01_11_01_11_1;
localparam CMD_SDRAM_WRITE         = 9'b10_11_10_10_0;
localparam CMD_SDRAM_WRITE_AP      = 9'b10_11_10_10_1;
localparam CMD_SDRAM_BURST_TERM    = 9'b10_11_11_10_0;
localparam CMD_SDRAM_PRECHARGE     = 9'b10_10_11_10_0;
localparam CMD_SDRAM_PRECHARGE_ALL = 9'b10_10_11_10_1;
localparam CMD_SDRAM_AUTO_REFRESH  = 9'b10_10_10_11_0;
localparam CMD_SDRAM_MODE_REG_WR   = 9'b10_10_10_10_0;


//******************************************************************************
//* SDRAM address select values.                                               *
//******************************************************************************
localparam ADDR_SEL_SDRAM_COL  = 2'b00;
localparam ADDR_SEL_SDRAM_ROW  = 2'b01;
localparam ADDR_SEL_SDRAM_MREG = 2'b10;

