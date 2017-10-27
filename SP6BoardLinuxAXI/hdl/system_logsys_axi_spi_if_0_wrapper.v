//-----------------------------------------------------------------------------
// system_logsys_axi_spi_if_0_wrapper.v
//-----------------------------------------------------------------------------

module system_logsys_axi_spi_if_0_wrapper
  (
    flash_csn,
    lcd_csn,
    sdcard_csn,
    spi_clk,
    irq,
    S_AXI_ACLK,
    S_AXI_ARESETN,
    S_AXI_AWADDR,
    S_AXI_AWVALID,
    S_AXI_WDATA,
    S_AXI_WSTRB,
    S_AXI_WVALID,
    S_AXI_BREADY,
    S_AXI_ARADDR,
    S_AXI_ARVALID,
    S_AXI_RREADY,
    S_AXI_ARREADY,
    S_AXI_RDATA,
    S_AXI_RRESP,
    S_AXI_RVALID,
    S_AXI_WREADY,
    S_AXI_BRESP,
    S_AXI_BVALID,
    S_AXI_AWREADY,
    spi_mosi_O,
    spi_mosi_T,
    spi_miso_I,
    spi_miso_O,
    spi_miso_T
  );
  output flash_csn;
  output lcd_csn;
  output sdcard_csn;
  output spi_clk;
  output irq;
  input S_AXI_ACLK;
  input S_AXI_ARESETN;
  input [3:0] S_AXI_AWADDR;
  input S_AXI_AWVALID;
  input [31:0] S_AXI_WDATA;
  input [3:0] S_AXI_WSTRB;
  input S_AXI_WVALID;
  input S_AXI_BREADY;
  input [3:0] S_AXI_ARADDR;
  input S_AXI_ARVALID;
  input S_AXI_RREADY;
  output S_AXI_ARREADY;
  output [31:0] S_AXI_RDATA;
  output [1:0] S_AXI_RRESP;
  output S_AXI_RVALID;
  output S_AXI_WREADY;
  output [1:0] S_AXI_BRESP;
  output S_AXI_BVALID;
  output S_AXI_AWREADY;
  output spi_mosi_O;
  output spi_mosi_T;
  input spi_miso_I;
  output spi_miso_O;
  output spi_miso_T;

  logsys_axi_spi_if
    #(
      .C_S_AXI_DATA_WIDTH ( 32 ),
      .C_S_AXI_ADDR_WIDTH ( 4 ),
      .C_S_AXI_MIN_SIZE ( 32'h0000000f ),
      .C_USE_WSTRB ( 1 ),
      .C_DPHASE_TIMEOUT ( 4 ),
      .C_BASEADDR ( 32'h85000000 ),
      .C_HIGHADDR ( 32'h8500ffff ),
      .C_FAMILY ( "spartan6" ),
      .C_NUM_REG ( 1 ),
      .C_NUM_MEM ( 1 ),
      .C_SLV_AWIDTH ( 4 ),
      .C_SLV_DWIDTH ( 32 )
    )
    logsys_axi_spi_if_0 (
      .flash_csn ( flash_csn ),
      .lcd_csn ( lcd_csn ),
      .sdcard_csn ( sdcard_csn ),
      .spi_clk ( spi_clk ),
      .irq ( irq ),
      .S_AXI_ACLK ( S_AXI_ACLK ),
      .S_AXI_ARESETN ( S_AXI_ARESETN ),
      .S_AXI_AWADDR ( S_AXI_AWADDR ),
      .S_AXI_AWVALID ( S_AXI_AWVALID ),
      .S_AXI_WDATA ( S_AXI_WDATA ),
      .S_AXI_WSTRB ( S_AXI_WSTRB ),
      .S_AXI_WVALID ( S_AXI_WVALID ),
      .S_AXI_BREADY ( S_AXI_BREADY ),
      .S_AXI_ARADDR ( S_AXI_ARADDR ),
      .S_AXI_ARVALID ( S_AXI_ARVALID ),
      .S_AXI_RREADY ( S_AXI_RREADY ),
      .S_AXI_ARREADY ( S_AXI_ARREADY ),
      .S_AXI_RDATA ( S_AXI_RDATA ),
      .S_AXI_RRESP ( S_AXI_RRESP ),
      .S_AXI_RVALID ( S_AXI_RVALID ),
      .S_AXI_WREADY ( S_AXI_WREADY ),
      .S_AXI_BRESP ( S_AXI_BRESP ),
      .S_AXI_BVALID ( S_AXI_BVALID ),
      .S_AXI_AWREADY ( S_AXI_AWREADY ),
      .spi_mosi_O ( spi_mosi_O ),
      .spi_mosi_T ( spi_mosi_T ),
      .spi_miso_I ( spi_miso_I ),
      .spi_miso_O ( spi_miso_O ),
      .spi_miso_T ( spi_miso_T )
    );

endmodule

