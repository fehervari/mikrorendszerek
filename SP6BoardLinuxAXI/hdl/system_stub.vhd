-------------------------------------------------------------------------------
-- system_stub.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity system_stub is
  port (
    dev_miso : out std_logic;
    dev_mosi : in std_logic;
    man_rstn : in std_logic;
    osc_clk : in std_logic;
    SDRAM_mem_addr_pin : out std_logic_vector(17 downto 0);
    SDRAM_mem_data_pin : inout std_logic_vector(15 downto 0);
    SDRAM_mem_wen_pin : out std_logic;
    SDRAM_mem_lbn_pin : out std_logic;
    SDRAM_mem_ubn_pin : out std_logic;
    SDRAM_sram_csn_pin : out std_logic;
    SDRAM_sram_oen_pin : out std_logic;
    SDRAM_sdram_clk_pin : out std_logic;
    SDRAM_sdram_cke_pin : out std_logic;
    SDRAM_sdram_csn_pin : out std_logic;
    spi_lcd_csn : out std_logic;
    spi_clk : out std_logic;
    spi_mosi : out std_logic;
    spi_miso : out std_logic;
    buttons_GPIO_IO_I_pin : in std_logic_vector(2 downto 0)
  );
end system_stub;

architecture STRUCTURE of system_stub is

  component system is
    port (
      dev_miso : out std_logic;
      dev_mosi : in std_logic;
      man_rstn : in std_logic;
      osc_clk : in std_logic;
      SDRAM_mem_addr_pin : out std_logic_vector(17 downto 0);
      SDRAM_mem_data_pin : inout std_logic_vector(15 downto 0);
      SDRAM_mem_wen_pin : out std_logic;
      SDRAM_mem_lbn_pin : out std_logic;
      SDRAM_mem_ubn_pin : out std_logic;
      SDRAM_sram_csn_pin : out std_logic;
      SDRAM_sram_oen_pin : out std_logic;
      SDRAM_sdram_clk_pin : out std_logic;
      SDRAM_sdram_cke_pin : out std_logic;
      SDRAM_sdram_csn_pin : out std_logic;
      spi_lcd_csn : out std_logic;
      spi_clk : out std_logic;
      spi_mosi : out std_logic;
      spi_miso : out std_logic;
      buttons_GPIO_IO_I_pin : in std_logic_vector(2 downto 0)
    );
  end component;

  attribute BOX_TYPE : STRING;
  attribute BOX_TYPE of system : component is "user_black_box";

begin

  system_i : system
    port map (
      dev_miso => dev_miso,
      dev_mosi => dev_mosi,
      man_rstn => man_rstn,
      osc_clk => osc_clk,
      SDRAM_mem_addr_pin => SDRAM_mem_addr_pin,
      SDRAM_mem_data_pin => SDRAM_mem_data_pin,
      SDRAM_mem_wen_pin => SDRAM_mem_wen_pin,
      SDRAM_mem_lbn_pin => SDRAM_mem_lbn_pin,
      SDRAM_mem_ubn_pin => SDRAM_mem_ubn_pin,
      SDRAM_sram_csn_pin => SDRAM_sram_csn_pin,
      SDRAM_sram_oen_pin => SDRAM_sram_oen_pin,
      SDRAM_sdram_clk_pin => SDRAM_sdram_clk_pin,
      SDRAM_sdram_cke_pin => SDRAM_sdram_cke_pin,
      SDRAM_sdram_csn_pin => SDRAM_sdram_csn_pin,
      spi_lcd_csn => spi_lcd_csn,
      spi_clk => spi_clk,
      spi_mosi => spi_mosi,
      spi_miso => spi_miso,
      buttons_GPIO_IO_I_pin => buttons_GPIO_IO_I_pin
    );

end architecture STRUCTURE;

