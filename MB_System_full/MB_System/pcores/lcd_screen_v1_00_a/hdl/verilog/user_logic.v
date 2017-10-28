/**************** BASE + 0x0 -status registers {lcd_enable,  == clock enable
																spi_state,   == (IDLE,LOAD,SEND) 2 bit
																inst_notdata,== information about miso
																IE,			 == interrupt enable
																IF,			 == interrupt flag
																FULL_REG,	 == FIFO FULL
																EMPTY_REG}   == FIFO EMPTY
																
						BASE + 0x4 -spi fifo	-> WIDTH =  1  +    8		DEPTH = 16
																	|		  |
																	¡		  ¡
																 {I/D , PAYLOAD}
																
*****************/
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic #(
   //Bus protocol parameters.
   parameter C_SLV_DWIDTH = 32,
   parameter C_NUM_REG    = 2
) (
   //Bus protocol ports.
   input  wire                        Bus2IP_Clk,        //Clock signal
   input  wire                        Bus2IP_Resetn,     //Reset signal (active-low)
   input  wire [C_SLV_DWIDTH-1 : 0]   Bus2IP_Data,       //Input data bus
   input  wire [C_SLV_DWIDTH/8-1 : 0] Bus2IP_BE,         //Byte enable signals
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_RdCE,       //Register read enable signals
   input  wire [C_NUM_REG-1 : 0]      Bus2IP_WrCE,       //Register write enable signals
   output reg  [C_SLV_DWIDTH-1 : 0]   IP2Bus_Data,       //Output data bus
   output wire                        IP2Bus_RdAck,      //Read acknowledge signal
   output wire                        IP2Bus_WrAck,      //Write acknowledge signal
   output wire                        IP2Bus_Error,      //Bus error signal
   output wire                        irq,               //Interrupt request signal
   
   //SPI interface.
   output wire                        spi_csn,           //LCD chip select signal (active-low)
   output wire                        spi_clk,           //SPI serial clock
   output wire                        spi_mosi,          //SPI serial data output
   output wire                        spi_miso           //SPI serial data input and LCD CMD/DATA select
);

localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam SEND = 2'b10;

// registers
//status
reg lcd_enable;
reg [1:0]spi_state;
reg IE;
reg IF;
reg FULL_REG;
reg EMPTY_REG;
//other
reg fifo_rd_req;
reg [7:0]puffer;
reg inst_notdata; 
reg [3:0]counter;
reg [1:0]sclk_reg;

wire clk     =  Bus2IP_Clk;
wire rst     = ~Bus2IP_Resetn;
wire reg0_wr =  Bus2IP_WrCE[1];
wire reg0_rd =  Bus2IP_RdCE[1];
wire reg1_wr =  Bus2IP_WrCE[0];

//fifo
wire empty;
wire full;
wire [8:0]fifo_dout;
wire [8:0]fifo_din = Bus2IP_Data[8:0];
wire fifo_rd;
wire fifo_wr;
wire [7:0]status_reg = {lcd_enable,spi_state,inst_notdata,IE,IF,FULL_REG,EMPTY_REG};

//
wire sclk_rise = (sclk_reg == 2'b01);
wire sclk_fall = (sclk_reg == 2'b11);





assign fifo_wr = ~full & reg1_wr;
assign fifo_rd = ~empty & fifo_rd_req;

// RX FIFO
fifo
#(
.WIDTH(9)
)
rx_fifo(
.clk(clk),
.rst(rst),
.empty(empty),
.full(full),
.wr(fifo_wr),
.rd(fifo_rd),
.din(fifo_din),
.dout(fifo_dout)
);
// GENERATE CLK
always @(posedge clk)
begin
	if (rst)
		sclk_reg <= 1'b0;
	else if(lcd_enable)
		sclk_reg <= sclk_reg + 1;
end

assign spi_clk = (spi_state == SEND && counter < 8)? sclk_reg[1] : 1'b0;

//STATUS Register
always @(posedge clk)
begin
	if(rst)
	begin
		IE <= 0;
		IF <= 0;
		lcd_enable <= 0;
	end
	if(reg0_wr)
	begin
		lcd_enable <= Bus2IP_Data[0];
		IE		   <= Bus2IP_Data[1];
	end
	FULL_REG  <= full;
	EMPTY_REG <= empty;
	if(reg0_rd)
		IF <= 0;
	if(FULL_REG)
		IF <= 1;
end

assign irq = IE & IF;

//READ DATA FROM FIFO AND SEND OUT (SPI)
always @(posedge clk)
begin
	if (rst)
	begin
		puffer <= 0;
		spi_state <= IDLE;
		fifo_rd_req <= 0;
		counter <= 0;
	end
	case(spi_state)
		IDLE:
		begin
			if(~empty && lcd_enable)
			begin
				spi_state   <= LOAD;
				fifo_rd_req <= 1;
				puffer <= fifo_dout[7:0];
				inst_notdata <= fifo_dout[8];
			end
			else
				spi_state <= IDLE;
		end
		
		LOAD:
		begin
			if(fifo_rd_req)
			begin
				fifo_rd_req <= 0;
			end
			if(sclk_fall)
				spi_state <= SEND; //sync_transfer
			else
				spi_state <= LOAD;
		end
		
		SEND:
		begin
			//if(sclk_rise)
				
			if(sclk_fall)
			begin
				puffer <= {puffer[6:0], 1'b0};
				counter <= counter + 1;
			end
			if(counter == 10)
			begin
				if(sclk_fall)
				begin
					counter <= 4'b0000;
					if(~empty)
					begin
						fifo_rd_req <= 1;
						puffer <= fifo_dout[7:0];
						inst_notdata <= fifo_dout[8];
						spi_state <= LOAD;
					end
					else
						spi_state <= IDLE;
				end
			end
		end
		
	endcase

end
assign spi_mosi = ~(spi_state == SEND) ? 1'b0 : puffer[7];
assign spi_miso = ~(spi_state == SEND) ? 1'b0 : inst_notdata;
assign spi_csn  =  (spi_state == SEND || spi_state == LOAD) ? 1'b0 : 1'b1;


// Handling READ


assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_Error = 1'b0;

always @(*)
begin
   case (Bus2IP_RdCE)
      2'b10: IP2Bus_Data   <= {24'b0,status_reg};
      2'b01: IP2Bus_Data   <= {23'b0,fifo_dout}; //  -\_(?)_/- 
      default: IP2Bus_Data <= 32'd0;
   endcase
end



endmodule

`timescale 1ns / 1ps

module fifo
#(
	parameter WIDTH = 9
)
(
   input         clk,
   input         rst,
   input         wr,
   input         rd,
   input  [WIDTH-1:0] din,
   output [WIDTH-1:0] dout,
   output        empty,
   output        full
)/* synthesis syn_hier = "hard" */;
// Generating 16-deep SRL based shift register (no reset)
integer i;
reg [8:0] srl_shr[15:0];
always @ (posedge clk)
if (wr) begin
   for (i=15; i>0; i=i-1) begin
      srl_shr[i] <= srl_shr[i-1];
   end
   srl_shr[0] <= din;
end

// Data counter with the ability to count from 0 to 16
reg [4:0] srl_dcnt;
always @ (posedge clk)
if (rst)
   srl_dcnt <= 0;
else
   if (wr & ~rd)
      srl_dcnt <= srl_dcnt + 1;
   else if (~wr & rd)
      srl_dcnt <= srl_dcnt - 1;

// Read address for the SRL, 5 bit wide
reg [4:0] srl_addr;
always @ (posedge clk)
if (rst)
   srl_addr <= 5'h1F;
else
   if (wr & ~rd)
      srl_addr <= srl_addr + 1;
   else if (~wr & rd)
      srl_addr <= srl_addr - 1;

// FIFO status signals
assign empty = srl_addr[4];
assign full  = srl_dcnt[4];      

// Asyncronous data output
assign dout = srl_shr[srl_addr[3:0]];


endmodule
