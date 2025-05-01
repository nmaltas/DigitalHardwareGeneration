library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.Tests3x4.all;
use ieee.std_logic_misc.all;

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

  signal Clk        : std_logic               := '0';
  signal ClockCount : integer range 0 to 1023 := 0;

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
    ClockCount <= ClockCount + 1;
  end process;

  process
  begin
    wait until ClockCount >= 500;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
    variable i         : integer                        := 0;
    variable FinalPass : std_logic_vector (13 downto 0) := (others => '1');
    variable Pass      : boolean                        := true;

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

    -- No overflow/underflow.
    variable Input5 : InputTable := (
    (116, -121, 113, -125), -- This is W
    (94, -107, -113, -99),
    (-116, 121, -113, 125),
    (101, 83, -55, 0), -- This is B
    (-55, -14, -5, 32) -- This is X
    );

    -- Output without overflow/underflow.
    variable Output1 : OutputTable := (0, 0, 0);
    -- Output with overflowin position 2.
    variable Output2 : OutputTable := (0, 0, 0);
    -- Output with underflow in position 2.
    variable Output3 : OutputTable := (0, 0, 0);
    -- Output with overflow and underflow in positions 1 and 3 respectively
    variable Output4 : OutputTable := (0, 0, 0);
    -- Output without overflow/underflow.
    variable Output5 : OutputTable := (0, 0, 0);
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

    report "Test 0 starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- -- Test 0 : Resetting the system
    Test0_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Reset_L, InputValid, OutputReady, Pass);
    FinalPass(0) := Bool2Std(Pass);

    report "Test 1a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 1a: Memory Loading. Regular operation.
    Test1a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(1) := Bool2Std(Pass);

    report "Test 1b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 1b : Calculation. Regular operation.
    Test1b_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(2) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(3) := Bool2Std(Pass);

    report "Test 2a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2a : Calculation. Overflow detection test.
    Test2a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(4) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(5) := Bool2Std(Pass);

    report "Test 2b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2b : Calculation. Overflow detection test.
    Test2b_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(6) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(7) := Bool2Std(Pass);

    report "Test 2c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2c : Calculation. Simultaneous Overflow and Underflow detection test.
    Test2c_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(8) := Bool2Std(Pass);

    report "Test 3a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3a : Memory Loading with abrupt InputValid deassertion
    Test3a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input5, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(9) := Bool2Std(Pass);

    report "Test 3c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3c : Abrupt reset assertion during Run state.
    Test3c_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(10) := Bool2Std(Pass);

    report "Test 3b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3b : Memory Loading with abrupt reset assertion
    Test3b_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input5, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(11) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(12) := Bool2Std(Pass);

    report "Test 3d starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3d : Reset assertion during Done state
    Test3d_3x4(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(13) := Bool2Std(Pass);

    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    if (and_reduce(FinalPass) = '1') then
      report "PASS" severity error;
    else
      report "FAIL" severity error;
    end if;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;

    wait;
  end process;

end TB_TopModule1_3x4;