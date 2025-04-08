library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ControlModule is

  generic (
    Width   : integer := 8;
    Rows    : integer := 3
    Columns : integer := 4;
  );

  port (
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Clk         : in std_logic;
    Reset       : in std_logic;

    AddressW    : out integer range 0 to (Columns - 1);
    AddressX    : out integer range 0 to (Size - 1);
    REW         : out std_logic;
    REB         : out std_logic;
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
  signal CurrentState : StateName;

  signal RowCounter   : integer range 0 to (Rows - 1);
  signal OutputValid1 : std_logic;
  signal InputReady1  : std_logic;

begin
  -------------------------------------------------------------------------------------
  -------------------------Combinational Logic-----------------------------------------
  OutputValid <= OutputValid1;
  InputReady  <= InputReady1;
  AddressM    <= ColumnCounter;
  AddressX    <= RowCounter;

  WEX <= '1' when (InputValid = '1' and CurrentState = Load) else
    '0';

  -- QQQQQQQQQQQQQQQQQQQQQQQQQQQQ
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
      RowCounter    <= 0;
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
          ColumnCounter <= 0;
          RowCounter    <= 0;

          if (InputValid = '0') then
            CurrentState <= Standby;

          else
            CurrentState <= LoadM;

          end if;
          -----------------------------------------------------------------------

          -------------------------LoadM State------------------------------------
        when LoadM =>

          Hold         <= '0';
          Clear        <= '1';
          OutputValid1 <= '0';
          InputReady1  <= '1';

          if (InputValid = '0') then -- Wait for valid input
            ColumnCounter <= ColumnCounter;
            RowCounter    <= RowCounter;

            CurrentState <= CurrentState;

          elsif (ColumnCounter < (Size - 1)) then -- Increment ColumnCounter
            ColumnCounter <= ColumnCounter + 1;
            RowCounter    <= RowCounter;

            CurrentState <= CurrentState;

          elsif (RowCounter < (Size - 1)) then -- Increment RowCounter
            ColumnCounter <= 0;
            RowCounter    <= RowCounter + 1;

            CurrentState <= CurrentState;

          else -- When done, break out and go to LoadB state
            ColumnCounter <= 0;
            RowCounter    <= 0;

            CurrentState <= LoadB;

          end if;
          -----------------------------------------------------------------------

          -------------------------LoadB State------------------------------------
        when LoadB =>

          Clear         <= '1';
          Hold          <= '0';
          OutputValid1  <= '0';
          ColumnCounter <= 0;
          InputReady1   <= '1';

          if (InputValid = '0') then -- Wait for valid input
            RowCounter <= RowCounter;

            CurrentState <= CurrentState;

          elsif (RowCounter < (Size - 1)) then -- Increment RowCounter
            RowCounter <= RowCounter + 1;

            CurrentState <= CurrentState;

          else -- When done, break out and go to LoadX state
            RowCounter <= 0;

            CurrentState <= LoadX;

          end if;
          -----------------------------------------------------------------------

          -------------------------LoadX State------------------------------------
        when LoadX =>

          Clear        <= '1';
          Hold         <= '0';
          OutputValid1 <= '0';
          RowCounter   <= 0;

          if (InputValid = '0') then -- Wait for valid input
            InputReady1   <= '1';
            ColumnCounter <= ColumnCounter;

            CurrentState <= CurrentState;

          elsif (ColumnCounter < (Size - 1)) then -- Increment RowCounter
            InputReady1   <= '1';
            ColumnCounter <= ColumnCounter + 1;

            CurrentState <= CurrentState;

          else
            InputReady1   <= '0';
            ColumnCounter <= 0;

            CurrentState <= Flush;

          end if;
          -----------------------------------------------------------------------

          --------------------------Run State------------------------------------
        when Run =>

          Clear        <= '0';
          Hold         <= '0';
          InputReady1  <= '0';
          OutputValid1 <= '0';
          RowCounter   <= RowCounter;

          if (ColumnCounter < Size) then -- Normal operation. The MAC Unit is calculating.
            Hold          <= '0';
            ColumnCounter <= ColumnCounter + 1;

            CurrentState <= Run;

          else -- The row calculation is complete. System moving to Done state. One more cycle is necessary for the data to be available.
            ColumnCounter <= (Size - 1);

            CurrentState <= Done;

          end if;
          -----------------------------------------------------------------------

          -------------------------Done State------------------------------------
        when Done =>

          InputReady1 <= '0';

          if (OutputReady = '0') then -- Wait until the data can be output.
            Hold          <= '1';
            Clear         <= '0';
            OutputValid1  <= '1';
            RowCounter    <= RowCounter;
            ColumnCounter <= ColumnCounter;

            CurrentState <= Done;

          else
            ColumnCounter <= 0;

            if (OutputValid1 = '1') then
              OutputValid1 <= '0';
            else
              OutputValid1 <= '1';
            end if;

            -- if (RowCounter < Size) then -- When ready, flush the system and start over with the next row.
            Hold       <= '0';
            Clear      <= '1';
            RowCounter <= RowCounter + 1;

            CurrentState <= Flush;

            -- else -- If this is the last Done state, go back to Standby.
            --   Hold       <= '0';
            --   Clear      <= '1';
            --   RowCounter <= 0;

            --   CurrentState <= Standby;

            -- end if;
          end if;
          -----------------------------------------------------------------------

          -------------------------Flush State-----------------------------------
        when Flush =>

          InputReady1   <= '0';
          ColumnCounter <= ColumnCounter;
          OutputValid1  <= '0';
          Hold          <= '0';
          Clear         <= '1';

          if (RowCounter < Size) then
            RowCounter   <= RowCounter;
            CurrentState <= Run;
          else
            RowCounter   <= 0;
            CurrentState <= Standby;
          end if;
          ----------------------------------------------------------------------

          -------------------------Others---------------------------------------
        when others =>

          Clear         <= '0';
          Hold          <= '0';
          OutputValid1  <= '0';
          InputReady1   <= '0';
          RowCounter    <= 0;
          ColumnCounter <= 1;

          CurrentState <= Standby;
          ----------------------------------------------------------------------
      end case;
    end if;

  end process;

end ControlModule1;
