library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity DatapathModule is

  generic (
    DataWidth : integer := 8;
    Rows      : integer := 3;
    Columns   : integer := 4
  );

  port (
    DataIn   : in signed ((DataWidth - 1) downto 0);
    AddressW : in integer range 0 to (Columns - 1);
    AddressX : in integer range 0 to (Columns - 1);
    REW      : in std_logic;
    REB      : in std_logic;
    REX      : in std_logic;
    WEX      : in std_logic;
    Hold     : in std_logic;
    Reset_L  : in std_logic;
    Clk      : in std_logic;

    DataOut0 : out signed(((DataWidth * 2) - 1) downto 0);
    DataOut1 : out signed(((DataWidth * 2) - 1) downto 0);
    DataOut2 : out signed(((DataWidth * 2) - 1) downto 0);

    ErrorCheck20 : out std_logic_vector (1 downto 0);
    ErrorCheck21 : out std_logic_vector (1 downto 0);
    ErrorCheck22 : out std_logic_vector (1 downto 0)
  );
end DatapathModule;

architecture DatapathModule1 of DatapathModule is

  component MACUnit is
    generic (
      DataWidth : integer := 8
    );

    port (
      DataIn1 : in signed(DataWidth - 1 downto 0);
      DataIn2 : in signed(DataWidth - 1 downto 0);
      DataIn3 : in signed(DataWidth - 1 downto 0);
      Hold    : in std_logic;
      Clk     : in std_logic;
      Reset_L : in std_logic;

      DataOut     : out signed(((DataWidth * 2) - 1) downto 0);
      ErrorCheck2 : out std_logic_vector (1 downto 0)
    );
  end component;

  component MemoryModule is
    generic (
      DataWidth : integer := 8;
      MemSize   : integer := 20);

    port (
      DataIn  : in signed ((DataWidth - 1) downto 0);
      Address : in integer range 0 to (MemSize - 1);
      WE      : in std_logic;
      RE      : in std_logic;
      Clk     : in std_logic;

      DataOut : out signed (DataWidth - 1 downto 0)
    );
  end component;

  component ROMW is
    generic (
      DataWidth : integer := 8;
      Columns   : integer := 4;

      -- These memory slots need to be hardcoded. HLS will have to deal with this.
      Slot00 : integer := 1;
      Slot01 : integer := 2;
      Slot02 : integer := 3;
      Slot03 : integer := 4;
      Slot10 : integer := 5;
      Slot11 : integer := 6;
      Slot12 : integer := 7;
      Slot13 : integer := 8;
      Slot20 : integer := 9;
      Slot21 : integer := 10;
      Slot22 : integer := 11;
      Slot23 : integer := 12);

    port (
      Address : in integer range 0 to (Columns - 1);
      Enable  : in std_logic;
      Clk     : in std_logic;

      -- One output port is needed for each Row in order to support full parallelization.
      -- Number of output ports has to be hardcoded. HLS will have to deal with this.
      DataOut0 : out signed ((DataWidth - 1) downto 0);
      DataOut1 : out signed ((DataWidth - 1) downto 0);
      DataOut2 : out signed ((DataWidth - 1) downto 0)
    );
  end component;

  component ROMB is
    generic (
      DataWidth : integer := 8;

      -- Memory slots have to be hardcodded. HLS will deal with this.
      Slot0 : integer := 0;
      Slot1 : integer := 1;
      Slot2 : integer := 2);

    port (
      Enable : in std_logic;
      Clk    : in std_logic;

      -- Each Row/value neds a separate output port.
      -- Number of output ports has to be hardcoded. HLS will have to deal with this.
      DataOut0 : out signed ((DataWidth - 1) downto 0);
      DataOut1 : out signed ((DataWidth - 1) downto 0);
      DataOut2 : out signed ((DataWidth - 1) downto 0)
    );
  end component;

  signal DataInB0 : signed ((DataWidth - 1) downto 0);
  signal DataInB1 : signed ((DataWidth - 1) downto 0);
  signal DataInB2 : signed ((DataWidth - 1) downto 0);

  signal DataInW0 : signed ((DataWidth - 1) downto 0);
  signal DataInW1 : signed ((DataWidth - 1) downto 0);
  signal DataInW2 : signed ((DataWidth - 1) downto 0);

  signal DataInX : signed ((DataWidth - 1) downto 0);

begin

  MemoryW : ROMW
  generic map(
    DataWidth => DataWidth,
    Columns   => Columns,
    Slot00    => 116,
    Slot01    => - 121,
    Slot02    => 113,
    Slot03    => - 125,
    Slot10    => 94,
    Slot11    => - 107,
    Slot12    => - 113,
    Slot13    => - 99,
    Slot20    => - 116,
    Slot21    => 121,
    Slot22    => - 113,
    Slot23    => 125
  )
  port map
  (
    Address  => AddressW,
    Enable   => REW,
    Clk      => Clk,
    DataOut0 => DataInW0,
    DataOut1 => DataInW1,
    DataOut2 => DataInW2
  );

  MemoryB : ROMB
  generic map(
    DataWidth => DataWidth,
    Slot0     => 101,
    Slot1     => 83,
    Slot2     => - 55
  )
  port map
  (
    Enable   => REB,
    Clk      => Clk,
    DataOut0 => DataInB0,
    DataOut1 => DataInB1,
    DataOut2 => DataInB2
  );

  MemoryX : MemoryModule
  generic map(
    DataWidth => DataWidth,
    MemSize   => Columns
  )
  port map
  (
    DataIn  => DataIn,
    Address => AddressX,
    WE      => WEX,
    RE      => REX,
    Clk     => Clk,
    DataOut => DataInX
  );

  MACUNit0 : MACUnit
  generic map(
    DataWidth => DataWidth
  )
  port map
  (
    DataIn1     => DataInW0,
    DataIn2     => DataInX,
    DataIn3     => DataInB0,
    Hold        => Hold,
    Clk         => Clk,
    Reset_L     => Reset_L,
    DataOut     => DataOut0,
    ErrorCheck2 => ErrorCheck20
  );

  MACUNit1 : MACUnit
  generic map(
    DataWidth => DataWidth
  )
  port map
  (
    DataIn1     => DataInW1,
    DataIn2     => DataInX,
    DataIn3     => DataInB1,
    Hold        => Hold,
    Clk         => Clk,
    Reset_L     => Reset_L,
    DataOut     => DataOut1,
    ErrorCheck2 => ErrorCheck21
  );

  MACUNit2 : MACUnit
  generic map(
    DataWidth => DataWidth
  )
  port map
  (
    DataIn1     => DataInW2,
    DataIn2     => DataInX,
    DataIn3     => DataInB2,
    Hold        => Hold,
    Clk         => Clk,
    Reset_L     => Reset_L,
    DataOut     => DataOut2,
    ErrorCheck2 => ErrorCheck22
  );

end DatapathModule1;
