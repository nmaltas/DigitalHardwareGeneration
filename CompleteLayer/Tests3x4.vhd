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
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean
  );

  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  procedure Test1a_3x4(
    signal ClockCount      : in integer;
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

  -- Test 1b : Memory Loading. Regular operation.
  procedure Test1b_3x4(
    signal ClockCount      : in integer;
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
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck      : in std_logic_vector(5 downto 0);
    signal TotalClockCount : in integer;

    signal Reset_L     : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean) is

    variable TempPass : boolean;

  begin

    TempPass := true;

    Reset_L     <= '0';
    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';

    wait until (ClockCount = 1);
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
  -- Test 1 : Memory Loading state.
  --------------------------------------------------------------------
  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  --------------------------------------------------------------------
  procedure Test1a_3x4(
    signal ClockCount      : in integer;
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
    wait until (ClockCount = 1);
    -- Loading Memory

    -- Cycle through the X elements.
    i := 0;
    while i < Columns loop

      -- Deassert InputValid pseudorandomly.
      if (k mod 2 = 0) then
        TempInputValid := '0';
      elsif (k mod 3 = 0) then
        TempInputValid := '1';
      else
        TempInputValid := TempInputValid;
      end if;

      -- Deassert OutputReady pseudorandomly.
      TempOutputReady := not TempOutputReady;

      -- Only progress with the test when InputValid is high.
      if (TempInputValid = '1') then
        TempDataIn := to_signed(Input1((Input1'length(1) - 1), i), DataIn'length);
        i          := i + 1;
      end if;

      -- Pass the variable values to drive the signals.
      InputValid  <= TempInputValid;
      OutputReady <= TempOutputReady;
      DataIn      <= TempDataIn;

      wait until (ClockCount = k + 1);

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
      if (i = 1) then
        Reset_L <= '0';
        exit;
      end if;

      k := k + 1;
    end loop;

    wait until (ClockCount = k + 2);
    Reset_L     <= '1';
    InputValid  <= '0';
    OutputReady <= '0';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1a : PASS" severity warning;
    else
      report "Test 1a : FAIL" severity error;
    end if;

  end procedure Test1a_3x4;
  --------------------------------------------------------------------
  -- Test 1b : Memory Loading. Regular operation.
  --------------------------------------------------------------------
  procedure Test1b_3x4(
    signal ClockCount      : in integer;
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

    variable TempPass                        : boolean                           := false;
    variable i, InputValue                   : integer                           := 0;
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');
  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;

    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';
    -- Loading Memory

    -- Cycle through the X elements.
    i := 0;
    while i < Columns loop

      -- Pass the variable values to drive the signals.
      TempDataIn := to_signed(Input1((Input1'length(1) - 1), i), DataIn'length);
      DataIn <= TempDataIn;

      wait until (ClockCount = i + 1);

      -- Output must remain low throughout the loading stage.
      if (OutputValid /= '0') then
        report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;
      -- InputReady must remain high throughout the loading stage.

      if (InputReady /= '1') then
        if (ClockCount = Columns) then
          -- Everything is ok. Report no error.
        else
          report "InputReady went low prematurely. TotalClockCount: " & integer'image(TotalClockCount) severity error;
          TempPass := false;
        end if;
      end if;

      -- ErrorCheck must not be affected in any way while loading.
      if (ErrorCheck /= "000000") then
        report "ErrorCheck got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1b : PASS" severity warning;
    else
      report "Test 1b : FAIL" severity error;
    end if;

  end procedure Test1b_3x4;
  --------------------------------------------------------------------

  --------------------------------------------------------------------

end package body Tests3x4;