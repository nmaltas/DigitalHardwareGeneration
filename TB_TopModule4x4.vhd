library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.Tests.all;

entity TB_TopModule is
  generic (
    Width : integer := 8;
    Size  : integer := 4);

end TB_TopModule;

architecture TB_TopModule1 of TB_TopModule is

  component TopModule is
    generic (
      Width : integer := 8;
      Size  : integer := 4
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
    wait until TotalClockCount >= 200;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
    variable i    : integer := 0;
    variable Pass : boolean := true;

    variable Input1 : InputTable := (
    (3, -1, 4, 2), -- This is M
    (5, 2, 3, 1),
    (4, 5, -2, 3),
    (-1, 4, -5, -2),
    (4, -2, -5, -3), -- This is B
    (2, -5, 3, 1) -- This is X
    );

    variable Output1 : OutputTable := (0, 0, 0, 0);
  begin

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Calculate the Expected Output @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    Output1 := CalculateOutput(Input1);
    i       := 0;
    while i <= 3 loop
      assert (false) report "Row " & integer'image(i) & ": " & integer'image(Output1(i)) severity note;

      i := i + 1;
    end loop;

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    report "Test 0 starting at clock: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    report "Test 1a starting at clock: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
    Test1a(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    report "Test 1b starting at clock: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2aa starting at clock: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2aa : Calculation. Abrupt OutputReady deassertion and Reset.
    Test2aa(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);
    -- --------------------------------------------------

    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2ab starting at clock: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2ab : Calculation. Abrupt OutputReady deassertion and Reset.
    Test2ab(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);
    -- --------------------------------------------------

    -- PrufungsSalat(Output1);

    -- ---------- Test 0 : Reset ------------------------
    -- Reset       <= '1';
    -- NewTestCase <= '1';
    -- wait for 10ns;
    -- NewTestCase <= '0';

    -- wait until (ClockCount = 1);
    -- Reset <= '0';

    -- assert (OutputValid = '0') report "OutputValid does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    -- assert (InputReady = '0') report "InputReady does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    -- assert (ErrorCheck2 = "00") report "ErrorCheck2 does not reset properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    -- --------------------------------------------------

    -- ---------- Test 1b : Memory Loading ---------------
    -- -- Abrupt InputValid deassertion and Reset
    -- NewTestCase <= '1';
    -- wait for 10ns;
    -- NewTestCase <= '0';

    -- InputValid  <= '1';
    -- OutputReady <= '1';

    -- -- Loading M
    -- i := 1;

    -- while i <= 16 loop
    --   DataIn  <= to_signed(i, DataIn'length);

    --   wait until (ClockCount = i);

    --   assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

    --   i := i + 1;
    -- end loop;

    -- -- Loading B
    -- i := 1;

    -- while i <= 4 loop
    --   DataIn  <= to_signed(i * 10, DataIn'length);

    --   wait until (ClockCount = 16 + i);

    --   assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

    --   i := i + 1;
    -- end loop;

    -- -- Loading X
    -- i := 1;

    -- while i <= 4 loop
    --   DataIn  <= to_signed(i * 11, DataIn'length);

    --   wait until (ClockCount = 20 + i);

    --   assert (OutputValid = '0') report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (InputReady = '1') report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
    --   assert (ErrorCheck2 = "00") report "ErrorCheck2 got raised mistakenly. TotalClockCount: " & integer'image(TotalClockCount) severity error;

    --   i := i + 1;
    -- end loop;
    -- --------------------------------------------------

    -- ---------- Test 2b : Calculation -----------------
    -- -- Normal Operation
    -- NewTestCase <= '1';
    -- wait for 10ns;
    -- NewTestCase <= '0';

    -- InputValid  <= '1';
    -- OutputReady <= '1';

    -- i := 1;

    -- while i <= 35 loop

    --   wait until (ClockCount = i);

    --   -- Insert checks. NOT FOR DATAOUT YET. Test 2b will do that

    --   if (i mod 5 = 0) then
    --     OutputReady <= '0';
    --   elsif (i mod 3 = 0) then
    --     OutputReady <= '1';
    --   else
    --     OutputReady <= OutputReady;
    --   end if;

    --   if (i mod 2 = 0) then
    --     InputValid <= not InputValid;
    --   else
    --     InputValid <= InputValid;
    --   end if;

    --   i := i + 1;
    -- end loop;
    -- --------------------------------------------------

    wait;
  end process;

end TB_TopModule1;