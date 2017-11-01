//----------------------------------------------------------------------------
// user_logic.v - module
//----------------------------------------------------------------------------
//
// ***************************************************************************
// ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
// **                                                                       **
// ** Xilinx, Inc.                                                          **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
// ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
// ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
// ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
// ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
// ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
// ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
// ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
// ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
// ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
// ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
// ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
// ** FOR A PARTICULAR PURPOSE.                                             **
// **                                                                       **
// ***************************************************************************
//
//----------------------------------------------------------------------------
// Filename:          user_logic.v
// Version:           1.00.a
// Description:       User logic module.
// Date:              Fri Oct 27 12:47:44 2017 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//   component instantiations:              "<ENTITY_>I_<#|FUNC>"
//----------------------------------------------------------------------------

`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic
(
  // -- ADD USER PORTS BELOW THIS LINE ---------------
  // --USER ports added here 
  // -- ADD USER PORTS ABOVE THIS LINE ---------------
	cpld_clk,
	cpld_ld,
	cpld_mosi,
	cpld_miso,
	cpld_rstn,
	cpld_jtagen,
	irq,
  // -- DO NOT EDIT BELOW THIS LINE ------------------
  // -- Bus protocol ports, do not add to or delete 
  Bus2IP_Clk,                     // Bus to IP clock
  Bus2IP_Resetn,                  // Bus to IP reset
  Bus2IP_Data,                    // Bus to IP data bus
  Bus2IP_BE,                      // Bus to IP byte enables
  Bus2IP_RdCE,                    // Bus to IP read chip enable
  Bus2IP_WrCE,                    // Bus to IP write chip enable
  IP2Bus_Data,                    // IP to Bus data bus
  IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
  IP2Bus_Error                    // IP to Bus error response
  // -- DO NOT EDIT ABOVE THIS LINE ------------------
); // user_logic

// -- ADD USER PARAMETERS BELOW THIS LINE ------------
// --USER parameters added here 
// -- ADD USER PARAMETERS ABOVE THIS LINE ------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol parameters, do not add to or delete
parameter C_NUM_REG                      = 3;
parameter C_SLV_DWIDTH                   = 32;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

// -- ADD USER PORTS BELOW THIS LINE -----------------
// --USER ports added here 
// -- ADD USER PORTS ABOVE THIS LINE -----------------
output 	   cpld_clk;
output 	   cpld_ld;
output      cpld_mosi;
input       cpld_miso;
output      cpld_rstn;
output		cpld_jtagen;
output 		irq;
// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol ports, do not add to or delete
input                                     Bus2IP_Clk;
input                                     Bus2IP_Resetn;
input      [C_SLV_DWIDTH-1 : 0]           Bus2IP_Data;
input      [C_SLV_DWIDTH/8-1 : 0]         Bus2IP_BE;
input      [C_NUM_REG-1 : 0]              Bus2IP_RdCE;
input      [C_NUM_REG-1 : 0]              Bus2IP_WrCE;
output     [C_SLV_DWIDTH-1 : 0]           IP2Bus_Data;
output                                    IP2Bus_RdAck;
output                                    IP2Bus_WrAck;
output                                    IP2Bus_Error;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------

  // --USER nets declarations added here, as needed for user logic

  // Nets for user logic slave model s/w accessible register example
  reg        [C_SLV_DWIDTH-1 : 0]           slv_reg0;
  reg        [C_SLV_DWIDTH-1 : 0]           slv_reg1;
  reg        [C_SLV_DWIDTH-1 : 0]           slv_reg2;
  wire       [2 : 0]                        slv_reg_write_sel;
  wire       [2 : 0]                        slv_reg_read_sel;
  reg        [C_SLV_DWIDTH-1 : 0]           slv_ip2bus_data;
  wire                                      slv_read_ack;
  wire                                      slv_write_ack;
  integer                                   byte_index, bit_index;

  // USER logic implementation added here
 
   wire w_clk = Bus2IP_Clk; //input 
   wire w_rst = ~Bus2IP_Resetn; // rst
   
   //wire[7:0] led;   //input 
   //wire[3:0] seg0; //input  
   //wire[3:0] seg1; //input 
   //wire[7:0] sw; //output 
   
   wire w_cpld_clk; //output reg  
   wire w_cpld_ld;  //output reg  
   wire w_cpld_mosi; //output reg  
   wire w_cpld_miso; // input
	wire w_cpld_rstn = 1'b1;
	wire w_cpld_jtagen = 1'b0;
	
  	wire IE = slv_reg0[0];
	wire IF = slv_reg0[1];
	wire JTAG_EN = 1'b0;
	wire [3:0]w_seg0 = slv_reg2[3:0];
	wire [3:0]w_seg1 = slv_reg2[7:4];
	wire [12:0]w_sw;
	wire [7:0]w_led = slv_reg2[15:8];
	
	assign irq = IE && IF;
	
	assign cpld_clk = w_cpld_clk;
	assign cpld_ld = w_cpld_ld;
	assign cpld_mosi = w_cpld_mosi;
	assign w_cpld_miso = cpld_miso;
	assign cpld_rstn = w_cpld_rstn;
	assign cpld_jtagen = w_cpld_jtagen;
	
  
	fpga_cpld cpld(
   .clk(w_clk),
   .rst(w_rst),
   .led(w_led),
   .seg0(w_seg0),
   .seg1(w_seg1),
   .sw(w_sw),
   
   .cpld_clk(w_cpld_clk),
   .cpld_ld(w_cpld_ld),
   .cpld_mosi(w_cpld_mosi),
   .cpld_miso(w_cpld_miso)
);



  // ------------------------------------------------------
  // Example code to read/write user logic slave model s/w accessible registers
  // 
  // Note:
  // The example code presented here is to show you one way of reading/writing
  // software accessible registers implemented in the user logic slave model.
  // Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  // to one software accessible register by the top level template. For example,
  // if you have four 32 bit software accessible registers in the user logic,
  // you are basically operating on the following memory mapped registers:
  // 
  //    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  //                     "1000"   C_BASEADDR + 0x0
  //                     "0100"   C_BASEADDR + 0x4
  //                     "0010"   C_BASEADDR + 0x8
  //                     "0001"   C_BASEADDR + 0xC
  // 
  // ------------------------------------------------------





  assign
    slv_reg_write_sel = Bus2IP_WrCE[2:0],
    slv_reg_read_sel  = Bus2IP_RdCE[2:0],
    slv_write_ack     = Bus2IP_WrCE[0] || Bus2IP_WrCE[1] || Bus2IP_WrCE[2],
    slv_read_ack      = Bus2IP_RdCE[0] || Bus2IP_RdCE[1] || Bus2IP_RdCE[2];

  // implement slave model register(s)
  always @( posedge Bus2IP_Clk )
    begin

      if ( Bus2IP_Resetn == 1'b0 )
        begin
          slv_reg0 <= 0;
          slv_reg1 <= 0;
          slv_reg2 <= 0;
        end
      else
		begin
		  if(slv_reg1 != w_sw) //MAGIC TODO
		  begin
				slv_reg1[12:0] <= w_sw;
				slv_reg0[1] <= 1'b1; // IF
		  end
		  if(slv_reg_read_sel == 3'b100)
				slv_reg0[1] <= 1'b0; // IF
        case ( slv_reg_write_sel )
          3'b100 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                slv_reg0[(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];
          /*3'b010 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                slv_reg1[(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];*/
          3'b001 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                slv_reg2[(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];
          default : begin
            slv_reg0 <= slv_reg0;
            slv_reg1 <= slv_reg1;
            slv_reg2 <= slv_reg2;
			 end
        endcase
		end
    end // SLAVE_REG_WRITE_PROC

  // implement slave model register read mux
  always @( slv_reg_read_sel or slv_reg0 or slv_reg1 or slv_reg2 )
    begin 

      case ( slv_reg_read_sel )
        3'b100 : slv_ip2bus_data <= slv_reg0;
        //3'b010 : slv_ip2bus_data <= slv_reg1;
        3'b001 : slv_ip2bus_data <= slv_reg2;
        default : slv_ip2bus_data <= 0;
      endcase

    end // SLAVE_REG_READ_PROC

  // ------------------------------------------------------------
  // Example code to drive IP to Bus signals
  // ------------------------------------------------------------

assign IP2Bus_Data = (slv_read_ack == 1'b1) ? slv_ip2bus_data :  0 ;
  assign IP2Bus_WrAck = slv_write_ack;
  assign IP2Bus_RdAck = slv_read_ack;
  assign IP2Bus_Error = 0;

endmodule

module fpga_cpld(
   input clk,
   input rst,
   
   input  [7:0]  led,
   input  [3:0]  seg0,
   input  [3:0]  seg1,
   output [12:0] sw,
   
   output reg  cpld_clk,
   output reg  cpld_ld,
   output reg  cpld_mosi,
   input       cpld_miso
);

reg [11:0] clk_div = 0;
always @ (posedge clk)
   clk_div <= clk_div + 1;

reg clk_div_msb;
reg ce;
// lefutó él detektálás
always @ (posedge clk)
begin
   clk_div_msb <= clk_div[11];
   ce          <= clk_div_msb & ~clk_div[11];
end

reg [4:0] cntr = 0;
always @ (posedge clk)
if (ce)
   cntr <= cntr + 1;
   
wire ld;
assign ld = (cntr[3:0]==15);
   
wire [3:0] seg_mux;
assign seg_mux = (cntr[4]) ? seg1 : seg0;
   
reg [7:0] seg_data;
always @(seg_mux)
case (seg_mux)
   4'b0001 : seg_data = 8'b11111001;   // 1  
   4'b0010 : seg_data = 8'b10100100;   // 2   
   4'b0011 : seg_data = 8'b10110000;   // 3
   4'b0100 : seg_data = 8'b10011001;   // 4
   4'b0101 : seg_data = 8'b10010010;   // 5
   4'b0110 : seg_data = 8'b10000010;   // 6
   4'b0111 : seg_data = 8'b11111000;   // 7
   4'b1000 : seg_data = 8'b10000000;   // 8
   4'b1001 : seg_data = 8'b10010000;   // 9
   4'b1010 : seg_data = 8'b10001000;   // A
   4'b1011 : seg_data = 8'b10000011;   // b
   4'b1100 : seg_data = 8'b11000110;   // C
   4'b1101 : seg_data = 8'b10100001;   // d
   4'b1110 : seg_data = 8'b10000110;   // E
   4'b1111 : seg_data = 8'b10001110;   // F
   default : seg_data = 8'b11000000;   // 0
endcase
   
reg [15:0] shr;
always @ (posedge clk)
if (ce)
   if (ld)
      shr <= {~seg_data, led};
   else
      shr <= {1'b0, shr[15:1]};

always @ (posedge clk)
begin
   cpld_clk  <= clk_div[11];
   cpld_ld   <= ld;
   cpld_mosi <= shr[0];
end


reg [15:0] shr_in;
always @ (posedge clk)
if (ce)
   shr_in <= {cpld_miso, shr_in[15:1]};

reg [15:0] din_reg;
always @ (posedge clk)
if (ce & ld)
   din_reg <= shr_in;
   
assign sw = din_reg[12:0];

endmodule
