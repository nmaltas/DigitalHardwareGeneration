#include <iostream>
#include <cstdint>
#include <vector>
#include <fstream>

#include "Parameters.hpp"

using namespace std;

void PrintTables(const Parameters &Specs);
//
//
void GenerateROMB(const Parameters &Specs);
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

    Output << Specs.Libraries;
    Output << R"VHDL(
entity ROMB is

  generic (
    DataWidth : integer := )VHDL"
           << Specs.T << R"VHDL(;

    -- Memory slots have to be hardcodded. HLS will deal with this.
)VHDL";

    // Dynamic values #
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "    Slot" << i << " : integer := " << i;

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

    // Dynamic Port #
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "    DataOut" << i << " : out signed ((DataWidth - 1) downto 0)";

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

    // Dynamic memory slot signal #
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "  signal MemSlot" << i << " : signed ((DataWidth - 1) downto 0);" << endl;
    }

    Output << R"VHDL(
begin

  -- Values are assigned to the signals here.
  -- Hardcoded by HLS.
)VHDL";

    // Dynamic values to memory slot assignment
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "  MemSlot" << i << " <= to_signed(Slot" << i << ", MemSlot" << i << "'length);" << endl;
    }

    Output << R"VHDL(
  process (Clk) is
  begin
    if ((Clk'event) and (Clk = '1')) then

      -- Only output when Enable is asserted.
      if (Enable = '1') then
)VHDL";

    // Dynamic # of slots enabled
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "        DataOut" << i << " <= MemSlot" << i << ";" << endl;
    }

    Output << "      else" << endl;

    // Dynamic # of slots disabled
    for (int i = 0; i < Specs.M; i++)
    {
        Output << "        DataOut" << i << " <= (others => 'Z');" << endl;
    }

    Output << R"VHDL(      end if;
    end if;
  end process;

end ROMB1;)VHDL";

    Output.close();
}
//
//
// Generate ROMW VHDL file
void GenerateROMW(const Parameters &Specs)
{
    ofstream Output;
    Output.open("ROMB.vhd");

    Output << Specs.Libraries;

    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";
    Output << R"VHDL()VHDL";

    Output.close();
}