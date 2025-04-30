library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Tests3x4 is

  constant DataWidth : integer := 8;
  constant Rows      : integer := 3;
  constant Columns   : integer := 4;

  type InputTable is array (0 to (Rows + 1), 0 to (Columns - 1)) of integer range -128 to 127;
  type OutputTable is array (0 to (Rows - 1)) of integer range -60000 to 60000;

  -- Calculate the expected output
  function CalculateOutput_3x4(Input : InputTable) return OutputTable;

  -- Test 0 : Resetting the system
  procedure Test0_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean
  );

  -- Test 1a : Memory Loading. Regular operation.
  procedure Test1a_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    variable Input1        : in InputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2a : Calculation. Overflow detection test.
  procedure Test2a_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2b : Calculation. Underflow detection test.
  procedure Test2b_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 1b: Calculation. Regular operation.
  procedure Test1b_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  procedure Test1a_3x4zzzz(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2aa : Calculation. Abrupt OutputReady deassertion.
  procedure Test2aa_3x4(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

end package Tests3x4;
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
package body Tests3x4 is

  -- Function to calculate the expected output when given the predetermined input.
  function CalculateOutput_3x4(Input : InputTable) return OutputTable is

    variable TempOutput : OutputTable                   := (0, 0, 0);
    variable i, j       : integer range 0 to 31         := 0;
    variable Sum        : integer range -60000 to 60000 := 0;
  begin

    -- Cycle through output matrix rows.
    i := 0;

    while i <= (Rows - 1) loop
      Sum := Input(Rows, i);
      j   := 0;
      while (j <= (Columns - 1)) loop

        Sum := Sum + (Input(i, j) * Input((Rows + 1), j));

        j := j + 1;
      end loop;

      TempOutput(i) := Sum;

      i := i + 1;
    end loop;

    return TempOutput;
  end function CalculateOutput_3x4;

  --------------------------------------------------------------------
  -- Test 0 : Resetting the system
  --------------------------------------------------------------------
  procedure Test0_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean) is

    variable TempPass : boolean;
    variable i        : integer;

  begin

    TempPass := true;

    Reset_L     <= '0';
    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';

    i := 0;
    while i < Columns loop

      wait until Clk'event and Clk = '1';

      Reset_L <= '1';

      if (OutputValid /= '0') then
        report "OutputValid does not reset properly. Test0. Clock : " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      if (InputReady /= '0') then
        report "InputReady does not reset properly. Test0. Clock: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      if (ErrorCheck /= "000000") then
        report "ErrorCheck does not reset properly. Test0. Clock: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 0 : PASS" severity warning;
    else
      report "Test 0 : FAIL" severity error;
    end if;

  end procedure Test0_3x4;
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- Test 1 : Testing regular operation.
  --------------------------------------------------------------------
  -- Test 1a : Memory Loading. Regular operation.
  --------------------------------------------------------------------
  procedure Test1a_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    variable Input1        : in InputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean                           := false;
    variable i, k, InputValue                : integer                           := 0;
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');
  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';

    -- Loading Memory
    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;
    DataIn      <= to_signed(0, DataIn'length);

    k := 1;
    wait until Clk'event and Clk = '1';

    -- Cycle through the X elements.
    i := 0;
    while i < Columns loop

      -- Pass the variable values to drive the signals.
      TempDataIn := to_signed(Input1((Input1'length(1) - 1), i), DataIn'length);
      DataIn <= TempDataIn;

      wait until Clk'event and Clk = '1';

      -- Output must remain low throughout the loading stage.
      if (OutputValid /= '0') then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;
      -- InputReady must remain high throughout the loading stage.

      if (InputReady /= '1') and (i < (Columns - 2)) then
        report "InputReady went low prematurely. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- ErrorCheck must not be affected in any way while loading.
      if (ErrorCheck /= "000000") then
        report "ErrorCheck got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      if (TempInputValid = '1') then
        i := i + 1;
      end if;

      k := k + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1a : PASS" severity warning;
    else
      report "Test 1a : FAIL" severity error;
    end if;

  end procedure Test1a_3x4;
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  -- Test 1b : Calculation. Regular operation.
  --------------------------------------------------------------------
  procedure Test1b_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean                           := true;
    variable i, k, InputValue                : integer                           := 0;
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
  begin

    TempPass := true;

    InputValid  <= '1';
    OutputReady <= '0';
    TempInputValid := '0';

    i := 0;
    while i < (Columns + 2) loop

      -- Deassert InputValid pseudorandomly.
      if (i mod 2 = 0) then
        TempInputValid := not TempInputValid;
      else
        TempInputValid := TempInputValid;
      end if;

      InputValid <= TempInputValid;

      wait until Clk'event and Clk = '1';

      -- InputReady must remain low throughout the loading stage.
      if (InputReady /= '0') then
        report "InputReady does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- OutputValid must remain low throughout the calculation stage.
      if (OutputValid /= '0' and (i < (Columns + 1))) then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- ErrorCheck must remain low in this test.
      if (ErrorCheck /= "000000") then
        report "ErrorCheck got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    -- Wait for 5 clock cycles in Done state before asserting OutputReady.
    k := 0;
    while k < 5 loop

      wait until Clk'event and Clk = '1';

      -- When OutputValid goes high, the correct Data must be output.
      if (DataOut0 /= Output1(0)) then
        report "Incorrect DataOut at position 0: " & integer'image(to_integer(DataOut0)) & ". Expected : " & integer'image(Output1(0))severity error;
        TempPass := false;
      else
        report "Output = " & integer'image(to_integer(DataOut0)) severity note;
      end if;

      if (DataOut1 /= Output1(1)) then
        report "Incorrect DataOut at position 1: " & integer'image(to_integer(DataOut1)) & ". Expected : " & integer'image(Output1(1))severity error;
        TempPass := false;
      else
        report "Output = " & integer'image(to_integer(DataOut1)) severity note;
      end if;

      if (DataOut2 /= Output1(2)) then
        report "Incorrect DataOut at position 2: " & integer'image(to_integer(DataOut2)) & ". Expected : " & integer'image(Output1(2))severity error;
        TempPass := false;
      else
        report "Output = " & integer'image(to_integer(DataOut2)) severity note;
      end if;

      k := k + 1;
    end loop;

    OutputReady <= '1';
    InputValid  <= '0';

    if (DataOut0 /= Output1(0)) then
      report "Incorrect DataOut at position 0: " & integer'image(to_integer(DataOut0)) & ". Expected : " & integer'image(Output1(0))severity error;
      TempPass := false;
    else
      report "Output = " & integer'image(to_integer(DataOut0)) severity note;
    end if;

    if (DataOut1 /= Output1(1)) then
      report "Incorrect DataOut at position 1: " & integer'image(to_integer(DataOut1)) & ". Expected : " & integer'image(Output1(1))severity error;
      TempPass := false;
    else
      report "Output = " & integer'image(to_integer(DataOut1)) severity note;
    end if;

    if (DataOut2 /= Output1(2)) then
      report "Incorrect DataOut at position 2: " & integer'image(to_integer(DataOut2)) & ". Expected : " & integer'image(Output1(2))severity error;
      TempPass := false;
    else
      report "Output = " & integer'image(to_integer(DataOut2)) severity note;
    end if;

    wait until Clk'event and Clk = '1';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1b : PASS" severity warning;
    else
      report "Test 1b : FAIL" severity error;
    end if;

  end procedure Test1b_3x4;

  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- Test 2 : Calculation. Overflow and Underflow detection.
  --------------------------------------------------------------------
  -- Test 2a : Calculation. Overflow detection test.
  --------------------------------------------------------------------
  procedure Test2a_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean   := true;
    variable i, k, InputValue                : integer   := 0;
    variable TempOutputReady, TempInputValid : std_logic := '0';
  begin

    TempPass := true;

    InputValid  <= '1';
    OutputReady <= '0';
    TempInputValid := '0';

    i := 0;
    while i < (Columns + 2) loop

      -- Deassert InputValid pseudorandomly.
      if (i mod 2 = 0) then
        TempInputValid := not TempInputValid;
      else
        TempInputValid := TempInputValid;
      end if;

      InputValid <= TempInputValid;

      wait until Clk'event and Clk = '1';

      -- InputReady must remain low throughout the loading stage.
      if (InputReady /= '0') then
        report "InputReady does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- OutputValid must remain low throughout the calculation stage.
      if (OutputValid /= '0' and (i < (Columns + 1))) then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    -- Wait for 5 clock cycles in Done state before asserting OutputReady.
    k := 0;
    while k < 5 loop

      wait until Clk'event and Clk = '1';

      if (ErrorCheck = "001000") then
        report "ErrorCheck got raised correctly because of an overflow. TotalClockCount: " & integer'image(TotalClockCount) severity note;
      else
        report "ErrorCheck did not get raised properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      k := k + 1;
    end loop;

    OutputReady <= '1';
    InputValid  <= '0';

    wait until Clk'event and Clk = '1';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 2a : PASS" severity warning;
    else
      report "Test 2a : FAIL" severity error;
    end if;

    InputValid <= '0';

  end procedure Test2a_3x4;

  --------------------------------------------------------------------
  -- Test 2b : Calculation. Underflow detection test.
  --------------------------------------------------------------------
  procedure Test2b_3x4(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    signal Clk             : in std_logic;
    signal DataOut0        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut1        : in signed (((DataWidth * 2) - 1) downto 0);
    signal DataOut2        : in signed (((DataWidth * 2) - 1) downto 0);
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean   := true;
    variable i, k, InputValue                : integer   := 0;
    variable TempOutputReady, TempInputValid : std_logic := '0';
  begin

    TempPass := true;

    InputValid  <= '1';
    OutputReady <= '0';
    TempInputValid := '0';

    i := 0;
    while i < (Columns + 2) loop

      -- Deassert InputValid pseudorandomly.
      if (i mod 2 = 0) then
        TempInputValid := not TempInputValid;
      else
        TempInputValid := TempInputValid;
      end if;

      InputValid <= TempInputValid;

      wait until Clk'event and Clk = '1';

      -- InputReady must remain low throughout the loading stage.
      if (InputReady /= '0') then
        report "InputReady does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- OutputValid must remain low throughout the calculation stage.
      if (OutputValid /= '0' and (i < (Columns + 1))) then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    -- Wait for 5 clock cycles in Done state before asserting OutputReady.
    k := 0;
    while k < 5 loop

      wait until Clk'event and Clk = '1';

      if (ErrorCheck = "000100") then
        report "ErrorCheck got raised correctly because of an underflow. TotalClockCount: " & integer'image(TotalClockCount) severity note;
      else
        report "ErrorCheck did not get raised properly. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      k := k + 1;
    end loop;

    OutputReady <= '1';
    InputValid  <= '0';

    wait until Clk'event and Clk = '1';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 2b : PASS" severity warning;
    else
      report "Test 2b : FAIL" severity error;
    end if;

    InputValid <= '0';

  end procedure Test2b_3x4;

  --------------------------------------------------------------------
  -- Test 2aa : Calculation. Abrupt OutputReady deassertion.
  --------------------------------------------------------------------
  procedure Test2aa_3x4(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    variable Output1       : in OutputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean   := true;
    variable i, InputValue                   : integer   := 0;
    variable TempOutputReady, TempInputValid : std_logic := '0';
  begin

    InputValid  <= '1';
    OutputReady <= '1';

    i := 0;
    while i < (Columns + 2) loop

      -- Deassert OutputReady pseudorandomly.
      if (i mod 3 = 0) then
        TempOutputReady := '0';
      else
        TempOutputReady := '1';
      end if;
      -- Deassert InputValid pseudorandomly.
      if (i mod 2 = 0) then
        TempInputValid := not TempInputValid;
      else
        TempInputValid := TempInputValid;
      end if;
      InputValid  <= TempInputValid;
      OutputReady <= TempOutputReady;

      wait until (ClockCount = i + Columns + 3);

      -- InputReady must remain low throughout the calculation stage.
      if (InputReady /= '0') then
        report "InputReady does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- OutputValid must remain low throughout the calculation stage.
      if (OutputValid /= '0') then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- ErrorCheck must remain low in this test.
      if (ErrorCheck /= "000000") then
        report "ErrorCheck got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;
      i := i + 1;

      if (i = 3) then
        Reset_L <= '0';
        exit;
      end if;

    end loop;

    wait until (ClockCount = i + Columns + 4);

    Reset_L <= '1';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 2aa : PASS" severity warning;
    else
      report "Test 2aa : FAIL" severity error;
    end if;

  end procedure Test2aa_3x4;

  --------------------------------------------------------------------
  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  --------------------------------------------------------------------
  procedure Test1a_3x4zzzz(
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean                           := true;
    variable i, k, InputValue                : integer                           := 0;
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');

  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';

    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;

    k := 1;
    -- wait until (ClockCount = 1);
    -- Loading Memory

    -- Cycle through the X elements.
    i := 0;
    while i < Columns loop

      -- Deassert InputValid pseudorandomly.
      TempInputValid := not TempInputValid;

      -- Deassert OutputReady pseudorandomly.
      if (k mod 2 = 0) then
        TempOutputReady := not TempOutputReady;
      end if;

      -- Only progress with the test when InputValid is high.
      if (TempInputValid = '1' and InputReady = '1') then
        TempDataIn := to_signed(Input1((Input1'length(1) - 1), i), DataIn'length);
        i          := i + 1;
      end if;

      -- Pass the variable values to drive the signals.
      InputValid  <= TempInputValid;
      OutputReady <= TempOutputReady;
      DataIn      <= TempDataIn;

      -- wait until (ClockCount = k + 1);

      -- Output must remain low throughout the loading stage.
      if (OutputValid /= '0') then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;
      -- InputReady must remain high throughout the loading stage.
      if (InputReady /= '1') then
        report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;
      -- ErrorCheck must not be affected in any way while loading.
      if (ErrorCheck /= "000000") then
        report "ErrorCheck got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      -- Abrupt reset asserted here.
      if (i = 2) then
        Reset_L <= '0';
        exit;
      end if;

      k := k + 1;
    end loop;

    -- wait until (ClockCount = k + 2);
    Reset_L     <= '1';
    InputValid  <= '0';
    OutputReady <= '0';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 2a : PASS" severity warning;
    else
      report "Test 1a : FAIL" severity error;
    end if;

  end procedure Test1a_3x4zzzz;

end package body Tests3x4;