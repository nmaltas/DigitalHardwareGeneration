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
// MAIN
int main()
{

    Parameters Specs;

    PrintTables(Specs);

    GenerateROMB(Specs);
    GenerateMemoryX(Specs);
    GenerateROMW(Specs);

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