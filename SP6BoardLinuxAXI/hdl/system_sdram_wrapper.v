//-----------------------------------------------------------------------------
// system_sdram_wrapper.v
//-----------------------------------------------------------------------------

module system_sdram_wrapper
  (
    s_axi_aclk2x,
    mem_addr,
    mem_wen,
    mem_lbn,
    mem_ubn,
    sram_csn,
    sram_oen,
    sdram_clk,
    sdram_cke,
    sdram_csn,
    init_done,
    s_axi_aclk,
    s_axi_aresetn,
    s_axi_awid,
    s_axi_awaddr,
    s_axi_awlen,
    s_axi_awsize,
    s_axi_awburst,
    s_axi_awlock,
    s_axi_awcache,
    s_axi_awprot,
    s_axi_awvalid,
    s_axi_awready,
    s_axi_wdata,
    s_axi_wstrb,
    s_axi_wlast,
    s_axi_wvalid,
    s_axi_wready,
    s_axi_bid,
    s_axi_bresp,
    s_axi_bvalid,
    s_axi_bready,
    s_axi_arid,
    s_axi_araddr,
    s_axi_arlen,
    s_axi_arsize,
    s_axi_arburst,
    s_axi_arlock,
    s_axi_arcache,
    s_axi_arprot,
    s_axi_arvalid,
    s_axi_arready,
    s_axi_rid,
    s_axi_rdata,
    s_axi_rresp,
    s_axi_rvalid,
    s_axi_rready,
    s_axi_rlast,
    mem_data_I,
    mem_data_O,
    mem_data_T
  );
  input s_axi_aclk2x;
  output [17:0] mem_addr;
  output mem_wen;
  output mem_lbn;
  output mem_ubn;
  output sram_csn;
  output sram_oen;
  output sdram_clk;
  output sdram_cke;
  output sdram_csn;
  output init_done;
  input s_axi_aclk;
  input s_axi_aresetn;
  input [0:0] s_axi_awid;
  input [24:0] s_axi_awaddr;
  input [7:0] s_axi_awlen;
  input [2:0] s_axi_awsize;
  input [1:0] s_axi_awburst;
  input s_axi_awlock;
  input [3:0] s_axi_awcache;
  input [2:0] s_axi_awprot;
  input s_axi_awvalid;
  output s_axi_awready;
  input [31:0] s_axi_wdata;
  input [3:0] s_axi_wstrb;
  input s_axi_wlast;
  input s_axi_wvalid;
  output s_axi_wready;
  output [0:0] s_axi_bid;
  output [1:0] s_axi_bresp;
  output s_axi_bvalid;
  input s_axi_bready;
  input [0:0] s_axi_arid;
  input [24:0] s_axi_araddr;
  input [7:0] s_axi_arlen;
  input [2:0] s_axi_arsize;
  input [1:0] s_axi_arburst;
  input s_axi_arlock;
  input [3:0] s_axi_arcache;
  input [2:0] s_axi_arprot;
  input s_axi_arvalid;
  output s_axi_arready;
  output [0:0] s_axi_rid;
  output [31:0] s_axi_rdata;
  output [1:0] s_axi_rresp;
  output s_axi_rvalid;
  input s_axi_rready;
  output s_axi_rlast;
  input [15:0] mem_data_I;
  output [15:0] mem_data_O;
  output [15:0] mem_data_T;

  logsys_axi_sdram_ctrl
    #(
      .C_S_AXI_PROTOCOL ( "AXI4" ),
      .C_S_AXI_ADDR_WIDTH ( 25 ),
      .C_S_AXI_DATA_WIDTH ( 32 ),
      .C_S_AXI_ID_WIDTH ( 1 ),
      .C_S_AXI_ACLK_PERIOD_PS ( 16667 ),
      .C_T_SDRAM_RP_NS ( 20 ),
      .C_T_SDRAM_RFC_NS ( 66 ),
      .C_T_SDRAM_RMD_CLK ( 2 ),
      .C_T_SDRAM_RCD_NS ( 20 ),
      .C_T_SDRAM_RC_NS ( 66 ),
      .C_T_SDRAM_RAS_MIN_NS ( 42 ),
      .C_T_SDRAM_RAS_MAX_NS ( 100000 ),
      .C_T_SDRAM_REFRESH_MS ( 64 ),
      .C_SDRAM_REFRESH_BURST ( 8 ),
      .C_SDRAM_CAS_LATENCY ( 2 )
    )
    SDRAM (
      .s_axi_aclk2x ( s_axi_aclk2x ),
      .mem_addr ( mem_addr ),
      .mem_wen ( mem_wen ),
      .mem_lbn ( mem_lbn ),
      .mem_ubn ( mem_ubn ),
      .sram_csn ( sram_csn ),
      .sram_oen ( sram_oen ),
      .sdram_clk ( sdram_clk ),
      .sdram_cke ( sdram_cke ),
      .sdram_csn ( sdram_csn ),
      .init_done ( init_done ),
      .s_axi_aclk ( s_axi_aclk ),
      .s_axi_aresetn ( s_axi_aresetn ),
      .s_axi_awid ( s_axi_awid ),
      .s_axi_awaddr ( s_axi_awaddr ),
      .s_axi_awlen ( s_axi_awlen ),
      .s_axi_awsize ( s_axi_awsize ),
      .s_axi_awburst ( s_axi_awburst ),
      .s_axi_awlock ( s_axi_awlock ),
      .s_axi_awcache ( s_axi_awcache ),
      .s_axi_awprot ( s_axi_awprot ),
      .s_axi_awvalid ( s_axi_awvalid ),
      .s_axi_awready ( s_axi_awready ),
      .s_axi_wdata ( s_axi_wdata ),
      .s_axi_wstrb ( s_axi_wstrb ),
      .s_axi_wlast ( s_axi_wlast ),
      .s_axi_wvalid ( s_axi_wvalid ),
      .s_axi_wready ( s_axi_wready ),
      .s_axi_bid ( s_axi_bid ),
      .s_axi_bresp ( s_axi_bresp ),
      .s_axi_bvalid ( s_axi_bvalid ),
      .s_axi_bready ( s_axi_bready ),
      .s_axi_arid ( s_axi_arid ),
      .s_axi_araddr ( s_axi_araddr ),
      .s_axi_arlen ( s_axi_arlen ),
      .s_axi_arsize ( s_axi_arsize ),
      .s_axi_arburst ( s_axi_arburst ),
      .s_axi_arlock ( s_axi_arlock ),
      .s_axi_arcache ( s_axi_arcache ),
      .s_axi_arprot ( s_axi_arprot ),
      .s_axi_arvalid ( s_axi_arvalid ),
      .s_axi_arready ( s_axi_arready ),
      .s_axi_rid ( s_axi_rid ),
      .s_axi_rdata ( s_axi_rdata ),
      .s_axi_rresp ( s_axi_rresp ),
      .s_axi_rvalid ( s_axi_rvalid ),
      .s_axi_rready ( s_axi_rready ),
      .s_axi_rlast ( s_axi_rlast ),
      .mem_data_I ( mem_data_I ),
      .mem_data_O ( mem_data_O ),
      .mem_data_T ( mem_data_T )
    );

endmodule

