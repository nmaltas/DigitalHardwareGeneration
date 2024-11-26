library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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

  type StateName is (Standby, Load, Run, Flush, Done);
  signal CurrentState : StateName;

  signal StateCounter : integer range 0 to (Size * Size);
  signal RowCounter   : integer range 0 to Size;
  signal OutputValid1 : std_logic;
  signal AddressM1    : integer range 0 to ((Size * Size) - 1);
  signal AddressX1    : integer range 0 to (Size - 1);
  signal InputReady1  : std_logic;

begin
  -------------------------------------------------------------------------------------
  -------------------------Combinational Logic-----------------------------------------
  OutputValid <= OutputValid1;
  InputReady  <= InputReady1;
  AddressM    <= AddressM1;
  AddressX    <= AddressX1;
  -------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------

  process (Clk)
  begin

    if ((Clk'event) and (Clk = '1')) then

      ----------------------------Synchronous Reset--------------------------------------
      if (Reset = '1') then
        WEX          <= '0';
        WEM          <= '0';
        Clear        <= '0';
        Hold         <= '0';
        OutputValid1 <= '0';
        InputReady1  <= '0';
        RowCounter   <= 0;
        AddressX1    <= 0;
        StateCounter <= 0;
        AddressM1    <= 0;

        CurrentState <= Standby;

      else

        case CurrentState is

            ------------------------Standby State----------------------------------
          when Standby =>

            WEX          <= '0';
            Clear        <= '0';
            Hold         <= '0';
            OutputValid1 <= '0';
            InputReady1  <= '1';
            RowCounter   <= 0;
            AddressX1    <= 0;
            AddressM1    <= 0;

            if (InputValid = '0') then
              WEM          <= '0';
              StateCounter <= 0;

              CurrentState <= Standby;

            else
              WEM          <= '1';
              StateCounter <= StateCounter + 1;

              CurrentState <= Load;

            end if;
            -----------------------------------------------------------------------
            -------------------------Load State------------------------------------
          when Load =>

            Hold         <= '0';
            Clear        <= '0';
            OutputValid1 <= '0';

            if (InputValid = '0') then -- Wait for valid input
              InputReady1  <= InputReady1;
              WEX          <= '0';
              WEM          <= '0';
              AddressM1    <= AddressM1;
              StateCounter <= StateCounter;
              AddressX1    <= AddressX1;
              RowCounter   <= RowCounter;

              CurrentState <= CurrentState;

            else
              if (StateCounter < (Size * Size)) then -- Load Memory M first
                InputReady1  <= '1';
                WEX          <= '0';
                WEM          <= '1';
                AddressM1    <= StateCounter;
                StateCounter <= StateCounter + 1;
                AddressX1    <= AddressX1;
                RowCounter   <= RowCounter;

                CurrentState <= CurrentState;

              else
                if (RowCounter < (Size - 1)) then -- When done with M, load Memory X
                  InputReady1  <= '1';
                  WEX          <= '1';
                  WEM          <= '0';
                  AddressM1    <= AddressM1;
                  StateCounter <= StateCounter;
                  AddressX1    <= RowCounter;
                  RowCounter   <= RowCounter + 1;

                  CurrentState <= CurrentState;

                elsif (RowCounter = (Size - 1)) then -- Special case so that InputReady goes low when no more data can be obtained.
                  InputReady1  <= '0';
                  WEX          <= '1';
                  WEM          <= '0';
                  AddressM1    <= AddressM1;
                  StateCounter <= StateCounter;
                  AddressX1    <= RowCounter;
                  RowCounter   <= RowCounter + 1;

                  CurrentState <= CurrentState;

                else -- When done, break out and go to Run state
                  InputReady1  <= '0';
                  WEX          <= '0';
                  WEM          <= '0';
                  AddressM1    <= 0;
                  StateCounter <= 1;
                  AddressX1    <= 0;
                  RowCounter   <= 0;

                  CurrentState <= Run;

                end if;
              end if;
            end if;

            -----------------------------------------------------------------------
            --------------------------Run State------------------------------------
          when Run =>

            Clear       <= '0';
            WEX         <= '0';
            WEM         <= '0';
            InputReady1 <= '0';
            AddressX1   <= RowCounter;
            AddressM1   <= (RowCounter * Size) + StateCounter;

            if (StateCounter < Size) then -- Normal operation. The MAC Unit is calculating.
              Hold         <= '0';
              StateCounter <= StateCounter + 1;
              RowCounter   <= RowCounter;
              OutputValid1 <= '0';

              CurrentState <= Run;

            else -- The row calculation is complete. System moving to Done state. One more cycle is necessary for the data to be available.
              Hold         <= '1';
              StateCounter <= StateCounter + 1;
              RowCounter   <= RowCounter + 1;
              OutputValid1 <= '1';

              CurrentState <= Done;

            end if;
            -----------------------------------------------------------------------
            -------------------------Done State------------------------------------
          when Done =>

            WEX         <= '0';
            WEM         <= '0';
            InputReady1 <= '0';
            AddressX1   <= RowCounter;
            RowCounter  <= RowCounter;
            AddressM1   <= RowCounter * Size;

            if (OutputReady = '0') then -- Wait until the data can be output.
              OutputValid1 <= '1';
              Hold         <= '1';
              Clear        <= '0';
              StateCounter <= 0;

              CurrentState <= Done;

            else
              if (RowCounter < Size) then -- When ready, flush the system and start over with the next row.
                OutputValid1 <= '0';
                Hold         <= '0';
                Clear        <= '1';
                StateCounter <= 0;

                CurrentState <= Run;

              else -- When ready, with all rows go back to Standby
                OutputValid1 <= '0';
                Hold         <= '0';
                Clear        <= '1';
                StateCounter <= 0;

                CurrentState <= Standby;

              end if;

            end if;
            -----------------------------------------------------------------------
            -------------------------Others---------------------------------------
          when others =>

            WEX          <= '0';
            Clear        <= '0';
            Hold         <= '0';
            OutputValid1 <= '0';
            InputReady1  <= '0';
            RowCounter   <= 0;
            AddressX1    <= 0;
            WEM          <= '0';
            AddressM1    <= 0;
            StateCounter <= 1;

            CurrentState <= Standby;
            ----------------------------------------------------------------------
        end case;
      end if;
    end if;

  end process;

end ControlModule1;
