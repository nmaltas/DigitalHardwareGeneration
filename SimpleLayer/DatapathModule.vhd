library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity DatapathModule is

  generic (
    Width : integer := 8;
    Size  : integer := 3
  );

  port (
    DataIn   : in signed ((Width - 1) downto 0);
    AddressM : in integer range 0 to ((Size * Size) - 1);
    AddressB : in integer range 0 to (Size - 1);
    AddressX : in integer range 0 to (Size - 1);
    WEM      : in std_logic;
    WEB      : in std_logic;
    WEX      : in std_logic;
    Hold     : in std_logic;
    Reset    : in std_logic;
    Clk      : in std_logic;

    DataOut     : out signed(((Width * 2) - 1) downto 0);
    ErrorCheck2 : out std_logic_vector (1 downto 0)
  );
end DatapathModule;

architecture DatapathModule1 of DatapathModule is

  component MACUnit is
    generic (
      InputBitWidth : integer := 8
    );

    port (
      DataIn1 : in signed(Width - 1 downto 0);
      DataIn2 : in signed(Width - 1 downto 0);
      DataIn3 : in signed(Width - 1 downto 0);
      Hold    : in std_logic;
      Clk     : in std_logic;
      Reset   : in std_logic;

      DataOut     : out signed(((Width * 2) - 1) downto 0);
      ErrorCheck2 : out std_logic_vector (1 downto 0)
    );
  end component;

  component MemoryModule is
    generic (
      DataWidth : integer := 8;
      MemSize   : integer := 20);

    port (
      DataIn  : in signed ((DataWidth - 1) downto 0);
      Address : in integer range 0 to (Size - 1);
      WE      : in std_logic;
      Clk     : in std_logic;

      DataOut : out signed (DataWidth - 1 downto 0)
    );
  end component;

  signal DataInM : signed ((Width - 1) downto 0);
  signal DataInB : signed ((Width - 1) downto 0);
  signal DataInX : signed ((Width - 1) downto 0);

begin

  MemoryM : MemoryModule
  generic map(
    DataWidth => Width,
    MemSize   => (Size * Size)
  )
  port map
  (
    DataIn  => DataIn,
    Address => AddressM,
    WE      => WEM,
    Clk     => Clk,
    DataOut => DataInM
  );

  MemoryB : MemoryModule
  generic map(
    DataWidth => Width,
    MemSize   => Size
  )
  port map
  (
    DataIn  => DataIn,
    Address => AddressB,
    WE      => WEB,
    Clk     => Clk,
    DataOut => DataInB
  );

  MemoryX : MemoryModule
  generic map(
    DataWidth => Width,
    MemSize   => Size
  )
  port map
  (
    DataIn  => DataIn,
    Address => AddressX,
    WE      => WEX,
    Clk     => Clk,
    DataOut => DataInX
  );

  MACUNit_1 : MACUnit
  generic map(
    InputBitWidth => Width
  )
  port map
  (
    DataIn1     => DataInM,
    DataIn2     => DataInX,
    DataIn3     => DataInB,
    Hold        => Hold,
    Clk         => Clk,
    Reset       => Reset,
    DataOut     => DataOut,
    ErrorCheck2 => ErrorCheck2
  );

end DatapathModule1;
