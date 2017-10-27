//*****************************************************************************
//* Master SPI interface for the LOGSYS Spartan-6 FPGA board (AXI4 version).  *
//* Written by   : Tamas Raikovich                                            *
//* Version      : 1.0                                                        *
//* Last modified: 2013.09.15.                                                *
//*****************************************************************************
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic #(
   //Bus protocol parameters.
   parameter C_SLV_DWIDTH = 32,
   parameter C_NUM_REG    = 4
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
   output reg                         irq,               //Interrupt request signal
   
   //SPI interface.
   output wire                        flash_csn,         //FLASH chip select signal (active-low)
   output wire                        lcd_csn,           //LCD chip select signal (active-low)
   output wire                        sdcard_csn,        //MicroSD card chip select signal (active-low)
   output wire                        spi_clk,           //SPI serial clock
   output wire                        spi_mosi_O,        //SPI serial data output
   output wire                        spi_mosi_T,
   output wire                        spi_miso_O,        //SPI serial data input and LCD CMD/DATA select
   input  wire                        spi_miso_I,
   output wire                        spi_miso_T
);

//******************************************************************************
//* Clock and reset signals.                                                   *
//******************************************************************************
wire clk  = Bus2IP_Clk;
wire rstn = Bus2IP_Resetn;


//******************************************************************************
//* SPI control/status register                                                *
//* BASE + 0x00, 16 bit, read/write                                            *
//******************************************************************************
reg  [5:0]  ctrl_reg;
wire [15:0] ctrl_reg_din = Bus2IP_Data[15:0];
wire        ctrl_reg_wr  = Bus2IP_WrCE[3] & (Bus2IP_BE == 4'b0011);

always @(posedge clk)
begin
   if (rstn == 0)
      ctrl_reg <= 6'b00_0000;
   else
      if (ctrl_reg_wr)
         ctrl_reg <= ctrl_reg_din[5:0];
end

//Writable bits of the control register.
wire [1:0] slave_sel   = ctrl_reg[1:0];
wire       transfer_en = ctrl_reg[2];
wire       rx_discard  = ctrl_reg[3];
wire       crc_mode    = ctrl_reg[4];
wire       crc_source  = ctrl_reg[5];
wire       tx_fifo_clr = ctrl_reg_wr & ctrl_reg_din[6];
wire       rx_fifo_clr = ctrl_reg_wr & ctrl_reg_din[7];

//Bits of the status register.
wire [15:0] status_reg;
wire        tx_fifo_full;
wire        tx_fifo_half_full;
wire        tx_fifo_exists;
wire        rx_fifo_full;
wire        rx_fifo_half_full;
wire        rx_fifo_exists;

assign status_reg[5:0] = ctrl_reg;
assign status_reg[8:6] = 3'b000;
assign status_reg[9]   = ~tx_fifo_full;
assign status_reg[10]  = ~tx_fifo_half_full;
assign status_reg[11]  = ~tx_fifo_exists;
assign status_reg[12]  = rx_fifo_full;
assign status_reg[13]  = rx_fifo_half_full;
assign status_reg[14]  = rx_fifo_exists;
assign status_reg[15]  = busy;


//******************************************************************************
//* Driving the chip-select outputs.                                           *
//******************************************************************************
localparam FLASH_SEL  = 2'b01;
localparam LCD_SEL    = 2'b10;
localparam SDCARD_SEL = 2'b11;

(* iob = "force" *)
reg flash_csn_reg;
(* iob = "force" *)
reg lcd_csn_reg;
(* iob = "force" *)
reg sdcard_csn_reg;

always @(posedge clk)
begin
   flash_csn_reg  <= ~(slave_sel == FLASH_SEL);
   lcd_csn_reg    <= ~(slave_sel == LCD_SEL);
   sdcard_csn_reg <= ~(slave_sel == SDCARD_SEL);
end

assign flash_csn  = flash_csn_reg;
assign lcd_csn    = lcd_csn_reg;
assign sdcard_csn = sdcard_csn_reg;


//******************************************************************************
//* SPI clock divisor register                                                 *
//* BASE + 0x02, 16 bit, read/write                                            *
//******************************************************************************
reg  [11:0] clkdiv_reg;
wire [15:0] clkdiv_reg_din  = Bus2IP_Data[31:16];
wire [15:0] clkdiv_reg_dout = {4'd0, clkdiv_reg};
wire        clkdiv_reg_wr   = Bus2IP_WrCE[3] & (Bus2IP_BE == 4'b1100);

always @(posedge clk)
begin
   if (rstn == 0)
      clkdiv_reg <= 12'd0;
   else
      if (clkdiv_reg_wr)
         clkdiv_reg <= clkdiv_reg_din[11:0];
end

//SPI clock divisor.
reg  [11:0] clk_div_cnt;
wire        clk_div_cnt_tc = (clk_div_cnt == 0);

always @(posedge clk)
begin
   if ((rstn == 0) || clk_div_cnt_tc)
      clk_div_cnt <= clkdiv_reg;
   else
      clk_div_cnt <= clk_div_cnt - 12'd1;
end

//SPI clock rising and falling edge indicator signals.
reg internal_sck;
reg sck_rising;
reg sck_falling;

always @(posedge clk)
begin
   if (rstn == 0)
      internal_sck <= 1'b0;
   else
      if (clk_div_cnt_tc)
         internal_sck <= ~internal_sck;
end

always @(posedge clk)
begin
   sck_rising  <= clk_div_cnt_tc & ~internal_sck;
   sck_falling <= clk_div_cnt_tc &  internal_sck;
end

//Driving the SPI clock output.
(* use_clock_enable = "yes" *)
(* iob = "force" *)
reg  spi_clk_reg;
wire sck_enable;

always @(posedge clk)
begin
   if (rstn == 0)
      spi_clk_reg <= 1'b0;
   else
      if ((sck_rising && sck_enable) || sck_falling)
         spi_clk_reg <= sck_rising & sck_enable;
end

assign spi_clk = spi_clk_reg;


//******************************************************************************
//* TX FIFO occupancy register                                                 *
//* BASE + 0x04, 8 bit, read-only                                              *
//******************************************************************************
wire [5:0] tx_occupancy;
reg  [7:0] tx_occupancy_reg;

always @(posedge clk)
begin
   tx_occupancy_reg[5:0] <= tx_occupancy;
   tx_occupancy_reg[6]   <= tx_occupancy[5];
   tx_occupancy_reg[7]   <= tx_occupancy[5];
end


//******************************************************************************
//* RX FIFO occupancy register                                                 *
//* BASE + 0x05, 8 bit, read-only                                              *
//******************************************************************************
wire [5:0] rx_occupancy;
reg  [7:0] rx_occupancy_reg;

always @(posedge clk)
begin
   rx_occupancy_reg[5:0] <= rx_occupancy;
   rx_occupancy_reg[6]   <= rx_occupancy[5];
   rx_occupancy_reg[7]   <= rx_occupancy[5];
end


//******************************************************************************
//* Interrupt enable register                                                  *
//* BASE + 0x06, 8 bit, read/write                                             *
//******************************************************************************
reg  [6:0] ie_reg;
wire [7:0] ie_reg_din  = Bus2IP_Data[23:16];
wire [7:0] ie_reg_dout = {1'd0, ie_reg};
wire       ie_reg_wr   = Bus2IP_WrCE[2] & (Bus2IP_BE == 4'b0100);

always @(posedge clk)
begin
   if (rstn == 0)
      ie_reg <= 7'd0;
   else
      if (ie_reg_wr)
         ie_reg <= ie_reg_din[6:0];
end


//******************************************************************************
//* Interrupt flag register                                                    *
//* BASE + 0x07, 8 bit, read/write                                             *
//******************************************************************************
reg  [6:0] if_reg;
wire [7:0] if_reg_din  = Bus2IP_Data[31:24];
wire [7:0] if_reg_dout = {1'b0, if_reg};
wire       if_reg_wr   = Bus2IP_WrCE[2] & (Bus2IP_BE == 4'b1000);

integer i;

//Rising edge detection on the interrupt sources.
wire [6:0] int_source;
reg  [6:0] int_src_sample;

assign int_source[0] = ~tx_fifo_full;        //TX FIFO not full
assign int_source[1] = ~tx_fifo_half_full;   //TX FIFO half empty
assign int_source[2] = ~tx_fifo_exists;      //TX FIFO empty
assign int_source[3] = rx_fifo_full;         //RX FIFO full
assign int_source[4] = rx_fifo_half_full;    //RX FIFO half full
assign int_source[5] = rx_fifo_exists;       //RX FIFO not empty
assign int_source[6] = ~busy;                //Done

always @(posedge clk)
begin
   if (rstn == 0)
      int_src_sample <= 7'b1_000_111;
   else
      int_src_sample <= int_source;
end

always @(posedge clk)
begin
   for (i = 0; i < 7; i = i + 1)
      if (rstn == 0)
         if_reg[i] <= 1'b0;
      else
         if (int_source[i] && (int_src_sample[i] == 0))
            if_reg[i] <= 1'b1;
         else
            if (if_reg_wr & if_reg_din[i])
               if_reg[i] <= 1'b0;
end


//******************************************************************************
//* Driving the interrupt request output.                                      *
//******************************************************************************
always @(posedge clk)
begin
   if (rstn == 0)
      irq <= 1'b0;
   else
      irq <= |(ie_reg & if_reg);
end


//******************************************************************************
//* SPI data register                                                          *
//* BASE + 0x08, 8/16 bit, read/write                                          *
//******************************************************************************
wire [8:0] tx_fifo_din;
wire [8:0] tx_fifo_dout;
wire       tx_fifo_wr = Bus2IP_WrCE[1] & (Bus2IP_BE[3:2] == 2'b00) & Bus2IP_BE[0];
wire       tx_fifo_rd;

assign tx_fifo_din[7:0] = Bus2IP_Data[7:0];
assign tx_fifo_din[8]   = Bus2IP_Data[8] & Bus2IP_BE[1];

fifo #(
   //Depth of the FIFO.
   .DEPTH(32),
   //Number of bits in the data words.
   .WIDTH(9),
   //The programmable full flag is set to 1 when the FIFO
   //contains at least PRG_FULL_H_TRESH data words.
   .PRG_FULL_H_TRESH(17),
   //The programmable full flag is set to 0 when the FIFO
   //contains less than PRG_FULL_L_TRESH data words.
   .PRG_FULL_L_TRESH(17)
) tx_fifo (
   //Clock and reset.
   .clk(clk),                          //Clock signal
   .rstn(rstn & ~tx_fifo_clr),         //Reset signal (active-low)
   
   //Data input and output.
   .data_in(tx_fifo_din),              //FIFO data input
   .data_out(tx_fifo_dout),            //FIFO data output
   
   //Control inputs.
   .write(tx_fifo_wr),                 //FIFO write signal
   .read(tx_fifo_rd),                  //FIFO read signal
   
   //Status outputs.
   .exists(tx_fifo_exists),            //FIFO is not empty
   .full(tx_fifo_full),                //FIFO is full
   .prg_full(tx_fifo_half_full),       //Programmable FULL flag
   .occupancy(tx_occupancy)            //FIFO occupancy
);

wire [7:0] rx_fifo_din;
wire [7:0] rx_fifo_dout;
wire       rx_fifo_wr;
wire       rx_fifo_rd = Bus2IP_RdCE[1];

fifo #(
   //Depth of the FIFO.
   .DEPTH(32),
   //Number of bits in the data words.
   .WIDTH(8),
   //The programmable full flag is set to 1 when the FIFO
   //contains at least PRG_FULL_H_TRESH data words.
   .PRG_FULL_H_TRESH(16),
   //The programmable full flag is set to 0 when the FIFO
   //contains less than PRG_FULL_L_TRESH data words.
   .PRG_FULL_L_TRESH(16)
) rx_fifo (
   //Clock and reset.
   .clk(clk),                          //Clock signal
   .rstn(rstn & ~rx_fifo_clr),         //Reset signal (active-low)
   
   //Data input and output.
   .data_in(rx_fifo_din),              //FIFO data input
   .data_out(rx_fifo_dout),            //FIFO data output
   
   //Control inputs.
   .write(rx_fifo_wr),                 //FIFO write signal
   .read(rx_fifo_rd),                  //FIFO read signal
   
   //Status outputs.
   .exists(rx_fifo_exists),            //FIFO is not empty
   .full(rx_fifo_full),                //FIFO is full
   .prg_full(rx_fifo_half_full),       //Programmable FULL flag
   .occupancy(rx_occupancy)            //FIFO occupancy
);


//******************************************************************************
//* CRC data register                                                          *
//* BASE + 0x0C, 16 bit, read/write                                            *
//*                                                                            *
//* crc_mode=0 -> G(x) =         x^7 + x^3 + 1 (CRC-7)                         *
//* crc_mode=1 -> G(x) = x^16 + x^12 + x^5 + 1 (CRC-16)                        *
//******************************************************************************
reg  [15:0] crc_reg;
wire [15:0] crc_reg_din = Bus2IP_Data[15:0];
wire        crc_reg_wr  = Bus2IP_WrCE[0] & (Bus2IP_BE == 4'b0011);
reg         crc_reg_shift;
wire        crc_reg_msb = (crc_mode) ? crc_reg[15] : crc_reg[6];
wire        crc_reg_sin;

always @(posedge clk)
begin
   if (crc_reg_wr)
      crc_reg[6:0] <= crc_reg_din[6:0];
   else
      if (crc_reg_shift)
      begin
         crc_reg[0]   <= crc_reg_msb ^ crc_reg_sin;
         crc_reg[2:1] <= crc_reg[1:0];
         crc_reg[3]   <= crc_reg[2] ^ ((crc_reg_msb ^ crc_reg_sin) & ~crc_mode);
         crc_reg[4]   <= crc_reg[3];
         crc_reg[5]   <= crc_reg[4] ^ ((crc_reg_msb ^ crc_reg_sin) &  crc_mode);
         crc_reg[6]   <= crc_reg[5];
      end
end

always @(posedge clk)
begin
   if (crc_mode == 0)
      crc_reg[15:7] <= 9'd0;
   else
      if (crc_reg_wr)
         crc_reg[15:7] <= crc_reg_din[15:7];
      else
         if (crc_reg_shift)
         begin
            crc_reg[11:7]  <= crc_reg[10:6];
            crc_reg[12]    <= crc_reg[11] ^ ((crc_reg_msb ^ crc_reg_sin) & crc_mode);
            crc_reg[15:13] <= crc_reg[14:12];
         end
end


//******************************************************************************
//* Controller state machine.                                                  *
//******************************************************************************
localparam STATE_IDLE     = 2'd0;
localparam STATE_FIFO_RW  = 2'd1;
localparam STATE_TRANSFER = 2'd2;
localparam STATE_RX_FULL  = 2'd3;

reg [1:0] spi_state;
reg       rx_valid;
reg [2:0] bit_cnt;

always @(posedge clk)
begin
   if (rstn == 0)
      spi_state <= STATE_IDLE;
   else
      case (spi_state)
         STATE_IDLE    : if (tx_fifo_exists && transfer_en)
                            spi_state <= STATE_FIFO_RW;
                         else
                            spi_state <= STATE_IDLE;
                            
         STATE_FIFO_RW : if (sck_falling)
                            if (tx_fifo_exists && transfer_en)
                               spi_state <= STATE_TRANSFER;
                            else
                               spi_state <= STATE_IDLE;
                         else
                            spi_state <= STATE_FIFO_RW;
                            
         STATE_TRANSFER: if (sck_rising && (bit_cnt == 0))
                            if (rx_fifo_full)
                               spi_state <= STATE_RX_FULL;
                            else
                               spi_state <= STATE_FIFO_RW;
                         else
                            spi_state <= STATE_TRANSFER;
                            
         STATE_RX_FULL : if (rx_fifo_full)
                            spi_state <= STATE_RX_FULL;
                         else
                            spi_state <= STATE_FIFO_RW;
      endcase
end

//Received data valid indicator signal.
always @(posedge clk)
begin
   if ((spi_state == STATE_IDLE) || (spi_state == STATE_FIFO_RW) || rx_discard)
      rx_valid <= 1'b0;
   else
      if (spi_state == STATE_TRANSFER)
         rx_valid <= 1'b1;
end

//Bit counter.
always @(posedge clk)
begin
   if (spi_state == STATE_FIFO_RW)
      bit_cnt <= 3'd7;
   else
      if (sck_rising && (spi_state == STATE_TRANSFER))
         bit_cnt <= bit_cnt - 3'd1;
end

//FIFO control signals.
assign tx_fifo_rd = (spi_state == STATE_FIFO_RW) & sck_falling & tx_fifo_exists & transfer_en;
assign rx_fifo_wr = (spi_state == STATE_FIFO_RW) & rx_valid;

//SPI clock enable signal.
assign sck_enable = (spi_state == STATE_TRANSFER);

//CRC register shift enable signal.
always @(posedge clk)
begin
   crc_reg_shift <= sck_rising & (spi_state == STATE_TRANSFER);
end 

//Busy status signal.
assign busy = ~(spi_state == STATE_IDLE);


//******************************************************************************
//* TX shift register.                                                         *
//******************************************************************************
(* use_clock_enable = "yes" *)
(* iob = "force" *)
reg        spi_mosi_reg;
reg  [7:0] tx_shr;

always @(posedge clk)
begin
   if (sck_falling)
      if ((spi_state == STATE_FIFO_RW) && tx_fifo_exists)
         spi_mosi_reg <= tx_fifo_dout[7];
      else
         if (spi_state == STATE_TRANSFER)
            spi_mosi_reg <= tx_shr[6];
end

always @(posedge clk)
begin
   if (sck_falling)
      if ((spi_state == STATE_FIFO_RW) && tx_fifo_exists && transfer_en)
         tx_shr <= tx_fifo_dout[7:0];
      else
         if (spi_state == STATE_TRANSFER)
            tx_shr <= {tx_shr[6:0], 1'b0};
end

//Driving the SPI MOSI output.
assign spi_mosi_O = spi_mosi_reg;
assign spi_mosi_T = (spi_state == STATE_IDLE);

//Driving the SPI MISO output (LCD command/data select).
(* iob = "force" *)
reg spi_miso_O_reg;

always @(posedge clk)
begin
   if (tx_fifo_rd)
      spi_miso_O_reg <= tx_fifo_dout[8];
end

assign spi_miso_O = spi_miso_O_reg;
assign spi_miso_T = ~(slave_sel == LCD_SEL);


//******************************************************************************
//* RX shift register.                                                         *
//******************************************************************************
(* iob = "force" *)
reg        rx_shr_lsb;
reg  [7:1] rx_shr;
wire       rx_shr_shift = sck_rising & (spi_state == STATE_TRANSFER);

always @(posedge clk)
begin
   if (rx_shr_shift)
      rx_shr_lsb <= spi_miso_I;
end

always @(posedge clk)
begin
   if (rx_shr_shift)
      rx_shr <= {rx_shr[6:1], rx_shr_lsb};
end

assign rx_fifo_din = {rx_shr, rx_shr_lsb};

//Driving the serial input of the CRC register.
assign crc_reg_sin = (crc_source) ? rx_shr_lsb : tx_shr[7];


//******************************************************************************
//* Driving the AXI output ports.                                              *
//******************************************************************************
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_Error = 1'b0;

always @(*)
begin
   case (Bus2IP_RdCE)
      4'b1000: IP2Bus_Data <= {clkdiv_reg_dout, status_reg};
      4'b0100: IP2Bus_Data <= {if_reg_dout, ie_reg_dout, rx_occupancy_reg, tx_occupancy_reg};
      4'b0010: IP2Bus_Data <= {24'd0, rx_fifo_dout};
      4'b0001: IP2Bus_Data <= {16'd0, crc_reg};
      default: IP2Bus_Data <= 32'd0;
   endcase
end


endmodule
