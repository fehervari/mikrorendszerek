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
    rstbt : in std_logic;
    clk50M : in std_logic;
    sdram_csn : out std_logic;
    spi_sdcard_csn : out std_logic;
    spi_flash_csn : out std_logic;
    spi_lcd_csn : out std_logic;
    sram_csn : out std_logic;
    spi_clk : out std_logic;
    spi_mosi : out std_logic;
    spi_miso : out std_logic;
    cpld_jtagen : out std_logic;
    cpld_rstn : out std_logic;
    cpld_miso : in std_logic;
    cpld_mosi : out std_logic;
    cpld_load : out std_logic;
    cpld_clk : out std_logic
  );
end system_stub;

architecture STRUCTURE of system_stub is

  component system is
    port (
      dev_miso : out std_logic;
      dev_mosi : in std_logic;
      rstbt : in std_logic;
      clk50M : in std_logic;
      sdram_csn : out std_logic;
      spi_sdcard_csn : out std_logic;
      spi_flash_csn : out std_logic;
      spi_lcd_csn : out std_logic;
      sram_csn : out std_logic;
      spi_clk : out std_logic;
      spi_mosi : out std_logic;
      spi_miso : out std_logic;
      cpld_jtagen : out std_logic;
      cpld_rstn : out std_logic;
      cpld_miso : in std_logic;
      cpld_mosi : out std_logic;
      cpld_load : out std_logic;
      cpld_clk : out std_logic
    );
  end component;

  attribute BOX_TYPE : STRING;
  attribute BOX_TYPE of system : component is "user_black_box";

begin

  system_i : system
    port map (
      dev_miso => dev_miso,
      dev_mosi => dev_mosi,
      rstbt => rstbt,
      clk50M => clk50M,
      sdram_csn => sdram_csn,
      spi_sdcard_csn => spi_sdcard_csn,
      spi_flash_csn => spi_flash_csn,
      spi_lcd_csn => spi_lcd_csn,
      sram_csn => sram_csn,
      spi_clk => spi_clk,
      spi_mosi => spi_mosi,
      spi_miso => spi_miso,
      cpld_jtagen => cpld_jtagen,
      cpld_rstn => cpld_rstn,
      cpld_miso => cpld_miso,
      cpld_mosi => cpld_mosi,
      cpld_load => cpld_load,
      cpld_clk => cpld_clk
    );

end architecture STRUCTURE;

