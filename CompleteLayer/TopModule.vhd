library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TopModule is

  generic (
    DataWidth : integer := 8;
    Rows      : integer := 3;
    Columns   : integer := 4
  );

  port (
    DataIn      : in signed ((DataWidth - 1) downto 0);
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Reset       : in std_logic;
    Clk         : in std_logic;

    OutputValid : out std_logic;
    InputReady  : out std_logic;

    DataOut0 : out signed ((DataWidth - 1) downto 0);
    DataOut1 : out signed ((DataWidth - 1) downto 0);
    DataOut2 : out signed ((DataWidth - 1) downto 0);

    ErrorCheck : out std_logic_vector (5 downto 0)
  );
end TopModule;

architecture TopModule1 of TopModule is

  component ControlModule is
    generic (
      DataWidth : integer := 16;
      Rows      : integer := 3;
      Columns   : integer := 4
    );

    port (
      InputValid  : in std_logic;
      OutputReady : in std_logic;
      Clk         : in std_logic;
      Reset       : in std_logic;

      AddressW    : out integer range 0 to (Columns - 1);
      AddressX    : out integer range 0 to (Columns - 1);
      REW         : out std_logic;
      REB         : out std_logic;
      REX         : out std_logic;
      WEX         : out std_logic;
      Clear       : out std_logic;
      Hold        : out std_logic;
      OutputValid : out std_logic;
      InputReady  : out std_logic
    );
  end component;

  component DatapathModule is
    generic (
      DataWidth : integer := 16;
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
      Reset    : in std_logic;
      Clk      : in std_logic;

      DataOut0 : out signed((DataWidth - 1) downto 0);
      DataOut1 : out signed((DataWidth - 1) downto 0);
      DataOut2 : out signed((DataWidth - 1) downto 0);

      ErrorCheck20 : out std_logic_vector (1 downto 0);
      ErrorCheck21 : out std_logic_vector (1 downto 0);
      ErrorCheck22 : out std_logic_vector (1 downto 0)
    );
  end component;

  signal AddressW : integer range 0 to (Columns - 1);
  signal AddressX : integer range 0 to (Columns - 1);
  signal REW      : std_logic;
  signal REB      : std_logic;
  signal REX      : std_logic;
  signal WEX      : std_logic;

  signal Hold  : std_logic;
  signal Clear : std_logic;

begin

  ControlModule1 : ControlModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Clk         => Clk,
    Reset       => Reset,
    AddressW    => AddressW,
    AddressX    => AddressX,
    REW         => REW,
    REB         => REB,
    REX         => REX,
    WEX         => WEX,
    Clear       => Clear,
    Hold        => Hold,
    OutputValid => OutputValid,
    InputReady  => InputReady
  );

  DatapathModule_1 : DatapathModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    DataIn       => DataIn,
    AddressW     => AddressW,
    AddressX     => AddressX,
    REW          => REW,
    REB          => REB,
    REX          => REX,
    WEX          => WEX,
    Hold         => Hold,
    Reset        => Clear,
    Clk          => Clk,
    DataOut0     => DataOut0,
    DataOut1     => DataOut1,
    DataOut2     => DataOut2,
    ErrorCheck20 => ErrorCheck(1 downto 0),
    ErrorCheck21 => ErrorCheck(3 downto 2),
    ErrorCheck22 => ErrorCheck(5 downto 4)
  );
end TopModule1;