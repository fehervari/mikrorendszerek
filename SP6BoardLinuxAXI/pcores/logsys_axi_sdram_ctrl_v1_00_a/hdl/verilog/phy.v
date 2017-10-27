//******************************************************************************
//* Physical interface of the memory controller.                               *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 2.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module phy(
   //Clock and reset.
   input  wire        clk,                //1x system clock signal
   input  wire        clk2x,              //2x system clock signal
   input  wire        rstn,               //Asynchronous reset signal (active-low)
   
   //Signals from the memory controller.
   input  wire        sdram_cke_set,      //SDRAM clock enable output set signal
   input  wire [14:0] sdram_mreg_val,     //Value of the SDRAM mode register
   input  wire [8:0]  sdram_cmd,          //SDRAM command input
   input  wire [24:1] address_in,         //Memory address input
   input  wire [1:0]  sdram_addr_sel,     //SDRAM address select signal
   input  wire [31:0] write_data,         //Write data input (little-endian)
   input  wire        dout_buf_tri,       //Output buffer tri-state signal  
   input  wire [3:0]  byte_enable,        //Byte enable signals (little-endian)
   input  wire        be_valid,           //Byte enable valid signal
   input  wire        be_delay_sel,       //Byte enable delay select
   input  wire        iodelay_cal,        //IODELAY calibration start signal
   input  wire        init_done,          //SDRAM initialization done signal
   
   //Signals to the memory controller.
   output wire [31:0] read_data,          //Read data output (little-endian)
   output wire [1:0]  sdram_bank_addr,    //SDRAM bank address
   output wire [12:0] sdram_row_addr,     //SDRAM row address
   output wire [8:0]  sdram_col_addr,     //SDRAM column address
   output reg         iodelay_busy,       //IODELAY calibration is in progress
   
   //Common memory interface signals.
   output wire [17:0] mem_addr,           //Memory address bus.
   output wire [15:0] mem_data_O,         //Memory data bus.
   input  wire [15:0] mem_data_I,
   output wire [15:0] mem_data_T,
   output wire        mem_wen,            //Memory write enable signal (active-low).
   output wire        mem_lbn,            //Lower data byte enable (active-low).
   output wire        mem_ubn,            //Upper data byte enable (active-low).
   
   //Signals related to the SRAM.
   output wire        sram_csn,           //SRAM chip select signal (active low).
   output wire        sram_oen,           //SRAM output enable signal (active low).
   
   //Signals related to the SDRAM.
   output wire        sdram_clk,          //SDRAM clock signal.
   output wire        sdram_cke,          //SDRAM clock enable signal.
   output wire        sdram_csn           //SDRAM chip select signal (active low).
);

`include "memctrl_defs.vh"
`include "functions.vh"

//******************************************************************************
//* Driving the SDRAM clock. The 2x system clock is 180° phase shifted so the  *
//* SDRAM signals have Tclk2x/2 setup and hold time.                           *
//******************************************************************************
ODDR2 #(
   .DDR_ALIGNMENT("NONE"),                // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b0),                           // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("SYNC")                        // Specifies "SYNC" or "ASYNC" set/reset
) sdram_clk_out (
   .Q(sdram_clk),                         // 1-bit DDR output data
   .C0(clk2x),                            // 1-bit clock input
   .C1(~clk2x),                           // 1-bit clock input
   .CE(1'b1),                             // 1-bit clock enable input
   .D0(1'b0),                             // 1-bit data input (associated with C0)
   .D1(1'b1),                             // 1-bit data input (associated with C1)
   .R(1'b0),                              // 1-bit reset input
   .S(1'b0)                               // 1-bit set input
);


//******************************************************************************
//* SDRAM clock enable register.                                               *
//******************************************************************************
(* iob = "force" *)
reg sdram_cke_reg;
reg sdram_cke_reg_in;

always @(posedge clk or negedge rstn)
begin
   if (rstn == 0)
      sdram_cke_reg_in <= 1'b0;
   else
      if (sdram_cke_set)
         sdram_cke_reg_in <= 1'b1;
end

always @(posedge clk or negedge rstn)
begin
   if (rstn == 0)
      sdram_cke_reg <= 1'b0;
   else
      sdram_cke_reg <= sdram_cke_reg_in;
end

assign sdram_cke = sdram_cke_reg;


//******************************************************************************
//* Driving the SRAM and SDRAM control signals.                                *
//******************************************************************************
wire sdram_rasn;
wire sdram_casn;
wire sdram_a10 = sdram_cmd[0];

//SDRAM WEn signal.
ODDR2 #(
   .DDR_ALIGNMENT("C0"),                     // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                              // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                          // Specifies "SYNC" or "ASYNC" set/reset
) mem_wen_reg (
   .Q(mem_wen),                              // 1-bit DDR output data
   .C0(clk),                                 // 1-bit clock input
   .C1(~clk),                                // 1-bit clock input
   .CE(1'b1),                                // 1-bit clock enable input
   .D0(sdram_cmd[1]),                        // 1-bit data input (associated with C0)
   .D1(sdram_cmd[2]),                        // 1-bit data input (associated with C1)
   .R(1'b0),                                 // 1-bit reset input
   .S(~rstn)                                 // 1-bit set input
);

//SDRAM CASn signal.
ODDR2 #(
   .DDR_ALIGNMENT("C0"),                     // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                              // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                          // Specifies "SYNC" or "ASYNC" set/reset
) sdram_casn_reg (
   .Q(sdram_casn),                           // 1-bit DDR output data
   .C0(clk),                                 // 1-bit clock input
   .C1(~clk),                                // 1-bit clock input
   .CE(1'b1),                                // 1-bit clock enable input
   .D0(sdram_cmd[3]),                        // 1-bit data input (associated with C0)
   .D1(sdram_cmd[4]),                        // 1-bit data input (associated with C1)
   .R(1'b0),                                 // 1-bit reset input
   .S(~rstn)                                 // 1-bit set input
);

//SDRAM RASn signal.
ODDR2 #(
   .DDR_ALIGNMENT("C0"),                     // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                              // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                          // Specifies "SYNC" or "ASYNC" set/reset
) sdram_rasn_reg (
   .Q(sdram_rasn),                           // 1-bit DDR output data
   .C0(clk),                                 // 1-bit clock input
   .C1(~clk),                                // 1-bit clock input
   .CE(1'b1),                                // 1-bit clock enable input
   .D0(sdram_cmd[5]),                        // 1-bit data input (associated with C0)
   .D1(sdram_cmd[6]),                        // 1-bit data input (associated with C1)
   .R(1'b0),                                 // 1-bit reset input
   .S(~rstn)                                 // 1-bit set input
);

//SDRAM CSn signal.
ODDR2 #(
   .DDR_ALIGNMENT("C0"),                     // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                              // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                          // Specifies "SYNC" or "ASYNC" set/reset
) sdram_csn_reg (
   .Q(sdram_csn),                            // 1-bit DDR output data
   .C0(clk),                                 // 1-bit clock input
   .C1(~clk),                                // 1-bit clock input
   .CE(1'b1),                                // 1-bit clock enable input
   .D0(sdram_cmd[7]),                        // 1-bit data input (associated with C0)
   .D1(sdram_cmd[8]),                        // 1-bit data input (associated with C1)
   .R(1'b0),                                 // 1-bit reset input
   .S(~rstn)                                 // 1-bit set input
);

//SRAM control signals.
assign sram_oen  = 1'b1;
assign sram_csn  = 1'b1;


//******************************************************************************
//* Driving the memory address bus.                                            *
//******************************************************************************
(* iob = "force" *)
reg [14:0] mem_addr_reg;

assign sdram_col_addr  = address_in[9:1];
assign sdram_row_addr  = address_in[24:12];
assign sdram_bank_addr = address_in[11:10];

always @(posedge clk)
begin
   case (sdram_addr_sel)
      ADDR_SEL_SDRAM_COL : mem_addr_reg <= {sdram_bank_addr, 2'b00, sdram_a10, 1'b0, sdram_col_addr};
      ADDR_SEL_SDRAM_ROW : mem_addr_reg <= {sdram_bank_addr, sdram_row_addr};
      ADDR_SEL_SDRAM_MREG: mem_addr_reg <= sdram_mreg_val;
      default            : mem_addr_reg <= 15'd0;
   endcase
end

assign mem_addr[14:0] = mem_addr_reg;
assign mem_addr[15]   = sdram_rasn;
assign mem_addr[16]   = sdram_casn;
assign mem_addr[17]   = 1'b0;


//******************************************************************************
//* Driving the memory output data bus and the output buffer enable signals.   *
//******************************************************************************
reg         iodelay_cal_data;
wire [31:0] mem_data_out;
wire        mem_data_tri;

genvar j;

always @(posedge clk or negedge rstn)
begin
   if (rstn == 0)
      iodelay_cal_data <= 1'b0;
   else
      if (iodelay_busy)
         iodelay_cal_data <= ~iodelay_cal_data;
end

assign mem_data_out[15:0]  = (iodelay_busy) ? {16{ iodelay_cal_data}} : write_data[15:0];
assign mem_data_out[31:16] = (iodelay_busy) ? {16{~iodelay_cal_data}} : write_data[31:16];
assign mem_data_tri        = (iodelay_busy) ? 1'b0 : dout_buf_tri;

generate
   for (j = 0; j < 16; j = j + 1)
   begin: mem_dout_loop
      ODDR2 #(
         .DDR_ALIGNMENT("C0"),            // Sets output alignment to "NONE", "C0" or "C1" 
         .INIT(1'b0),                     // Sets initial state of the Q output to 1'b0 or 1'b1
         .SRTYPE("ASYNC")                 // Specifies "SYNC" or "ASYNC" set/reset
      ) mem_data_O_reg (
         .Q(mem_data_O[j]),               // 1-bit DDR output data
         .C0(clk),                        // 1-bit clock input
         .C1(~clk),                       // 1-bit clock input
         .CE(1'b1),                       // 1-bit clock enable input
         .D0(mem_data_out[j]),            // 1-bit data input (associated with C0)
         .D1(mem_data_out[16+j]),         // 1-bit data input (associated with C1)
         .R(~rstn),                       // 1-bit reset input
         .S(1'b0)                         // 1-bit set input
      );
      
      ODDR2 #(
         .DDR_ALIGNMENT("C0"),            // Sets output alignment to "NONE", "C0" or "C1" 
         .INIT(1'b1),                     // Sets initial state of the Q output to 1'b0 or 1'b1
         .SRTYPE("ASYNC")                 // Specifies "SYNC" or "ASYNC" set/reset
      ) mem_data_T_reg (
         .Q(mem_data_T[j]),               // 1-bit DDR output data
         .C0(clk),                        // 1-bit clock input
         .C1(~clk),                       // 1-bit clock input
         .CE(1'b1),                       // 1-bit clock enable input
         .D0(mem_data_tri),               // 1-bit data input (associated with C0)
         .D1(mem_data_tri),               // 1-bit data input (associated with C1)
         .R(1'b0),                        // 1-bit reset input
         .S(~rstn)                        // 1-bit set input
      );
   end
endgenerate


//******************************************************************************
//* Driving the memory byte mask signals.                                      *
//******************************************************************************
wire [3:0] byte_mask = (be_valid) ? ~byte_enable : 4'b1111;

//Byte mask delay register (for CL=3 reads).
reg [3:0] bm_cl3rd_delay;

always @(posedge clk or negedge rstn)
begin
   if (rstn == 0)
      bm_cl3rd_delay <= 4'b1111;
   else
      bm_cl3rd_delay <= byte_mask;
end

//Output byte mask register.
wire [3:0] bm_reg_din = (be_delay_sel) ? bm_cl3rd_delay : byte_mask;

ODDR2 #(
   .DDR_ALIGNMENT("C0"),            // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                     // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                 // Specifies "SYNC" or "ASYNC" set/reset
) mem_lbn_reg (
   .Q(mem_lbn),                     // 1-bit DDR output data
   .C0(clk),                        // 1-bit clock input
   .C1(~clk),                       // 1-bit clock input
   .CE(1'b1),                       // 1-bit clock enable input
   .D0(bm_reg_din[0]),              // 1-bit data input (associated with C0)
   .D1(bm_reg_din[2]),              // 1-bit data input (associated with C1)
   .R(1'b0),                        // 1-bit reset input
   .S(~rstn)                        // 1-bit set input
);

ODDR2 #(
   .DDR_ALIGNMENT("C0"),            // Sets output alignment to "NONE", "C0" or "C1" 
   .INIT(1'b1),                     // Sets initial state of the Q output to 1'b0 or 1'b1
   .SRTYPE("ASYNC")                 // Specifies "SYNC" or "ASYNC" set/reset
) mem_ubn_reg (
   .Q(mem_ubn),                     // 1-bit DDR output data
   .C0(clk),                        // 1-bit clock input
   .C1(~clk),                       // 1-bit clock input
   .CE(1'b1),                       // 1-bit clock enable input
   .D0(bm_reg_din[1]),              // 1-bit data input (associated with C0)
   .D1(bm_reg_din[3]),              // 1-bit data input (associated with C1)
   .R(1'b0),                        // 1-bit reset input
   .S(~rstn)                        // 1-bit set input
);


//******************************************************************************
//* Signals related to the calibration of the IODELAYs.                        *
//******************************************************************************
reg         iodelay_cal_reg;
reg         iodelay_rst_reg;
wire [15:0] iodelay_cal_busy;

always @(posedge clk or negedge rstn)
begin
   if (rstn == 0)
   begin
      iodelay_cal_reg <= 1'b0;
      iodelay_rst_reg <= 1'b0;
      iodelay_busy    <= 1'b0;
   end
   else
   begin
      iodelay_cal_reg <= iodelay_cal;
      iodelay_rst_reg <= iodelay_cal & ~init_done;
      iodelay_busy    <= |iodelay_cal_busy;
   end
end


//******************************************************************************
//* Sampling the memory input data bus.                                        *
//******************************************************************************
genvar k;

generate
   for (k = 0; k < 16; k = k + 1)
   begin: mem_din_loop
      wire idelay_dout;
      
      IODELAY2 #(
         .COUNTER_WRAPAROUND("STAY_AT_LIMIT"),     // "STAY_AT_LIMIT" or "WRAPAROUND" 
         .DATA_RATE("DDR"),                        // "SDR" or "DDR" 
         .DELAY_SRC("IDATAIN"),                    // "IO", "ODATAIN" or "IDATAIN" 
         .IDELAY2_VALUE(0),                        // Delay value when IDELAY_MODE="PCI" (0-255)
         .IDELAY_MODE("NORMAL"),                   // "NORMAL" or "PCI" 
         .IDELAY_TYPE("VARIABLE_FROM_HALF_MAX"),   // "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO",
                                                   // "VARIABLE_FROM_HALF_MAX" or "DIFF_PHASE_DETECTOR" 
         .IDELAY_VALUE(0),                         // Amount of taps for fixed input delay (0-255)
         .ODELAY_VALUE(0),                         // Amount of taps fixed output delay (0-255)
         .SERDES_MODE("NONE"),                     // "NONE", "MASTER" or "SLAVE" 
         .SIM_TAPDELAY_VALUE(50)                   // Per tap delay used for simulation in ps
      ) idelay (
         .BUSY(iodelay_cal_busy[k]),               // 1-bit output: Busy output after CAL
         .DATAOUT(idelay_dout),                    // 1-bit output: Delayed data output to ISERDES/input register
         .DATAOUT2(),                              // 1-bit output: Delayed data output to general FPGA fabric
         .DOUT(),                                  // 1-bit output: Delayed data output
         .TOUT(),                                  // 1-bit output: Delayed 3-state output
         .CAL(iodelay_cal_reg),                    // 1-bit input: Initiate calibration input
         .CE(1'b0),                                // 1-bit input: Enable INC input
         .CLK(clk),                                // 1-bit input: Clock input
         .IDATAIN(mem_data_I[k]),                  // 1-bit input: Data input (connect to top-level port or I/O buffer)
         .INC(1'b0),                               // 1-bit input: Increment / decrement input
         .IOCLK0(clk),                             // 1-bit input: Input from the I/O clock network
         .IOCLK1(~clk),                            // 1-bit input: Input from the I/O clock network
         .ODATAIN(1'b0),                           // 1-bit input: Output data input from output register or OSERDES2.
         .RST(iodelay_rst_reg),                    // 1-bit input: Reset to zero or 1/2 of total delay period
         .T(1'b1)                                  // 1-bit input: 3-state input signal
      );
      
      IDDR2 #(
         .DDR_ALIGNMENT("C0"),                     // Sets output alignment to "NONE", "C0" or "C1" 
         .INIT_Q0(1'b0),                           // Sets initial state of the Q0 output to 1'b0 or 1'b1
         .INIT_Q1(1'b0),                           // Sets initial state of the Q1 output to 1'b0 or 1'b1
         .SRTYPE("ASYNC")                          // Specifies "SYNC" or "ASYNC" set/reset
      ) mem_data_I_reg (
         .Q0(read_data[16+k]),                     // 1-bit output captured with C0 clock
         .Q1(read_data[k]),                        // 1-bit output captured with C1 clock
         .C0(clk),                                 // 1-bit clock input
         .C1(~clk),                                // 1-bit clock input
         .CE(1'b1),                                // 1-bit clock enable input
         .D(idelay_dout),                          // 1-bit DDR data input
         .R(~rstn),                                // 1-bit reset input
         .S(1'b0)                                  // 1-bit set input
      );
   end
endgenerate


endmodule
