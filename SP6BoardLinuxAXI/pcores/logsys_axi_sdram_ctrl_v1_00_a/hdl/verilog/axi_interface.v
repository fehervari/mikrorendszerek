//******************************************************************************
//* AXI4 interface module.                                                     *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 1.0                                                         *
//* Last modified: 2013.04.29.                                                 *
//******************************************************************************
module axi_interface #(
   //AXI related parameters.
   parameter AXI_ID_WIDTH     = 1,                    //Master ID size in bits
   parameter AXI_ADDR_WIDTH   = 25,                   //Address bus size in bits
   parameter AXI_DATA_WIDTH   = 32,                   //Data bus size in bits
   
   //Memory read pipeline delay in clocks.
   parameter MEM_RD_DELAY_CLK = 4
) (
   //AXI clock and reset.
   input  wire                        axi_aclk,       //Clock signal
   input  wire                        axi_aresetn,    //Reset signal (active-low)
   
   //AXI write address channel.
   input  wire [AXI_ID_WIDTH-1:0]     axi_awid,       //Master ID
   input  wire [AXI_ADDR_WIDTH-1:0]   axi_awaddr,     //Address
   input  wire [7:0]                  axi_awlen,      //Number of transfers in the burst
   input  wire [2:0]                  axi_awsize,     //Transfer size
   input  wire [1:0]                  axi_awburst,    //Burst type
   input  wire                        axi_awlock,     //Exclusive access (not used)
   input  wire [3:0]                  axi_awcache,    //Memory type (not used)
   input  wire [2:0]                  axi_awprot,     //Access permissions (not used)
   input  wire                        axi_awvalid,    //Address valid indicator
   output wire                        axi_awready,    //Address accepted indicator
   
   //AXI write data channel.
   input  wire [AXI_DATA_WIDTH-1:0]   axi_wdata,      //Data bus
   input  wire [AXI_DATA_WIDTH/8-1:0] axi_wstrb,      //Byte enable signals
   input  wire                        axi_wlast,      //Last transfer indicator
   input  wire                        axi_wvalid,     //Data valid indicator
   output wire                        axi_wready,     //Data accepted indicator
   
   //AXI write response channel.
   output wire [AXI_ID_WIDTH-1:0]     axi_bid,        //Master ID
   output wire [1:0]                  axi_bresp,      //Response
   output wire                        axi_bvalid,     //Response valid indicator
   input  wire                        axi_bready,     //Response accepted indicator
   
   //AXI read address channel.
   input  wire [AXI_ID_WIDTH-1:0]     axi_arid,       //Master ID
   input  wire [AXI_ADDR_WIDTH-1:0]   axi_araddr,     //Address
   input  wire [7:0]                  axi_arlen,      //Number of transfers in the burst
   input  wire [2:0]                  axi_arsize,     //Transfer size
   input  wire [1:0]                  axi_arburst,    //Burst type
   input  wire                        axi_arlock,     //Exclusive access (not used)
   input  wire [3:0]                  axi_arcache,    //Memory type (not used)
   input  wire [2:0]                  axi_arprot,     //Access permissions (not used)
   input  wire                        axi_arvalid,    //Address valid indicator
   output wire                        axi_arready,    //Address accepted indicator
   
   //AXI read response channel.
   output wire [AXI_ID_WIDTH-1:0]     axi_rid,        //Master ID
   output wire [AXI_DATA_WIDTH-1:0]   axi_rdata,      //Data bus
   output wire [1:0]                  axi_rresp,      //Response
   output wire                        axi_rvalid,     //Response valid indicator
   input  wire                        axi_rready,     //Response accepted indicator
   output wire                        axi_rlast,      //Last transfer indicator
   
   //Memory controller interface signals (little-endian).
   output wire                        mem_write_req,  //Write transfer request signal
   output wire                        mem_read_req,   //Read transfer request signal
   output wire [24:1]                 mem_address,    //Address output
   output wire [3:0]                  mem_byte_en,    //Byte enable signals
   input  wire                        mem_write_ack,  //Write acknowledge signal
   output wire                        mem_wr_valid,   //Write data valid signal
   output wire [31:0]                 mem_wr_data,    //Write data output
   input  wire                        mem_read_ack,   //Write acknowledge signal
   input  wire                        mem_rd_valid,   //Read data valid signal
   input  wire [31:0]                 mem_rd_data     //Read data input
);

//******************************************************************************
//* Clock and reset.                                                           *
//******************************************************************************
wire clk  = axi_aclk;
wire rstn = axi_aresetn;


//******************************************************************************
//* Arbiter for the write and read address channels. Least recently used       *
//* arbitration scheme is used.                                                *
//******************************************************************************
wire       addr_fifo_full;
reg        priority_sel;
reg  [2:0] arbiter_rom_data;
wire [3:0] arbiter_rom_addr = {addr_fifo_full, priority_sel, axi_arvalid, axi_awvalid};

//Arbiter ROM.
always @(*)
begin
   casex (arbiter_rom_addr)
      //Write address accepted -----------\
      //Read address accepted  ---------\ |
      //Address ch. FIFO write -------\ | |
      //                              | | |
      //                              V V V
      4'b0000: arbiter_rom_data <= 3'b0_0_0;    //No request
      4'b0001: arbiter_rom_data <= 3'b1_0_1;    //Write address channel is selected
      4'b0010: arbiter_rom_data <= 3'b1_1_0;    //Read address channel is selected
      4'b0011: arbiter_rom_data <= 3'b1_0_1;    //Write address channel is selected
      4'b0100: arbiter_rom_data <= 3'b0_0_0;    //No request
      4'b0101: arbiter_rom_data <= 3'b1_0_1;    //Write address channel is selected
      4'b0110: arbiter_rom_data <= 3'b1_1_0;    //Read address channel is selected
      4'b0111: arbiter_rom_data <= 3'b1_1_0;    //Read address channel is selected
      4'b1xxx: arbiter_rom_data <= 3'b0_0_0;    //Address channel FIFO is full
   endcase
end

//Priority select signal.
//0: write address channel has priority.
//1: read address channel has priority.
always @(posedge clk)
begin
   if (rstn == 0)
      priority_sel <= 1'b0;
   else
      if (arbiter_rom_data[2])
         priority_sel <= axi_awready;
end

//Driving the READY signals of the address channels.
assign axi_awready = arbiter_rom_data[0];
assign axi_arready = arbiter_rom_data[1];

//Address channel select multiplexers. The exclusive access, the memory
//type and the access permission indicators are not used. The FIXED burst
//is converted to INCR burst. The 32 MB SDRAM requires 25 address bits.
wire [AXI_ID_WIDTH-1:0] axid_mux    = (axi_awready) ? axi_awid         : axi_arid;
wire [24:0]             axaddr_mux  = (axi_awready) ? axi_awaddr[24:0] : axi_araddr[24:0];
wire [7:0]              axlen_mux   = (axi_awready) ? axi_awlen        : axi_arlen;
wire [2:0]              axsize_mux  = (axi_awready) ? axi_awsize       : axi_arsize;
wire                    axburst_mux = (axi_awready) ? axi_awburst[1]   : axi_arburst[1];


//******************************************************************************
//* AXI address channel FIFO.                                                  *
//******************************************************************************
localparam ADDR_FIFO_WIDTH = AXI_ID_WIDTH + 25 + 8 + 3 + 1 + 1;

wire [ADDR_FIFO_WIDTH-1:0] addr_fifo_din;
wire [ADDR_FIFO_WIDTH-1:0] addr_fifo_dout;
wire                       addr_fifo_rd;
wire                       addr_fifo_exists;

fifo #(
   //Depth of the FIFO.
   .DEPTH(16),
   //Number of bits in the data words.
   .WIDTH(ADDR_FIFO_WIDTH),
   //The programmable full flag is set to 1 when the FIFO
   //contains at least PRG_FULL_H_TRESH data words.
   .PRG_FULL_H_TRESH(16),
   //The programmable full flag is set to 0 when the FIFO
   //contains less than PRG_FULL_L_TRESH data words.
   .PRG_FULL_L_TRESH(16)
) addr_fifo (
   //Clock and reset.
   .clk(clk),                       //Clock signal
   .rstn(rstn),                     //Reset signal (active-low)
   
   //Data input and output.
   .data_in(addr_fifo_din),         //FIFO data input.
   .data_out(addr_fifo_dout),       //FIFO data output.
   
   //Control inputs.
   .write(arbiter_rom_data[2]),     //FIFO write signal.
   .read(addr_fifo_rd),             //FIFO read signal.
   
   //Status outputs.
   .exists(addr_fifo_exists),       //FIFO is not empty.
   .full(addr_fifo_full),           //FIFO is full.
   .prg_full()                      //Programmable FULL flag
);

//Driving the data input of the FIFO.
assign addr_fifo_din[AXI_ID_WIDTH-1:0]                = axid_mux;
assign addr_fifo_din[AXI_ID_WIDTH+24:AXI_ID_WIDTH]    = axaddr_mux;
assign addr_fifo_din[AXI_ID_WIDTH+32:AXI_ID_WIDTH+25] = axlen_mux;
assign addr_fifo_din[AXI_ID_WIDTH+35:AXI_ID_WIDTH+33] = axsize_mux;
assign addr_fifo_din[AXI_ID_WIDTH+36]                 = axburst_mux;
assign addr_fifo_din[AXI_ID_WIDTH+37]                 = axi_arready;

//Output signals from the FIFO.
wire [AXI_ID_WIDTH-1:0] axid    = addr_fifo_dout[AXI_ID_WIDTH-1:0];
wire [24:0]             axaddr  = addr_fifo_dout[AXI_ID_WIDTH+24:AXI_ID_WIDTH];
wire [7:0]              axlen   = addr_fifo_dout[AXI_ID_WIDTH+32:AXI_ID_WIDTH+25];
wire [2:0]              axsize  = addr_fifo_dout[AXI_ID_WIDTH+35:AXI_ID_WIDTH+33];
wire                    axburst = addr_fifo_dout[AXI_ID_WIDTH+36];
wire                    axrnw   = addr_fifo_dout[AXI_ID_WIDTH+37];


//******************************************************************************
//* Master ID register.                                                        *
//******************************************************************************
reg  [AXI_ID_WIDTH-1:0] id_reg;
wire                    id_reg_ld;

always @(posedge clk)
begin
   if (id_reg_ld)
      id_reg <= axid;
end


//******************************************************************************
//* Burst length counter (number of transfers in a burst).                     *
//******************************************************************************
reg  [7:0] burst_len_cnt;
wire       burst_len_cnt_ld;
wire       burst_len_cnt_en;

always @(posedge clk)
begin
   if (burst_len_cnt_ld)
      burst_len_cnt <= axlen;
   else
      if (burst_len_cnt_en)
         burst_len_cnt <= burst_len_cnt - 8'd1;
end

//Last read transfer indicator signal.
wire last_rd_transfer = (burst_len_cnt == 8'd0);


//******************************************************************************
//* Transfer size register (number of bytes in a transfer).                    *
//******************************************************************************
reg  [7:0] tr_size_reg;
wire       tr_size_reg_ld;

always @(posedge clk)
begin
   if (tr_size_reg_ld)
      case (axsize)
         3'b000: tr_size_reg <= 8'd1;
         3'b001: tr_size_reg <= 8'd2;
         3'b010: tr_size_reg <= 8'd4;
         3'b011: tr_size_reg <= 8'd8;
         3'b100: tr_size_reg <= 8'd16;
         3'b101: tr_size_reg <= 8'd32;
         3'b110: tr_size_reg <= 8'd64;
         3'b111: tr_size_reg <= 8'd128;
      endcase
end


//******************************************************************************
//* Address counter.                                                           *
//******************************************************************************
reg  [24:0] addr_reg;
wire        addr_reg_ld;
wire        addr_cnt_en;
reg  [11:0] addr_cnt_mask;
wire [11:0] next_address = addr_reg[11:0] + {4'd0, tr_size_reg};

integer i;

always @(posedge clk)
begin     
   //addr_reg[11:0]: address counter.
   //Transfers must not cross the 4 kB address boundary,
   //therefore a 12-bit wide address counter is enough.
   for (i = 0; i < 12; i = i + 1)
      if (addr_reg_ld)
         addr_reg[i] <= axaddr[i];
      else
         if (addr_cnt_en && addr_cnt_mask[i])
            addr_reg[i] <= next_address[i];
       
   //addr_reg[24:12]: upper address bits.
   if (addr_reg_ld)
      addr_reg[24:12] <= axaddr[24:12];
end

//Barrel shifter for generating the address counter mask value.
wire [4:0]  shift1 = (axsize[0]) ? {axlen[3:0], 1'b1} : {1'b0, axlen[3:0]};
wire [6:0]  shift2 = (axsize[1]) ? {shift1, 2'b11}    : {2'b00, shift1};
wire [10:0] shift3 = (axsize[2]) ? {shift2, 4'b1111}  : {4'b0000, shift2};

//Address counter mask register.
always @(posedge clk)
begin
   if (addr_reg_ld)
      if (axburst == 0)
         addr_cnt_mask <= 12'hfff;           //INCR burst
      else
         addr_cnt_mask <= {1'b0, shift3};    //WRAP burst
end


//******************************************************************************
//* AXI read response channel FIFO.                                            *
//******************************************************************************
localparam RD_FIFO_WIDTH = AXI_ID_WIDTH + 32 + 1;

wire [RD_FIFO_WIDTH-1:0] rd_fifo_din;
wire [RD_FIFO_WIDTH-1:0] rd_fifo_dout;
wire                     rd_fifo_rd;
wire                     rd_fifo_full;
wire                     rd_fifo_exists;
 
fifo #(
   //Depth of the FIFO.
   .DEPTH(16),
   //Number of bits in the data words.
   .WIDTH(RD_FIFO_WIDTH),
   //The programmable full flag is set to 1 when the FIFO
   //contains at least PRG_FULL_H_TRESH data words.
   .PRG_FULL_H_TRESH(16 - MEM_RD_DELAY_CLK - 1),
   //The programmable full flag is set to 0 when the FIFO
   //contains less than PRG_FULL_L_TRESH data words.
   .PRG_FULL_L_TRESH(MEM_RD_DELAY_CLK + 3)
) rd_fifo (
   //Clock and reset.
   .clk(clk),                       //Clock signal
   .rstn(rstn),                     //Reset signal (active-low)
   
   //Data input and output.
   .data_in(rd_fifo_din),           //FIFO data input
   .data_out(rd_fifo_dout),         //FIFO data output
   
   //Control inputs.
   .write(mem_rd_valid),            //FIFO write signal
   .read(rd_fifo_rd),               //FIFO read signal
   
   //Status outputs.
   .exists(rd_fifo_exists),         //FIFO is not empty
   .full(),                         //FIFO is full
   .prg_full(rd_fifo_full)          //Programmable FULL flag
);

//Delaying the master ID.
reg [AXI_ID_WIDTH-1:0] id_shr [MEM_RD_DELAY_CLK-1:0];

integer j;

always @(posedge clk)
begin
   id_shr[MEM_RD_DELAY_CLK-1] <= id_reg;
   for (j = MEM_RD_DELAY_CLK - 1; j > 0; j = j - 1)
      id_shr[j-1] <= id_shr[j];
end

//Delaying the last transfer indicator.
reg [MEM_RD_DELAY_CLK-1:0] last_rd_transfer_shr;

always @(posedge clk)
begin
   last_rd_transfer_shr <= {last_rd_transfer, last_rd_transfer_shr[MEM_RD_DELAY_CLK-1:1]};
end

//Driving the data input of the FIFO.
assign rd_fifo_din[31:0]                 = mem_rd_data;
assign rd_fifo_din[32]                   = last_rd_transfer_shr[0];
assign rd_fifo_din[33+AXI_ID_WIDTH-1:33] = id_shr[0];

//FIFO read signal.
assign rd_fifo_rd = rd_fifo_exists & axi_rready;


//******************************************************************************
//* Driving the outputs of the AXI read response channel.                      *
//******************************************************************************
//Master ID.
assign axi_rid    = rd_fifo_dout[33+AXI_ID_WIDTH-1:33];
//Data bus
assign axi_rdata  = rd_fifo_dout[31:0];
//Response (always OKAY).
assign axi_rresp  = 2'b00;
//Response valid indicator.
assign axi_rvalid = rd_fifo_exists;
//Last transfer indicator.
assign axi_rlast  = rd_fifo_dout[32];      


//******************************************************************************
//* Controller state machine.                                                  *
//******************************************************************************
localparam STATE_REQ_WAIT  = 3'd0;
localparam STATE_MEM_WRITE = 3'd1;
localparam STATE_WRITE_ACK = 3'd2;
localparam STATE_MEM_READ  = 3'd3;
localparam STATE_FIFO_FULL = 3'd4;

reg [2:0] state;

always @(posedge clk)
begin
   if (rstn == 0)
      state <= STATE_REQ_WAIT;
   else
      case (state)
         //Wait for the request.
         STATE_REQ_WAIT : if (addr_fifo_exists)
                             if (axrnw)
                                if (rd_fifo_full)
                                   state <= STATE_FIFO_FULL;
                                else
                                   state <= STATE_MEM_READ;
                             else
                                state <= STATE_MEM_WRITE;
                          else
                             state <= STATE_REQ_WAIT;
                             
         //Servicing a write request.
         STATE_MEM_WRITE: if (mem_write_ack && axi_wvalid && axi_wlast)
                             state <= STATE_WRITE_ACK;
                          else
                             state <= STATE_MEM_WRITE;
                             
         STATE_WRITE_ACK: if (axi_bready)
                             state <= STATE_REQ_WAIT;
                          else
                             state <= STATE_WRITE_ACK;
         
         //Servicing a read request.
         STATE_MEM_READ : if (mem_read_ack)
                             if (last_rd_transfer)
                                state <= STATE_REQ_WAIT;
                             else
                                if (rd_fifo_full)
                                   state <= STATE_FIFO_FULL;
                                else
                                   state <= STATE_MEM_READ;
                          else
                             state <= STATE_MEM_READ;
                         
         STATE_FIFO_FULL: if (rd_fifo_full)
                             state <= STATE_FIFO_FULL;
                          else
                             state <= STATE_MEM_READ;
         
         //Invalid states.
         default        : state <= STATE_REQ_WAIT;
      endcase
end


//******************************************************************************
//* Driving the outputs of the AXI write data channel.                         *
//******************************************************************************
//Data accepted indicator.
assign axi_wready = (state == STATE_MEM_WRITE) & mem_write_ack;


//******************************************************************************
//* Driving the outputs of the AXI write response channel.                     *
//******************************************************************************
//Master ID.
assign axi_bid    = id_reg;
//Response (always OKAY).
assign axi_bresp  = 2'b00;
//Response valid indicator.
assign axi_bvalid = (state == STATE_WRITE_ACK);


//******************************************************************************
//* Driving the memory controller interface signals.                           *
//******************************************************************************
//Write transfer request signal.
assign mem_write_req = (state == STATE_MEM_WRITE) & ~(mem_write_ack & axi_wvalid & axi_wlast);
//Read transfer request signal.     
assign mem_read_req  = (state == STATE_MEM_READ)  & ~(mem_read_ack & (rd_fifo_full | last_rd_transfer));
//Address output.
assign mem_address   = {addr_reg[24:2], 1'b0};
//Byte enable signals.
assign mem_byte_en   = (state == STATE_MEM_WRITE) ? axi_wstrb : 4'b1111;
//Write data valid signal
assign mem_wr_valid  = (state == STATE_MEM_WRITE) & axi_wvalid;
//Write data output.
assign mem_wr_data   = axi_wdata;


//******************************************************************************
//* Register control signals.                                                  *
//******************************************************************************
//Master ID register load signal.
assign id_reg_ld = (state == STATE_REQ_WAIT) & addr_fifo_exists;

//Burst length counter control signals.
assign burst_len_cnt_ld = (state == STATE_REQ_WAIT) & addr_fifo_exists;
assign burst_len_cnt_en = mem_read_ack;

//Transfer size register load signal.
assign tr_size_reg_ld = (state == STATE_REQ_WAIT) & addr_fifo_exists;

//Address counter control signals.
assign addr_reg_ld = (state == STATE_REQ_WAIT) & addr_fifo_exists;
assign addr_cnt_en = mem_write_ack | mem_read_ack;


//******************************************************************************
//* FIFO control signals.                                                      *
//******************************************************************************
//AXI address channel FIFO read signal.
assign addr_fifo_rd = (state == STATE_REQ_WAIT) & addr_fifo_exists;


endmodule
