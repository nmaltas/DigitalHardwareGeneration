library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TB_TopModule is
  generic (
    Width : integer := 8;
    Size  : integer := 4);

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

  signal Clk             : std_logic               := '0';
  signal ClockCount      : integer range 0 to 555  := 0;
  signal TotalClockCount : integer range 0 to 1023 := 0;
  signal NewTestCase     : std_logic               := '0';

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

  ------------------------------ Simulation Stimuli ----------------------------
  process
    variable i : integer := 0;
  begin

    ---------- Test 0 : Reset ------------------------
    Reset       <= '1';
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    wait until (ClockCount = 1);
    Reset <= '0';

    assert (OutputValid = '0') report "OutputValid does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (InputReady = '0') report "InputReady does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (ErrorCheck2 = "00") report "ErrorCheck2 does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --------------------------------------------------

    ---------- Test 1a : Memory Loading ---------------
    -- Abrupt InputValid deassertion and Reset

    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    InputValid  <= '1';
    OutputReady <= '1';

    i := 1;

    -- Loading M
    while i <= 24 loop
      DataIn  <= to_signed(i, DataIn'length);

      wait until (ClockCount = i);

      assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

      if (i mod 5 = 0) then
        InputValid <= '0';
      elsif (i mod 3 = 0) then
        InputValid <= '1';
      else
        InputValid <= InputValid;
      end if;

      if (i mod 2 = 0) then
        OutputReady <= not OutputReady;
      else
        OutputReady <= OutputReady;
      end if;

      i := i + 1;
    end loop;
    ------------------------------------------------------------------------------

    ---------- Test 0 : Reset ------------------------
    Reset       <= '1';
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    wait until (ClockCount = 1);
    Reset <= '0';

    assert (OutputValid = '0') report "OutputValid does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (InputReady = '0') report "InputReady does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (ErrorCheck2 = "00") report "ErrorCheck2 does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --------------------------------------------------

    ---------- Test 1b : Memory Loading ---------------
    -- Abrupt InputValid deassertion and Reset
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    InputValid  <= '1';
    OutputReady <= '1';

    -- Loading M
    i := 1;

    while i <= 16 loop
      DataIn  <= to_signed(i, DataIn'length);

      wait until (ClockCount = i);

      assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

      i := i + 1;
    end loop;

    -- Loading B
    i := 1;

    while i <= 4 loop
      DataIn  <= to_signed(i * 10, DataIn'length);

      wait until (ClockCount = 16 + i);

      assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

      i := i + 1;
    end loop;

    -- Loading X
    i := 1;

    while i <= 4 loop
      DataIn  <= to_signed(i * 11, DataIn'length);

      wait until (ClockCount = 20 + i);

      assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
      assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

      i := i + 1;
    end loop;
    --------------------------------------------------

    ---------- Test 2a : Calculation -----------------
    -- Abrupt OutputReady deassertion and Reset
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    InputValid  <= '1';
    OutputReady <= '1';

    i := 1;

    while i <= 35 loop

      wait until (ClockCount = i);

      -- Insert checks. NOT FOR DATAOUT YET. Test 2b will do that

      if (i mod 5 = 0) then
        OutputReady <= '0';
      elsif (i mod 3 = 0) then
        OutputReady <= '1';
      else
        OutputReady <= OutputReady;
      end if;

      if (i mod 2 = 0) then
        InputValid <= not InputValid;
      else
        InputValid <= InputValid;
      end if;

      i := i + 1;
    end loop;
    --------------------------------------------------

    ---------- Test 0 : Reset ------------------------
    Reset       <= '1';
    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    wait until (ClockCount = 1);
    Reset <= '0';

    assert (OutputValid = '0') report "OutputValid does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (InputReady = '0') report "InputReady does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    assert (ErrorCheck2 = "00") report "ErrorCheck2 does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --------------------------------------------------
    wait;
  end process;

end TB_TopModule1;