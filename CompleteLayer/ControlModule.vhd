library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ControlModule is

  generic (
    DataWidth : integer := 8;
    Rows      : integer := 3;
    Columns   : integer := 4
  );

  port (
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Clk         : in std_logic;
    Reset_L     : in std_logic;

    AddressW    : out integer range 0 to (Columns - 1);
    AddressX    : out integer range 0 to (Columns - 1);
    REW         : out std_logic;
    REB         : out std_logic; -- Only to be set high at the transition of Load to Run.
    REX         : out std_logic;
    WEX         : out std_logic;
    Clear_L     : out std_logic;
    Hold        : out std_logic;
    OutputValid : out std_logic;
    InputReady  : out std_logic
  );
end ControlModule;

architecture ControlModule1 of ControlModule is

  type StateName is (Standby, Load, Run, Done);
  signal CurrentState  : StateName;
  signal ColumnCounter : integer range 0 to (Columns - 1);
  signal OutputValid1  : std_logic;
  signal InputReady1   : std_logic;

begin
  -------------------------------------------------------------------------------------
  -------------------------Combinational Logic-----------------------------------------
  OutputValid <= OutputValid1;
  InputReady  <= InputReady1;

  AddressW <= ColumnCounter when (ColumnCounter < Columns) else
    0;
  AddressX <= ColumnCounter when (ColumnCounter < Columns) else
    0;

  WEX <= '1' when (InputValid = '1' and InputReady1 = '1' and CurrentState = Load) else
    '0'; -- Only goes high during Load state and ONLY when there is valid input.
  REW <= '1' when (CurrentState = Run) else
    '0'; -- Stays high for the entirety of Run state
  REX <= '1' when (CurrentState = Run) else
    '0'; -- Stays high for the entirety of Run state
  REB <= '1'; -- Can stay high for the entirety of the process. Only gets used when Clear is asserted.

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  process (Clk)
  begin

    ----------------------------Asynchronous Reset--------------------------------------
    if (Reset_L = '0') then
      Clear_L       <= '0';
      Hold          <= '0';
      OutputValid1  <= '0';
      InputReady1   <= '0';
      ColumnCounter <= 0;

      CurrentState <= Standby;

    elsif ((Clk'event) and (Clk = '1')) then

      case CurrentState is

          ------------------------Standby State----------------------------------
        when Standby =>

          Clear_L       <= '0';
          Hold          <= '0';
          OutputValid1  <= '0';
          ColumnCounter <= 0;

          if (InputValid = '0') then
            InputReady1 <= '0';

            CurrentState <= Standby;
          else
            InputReady1 <= '1';

            CurrentState <= Load;
          end if;
          -----------------------------------------------------------------------

          -------------------------Load State------------------------------------
        when Load =>

          Clear_L      <= '0';
          Hold         <= '0';
          OutputValid1 <= '0';

          if (InputValid = '0') then -- Wait for valid input
            ColumnCounter <= ColumnCounter;

          elsif (ColumnCounter < (Columns - 1)) then -- This is necessary because MemoryX can not write and read at the same time.
            ColumnCounter <= ColumnCounter + 1;

          else -- When done, break out and go to Run state
            ColumnCounter <= 0;
            InputReady1   <= '0';

            CurrentState <= Run;
          end if;
          -----------------------------------------------------------------------

          --------------------------Run State------------------------------------
        when Run =>

          Clear_L     <= '1';
          InputReady1 <= '0';

          if (ColumnCounter < Columns) then -- Regular operation. The MAC Unit is calculating.
            Hold          <= '0';
            ColumnCounter <= ColumnCounter + 1;
            OutputValid1  <= '0';

          elsif (ColumnCounter = Columns) then -- Needs one more cycle because of pipelining.
            Hold          <= '0';
            ColumnCounter <= ColumnCounter + 1;
            OutputValid1  <= '0';

          else -- The calculation is complete. System moving to Done state. One more cycle is necessary for the data to be available.
            ColumnCounter <= 0;
            OutputValid1  <= '1';
            Hold          <= '1';

            CurrentState <= Done;

          end if;
          -----------------------------------------------------------------------

          -------------------------Done State------------------------------------
        when Done =>

          InputReady1 <= '0';

          if (OutputReady = '0') then -- Wait until the data can be output.
            Hold         <= '1';
            Clear_L      <= '1';
            OutputValid1 <= '1'; -- Maybe this can be raised when changing state to Done to improve throughput? Will check later

          else

            OutputValid1 <= '0';

            Hold         <= '0';
            Clear_L      <= '0';
            CurrentState <= Standby;

          end if;
          -----------------------------------------------------------------------

          -------------------------Others---------------------------------------
        when others =>

          Clear_L       <= '0';
          Hold          <= '0';
          OutputValid1  <= '0';
          InputReady1   <= '0';
          ColumnCounter <= 0;

          CurrentState <= Standby;
          ----------------------------------------------------------------------
      end case;
    end if;

  end process;

end ControlModule1;
