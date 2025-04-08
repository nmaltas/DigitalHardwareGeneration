library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TB_MemoryModules is
  generic (
    MemSize   : integer := 4;
    DataWidth : integer := 16);

end TB_MemoryModules;

architecture TB_MemoryModules1 of TB_MemoryModules is

  signal Address  : integer range 0 to (MemSize - 1);
  signal DataIn   : signed ((DataWidth - 1) downto 0);
  signal DataOut0 : signed ((DataWidth - 1) downto 0);
  signal DataOut1 : signed ((DataWidth - 1) downto 0);
  signal DataOut2 : signed ((DataWidth - 1) downto 0);

  signal Enable          : std_logic               := '0';
  signal WE              : std_logic               := '0';
  signal Clk             : std_logic               := '0';
  signal ClockCount      : integer range 0 to 555  := 0;
  signal TotalClockCount : integer range 0 to 1023 := 0;
  signal NewTestCase     : std_logic               := '0';

  component ROMB is
    generic (
      DataWidth : integer := 16;

      Slot0 : integer := 5;
      Slot1 : integer := 14;
      Slot2 : integer := 13);

    port (
      Enable : in std_logic;
      Clk    : in std_logic;

      DataOut0 : out signed ((DataWidth - 1) downto 0);
      DataOut1 : out signed ((DataWidth - 1) downto 0);
      DataOut2 : out signed ((DataWidth - 1) downto 0)
    );

  end component;

  component ROMW is
    generic (
      DataWidth : integer := 16;
      Columns   : integer := 4;

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

      DataOut0 : out signed ((DataWidth - 1) downto 0);
      DataOut1 : out signed ((DataWidth - 1) downto 0);
      DataOut2 : out signed ((DataWidth - 1) downto 0)
    );
  end component;

  component MemoryModule is
    generic (
      DataWidth : integer := 16;
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

begin

  ROM1 : ROMW
  generic map(
    DataWidth => 16,
    Columns   => 4,
    Slot00    => 1,
    Slot01    => 2,
    Slot02    => 3,
    Slot03    => 4,
    Slot10    => 5,
    Slot11    => 6,
    Slot12    => 7,
    Slot13    => 8,
    Slot20    => 9,
    Slot21    => 10,
    Slot22    => 11,
    Slot23    => 12
  )
  port map
  (
    Address  => Address,
    Enable   => Enable,
    Clk      => Clk,
    DataOut0 => DataOut0,
    DataOut1 => DataOut1,
    DataOut2 => DataOut2
  );

  Clk <= not Clk after 5 ns;

  process
  begin
    wait until Clk'event and Clk = '1';
    wait for 1 ns;
    TotalClockCount <= TotalClockCount + 1;

    if (NewTestCase = '1') then
      ClockCount <= 0;
    else
      ClockCount <= ClockCount + 1;
    end if;
  end process;

  process
  begin
    wait until TotalClockCount >= 100;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  -------------------------------------- Simulation Stimuli --------------------------------------
  process
    variable a, b : integer := 0;

  begin
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    Enable <= '0';
    WE     <= '1';

    b := 0;
    a := 0;
    while (a < 20) loop
      Address <= a;
      DataIn  <= to_signed(b, DataIn'length);

      if (b mod 3 = 0) then
        Enable <= not Enable;
      end if;

      wait until (ClockCount = b + 1);

      if (Enable = '1') then
        a := a + 1;
      end if;

      b := b + 1;
    end loop;

    WE <= '0';

    a := 0;
    while (a < 65) loop
      Address <= a;

      if (b mod 3 = 0) then
        Enable <= not Enable;
      end if;

      wait until (ClockCount = b + 1);

      if (Enable = '1') then
        a := a + 1;
      end if;

      b := b + 1;
    end loop;
    wait;
  end process;

end architecture;