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
  AddressW    <= ColumnCounter;
  AddressX    <= ColumnCounter;

  WEX <= '1' when (InputValid = '1' and CurrentState = Load) else
    '0'; -- Only goes high during Load state and ONLY when there is valid input.
  REW <= '1' when (CurrentState = Run) else
    '0'; -- Stays high for the entirety of Run state
  REX <= '1' when (CurrentState = Run) else
    '0'; -- Stays high for the entirety of Run state

  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  process (Clk)
  begin

    ----------------------------Asynchronous Reset--------------------------------------
    if (Reset = '1') then
      Clear         <= '1';
      Hold          <= '0';
      OutputValid1  <= '0';
      InputReady1   <= '0';
      REB           <= '0';
      ColumnCounter <= 0;

      CurrentState <= Standby;

    elsif ((Clk'event) and (Clk = '1')) then

      case CurrentState is

          ------------------------Standby State----------------------------------
        when Standby =>

          Clear         <= '1';
          Hold          <= '0';
          OutputValid1  <= '0';
          InputReady1   <= '1';
          REB           <= '0';
          ColumnCounter <= 0;

          if (InputValid = '0') then
            CurrentState <= Standby;

          else
            CurrentState <= Load;
          end if;
          -----------------------------------------------------------------------

          -------------------------Load State------------------------------------
        when Load =>

          Hold         <= '0';
          Clear        <= '1';
          OutputValid1 <= '0';
          InputReady1  <= '1';

          if (InputValid = '0') then -- Wait for valid input
            REB           <= '0';
            ColumnCounter <= ColumnCounter;

          elsif (ColumnCounter < (Columns - 1)) then -- Increment ColumnCounter
            REB           <= '0';
            ColumnCounter <= ColumnCounter + 1;

          else -- When done, break out and go to Run state
            REB           <= '1';
            ColumnCounter <= 0;

            CurrentState <= Run;
          end if;
          -----------------------------------------------------------------------

          --------------------------Run State------------------------------------
        when Run =>

          Clear        <= '0';
          Hold         <= '0';
          InputReady1  <= '0';
          OutputValid1 <= '0'; -- Maybe this can be raised when changing state to Done to improve throughput? Will check later
          REB          <= '0';

          if (ColumnCounter < Columns) then -- Regular operation. The MAC Unit is calculating.
            Hold          <= '0';
            ColumnCounter <= ColumnCounter + 1;

          else -- The calculation is complete. System moving to Done state. One more cycle is necessary for the data to be available.
            ColumnCounter <= 0;

            CurrentState <= Done;

          end if;
          -----------------------------------------------------------------------

          -------------------------Done State------------------------------------
        when Done =>

          InputReady1 <= '0';
          REB         <= '0';

          if (OutputReady = '0') then -- Wait until the data can be output.
            Hold         <= '1';
            Clear        <= '0';
            OutputValid1 <= '1'; -- Maybe this can be raised when changing state to Done to improve throughput? Will check later

          else

            OutputValid1 <= '0';

            Hold         <= '0';
            Clear        <= '1';
            CurrentState <= Standby;

          end if;
          -----------------------------------------------------------------------

          -------------------------Others---------------------------------------
        when others =>

          Clear         <= '1';
          Hold          <= '0';
          OutputValid1  <= '0';
          InputReady1   <= '0';
          REB           <= '0';
          ColumnCounter <= 0;

          CurrentState <= Standby;
          ----------------------------------------------------------------------
      end case;
    end if;

  end process;

end ControlModule1;
