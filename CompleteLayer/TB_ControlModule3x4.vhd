library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_ControlModule is
  generic (
    DataWidth : integer := 16;
    Rows      : integer := 3;
    Columns   : integer := 4
  );

end TB_ControlModule;

architecture TB_ControlModule1 of TB_ControlModule is

  component ControlModule is
    generic (
      DataWidth : integer := 8;
      Rows      : integer := 3;
      Columns   : integer := 4
    );

    port (
      InputValid  : in std_logic;
      OutputReady : in std_logic;
      Clk         : in std_logic;
      Reset       : in std_logic;

      AddressW    : out integer range 0 to (Columns - 1);
      AddressX    : out integer range 0 to (Columns - 1);
      REW         : out std_logic;
      REB         : out std_logic; -- Only to be set high at the transition of Load to Run.
      REX         : out std_logic;
      WEX         : out std_logic;
      Clear       : out std_logic;
      Hold        : out std_logic;
      OutputValid : out std_logic;
      InputReady  : out std_logic
    );
  end component;

  signal Clk        : std_logic              := '0';
  signal ClockCount : integer range 0 to 555 := 0;

  signal InputValid  : std_logic := '0';
  signal OutputReady : std_logic := '0';
  signal Reset       : std_logic := '0';

  signal AddressW    : integer range 0 to (Columns - 1) := 0;
  signal AddressX    : integer range 0 to (Columns - 1) := 0;
  signal REW         : std_logic                        := '0';
  signal REB         : std_logic                        := '0';
  signal REX         : std_logic                        := '0';
  signal WEX         : std_logic                        := '0';
  signal Clear       : std_logic                        := '0';
  signal Hold        : std_logic                        := '0';
  signal OutputValid : std_logic                        := '0';
  signal InputReady  : std_logic                        := '0';

begin

  DUT1 : ControlModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Clk         => Clk,
    Reset       => Reset,
    AddressW    => AddressW,
    AddressX    => AddressX,
    REW         => REW,
    REB         => REB,
    REX         => REX,
    WEX         => WEX,
    Clear       => Clear,
    Hold        => Hold,
    OutputValid => OutputValid,
    InputReady  => InputReady
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
    wait until ClockCount >= 50;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
  begin

    -- Test 0: Reset
    assert FALSE report "Test 0: Reset" severity warning;

    Reset <= '1';
    wait for 1 ns;

    wait until (ClockCount = 1);

    assert (REW = '0') report "REW does not reset properly." severity error;
    assert (REB = '0') report "REB does not reset properly." severity error;
    assert (REX = '0') report "REX does not reset properly." severity error;
    assert (WEX = '0') report "WEX does not reset properly." severity error;
    assert (Clear = '0') report "Clear does not reset properly." severity error;
    assert (Hold = '0') report "Hold does not reset properly." severity error;
    assert (OutputValid = '0') report "OutputValid does not reset properly." severity error;
    assert (InputReady = '0') report "InputReady does not reset properly." severity error;
    assert (AddressW = 0) report "AddressW does not reset properly." severity error;
    assert (AddressX = 0) report "AddressX does not reset properly." severity error;

    Reset <= '0';

    -- Test 1: Load Data to Memory
    assert FALSE report "Test 1: Loading to Memory" severity warning;

    wait until (ClockCount = 5);

    assert (REW = '0') report "REW does not remain low in Standby state." severity error;
    assert (REB = '0') report "REW does not remain low in Standby state." severity error;
    assert (REX = '0') report "WEX does not remain low in Standby state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Standby state." severity error;
    assert (Clear = '0') report "Clear does not remain low in Standby state" severity error;
    assert (Hold = '0') report "Hold does not remain low in Standby state" severity error;
    assert (OutputValid = '0') report "OutputValid does not reset properly." severity error;
    assert (InputReady = '1') report "InputReady does not get raised in Standby state." severity error;
    assert (AddressW = 0) report "AddressW does not start from 0." severity error;
    assert (AddressX = 0) report "AddressX does not start from 0." severity error;

    InputValid <= '1';

    wait until (ClockCount = 7);

    assert (REW = '1') report "REW does not go high during first half of Load state." severity error;
    assert (REB = '1') report "REW does not go high during first half of Load state." severity error;
    assert (REX = '0') report "WEX does not remain low during first half of Load state." severity error;
    assert (WEX = '0') report "WEX does not remain low during first half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low during first half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low during first half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low during first half of Load state." severity error;
    assert (InputReady = '1') report "InputReady does not remain high during first half of Load state." severity error;
    assert (AddressW = 1) report "AddressW does not have the right value. Expected: 1. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not have the right value. Expected: 0. Actual: " & integer'image(AddressX) severity error;

    InputValid <= '0';

    wait until (ClockCount = 8);

    assert (REW = '0') report "REW does not go low when InputValid gets deasserted during Load state." severity error;
    assert (REB = '0') report "REW does not go low when InputValid gets deasserted during Load state." severity error;
    assert (REX = '0') report "WEX does not remain low while waiting in first half of Load state." severity error;
    assert (WEX = '0') report "WEX does not remain low while waiting in first half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low while waiting in first half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low while waiting in first half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low while waiting in first half of Load state." severity error;
    assert (InputReady = '1') report "InputReady does not remain high while waiting in first half of Load state." severity error;
    assert (AddressW = 1) report "AddressW does not retain its value while waiting in first half of Load state. Expected: 1. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not retain its value while waiting in first half of Load state. Expected: 1. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 12);

    InputValid <= '1';

    wait until (ClockCount = 13);

    assert (REW = '1') report "REW does not go high when InputValid gets reasserted during Load state." severity error;
    assert (REB = '1') report "REW does not go high when InputValid gets reasserted during Load state." severity error;
    assert (REX = '0') report "WEX does not remain low while waiting in first half of Load state." severity error;
    assert (WEX = '0') report "WEX does not remain low while waiting in first half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low while waiting in first half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low while waiting in first half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low while waiting in first half of Load state." severity error;
    assert (InputReady = '1') report "InputReady does not remain high while waiting in first half of Load state." severity error;
    assert (AddressW = 2) report "AddressW does not retain its value while waiting in first half of Load state. Expected: 2. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not retain its value while waiting in first half of Load state. Expected: 0. Actual:  " & integer'image(AddressX) severity error;

    wait until (ClockCount = 20);

    assert (REW = '0') report "REW does not go low in second half of Load state." severity error;
    assert (WEX = '1') report "WEX does not go high in second half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low in second half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low in second half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low in second half of Load state." severity error;
    assert (InputReady = '1') report "InputReady does not remain high while in second half of Load state." severity error;
    assert (AddressW = 8) report "AddressW does not have the right value. Expected: 8. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not have the right value. Expected: 0. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 22);

    assert (REW = '0') report "REW does not remain low in second half of Load state." severity error;
    assert (WEX = '1') report "WEX does not remain high in second half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low in second half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low in second half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low in second half of Load state." severity error;
    assert (InputReady = '0') report "InputReady does not go low when no more data can be accepted." severity error;
    assert (AddressW = 8) report "AddressW does not have the right value. Expected: 8. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 2) report "AddressX does not have the right value. Expected: 2. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 23);

    assert (REW = '0') report "REW does not go low in Run state." severity error;
    assert (WEX = '0') report "WEX does not go low in Run state." severity error;
    assert (Clear = '0') report "Clear does not go low in Run state." severity error;
    assert (Hold = '0') report "Hold does not go low in Run state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low during Run state." severity error;
    assert (InputReady = '0') report "InputReady does not go low during Run state." severity error;
    assert (AddressW = 0) report "AddressW does not have the right value. Expected: 0. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not have the right value. Expected: 0. Actual: " & integer'image(AddressX) severity error;

    -- Test 2: Normal operation
    assert FALSE report "Test 2: Normal Operation" severity warning;

    wait until (ClockCount = 27);

    assert (REW = '0') report "REW does not remain low in Done state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Done state." severity error;
    assert (Clear = '0') report "Clear does not remain low in Done state." severity error;
    assert (Hold = '1') report "Hold does not go high in Done state." severity error;
    assert (OutputValid = '1') report "OutputValid does not go high during Done state." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during Done state." severity error;
    assert (AddressW = 3) report "AddressW does not have the right value. Expected: 3. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 1) report "AddressX does not have the right value. Expected: 1. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 29);

    assert (REW = '0') report "REW does not remain low in extended Done state." severity error;
    assert (WEX = '0') report "WEX does not remain low in extended Done state." severity error;
    assert (Clear = '0') report "Clear does not remain low in extended Done state." severity error;
    assert (Hold = '1') report "Hold does not remain high in extended Done state." severity error;
    assert (OutputValid = '1') report "OutputValid does not remain high during extended Done state." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during extended Done state." severity error;
    assert (AddressW = 3) report "AddressW does not retain its value during extended Done state. Expected: 3. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 1) report "AddressX does not retain its value during extended Done state. Expected: 1. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 30);

    OutputReady <= '1';

    wait until (ClockCount = 31);

    assert (REW = '0') report "REW does not remain low in Run state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Run state." severity error;
    assert (Clear = '1') report "Clear does not go high at the beginning of a new Run state." severity error;
    assert (Hold = '0') report "Hold does not go low in Run state." severity error;
    assert (OutputValid = '0') report "OutputValid does not go low at the beginning of new Run state." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during Run state." severity error;
    assert (AddressW = 3) report "AddressW does not have the right value.  Expected: 3. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 1) report "AddressX does not have the right value.  Expected: 1. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 34);

    assert (REW = '0') report "REW does not remain low in Run state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Run state." severity error;
    assert (Clear = '0') report "Clear does not stay low during Run state." severity error;
    assert (Hold = '0') report "Hold does not stay low during Run state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low during Run state." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during Run state." severity error;
    assert (AddressW = 5) report "AddressW does not have the right value. Expected: 5. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 1) report "AddressX does not have the right value. Expected: 1. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 36);

    assert (REW = '0') report "REW does not remain low in Run state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Run state." severity error;
    assert (Clear = '1') report "Clear does not go high at the beginning of new Run state." severity error;
    assert (Hold = '0') report "Hold does not go low at the end of Done state." severity error;
    assert (OutputValid = '0') report "OutputValid does not go low at the beginning of new Run state." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during Run state." severity error;
    assert (AddressW = 6) report "AddressW does not have the right value. Expected: 6. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 2) report "AddressX does not have the right value. Expected: 2. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 41);

    assert (REW = '0') report "REW does not remain low in Run state." severity error;
    assert (WEX = '0') report "WEX does not remain low in Run state." severity error;
    assert (Clear = '1') report "Clear does not go high at the end of the entire cycle." severity error;
    assert (Hold = '0') report "Hold does not go low at the end of Done state." severity error;
    assert (OutputValid = '0') report "OutputValid does not go low when Stanbdy state occurs." severity error;
    assert (InputReady = '0') report "InputReady does not remain low during Run state." severity error;

    wait until (ClockCount = 42);

    assert (REW = '1') report "REW does not go high during first half of Load state." severity error;
    assert (WEX = '0') report "WEX does not remain low during first half of Load state." severity error;
    assert (Clear = '0') report "Clear does not remain low during first half of Load state." severity error;
    assert (Hold = '0') report "Hold does not remain low during first half of Load state." severity error;
    assert (OutputValid = '0') report "OutputValid does not remain low during first half of Load state." severity error;
    assert (InputReady = '1') report "InputReady does not remain high during first half of Load state." severity error;
    assert (AddressW = 0) report "AddressW does not have the right value. Expected: 0. Actual: " & integer'image(AddressW) severity error;
    assert (AddressX = 0) report "AddressX does not have the right value. Expected: 0. Actual: " & integer'image(AddressX) severity error;

    wait until (ClockCount = 46);

    -- Test 0: Reset
    assert FALSE report "Test 0: Reset" severity warning;

    Reset <= '1';

    wait until (ClockCount = 47);

    assert (REW = '0') report "REW does not reset properly." severity error;
    assert (WEX = '0') report "WEX does not reset properly." severity error;
    assert (Clear = '0') report "Clear does not reset properly." severity error;
    assert (Hold = '0') report "Hold does not reset properly." severity error;
    assert (OutputValid = '0') report "OutputValid does not reset properly." severity error;
    assert (InputReady = '0') report "InputReady does not reset properly." severity error;
    assert (AddressW = 0) report "AddressW does not reset properly." severity error;
    assert (AddressX = 0) report "AddressX does not reset properly." severity error;

    Reset <= '0';

    wait;
  end process;
  ------------------------------------------------------------------------------
end TB_ControlModule1;