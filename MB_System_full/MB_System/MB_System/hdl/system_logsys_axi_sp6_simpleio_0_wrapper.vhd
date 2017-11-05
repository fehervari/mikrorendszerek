-------------------------------------------------------------------------------
-- system_logsys_axi_sp6_simpleio_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library logsys_axi_sp6_simpleio_v1_00_a;
use logsys_axi_sp6_simpleio_v1_00_a.all;

entity system_logsys_axi_sp6_simpleio_0_wrapper is
  port (
    irq : out std_logic;
    btn_in : in std_logic_vector(2 downto 0);
    sw_out : out std_logic_vector(7 downto 0);
    cpld_jtagen : out std_logic;
    cpld_rstn : out std_logic;
    cpld_clk : out std_logic;
    cpld_load : out std_logic;
    cpld_mosi : out std_logic;
    cpld_miso : in std_logic;
    gpio_I : in std_logic_vector(12 downto 0);
    gpio_O : out std_logic_vector(12 downto 0);
    gpio_T : out std_logic_vector(12 downto 0);
    S_AXI_ACLK : in std_logic;
    S_AXI_ARESETN : in std_logic;
    S_AXI_AWADDR : in std_logic_vector(3 downto 0);
    S_AXI_AWVALID : in std_logic;
    S_AXI_WDATA : in std_logic_vector(31 downto 0);
    S_AXI_WSTRB : in std_logic_vector(3 downto 0);
    S_AXI_WVALID : in std_logic;
    S_AXI_BREADY : in std_logic;
    S_AXI_ARADDR : in std_logic_vector(3 downto 0);
    S_AXI_ARVALID : in std_logic;
    S_AXI_RREADY : in std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA : out std_logic_vector(31 downto 0);
    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    S_AXI_RVALID : out std_logic;
    S_AXI_WREADY : out std_logic;
    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    S_AXI_BVALID : out std_logic;
    S_AXI_AWREADY : out std_logic
  );
end system_logsys_axi_sp6_simpleio_0_wrapper;

architecture STRUCTURE of system_logsys_axi_sp6_simpleio_0_wrapper is

  component logsys_axi_sp6_simpleio is
    generic (
      C_S_AXI_DATA_WIDTH : INTEGER;
      C_S_AXI_ADDR_WIDTH : INTEGER;
      C_S_AXI_MIN_SIZE : std_logic_vector;
      C_USE_WSTRB : INTEGER;
      C_DPHASE_TIMEOUT : INTEGER;
      C_BASEADDR : std_logic_vector;
      C_HIGHADDR : std_logic_vector;
      C_FAMILY : STRING;
      C_NUM_REG : INTEGER;
      C_NUM_MEM : INTEGER;
      C_SLV_AWIDTH : INTEGER;
      C_SLV_DWIDTH : INTEGER;
      C_S_AXI_ACLK_FREQ_HZ : INTEGER;
      C_GPIO_ENABLE : INTEGER;
      C_GPIO_WIDTH : INTEGER
    );
    port (
      irq : out std_logic;
      btn_in : in std_logic_vector(2 downto 0);
      sw_out : out std_logic_vector(7 downto 0);
      cpld_jtagen : out std_logic;
      cpld_rstn : out std_logic;
      cpld_clk : out std_logic;
      cpld_load : out std_logic;
      cpld_mosi : out std_logic;
      cpld_miso : in std_logic;
      gpio_I : in std_logic_vector((C_GPIO_WIDTH-1) downto 0);
      gpio_O : out std_logic_vector((C_GPIO_WIDTH-1) downto 0);
      gpio_T : out std_logic_vector((C_GPIO_WIDTH-1) downto 0);
      S_AXI_ACLK : in std_logic;
      S_AXI_ARESETN : in std_logic;
      S_AXI_AWADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
      S_AXI_AWVALID : in std_logic;
      S_AXI_WDATA : in std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
      S_AXI_WSTRB : in std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1) downto 0);
      S_AXI_WVALID : in std_logic;
      S_AXI_BREADY : in std_logic;
      S_AXI_ARADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
      S_AXI_ARVALID : in std_logic;
      S_AXI_RREADY : in std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
      S_AXI_RRESP : out std_logic_vector(1 downto 0);
      S_AXI_RVALID : out std_logic;
      S_AXI_WREADY : out std_logic;
      S_AXI_BRESP : out std_logic_vector(1 downto 0);
      S_AXI_BVALID : out std_logic;
      S_AXI_AWREADY : out std_logic
    );
  end component;

begin

  logsys_axi_sp6_simpleio_0 : logsys_axi_sp6_simpleio
    generic map (
      C_S_AXI_DATA_WIDTH => 32,
      C_S_AXI_ADDR_WIDTH => 4,
      C_S_AXI_MIN_SIZE => X"0000000f",
      C_USE_WSTRB => 1,
      C_DPHASE_TIMEOUT => 4,
      C_BASEADDR => X"43000000",
      C_HIGHADDR => X"4300FFFF",
      C_FAMILY => "spartan6",
      C_NUM_REG => 1,
      C_NUM_MEM => 1,
      C_SLV_AWIDTH => 4,
      C_SLV_DWIDTH => 32,
      C_S_AXI_ACLK_FREQ_HZ => 50000000,
      C_GPIO_ENABLE => 0,
      C_GPIO_WIDTH => 13
    )
    port map (
      irq => irq,
      btn_in => btn_in,
      sw_out => sw_out,
      cpld_jtagen => cpld_jtagen,
      cpld_rstn => cpld_rstn,
      cpld_clk => cpld_clk,
      cpld_load => cpld_load,
      cpld_mosi => cpld_mosi,
      cpld_miso => cpld_miso,
      gpio_I => gpio_I,
      gpio_O => gpio_O,
      gpio_T => gpio_T,
      S_AXI_ACLK => S_AXI_ACLK,
      S_AXI_ARESETN => S_AXI_ARESETN,
      S_AXI_AWADDR => S_AXI_AWADDR,
      S_AXI_AWVALID => S_AXI_AWVALID,
      S_AXI_WDATA => S_AXI_WDATA,
      S_AXI_WSTRB => S_AXI_WSTRB,
      S_AXI_WVALID => S_AXI_WVALID,
      S_AXI_BREADY => S_AXI_BREADY,
      S_AXI_ARADDR => S_AXI_ARADDR,
      S_AXI_ARVALID => S_AXI_ARVALID,
      S_AXI_RREADY => S_AXI_RREADY,
      S_AXI_ARREADY => S_AXI_ARREADY,
      S_AXI_RDATA => S_AXI_RDATA,
      S_AXI_RRESP => S_AXI_RRESP,
      S_AXI_RVALID => S_AXI_RVALID,
      S_AXI_WREADY => S_AXI_WREADY,
      S_AXI_BRESP => S_AXI_BRESP,
      S_AXI_BVALID => S_AXI_BVALID,
      S_AXI_AWREADY => S_AXI_AWREADY
    );

end architecture STRUCTURE;

