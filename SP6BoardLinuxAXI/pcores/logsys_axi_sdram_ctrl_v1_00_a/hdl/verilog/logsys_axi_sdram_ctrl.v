//******************************************************************************
//* AXI SDRAM controller for the LOGSYS Spartan-6 FPGA board.                  *
//*                                                                            *
//* Written by   : Tamas Raikovich                                             *
//* Version      : 1.0                                                         *
//* Last modified: 2012.10.21.                                                 *
//******************************************************************************
module logsys_axi_sdram_ctrl #(
   //SDRAM timing parameters.
   parameter C_T_SDRAM_RP_NS        = 20,                   //Wait time after PRECHARGE command in ns
   parameter C_T_SDRAM_RFC_NS       = 66,                   //AUTO REFRESH command period in ns
   parameter C_T_SDRAM_RMD_CLK      = 2,                    //Wait time after mode reg. write in clocks
   parameter C_T_SDRAM_RCD_NS       = 20,                   //RAS to CAS delay in ns
   parameter C_T_SDRAM_RC_NS        = 66,                   //RAS to RAS delay in ns
   parameter C_T_SDRAM_RAS_MIN_NS   = 42,                   //Min. row active time in ns
   parameter C_T_SDRAM_RAS_MAX_NS   = 100000,               //Max. row active time in ns
   parameter C_T_SDRAM_REFRESH_MS   = 64,                   //Refresh period in ms
   parameter C_SDRAM_REFRESH_BURST  = 8,                    //Number of issued AUTO REFRESH commands
   parameter C_SDRAM_CAS_LATENCY    = 3,                    //CAS latency in clocks
   
   //AXI related parameters.
   parameter C_S_AXI_ACLK_PERIOD_PS = 10000,                //AXI clock period in ps
   parameter C_S_AXI_PROTOCOL       = "AXI4",               //AXI interface protocol
   parameter C_S_AXI_ID_WIDTH       = 1,                    //Master ID size in bits
   parameter C_S_AXI_ADDR_WIDTH     = 25,                   //Address bus size in bits
   parameter C_S_AXI_DATA_WIDTH     = 32                    //Data bus size in bits
) ( 
   //AXI clock and reset.
   input  wire                            s_axi_aclk,       //AXI clock signal
   input  wire                            s_axi_aclk2x,     //2x AXI clock signal
   input  wire                            s_axi_aresetn,    //Reset signal (active-low)
   
   //AXI write address channel.
   input  wire [C_S_AXI_ID_WIDTH-1:0]     s_axi_awid,       //Master ID
   input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,     //Address
   input  wire [7:0]                      s_axi_awlen,      //Number of transfers in the burst
   input  wire [2:0]                      s_axi_awsize,     //Transfer size
   input  wire [1:0]                      s_axi_awburst,    //Burst type
   input  wire                            s_axi_awlock,     //Exclusive access (not used)
   input  wire [3:0]                      s_axi_awcache,    //Memory type (not used)
   input  wire [2:0]                      s_axi_awprot,     //Access permissions (not used)
   input  wire                            s_axi_awvalid,    //Address valid indicator
   output wire                            s_axi_awready,    //Address accepted indicator
   
   //AXI write data channel.
   input  wire [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,      //Data bus
   input  wire [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,      //Byte enable signals
   input  wire                            s_axi_wlast,      //Last transfer indicator
   input  wire                            s_axi_wvalid,     //Data valid indicator
   output wire                            s_axi_wready,     //Data accepted indicator
   
   //AXI write response channel.
   output wire [C_S_AXI_ID_WIDTH-1:0]     s_axi_bid,        //Master ID
   output wire [1:0]                      s_axi_bresp,      //Response
   output wire                            s_axi_bvalid,     //Response valid indicator
   input  wire                            s_axi_bready,     //Response accepted indicator
   
   //AXI read address channel.
   input  wire [C_S_AXI_ID_WIDTH-1:0]     s_axi_arid,       //Master ID
   input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,     //Address
   input  wire [7:0]                      s_axi_arlen,      //Number of transfers in the burst
   input  wire [2:0]                      s_axi_arsize,     //Transfer size
   input  wire [1:0]                      s_axi_arburst,    //Burst type
   input  wire                            s_axi_arlock,     //Exclusive access (not used)
   input  wire [3:0]                      s_axi_arcache,    //Memory type (not used)
   input  wire [2:0]                      s_axi_arprot,     //Access permissions (not used)
   input  wire                            s_axi_arvalid,    //Address valid indicator
   output wire                            s_axi_arready,    //Address accepted indicator
   
   //AXI read response channel.
   output wire [C_S_AXI_ID_WIDTH-1:0]     s_axi_rid,        //Master ID
   output wire [C_S_AXI_DATA_WIDTH-1:0]   s_axi_rdata,      //Data bus
   output wire [1:0]                      s_axi_rresp,      //Response
   output wire                            s_axi_rvalid,     //Response valid indicator
   input  wire                            s_axi_rready,     //Response accepted indicator
   output wire                            s_axi_rlast,      //Last transfer indicator
   
   //Common memory interface signals.
   output wire [17:0]                     mem_addr,         //Memory address bus
   output wire [15:0]                     mem_data_O,       //Memory data bus
   input  wire [15:0]                     mem_data_I,
   output wire [15:0]                     mem_data_T,
   output wire                            mem_wen,          //Memory write enable signal (active-low)
   output wire                            mem_lbn,          //Lower data byte enable (active-low)
   output wire                            mem_ubn,          //Upper data byte enable (active-low)
   
   //Signals related to the SRAM.
   output wire                            sram_csn,         //SRAM chip select signal (active-low)
   output wire                            sram_oen,         //SRAM output enable signal (active-low)
  
   //Signals related to the SDRAM.
   output wire                            sdram_clk,        //SDRAM clock signal
   output wire                            sdram_cke,        //SDRAM clock enable signal
   output wire                            sdram_csn,        //SDRAM chip select signal (active-low)
   
   //SDRAM initialization done signal.
   output wire                            init_done
);

`include "memctrl_defs.vh"
`include "functions.vh"

//******************************************************************************
//* AXI interface.                                                             *
//******************************************************************************
wire        mem_write_req;
wire        mem_read_req;
wire [24:1] mem_address;
wire [3:0]  mem_byte_en;
wire        mem_write_ack;
wire        mem_wr_valid;
wire [31:0] mem_wr_data;
wire        mem_read_ack;
wire        mem_rd_valid;
wire [31:0] mem_rd_data;

axi_interface #(
   //AXI related parameters.
   .AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),                   //Master ID size in bits
   .AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),               //Address bus size in bits
   .AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),               //Data bus size in bits
   
   //Memory read pipeline delay in clocks.
   .MEM_RD_DELAY_CLK(C_SDRAM_CAS_LATENCY+1)
) axi_interface (
   //AXI clock and reset.
   .axi_aclk(s_axi_aclk),                             //Clock signal
   .axi_aresetn(s_axi_aresetn),                       //Reset signal (active-low)
   
   //AXI write address channel.
   .axi_awid(s_axi_awid),                             //Master ID
   .axi_awaddr(s_axi_awaddr),                         //Address
   .axi_awlen(s_axi_awlen),                           //Number of transfers in the burst
   .axi_awsize(s_axi_awsize),                         //Transfer size
   .axi_awburst(s_axi_awburst),                       //Burst type
   .axi_awlock(s_axi_awlock),                         //Exclusive access (not used)
   .axi_awcache(s_axi_awcache),                       //Memory type (not used)
   .axi_awprot(s_axi_awprot),                         //Access permissions (not used)
   .axi_awvalid(s_axi_awvalid),                       //Address valid indicator
   .axi_awready(s_axi_awready),                       //Address accepted indicator
   
   //AXI write data channel.
   .axi_wdata(s_axi_wdata),                           //Data bus
   .axi_wstrb(s_axi_wstrb),                           //Byte enable signals
   .axi_wlast(s_axi_wlast),                           //Last transfer indicator
   .axi_wvalid(s_axi_wvalid),                         //Data valid indicator
   .axi_wready(s_axi_wready),                         //Data accepted indicator
   
   //AXI write response channel.
   .axi_bid(s_axi_bid),                               //Master ID
   .axi_bresp(s_axi_bresp),                           //Response
   .axi_bvalid(s_axi_bvalid),                         //Response valid indicator
   .axi_bready(s_axi_bready),                         //Response accepted indicator
   
   //AXI read address channel.
   .axi_arid(s_axi_arid),                             //Master ID
   .axi_araddr(s_axi_araddr),                         //Address
   .axi_arlen(s_axi_arlen),                           //Number of transfers in the burst
   .axi_arsize(s_axi_arsize),                         //Transfer size
   .axi_arburst(s_axi_arburst),                       //Burst type
   .axi_arlock(s_axi_arlock),                         //Exclusive access (not used)
   .axi_arcache(s_axi_arcache),                       //Memory type (not used)
   .axi_arprot(s_axi_arprot),                         //Access permissions (not used)
   .axi_arvalid(s_axi_arvalid),                       //Address valid indicator
   .axi_arready(s_axi_arready),                       //Address accepted indicator
   
   //AXI read response channel.
   .axi_rid(s_axi_rid),                               //Master ID
   .axi_rdata(s_axi_rdata),                           //Data bus
   .axi_rresp(s_axi_rresp),                           //Response
   .axi_rvalid(s_axi_rvalid),                         //Response valid indicator
   .axi_rready(s_axi_rready),                         //Response accepted indicator
   .axi_rlast(s_axi_rlast),                           //Last transfer indicator
   
   //Memory controller interface signals (little-endian).
   .mem_write_req(mem_write_req),                     //Write transfer request signal
   .mem_read_req(mem_read_req),                       //Read transfer request signal
   .mem_address(mem_address),                         //Address output
   .mem_byte_en(mem_byte_en),                         //Byte enable signals
   .mem_write_ack(mem_write_ack),                     //Write acknowledge signal
   .mem_wr_valid(mem_wr_valid),                       //Write data valid signal
   .mem_wr_data(mem_wr_data),                         //Write data output
   .mem_read_ack(mem_read_ack),                       //Write acknowledge signal
   .mem_rd_valid(mem_rd_valid),                       //Read data valid signal
   .mem_rd_data(mem_rd_data)                          //Read data input
);


//******************************************************************************
//* Memory controller state machine.                                           *
//******************************************************************************
wire        iodelay_cal;
wire        iodelay_busy;
wire [1:0]  sdram_bank_addr;
wire [12:0] sdram_row_addr;  
wire        sdram_cke_set;
wire [8:0]  sdram_cmd;
wire [1:0]  sdram_addr_sel;
wire        dout_buf_tri;
wire        be_valid;
wire        be_delay_sel;   

sdram_ctrl #(   
   //SDRAM timing parameters.
   .SDRAM_T_RP_PS(C_T_SDRAM_RP_NS * 1000),            //Wait time after PRECHARGE command in ps
   .SDRAM_T_RFC_PS(C_T_SDRAM_RFC_NS * 1000),          //AUTO REFRESH command period in ps
   .SDRAM_T_RMD_CLK(C_T_SDRAM_RMD_CLK),               //Wait time after mode reg. write in clocks
   .SDRAM_T_RCD_PS(C_T_SDRAM_RCD_NS * 1000),          //RAS to CAS delay in ps
   .SDRAM_T_RC_PS(C_T_SDRAM_RC_NS * 1000),            //RAS to RAS delay in ps
   .SDRAM_T_RAS_MIN_PS(C_T_SDRAM_RAS_MIN_NS * 1000),  //Min. row active time in ps
   .SDRAM_T_RAS_MAX_PS(C_T_SDRAM_RAS_MAX_NS * 1000),  //Max. row active time in ps
   .SDRAM_T_REFRESH_MS(C_T_SDRAM_REFRESH_MS),         //Refresh period in ms
   .SDRAM_REFRESH_BURST(C_SDRAM_REFRESH_BURST),       //Number of issued AUTO REFRESH commands
   .SDRAM_CAS_LATENCY(C_SDRAM_CAS_LATENCY),           //CAS latency in clocks
   
   //System clock parameters.
   .SYSCLK_PERIOD_PS(C_S_AXI_ACLK_PERIOD_PS)          //System clock period in ps
) sdram_ctrl (
   //Clock and reset.
   .clk(s_axi_aclk),                                  //Clock signal
   .rstn(s_axi_aresetn),                              //Reset signal (active-low)
   
   //Input control signals.
   .mem_write_req(mem_write_req),                     //Memory write request signal
   .mem_read_req(mem_read_req),                       //Memory read request signal
   .wr_data_valid(mem_wr_valid),                      //Write data valid signal
   .sdram_bank_addr(sdram_bank_addr),                 //SDRAM bank address
   .sdram_row_addr(sdram_row_addr),                   //SDRAM row address
   .iodelay_busy(iodelay_busy),                       //IODELAY calibration is in progress
   
   //Output control signals.
   .sdram_cke_set(sdram_cke_set),                     //SDRAM clock enable set signal
   .sdram_init_done(init_done),                       //SDRAM initialization done signal
   .iodelay_cal(iodelay_cal),                         //IODELAY calibration start signal
   .sdram_cmd(sdram_cmd),                             //SDRAM command
   .sdram_addr_sel(sdram_addr_sel),                   //SDRAM address select signal
   .mem_write_ack(mem_write_ack),                     //Write acknowledge signal
   .mem_read_ack(mem_read_ack),                       //Read acknowledge signal
   .dout_buf_tri(dout_buf_tri),                       //Output buffer tri-state signal
   .be_valid(be_valid),                               //Byte enable valid signal
   .be_delay_sel(be_delay_sel),                       //Byte enable delay select  
   .rd_data_valid(mem_rd_valid)                       //Read data valid signal
);


//******************************************************************************
//* Physical interface.                                                        *
//******************************************************************************
localparam SDRAM_MREG_VALUE = (C_SDRAM_CAS_LATENCY == 3) ? SDRAM_MREG_VALUE_CL3 : SDRAM_MREG_VALUE_CL2;

phy phy(
   //Clock and reset.
   .clk(s_axi_aclk),                                  //1x system clock signal
   .clk2x(s_axi_aclk2x),                              //2x system clock signal
   .rstn(s_axi_aresetn),                              //Asynchronous reset signal (active-low)
   
   //Signals from the memory controller.
   .sdram_cke_set(sdram_cke_set),                     //SDRAM clock enable output set signal
   .sdram_mreg_val(SDRAM_MREG_VALUE),                 //Value of the SDRAM mode register
   .sdram_cmd(sdram_cmd),                             //SDRAM command input
   .address_in(mem_address),                          //Memory address input
   .sdram_addr_sel(sdram_addr_sel),                   //SDRAM address select signal
   .write_data(mem_wr_data),                          //Write data input (little-endian)
   .dout_buf_tri(dout_buf_tri),                       //Output buffer tri-state signal  
   .byte_enable(mem_byte_en),                         //Byte enable signals (little-endian)
   .be_valid(be_valid),                               //Byte enable valid signal
   .be_delay_sel(be_delay_sel),                       //Byte enable delay select
   .iodelay_cal(iodelay_cal),                         //IODELAY calibration start signal
   .init_done(init_done),                             //SDRAM initialization done signal
   
   //Signals to the memory controller.
   .read_data(mem_rd_data),                           //Read data output (little-endian)
   .sdram_bank_addr(sdram_bank_addr),                 //SDRAM bank address
   .sdram_row_addr(sdram_row_addr),                   //SDRAM row address
   .sdram_col_addr(),                                 //SDRAM column address
   .iodelay_busy(iodelay_busy),                       //IODELAY calibration is in progress
   
   //Common memory interface signals.
   .mem_addr(mem_addr),                               //Memory address bus
   .mem_data_O(mem_data_O),                           //Memory data bus
   .mem_data_I(mem_data_I),
   .mem_data_T(mem_data_T),
   .mem_wen(mem_wen),                                 //Memory write enable signal (active low)
   .mem_lbn(mem_lbn),                                 //Lower data byte enable (active low)
   .mem_ubn(mem_ubn),                                 //Upper data byte enable (active low)
   
   //Signals related to the SRAM.
   .sram_csn(sram_csn),                               //SRAM chip select signal (active low)
   .sram_oen(sram_oen),                               //SRAM output enable signal (active low)
   
   //Signals related to the SDRAM.
   .sdram_clk(sdram_clk),                             //SDRAM clock signal.
   .sdram_cke(sdram_cke),                             //SDRAM clock enable signal
   .sdram_csn(sdram_csn)                              //SDRAM chip select signal (active low)
);


endmodule
