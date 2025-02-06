library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Tests is

  constant Size  : integer := 4;
  constant Width : integer := 8;
  type InputTable is array (0 to (Size + 1), 0 to (Size - 1)) of integer range -128 to 127;
  type OutputTable is array (0 to (Size - 1)) of integer range -128 to 127;

  -- Calculate the expected output
  function CalculateOutput(Input : InputTable) return OutputTable;
  -- Test 0 : Resetting the system
  procedure Test0(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
    signal TotalClockCount : in integer;

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean
  );

  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  procedure Test1a(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((Width - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 1b : Memory Loading. Regular operation.
  procedure Test1b(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((Width - 1) downto 0);
    variable Pass      : out boolean
  );

end package Tests;

package body Tests is

  -- Function to calculate the expected output when given the predetermined input.
  function CalculateOutput(Input : InputTable) return OutputTable is

    variable TempOutput : OutputTable               := (0, 0, 0, 0);
    variable i, j       : integer range 0 to 31     := 0;
    variable Sum        : integer range -128 to 127 := 0;
  begin
    -- Cycle through output matrix rows.
    i := 0;

    while i <= (Size - 1) loop
      Sum := 0;
      j   := 0;
      while (j <= (Size - 1)) loop

        Sum := Sum + (Input(i, j) * Input((Size + 1), j));

        j := j + 1;
      end loop;

      TempOutput(i) := Sum + Input(Size, i);

      i := i + 1;
    end loop;

    return TempOutput;
  end function CalculateOutput;

  --------------------------------------------------------------------
  -- Test 0 : Resetting the system
  --------------------------------------------------------------------
  procedure Test0(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
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
    wait for 10ns;
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

    if (ErrorCheck2 /= "00") then
      report "ErrorCheck2 does not reset properly. Test0. Clock: " & integer'image(TotalClockCount) severity error;
      TempPass := false;
    end if;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 0 : PASS" severity note;
    else
      report "Test 0 : FAIL" severity error;
    end if;

  end procedure Test0;
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- Test 1 : Memory Loading.
  --------------------------------------------------------------------
  -- Test 1a : Memory Loading with abrupt InputValid deassertion and reset
  --------------------------------------------------------------------
  procedure Test1a(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((Width - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean;
    variable i, j, k, InputValue             : integer;
    variable TempOutputReady, TempInputValid : std_logic;
    variable TempDataIn                      : signed ((Width - 1) downto 0);

  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;

    k := 1;

    -- Loading Memory

    -- Cycle through the 2D array rows
    i := 0;
    while i <= 3 loop

      -- Cycle through the 2D array columns.
      j := 0;
      while j <= 3 loop

        -- Deassert InputValid pseudorandomly.
        if (k mod 5 = 0) then
          TempInputValid := '0';
        elsif (k mod 3 = 0) then
          TempInputValid := '1';
        else
          TempInputValid := TempInputValid;
        end if;
        -- Deassert OutputReady pseudorandomly.
        if (k mod 2 = 0) then
          TempOutputReady := not TempOutputReady;
        else
          TempOutputReady := TempOutputReady;
        end if;
        -- Only progress with the test when InputValid is high.
        if (TempInputValid = '1') then
          TempDataIn := to_signed(Input1(i, j), DataIn'length);
          j          := j + 1;
        end if;

        -- Pass the variable values to drive the signals.
        InputValid  <= TempInputValid;
        OutputReady <= TempOutputReady;
        DataIn      <= TempDataIn;

        wait until (ClockCount = k);

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
        if (ErrorCheck2 /= "00") then
          report "ErrorCheck2 got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
          TempPass := false;
        end if;

        k := k + 1;
      end loop;
      i := i + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1a : PASS" severity note;
    else
      report "Test 1a : FAIL" severity error;
    end if;

  end procedure Test1a;
  --------------------------------------------------------------------
  -- Test 1b : Memory Loading. Regular operation.
  --------------------------------------------------------------------
  procedure Test1b(
    signal ClockCount      : in integer;
    signal OutputValid     : in std_logic;
    signal InputReady      : in std_logic;
    signal ErrorCheck2     : in std_logic_vector(1 downto 0);
    signal TotalClockCount : in integer;
    variable Input1        : in InputTable;

    signal Reset       : out std_logic;
    signal NewTestCase : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((Width - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean;
    variable i, j, k, InputValue             : integer;
    variable TempOutputReady, TempInputValid : std_logic;
    variable TempDataIn                      : signed ((Width - 1) downto 0);
  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    NewTestCase <= '1';
    wait for 10ns;
    NewTestCase <= '0';

    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;

    -- Loading Memory

    -- Cycle through the 2D array rows
    i := 0;
    while i <= (Size + 1) loop

      -- Cycle through the 2D array columns.
      j := 0;
      while j <= (Size - 1) loop

        -- Pass the variable values to drive the signals.
        TempDataIn := to_signed(Input1(i, j), DataIn'length);
        DataIn <= TempDataIn;

        wait until (ClockCount = (i * Size) + j + 1);

        -- Output must remain low throughout the loading stage.
        if (OutputValid /= '0') then
          report "OutputValid does not remain low. TotalClockCount: " & integer'image(TotalClockCount) severity error;
          TempPass := false;
        end if;
        -- InputReady must remain high throughout the loading stage.
        if ((InputReady /= '1') and (ClockCount /= (Size * (Size + 2)))) then -- InputReady has to go low on the last loading cycle.
          report "InputReady does not remain high. TotalClockCount: " & integer'image(TotalClockCount) severity error;
          TempPass := false;
        end if;
        -- ErrorCheck must not be affected in any way while loading.
        if (ErrorCheck2 /= "00") then
          report "ErrorCheck2 got raised erratically. TotalClockCount: " & integer'image(TotalClockCount) severity error;
          TempPass := false;
        end if;

        j := j + 1;
      end loop;
      i := i + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1b : PASS" severity note;
    else
      report "Test 1b : FAIL" severity error;
    end if;

  end procedure Test1b;
  --------------------------------------------------------------------

end package body Tests;
