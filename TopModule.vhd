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
      WEX         : out std_logic;
      WEM         : out std_logic;
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
      AddressX : in integer range 0 to (Size - 1);
      AddressM : in integer range 0 to ((Size * Size) - 1);
      WEX      : in std_logic;
      WEM      : in std_logic;
      Hold     : in std_logic;
      Reset    : in std_logic;
      Clk      : in std_logic;

      DataOut     : out signed(((Width * 2) - 1) downto 0);
      ErrorCheck2 : out std_logic_vector (1 downto 0)
    );
  end component;

  signal AddressM : integer range 0 to ((Size * Size) - 1);
  signal AddressX : integer range 0 to (Size - 1);
  signal WEX      : std_logic;
  signal WEM      : std_logic;
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
    AddressX    => AddressX,
    WEX         => WEX,
    WEM         => WEM,
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
    AddressX    => AddressX,
    AddressM    => AddressM,
    WEX         => WEX,
    WEM         => WEM,
    Hold        => Hold,
    Reset       => Clear,
    Clk         => Clk,
    DataOut     => DataOut,
    ErrorCheck2 => ErrorCheck2
  );
end TopModule1;