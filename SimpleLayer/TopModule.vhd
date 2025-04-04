library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TopModule is

  generic (
    Width : integer := 8;
    Size  : integer := 3
  );

  port (
    DataIn      : in signed ((Width - 1) downto 0);
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Reset       : in std_logic;
    Clk         : in std_logic;

    DataOut     : out signed(((Width * 2) - 1) downto 0);
    OutputValid : out std_logic;
    InputReady  : out std_logic;
    ErrorCheck2 : out std_logic_vector (1 downto 0)
  );
end TopModule;

architecture TopModule1 of TopModule is

  component ControlModule is
    generic (
      Width : integer := 8;
      Size  : integer := 3
    );

    port (
      InputValid  : in std_logic;
      OutputReady : in std_logic;
      Clk         : in std_logic;
      Reset       : in std_logic;

      AddressM    : out integer range 0 to ((Size * Size) - 1);
      AddressX    : out integer range 0 to (Size - 1);
      AddressB    : out integer range 0 to (Size - 1);
      WEM         : out std_logic;
      WEB         : out std_logic;
      WEX         : out std_logic;
      Clear       : out std_logic;
      Hold        : out std_logic;
      OutputValid : out std_logic;
      InputReady  : out std_logic
    );
  end component;

  component DatapathModule is
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
  end component;

  signal AddressM : integer range 0 to ((Size * Size) - 1);
  signal AddressB : integer range 0 to (Size - 1);
  signal AddressX : integer range 0 to (Size - 1);
  signal WEM      : std_logic;
  signal WEB      : std_logic;
  signal WEX      : std_logic;
  signal Hold     : std_logic;
  signal Clear    : std_logic;

begin

  ControlModule_1 : ControlModule
  generic map(
    Width => Width,
    Size  => Size
  )
  port map
  (
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Clk         => Clk,
    Reset       => Reset,
    AddressM    => AddressM,
    AddressB    => AddressB,
    AddressX    => AddressX,
    WEM         => WEM,
    WEB         => WEB,
    WEX         => WEX,
    Clear       => Clear,
    Hold        => Hold,
    OutputValid => OutputValid,
    InputReady  => InputReady
  );

  DatapathModule_1 : DatapathModule
  generic map(
    Width => Width,
    Size  => Size
  )
  port map
  (
    DataIn      => DataIn,
    AddressM    => AddressM,
    AddressB    => AddressB,
    AddressX    => AddressX,
    WEM         => WEM,
    WEB         => WEB,
    WEX         => WEX,
    Hold        => Hold,
    Reset       => Clear,
    Clk         => Clk,
    DataOut     => DataOut,
    ErrorCheck2 => ErrorCheck2
  );
end TopModule1;