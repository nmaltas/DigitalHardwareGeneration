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
    wait until TotalClockCount >= 500;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
    variable i    : integer := 0;
    variable Pass : boolean := true;

    -- No overflow/underflow.
    variable Input1 : InputTable := (
    (3, -1, 4, 2), -- This is M
    (5, 2, 3, 1),
    (4, 5, -2, 3),
    (-1, 4, -5, -2),
    (4, -2, -5, -3), -- This is B
    (2, -5, 3, 1) -- This is X
    );

    -- Going to cause an overflow.
    variable Input2 : InputTable := (
    (113, 125, 114, 121), -- This is M
    (5, 2, 3, 1),
    (4, 5, -2, 3),
    (111, 113, 86, 98),
    (1, 1, 1, 1), -- This is B
    (59, 122, 93, 86) -- This is X
    );

    -- Going to cause an underflow.
    variable Input3 : InputTable := (
    (5, 10, -4, 23), -- This is M
    (-116, 121, -113, 125),
    (-114, 93, -102, 111),
    (-1, -41, -52, -25),
    (42, -23, 75, -13), -- This is B
    (76, -99, 85, -91) -- This is X
    );

    variable Input4 : InputTable := (
    (3, -1, 5, 2), -- This is M
    (5, 2, 4, 1),
    (13, 5, -1, 3),
    (-1, 14, -5, -2),
    (4, -2, -16, -3), -- This is B
    (2, -55, 3, 1) -- This is X
    );

    -- Output without overflow/underflow.
    variable Output1 : OutputTable := (0, 0, 0, 0);
    -- Output with overflow.
    variable Output2 : OutputTable := (0, 0, 0, 0);
    -- Output with underflow.
    variable Output3 : OutputTable := (0, 0, 0, 0);
    -- 2nd output without overflow/underflow.
    variable Output4 : OutputTable := (0, 0, 0, 0);
  begin

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Calculate the Expected Output @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    Output1 := CalculateOutput(Input1);
    Output2 := CalculateOutput(Input2);
    Output3 := CalculateOutput(Input3);
    Output4 := CalculateOutput(Input4);

    -- i := 0;
    -- while i <= 3 loop
    --   assert (false) report "Row " & integer'image(i) & ": " & integer'image(Output1(i)) severity note;

    --   i := i + 1;
    -- end loop;

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    report "Test 0 starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    report "Test 1a starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
    Test1a(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    report "Test 1b starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2aa starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2aa : Calculation. Abrupt OutputReady deassertion and Reset.
    Test2aa(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input4, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2ab starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2ab : Calculation. Regular operation.
    Test2ab(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output4, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input2, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2ba starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2ba : Calculation. Overflow detection test.
    Test2ba(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output2, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input3, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2bb starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2bb : Calculation. Underflow test.
    Test2bb(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output3, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 3a starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 3a : Abrupt Reset assertion during memory loading phase.
    Test3a(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input3, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 3b starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 3b: Abrupt Reset assertion during Run state.
    Test3b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 3c starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    Test3c(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Input1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 3d starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    Test3d(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, DataOut, Output1, Reset, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 0 : Resetting the system
    Test0(ClockCount, OutputValid, InputReady, ErrorCheck2, TotalClockCount, Reset, NewTestCase, InputValid, OutputReady, Pass);
    -- --------------------------------------------------

    wait;
  end process;

end TB_TopModule1;