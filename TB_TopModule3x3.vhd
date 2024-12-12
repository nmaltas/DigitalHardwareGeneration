library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TB_TopModule is
  generic (
    Width : integer := 8;
    Size  : integer := 3);

end TB_TopModule;

architecture TB_TopModule1 of TB_TopModule is

  component TopModule is
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
  end component;

  signal Clk        : std_logic              := '0';
  signal ClockCount : integer range 0 to 555 := 0;

  signal InputValid  : std_logic := '0';
  signal OutputReady : std_logic := '0';
  signal Reset       : std_logic := '0';

  signal DataIn      : signed ((Width - 1) downto 0)       := (others => '0');
  signal DataOut     : signed (((Width * 2) - 1) downto 0) := (others => '0');
  signal OutputValid : std_logic                           := '0';
  signal InputReady  : std_logic                           := '0';
  signal ErrorCheck2 : std_logic_vector (1 downto 0)       := (others => '0');

begin

  DUT1 : TopModule
  generic map(
    Width => Width,
    Size  => Size
  )
  port map
  (
    DataIn      => DataIn,
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Reset       => Reset,
    Clk         => Clk,
    DataOut     => DataOut,
    OutputValid => OutputValid,
    InputReady  => InputReady,
    ErrorCheck2 => ErrorCheck2
  );

  Clk <= not Clk after 5 ns;

  process
  begin
    wait until Clk'event and Clk = '1';
    wait for 1 ns;
    ClockCount <= ClockCount + 1;
  end process;

  process
  begin
    wait until ClockCount >= 100;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
  begin

    Reset <= '1';
    wait until (ClockCount = 1);
    Reset <= '0';

    DataIn      <= to_signed(1, DataIn'length);
    InputValid  <= '1';
    OutputReady <= '1';

    wait until (CLockCount = 2);

    wait until (CLockCount = 3);
    DataIn <= to_signed(2, DataIn'length);

    wait until (CLockCount = 4);
    DataIn <= to_signed(3, DataIn'length);

    wait until (CLockCount = 5);
    DataIn <= to_signed(4, DataIn'length);

    wait until (CLockCount = 6);
    DataIn <= to_signed(5, DataIn'length);

    wait until (CLockCount = 7);
    DataIn <= to_signed(6, DataIn'length);

    wait until (CLockCount = 8);
    DataIn <= to_signed(7, DataIn'length);

    wait until (CLockCount = 9);
    DataIn <= to_signed(8, DataIn'length);

    wait until (CLockCount = 10);
    DataIn <= to_signed(9, DataIn'length);

    wait until (CLockCount = 11);
    DataIn <= to_signed(101, DataIn'length);

    wait until (CLockCount = 12);
    DataIn <= to_signed(102, DataIn'length);

    wait until (CLockCount = 13);
    DataIn <= to_signed(103, DataIn'length);

    wait until (CLockCount = 14);
    DataIn <= to_signed(10, DataIn'length);

    wait until (CLockCount = 15);
    DataIn <= to_signed(11, DataIn'length);

    wait until (CLockCount = 16);
    DataIn <= to_signed(12, DataIn'length);

    wait until (CLockCount = 32);
    DataIn <= to_signed(127, DataIn'length);

    wait until (CLockCount = 72);
    DataIn <= to_signed(-128, DataIn'length);

    wait until (CLockCount = 73);
    DataIn <= to_signed(127, DataIn'length);

    wait;
  end process;
  ------------------------------------------------------------------------------
end TB_TopModule1;