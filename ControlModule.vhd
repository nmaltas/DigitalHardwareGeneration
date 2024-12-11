library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ControlModule is

  generic (
    Width : integer := 8;
    Size  : integer := 3
  );

  port (
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Clk         : in std_logic;
    Reset       : in std_logic;

    AddressM    : out integer range 0 to ((Size * Size) - 1);
    AddressX    : out integer range 0 to (Size - 1);
    WEX         : out std_logic;
    WEM         : out std_logic;
    Clear       : out std_logic;
    Hold        : out std_logic;
    OutputValid : out std_logic;
    InputReady  : out std_logic
  );
end ControlModule;

architecture ControlModule1 of ControlModule is

  type StateName is (Standby, LoadM, LoadX, Run, Flush, Done);
  signal CurrentState : StateName;

  signal ColumnCounter : integer range 0 to (Size * Size);
  signal RowCounter    : integer range 0 to Size;
  signal OutputValid1  : std_logic;
  signal AddressM1     : integer range 0 to ((Size * Size) - 1);
  signal AddressX1     : integer range 0 to (Size - 1);
  signal InputReady1   : std_logic;

begin
  -------------------------------------------------------------------------------------
  -------------------------Combinational Logic-----------------------------------------
  OutputValid <= OutputValid1;
  InputReady  <= InputReady1;
  AddressM    <= (RowCounter * Size) + ColumnCounter;
  AddressX    <= RowCounter;
  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  process (Clk)
  begin

    ----------------------------Asynchronous Reset--------------------------------------
    if (Reset = '1') then
      WEX           <= '0';
      WEM           <= '0';
      Clear         <= '1';
      Hold          <= '0';
      OutputValid1  <= '0';
      InputReady1   <= '0';
      RowCounter    <= 0;
      ColumnCounter <= 0;

      CurrentState <= Standby;

    else
      if ((Clk'event) and (Clk = '1')) then

        case CurrentState is

            ------------------------Standby State----------------------------------
          when Standby =>

            WEX           <= '0';
            Clear         <= '1';
            Hold          <= '0';
            OutputValid1  <= '0';
            InputReady1   <= '1';
            ColumnCounter <= 0;
            RowCounter    <= 0;

            if (InputValid = '0') then
              WEM <= '0';

              CurrentState <= Standby;

            else
              WEM <= '1';

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
              WEX           <= '0';
              WEM           <= '0';
              ColumnCounter <= ColumnCounter;
              RowCounter    <= RowCounter;

              CurrentState <= CurrentState;

            else
              if (ColumnCounter < (Size - 1)) then -- Increment ColumnCounter
                WEX           <= '0';
                WEM           <= '1';
                ColumnCounter <= ColumnCounter + 1;
                RowCounter    <= RowCounter;

                CurrentState <= CurrentState;

              else
                if (RowCounter < (Size - 1)) then -- Increment RowCounter
                  WEX           <= '0';
                  WEM           <= '1';
                  ColumnCounter <= 0;
                  RowCounter    <= RowCounter + 1;

                  CurrentState <= CurrentState;

                else -- When done, break out and go to LoadX state
                  WEX           <= '1';
                  WEM           <= '0';
                  ColumnCounter <= 0;
                  RowCounter    <= 0;

                  CurrentState <= LoadX;

                end if;
              end if;
            end if;
            -----------------------------------------------------------------------

            -------------------------LoadX State------------------------------------
          when LoadX =>

            Clear         <= '1';
            Hold          <= '0';
            OutputValid1  <= '0';
            ColumnCounter <= 0;
            WEM           <= '0';

            if (InputValid = '0') then -- Wait for valid input
              InputReady1 <= '1';
              WEX         <= '0';
              RowCounter  <= RowCounter;

              CurrentState <= CurrentState;

            else
              if (RowCounter < (Size - 1)) then -- Increment RowCounter
                InputReady1 <= '1';
                WEX         <= '1';
                RowCounter  <= RowCounter + 1;

                CurrentState <= CurrentState;

              else
                InputReady1 <= '0';
                WEX         <= '0';
                RowCounter  <= 0;

                CurrentState <= Flush;

              end if;
            end if;
            -----------------------------------------------------------------------

            --------------------------Run State------------------------------------
          when Run =>

            Clear        <= '0';
            Hold         <= '0';
            WEX          <= '0';
            WEM          <= '0';
            InputReady1  <= '0';
            OutputValid1 <= '0';
            RowCounter   <= RowCounter;

            if (ColumnCounter < Size) then -- Normal operation. The MAC Unit is calculating.
              Hold          <= '0';
              ColumnCounter <= ColumnCounter + 1;

              CurrentState <= Run;

            else -- The row calculation is complete. System moving to Done state. One more cycle is necessary for the data to be available.
              ColumnCounter <= ColumnCounter;

              CurrentState <= Done;

            end if;
            -----------------------------------------------------------------------

            -------------------------Done State------------------------------------
          when Done =>

            WEX         <= '0';
            WEM         <= '0';
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

              if (RowCounter < (Size - 1)) then -- When ready, flush the system and start over with the next row.
                Hold       <= '0';
                Clear      <= '1';
                RowCounter <= RowCounter + 1;

                CurrentState <= Flush;

              else -- If this is the last Done state, go back to Standby.
                Hold       <= '0';
                Clear      <= '1';
                RowCounter <= 0;

                CurrentState <= Standby;

              end if;
            end if;
            -----------------------------------------------------------------------

            -------------------------Flush State-----------------------------------
          when Flush =>

            WEX           <= '0';
            WEM           <= '0';
            InputReady1   <= '0';
            ColumnCounter <= ColumnCounter;
            RowCounter    <= RowCounter;
            OutputValid1  <= '0';
            Hold          <= '0';
            Clear         <= '1';

            CurrentState <= Run;
            ----------------------------------------------------------------------

            -------------------------Others---------------------------------------
          when others =>

            WEX           <= '0';
            Clear         <= '0';
            Hold          <= '0';
            OutputValid1  <= '0';
            InputReady1   <= '0';
            RowCounter    <= 0;
            WEM           <= '0';
            ColumnCounter <= 1;

            CurrentState <= Standby;
            ----------------------------------------------------------------------
        end case;
      end if;
    end if;

  end process;

end ControlModule1;
