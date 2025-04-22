library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.Tests3x4.all;

entity TB_TopModule_3x4 is
  generic (
    DataWidth : integer := 8;
    Rows      : integer := 3;
    Columns   : integer := 4
  );

end TB_TopModule_3x4;

architecture TB_TopModule1_3x4 of TB_TopModule_3x4 is

  component TopModule is
    generic (
      DataWidth : integer := 8;
      Rows      : integer := 3;
      Columns   : integer := 4
    );

    port (
      DataIn      : in signed ((DataWidth - 1) downto 0);
      InputValid  : in std_logic;
      OutputReady : in std_logic;
      Reset_L     : in std_logic;
      Clk         : in std_logic;

      OutputValid : out std_logic;
      InputReady  : out std_logic;

      DataOut0 : out signed(((DataWidth * 2) - 1) downto 0);
      DataOut1 : out signed(((DataWidth * 2) - 1) downto 0);
      DataOut2 : out signed(((DataWidth * 2) - 1) downto 0);

      ErrorCheck : out std_logic_vector (5 downto 0)
    );
  end component;

  signal Clk             : std_logic               := '0';
  signal ClockCount      : integer range 0 to 555  := 0;
  signal TotalClockCount : integer range 0 to 1023 := 0;
  signal NewTestCase     : std_logic               := '0';

  signal InputValid  : std_logic := '0';
  signal OutputReady : std_logic := '0';
  signal Reset_L     : std_logic := '0';

  signal DataIn : signed ((DataWidth - 1) downto 0) := (others => '0');

  signal DataOut0    : signed(((DataWidth * 2) - 1) downto 0) := (others => '0');
  signal DataOut1    : signed(((DataWidth * 2) - 1) downto 0) := (others => '0');
  signal DataOut2    : signed(((DataWidth * 2) - 1) downto 0) := (others => '0');
  signal OutputValid : std_logic                              := '0';
  signal InputReady  : std_logic                              := '0';
  signal ErrorCheck  : std_logic_vector (5 downto 0)          := (others => '0');

begin

  DUT1 : TopModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    DataIn      => DataIn,
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Reset_L     => Reset_L,
    Clk         => Clk,
    DataOut0    => DataOut0,
    DataOut1    => DataOut1,
    DataOut2    => DataOut2,
    OutputValid => OutputValid,
    InputReady  => InputReady,
    ErrorCheck  => ErrorCheck
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
    (116, -121, 113, -125), -- This is W
    (94, -107, -113, -99),
    (-116, 121, -113, 125),
    (101, 83, -55, 0), -- This is B
    (-70, -17, -75, 3) -- This is X
    );

    -- Going to trigger an overflow in row 2.
    variable Input2 : InputTable := (
    (116, -121, 113, -125), -- This is W
    (94, -107, -113, -99),
    (-116, 121, -113, 125),
    (101, 83, -55, 0), -- This is B
    (105, -122, -93, -86) -- This is X
    );

    -- Going to trigger an underflow in row 2.
    variable Input3 : InputTable := (
    (116, -121, 113, -125), -- This is W
    (94, -107, -113, -99),
    (-116, 121, -113, 125),
    (101, 83, -55, 0), -- This is B
    (-105, 122, 93, 86) -- This is X
    );

    -- Going to trigger both an overflow and an underflow for rows 1 and 3 respectively.
    variable Input4 : InputTable := (
    (116, -121, 113, -125), -- This is W
    (94, -107, -113, -99),
    (-116, 121, -113, 125),
    (101, 83, -55, 0), -- This is B
    (76, -99, 85, -91) -- This is X
    );

    -- Output without overflow/underflow.
    variable Output1 : OutputTable := (0, 0, 0);
    -- Output with overflowin position 2.
    variable Output2 : OutputTable := (0, 0, 0);
    -- Output with underflow in position 2.
    variable Output3 : OutputTable := (0, 0, 0);
    -- Output with overflow and underflow in positions 1 and 3 respectively
    variable Output4 : OutputTable := (0, 0, 0);
  begin

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Calculate the Expected Output @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    Output1 := CalculateOutput_3x4(Input1);
    Output2 := CalculateOutput_3x4(Input2);
    Output3 := CalculateOutput_3x4(Input3);
    Output4 := CalculateOutput_3x4(Input4);

    -- i := 0;
    -- while i < Rows loop
    --   assert (false) report "Row " & integer'image(i) & ": " & integer'image(Output1(i)) severity note;

    --   i := i + 1;
    -- end loop;

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    report "Test 0 starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- -- Test 0 : Reset_Lting the system
    Test0_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Reset_L, NewTestCase, InputValid, OutputReady, Pass);

    report "Test 1a starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
    Test1a_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Input1, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 1b starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 1b: Memory Loading. Regular operation.
    Test1b_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Input1, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2aa starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2aa : Calculation. Abrupt OutputReady deassertion and Reset.
    Test2aa_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Output1, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Input1, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2ab starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2ab : Calculation. Regular operation.
    Test2ab_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, DataOut0, DataOut1, DataOut2, Output1, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    -- Test 1b: Memory Loading. Regular operation.
    Test1b_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, Input2, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    report "Test 2ba starting at clock cycle: " & integer'image(TotalClockCount + 1) severity warning;
    -- Test 2ba : Calculation. Overflow detection test.
    Test2ba_3x4(ClockCount, OutputValid, InputReady, ErrorCheck, TotalClockCount, DataOut0, DataOut1, DataOut2, Output2, Reset_L, NewTestCase, InputValid, OutputReady, DataIn, Pass);

    wait;
  end process;

end TB_TopModule1_3x4;