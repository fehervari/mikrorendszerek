-------------------------------------------------------------------------------
-- system_logsys_axi_eth_if_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library logsys_axi_eth_if_v1_00_a;
use logsys_axi_eth_if_v1_00_a.all;

entity system_logsys_axi_eth_if_0_wrapper is
  port (
    eth_en : out std_logic;
    eth_al : out std_logic;
    eth_rnw_ad8 : out std_logic;
    eth_irq : in std_logic;
    interrupt : out std_logic;
    S_AXI_ACLK : in std_logic;
    S_AXI_ARESETN : in std_logic;
    S_AXI_AWADDR : in std_logic_vector(11 downto 0);
    S_AXI_AWVALID : in std_logic;
    S_AXI_WDATA : in std_logic_vector(31 downto 0);
    S_AXI_WSTRB : in std_logic_vector(3 downto 0);
    S_AXI_WVALID : in std_logic;
    S_AXI_BREADY : in std_logic;
    S_AXI_ARADDR : in std_logic_vector(11 downto 0);
    S_AXI_ARVALID : in std_logic;
    S_AXI_RREADY : in std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA : out std_logic_vector(31 downto 0);
    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    S_AXI_RVALID : out std_logic;
    S_AXI_WREADY : out std_logic;
    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    S_AXI_BVALID : out std_logic;
    S_AXI_AWREADY : out std_logic;
    eth_ad_I : in std_logic_vector(7 downto 0);
    eth_ad_O : out std_logic_vector(7 downto 0);
    eth_ad_T : out std_logic_vector(7 downto 0)
  );
end system_logsys_axi_eth_if_0_wrapper;

architecture STRUCTURE of system_logsys_axi_eth_if_0_wrapper is

  component logsys_axi_eth_if is
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
      C_S_AXI_ACLK_PERIOD_PS : INTEGER
    );
    port (
      eth_en : out std_logic;
      eth_al : out std_logic;
      eth_rnw_ad8 : out std_logic;
      eth_irq : in std_logic;
      interrupt : out std_logic;
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
      S_AXI_AWREADY : out std_logic;
      eth_ad_I : in std_logic_vector(7 downto 0);
      eth_ad_O : out std_logic_vector(7 downto 0);
      eth_ad_T : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  logsys_axi_eth_if_0 : logsys_axi_eth_if
    generic map (
      C_S_AXI_DATA_WIDTH => 32,
      C_S_AXI_ADDR_WIDTH => 12,
      C_S_AXI_MIN_SIZE => X"00000fff",
      C_USE_WSTRB => 1,
      C_DPHASE_TIMEOUT => 0,
      C_BASEADDR => X"84000000",
      C_HIGHADDR => X"8400ffff",
      C_FAMILY => "spartan6",
      C_NUM_REG => 1,
      C_NUM_MEM => 1,
      C_SLV_AWIDTH => 12,
      C_SLV_DWIDTH => 32,
      C_S_AXI_ACLK_PERIOD_PS => 16667
    )
    port map (
      eth_en => eth_en,
      eth_al => eth_al,
      eth_rnw_ad8 => eth_rnw_ad8,
      eth_irq => eth_irq,
      interrupt => interrupt,
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
      S_AXI_AWREADY => S_AXI_AWREADY,
      eth_ad_I => eth_ad_I,
      eth_ad_O => eth_ad_O,
      eth_ad_T => eth_ad_T
    );

end architecture STRUCTURE;

