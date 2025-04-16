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

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean
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

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean) is

    variable TempPass : boolean;

  begin

    TempPass := true;

    Reset       <= '1';
    NewTestCase <= '1';
    wait for 10 ns;
    NewTestCase <= '0';

    wait until (ClockCount = 1);
    Reset <= '0';

    if (OutputValid /= '0') then
      report "OutputValid does not reset properly. Test0. Clock : " & integer'image(TotalClockCount) severity error;
      TempPass := false;
    end if;

    if (InputReady /= '0') then
      report "InputReady does not reset properly. Test0. Clock: " & integer'image(TotalClockCount) severity error;
      TempPass := false;
    end if;

    if (ErrorCheck /= "000000") then
      report "ErrorCheck2 does not reset properly. Test0. Clock: " & integer'image(TotalClockCount) severity error;
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

end package body Tests3x4;