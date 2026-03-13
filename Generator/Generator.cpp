#include <iostream>
#include <cstdint>
#include <vector>
#include <fstream>
#include <format>

#include "Parameters.hpp"

using namespace std;

void PrintTables(const Parameters &Specs);
//
//
void GenerateROMB(const Parameters &Specs);
//
//
void GenerateMemoryX(const Parameters &Specs);
//
//
void GenerateROMW(const Parameters &Specs);
//
//
void GenerateControlModule(const Parameters &Specs);
//
//
void GenerateMACUnit(const Parameters &Specs);
//
//
// MAIN
int main()
{

    Parameters Specs;

    PrintTables(Specs);

    GenerateROMB(Specs);
    GenerateMemoryX(Specs);
    GenerateROMW(Specs);
    GenerateControlModule(Specs);

    cout << "Hey!!" << endl;
    return 0;
}
//
//
void PrintTables(const Parameters &Specs)
{
    // Printing W Matrix
    cout << "W is :" << endl;
    for (int i = 0; i < Specs.M; i++)
    {
        cout << "| ";
        for (int j = 0; j < Specs.N; j++)
        {
            cout << Specs.WMatrix.at(i).at(j);
            if (j == (Specs.N - 1))
            {
                cout << "\t|" << endl;
            }
            else
            {
                cout << ", ";
            }
        }
    }

    // Printing X Matrix
    cout << "X is :" << endl;
    cout << "| ";
    for (int i = 0; i < Specs.N; i++)
    {
        cout << Specs.XMatrix.at(i);

        if (i == (Specs.N - 1))
        {
            cout << " |" << endl;
        }
        else
        {
            cout << ", ";
        }
    }

    // Printing B Matrix
    cout << "B is :" << endl;
    cout << "| ";
    for (int i = 0; i < Specs.M; i++)
    {
        cout << Specs.BMatrix.at(i);

        if (i == (Specs.M - 1))
        {
            cout << " |" << endl;
        }
        else
        {
            cout << ", ";
        }
    }

    return;
}
//
//
// Generate ROMB VHDL file
void GenerateROMB(const Parameters &Specs)
{
    ofstream Output;
    Output.open("ROMB.vhd");
    string Temp;

    Output << Specs.Libraries;
    Output << format(R"VHDL(
entity ROMB is

  generic (
    DataWidth : integer := {};

    -- Memory slots have to be hardcodded. HLS will deal with this.
)VHDL",
                     Specs.T);

    // Dynamic value generics.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("    Slot{0} : integer := {0}", i);

        if (i == Specs.M - 1)
        {
            Output << ");" << endl;
        }
        else
        {
            Output << ";" << endl;
        }
    }

    Output << R"VHDL(
  port (
    Enable : in std_logic;
    Clk    : in std_logic;

    -- Each Row/value needs a separate output port.
    -- Number of output ports has to be hardcoded. HLS will have to deal with this.
)VHDL";

    // Dynamic Ports.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("    DataOut{} : out signed ((DataWidth - 1) downto 0)", i);

        if (i == Specs.M - 1)
        {
            Output << "\n  );" << endl;
        }
        else
        {
            Output << ";" << endl;
        }
    }

    Output << R"VHDL(end ROMB;

architecture ROMB1 of ROMB is

  -- Hardcoded by HLS.
)VHDL";

    // Dynamic memory slot signal #.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("  signal MemSlot{} : signed ((DataWidth - 1) downto 0);", i) << endl;
    }

    Output << R"VHDL(
begin

  -- Values are assigned to the signals here.
  -- Hardcoded by HLS.
)VHDL";

    // Dynamic values to memory slot assignment.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("  MemSlot{0} <= to_signed(Slot{0}, MemSlot{0}'length);", i) << endl;
    }

    Output << R"VHDL(
  process (Clk) is
  begin
    if ((Clk'event) and (Clk = '1')) then

      -- Only output when Enable is asserted.
      if (Enable = '1') then
)VHDL";

    // Dynamic # of slots enabled.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("        DataOut{0} <= MemSlot{0};", i) << endl;
    }

    Output << "      else" << endl;

    // Dynamic # of slots disabled.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("        DataOut{} <= (others => 'Z');", i) << endl;
    }

    Output << R"VHDL(      end if;
    end if;
  end process;

end ROMB1;)VHDL";

    Output.close();
}
//
//
// Generate ROMX VHDL file
void GenerateMemoryX(const Parameters &Specs)
{
    ofstream Output;
    Output.open("MemoryModule.vhd");

    Output << Specs.Libraries;

    Output << format(R"VHDL(library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity MemoryModule is

  generic (
    DataWidth : integer := 8;
    MemSize   : integer := {});

  port (
    DataIn  : in signed ((DataWidth - 1) downto 0);
    Address : in integer range 0 to (MemSize - 1);
    WE      : in std_logic;
    RE      : in std_logic;
    Clk     : in std_logic;

    DataOut : out signed (DataWidth - 1 downto 0)
  );
end MemoryModule;

architecture MemoryModule1 of MemoryModule is
  type MemoryArray is array ((MemSize - 1) downto 0) of signed ((DataWidth - 1) downto 0);

  signal Data : MemoryArray;

begin

  process (Clk)
  begin
    if (Clk'event) and (Clk = '1') then

      if (WE = '1') then
        -- Guard against invalid Address values.
        if (Address   <= MemSize) then
          Data(Address) <= DataIn;
          DataOut       <= (others => 'Z');
        else
          DataOut <= (others => '1');
        end if;

      else
        if (RE = '1') then
          -- Guard against invalid Address values.
          if (Address < MemSize) then
            DataOut <= Data(Address);
          else
            DataOut <= (others => '1');
          end if;
        else
          DataOut <= (others => 'Z');
        end if;
      end if;
    end if;
  end process;
end MemoryModule1;
)VHDL",
                     Specs.N);

    Output.close();
}
//
//
// Generate ROMW VHDL file
void GenerateROMW(const Parameters &Specs)
{
    ofstream Output;
    Output.open("ROMW.vhd");

    Output << Specs.Libraries;

    Output << format(R"VHDL(
entity ROMW is

  generic (
    DataWidth : integer := {};
    Columns   : integer := {};

    -- These memory slots need to be hardcoded. HLS will have to deal with this.
)VHDL",
                     Specs.T, Specs.N);

    // Dynamic value generics.
    for (int i = 0; i < Specs.M; i++)
    {
        for (int j = 0; j < Specs.N; j++)
        {
            Output << format("    Slot{0}{1} : integer := {2}", i, j, ((i * 4) + j));

            if ((i * 4) + j == ((Specs.M * Specs.N) - 1))
            {
                Output << ");" << endl;
            }
            else
            {
                Output << ";" << endl;
            }
        }
    }

    Output << R"VHDL(
  port (
    Address : in integer range 0 to (Columns - 1);
    Enable  : in std_logic;
    Clk     : in std_logic;

    -- One output port is needed for each Row in order to support full parallelization.
    -- Number of output ports has to be hardcoded. HLS will have to deal with this.
)VHDL";

    // Dynamic ports.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("    DataOut{} : out signed ((DataWidth - 1) downto 0)", i);
        if (i == Specs.M - 1)
        {
            Output << "\n  );" << endl;
        }
        else
        {
            Output << ";" << endl;
        }
    }

    Output << R"VHDL(end ROMW;

architecture ROMW1 of ROMW is
  type MemoryArray is array ((Columns - 1) downto 0) of signed ((DataWidth - 1) downto 0);

  -- Hardcoded by HLS
)VHDL";

    // Dynamic memory slots declaration.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("  signal Row{} : MemoryArray;", i) << endl;
    }

    Output << R"VHDL(
begin

  -- Values are assigned to the arrays here.

  -- Hardcoded by HLS.
)VHDL";

    // Dynamic memory slots value assignment.
    for (int i = 0; i < Specs.M; i++)
    {
        for (int j = 0; j < Specs.N; j++)
        {
            Output << format("  Row{0}({1}) <= to_signed(Slot{0}{1}, DataWidth);", i, j) << endl;
        }

        Output << endl;
    }

    Output << R"VHDL(  process (Clk) is
  begin
    if ((Clk'event) and (Clk = '1')) then

      -- Only output when Enable is asserted.
      if (Enable = '1') then

        -- Guarding against Invalid Address values.
        if (Address < Columns) then
)VHDL";

    // Data out control.
    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("          DataOut{0} <= Row{0}(Address);", i) << endl;
    }

    Output << "        else" << endl;

    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("          DataOut{} <= (others => '1');", i) << endl;
    }

    Output << R"VHDL(        end if;

      else
)VHDL";

    for (int i = 0; i < Specs.M; i++)
    {
        Output << format("        DataOut{} <= (others => 'Z');", i) << endl;
    }

    Output << R"VHDL(      end if;
    end if;
  end process;
end ROMW1;)VHDL";

    Output.close();
}
//
//
void GenerateControlModule(const Parameters &Specs)
{
    ofstream Output;
    Output.open("ControlModule.vhd");

    Output << Specs.Libraries;

    Output << format(R"VHDL(library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ControlModule is

  generic (
    DataWidth : integer := {2};
    Rows      : integer := {0};
    Columns   : integer := {1}
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
)VHDL",
                     Specs.M, Specs.N, Specs.T);

    Output.close();
}
//
//
void GenerateMACUnit(const Parameters &Specs)
{
    ofstream Output;
    Output.open("MACUnit.vhd");

    Output << Specs.Libraries;

    Output << R"VHDL()VHDL";

    Output.close();
}