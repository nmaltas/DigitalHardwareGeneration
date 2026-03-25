#include <iostream>
#include <cstdint>
#include <vector>
#include <fstream>
#include <format>
#include <cmath>

#include "Parameters.hpp"

using namespace std;

void PrintTables(const Parameters &Specs);
//
//
void GenerateROMB(const Parameters &Specs);
void GenerateMemoryX(const Parameters &Specs);
void GenerateROMW(const Parameters &Specs);
void GenerateControlModule(const Parameters &Specs);
void GenerateMACUnit(const Parameters &Specs);
void GenerateDataPathModule(const Parameters &Specs);
void GenerateTopModule(const Parameters &Specs);
void GenerateTestbench(const Parameters &Specs);
void GenerateTests(const Parameters &Specs);
//
//
// MAIN
int main()
{

  Parameters Specs;

  if (!Specs.Verify())
  {
    cout << "> Failed to generate files." << endl;
    return 0;
  }

  PrintTables(Specs);

  GenerateROMB(Specs);
  GenerateMemoryX(Specs);
  GenerateROMW(Specs);
  GenerateControlModule(Specs);
  GenerateMACUnit(Specs);
  GenerateDataPathModule(Specs);
  GenerateTopModule(Specs);
  GenerateTestbench(Specs);
  GenerateTests(Specs);

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

      cout << ((j == Specs.N - 1) ? ("\t|\n") : (", "));
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

    -- Memory slots have to be hardcoded. HLS will deal with this.
)VHDL",
                   Specs.T);

  // Value generics.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    Slot{0} : integer := {0}", i);
    Output << ((i == Specs.M - 1) ? (");") : (";")) << endl;
  }

  Output << R"VHDL(
  port (
    Enable : in std_logic;
    Clk    : in std_logic;

    -- Each Row/value needs a separate output port.
    -- Number of output ports has to be hardcoded. HLS will have to deal with this.
)VHDL";

  // Ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    DataOut{} : out signed ((DataWidth - 1) downto 0)", i);
    Output << ((i == Specs.M - 1) ? ("\n  );") : (";")) << endl;
  }

  Output << R"VHDL(end ROMB;

architecture ROMB1 of ROMB is

  -- Hardcoded by HLS.
)VHDL";

  // Memory slot signals.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("  signal MemSlot{} : signed ((DataWidth - 1) downto 0);", i) << endl;
  }

  Output << R"VHDL(
begin

  -- Values are assigned to the signals here.
  -- Hardcoded by HLS.
)VHDL";

  // Values to memory signal assignment.
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

  // Read enable.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("        DataOut{0} <= MemSlot{0};", i) << endl;
  }

  Output << "      else" << endl;

  // Read disable.
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

  Output << format(R"VHDL(
entity MemoryModule is

  generic (
    DataWidth : integer := {};
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
                   Specs.T, Specs.N);

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

  // Value generics.
  for (int i = 0; i < Specs.M; i++)
  {
    for (int j = 0; j < Specs.N; j++)
    {
      Output << format("    Slot{0}{1} : integer := {2}", i, j, ((i * Specs.N) + j));
      Output << (((i * Specs.N) + j == ((Specs.M * Specs.N) - 1)) ? (");") : (";")) << endl;
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

  // Ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    DataOut{} : out signed ((DataWidth - 1) downto 0)", i);
    Output << ((i == Specs.M - 1) ? ("\n  );") : (";")) << endl;
  }

  Output << R"VHDL(end ROMW;

architecture ROMW1 of ROMW is
  type MemoryArray is array ((Columns - 1) downto 0) of signed ((DataWidth - 1) downto 0);

  -- Hardcoded by HLS
)VHDL";

  // Memory slot signals.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("  signal Row{} : MemoryArray;", i) << endl;
  }

  Output << R"VHDL(
begin

  -- Values are assigned to the arrays here.

  -- Hardcoded by HLS.
)VHDL";

  // Values to memory signal assignment.
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

  // Read enable.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("          DataOut{0} <= Row{0}(Address);", i) << endl;
  }

  Output << "        else" << endl;

  // Read disable.
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

  Output << R"VHDL(
entity MACUnit is

  generic (
    DataWidth : integer := 8
  );

  port (
    DataIn1 : in signed(DataWidth - 1 downto 0);
    DataIn2 : in signed(DataWidth - 1 downto 0);
    DataIn3 : in signed(DataWidth - 1 downto 0);
    Hold    : in std_logic;
    Clk     : in std_logic;
    Reset_L : in std_logic;

    DataOut     : out signed(((DataWidth * 2) - 1) downto 0);
    ErrorCheck2 : out std_logic_vector (1 downto 0)
  );
end MACUnit;

architecture MACUnit1 of MACUnit is

  signal Product1    : signed(((DataWidth * 2) - 1) downto 0);
  signal Product2    : signed(((DataWidth * 2) - 1) downto 0);
  signal Sum         : signed(((DataWidth * 2) - 1) downto 0);
  signal SumFeedback : signed(((DataWidth * 2) - 1) downto 0);
  signal MSB1        : std_logic;
  signal MSB2        : std_logic;
  signal MSB3        : std_logic;
  signal Overflow    : std_logic;
  signal Underflow   : std_logic;
  signal ErrorCheck1 : std_logic_vector (1 downto 0);

begin

  Product1 <= DataIn1 * DataIn2;

  Sum <= SumFeedback + Product2;

  MSB1 <= Product2(Product2'high);
  MSB2 <= SumFeedback(SumFeedback'high);
  MSB3 <= Sum(Sum'high);

  Overflow <= '1' when ((MSB1 = '0') and (MSB2 = '0') and (MSB3 = '1')) else
    '0';

  Underflow <= '1' when ((MSB1 = '1') and (MSB2 = '1') and (MSB3 = '0')) else
    '0';

  DataOut     <= SumFeedback;
  ErrorCheck2 <= ErrorCheck1;

  process (Clk)
  begin

    ----------------------------Synchronous Reset--------------------------------------
    if (Reset_L = '0') then
      Product2 <= (others => '0');

      SumFeedback <= (((DataWidth * 2) - 1) downto DataWidth => DataIn3(DataWidth - 1)) & DataIn3;
      ErrorCheck1 <= "00";

    elsif ((Clk'event) and (Clk = '1')) then
      ---------------------------- Hold current value when Hold is asserted --------------------------------------
      if (Hold = '1') then
        Product2    <= Product2;
        SumFeedback <= SumFeedback;
        ErrorCheck1 <= ErrorCheck1;
        ---------------------------- Otherwise run --------------------------------------
      else
        Product2    <= Product1;
        SumFeedback <= Sum;

        if (ErrorCheck1 = "00") then
          ErrorCheck1 <= (Overflow, Underflow);
        else
          ErrorCheck1 <= ErrorCheck1;
        end if;
      end if;
    end if;
  end process;

end MACUnit1;
)VHDL";

  Output.close();
}
//
//
void GenerateDataPathModule(const Parameters &Specs)
{
  ofstream Output;
  Output.open("DatapathModule.vhd");

  Output << Specs.Libraries;

  Output << format(R"VHDL(
entity DatapathModule is

  generic (
    DataWidth : integer := {};
    Rows      : integer := {};
    Columns   : integer := {}
  );

  port (
    DataIn   : in signed ((DataWidth - 1) downto 0);
    AddressW : in integer range 0 to (Columns - 1);
    AddressX : in integer range 0 to (Columns - 1);
    REW      : in std_logic;
    REB      : in std_logic;
    REX      : in std_logic;
    WEX      : in std_logic;
    Hold     : in std_logic;
    Reset_L  : in std_logic;
    Clk      : in std_logic;

)VHDL",
                   Specs.T, Specs.M, Specs.N);

  // Data out ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{} : out signed(((DataWidth * 2) - 1) downto 0);)VHDL", i) << endl;
  }

  Output << endl;

  // ErrorCheck ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    ErrorCheck2{0} : out std_logic_vector (1 downto 0))VHDL", i);
    Output << ((i == Specs.M - 1) ? ("\n  );") : (";")) << endl;
  }

  Output << R"VHDL(end DatapathModule;)VHDL" << endl;

  Output << format(R"VHDL(
architecture DatapathModule1 of DatapathModule is

  component MACUnit is
    generic (
      DataWidth : integer := {0}
    );

    port (
      DataIn1 : in signed(DataWidth - 1 downto 0);
      DataIn2 : in signed(DataWidth - 1 downto 0);
      DataIn3 : in signed(DataWidth - 1 downto 0);
      Hold    : in std_logic;
      Clk     : in std_logic;
      Reset_L : in std_logic;

      DataOut     : out signed(((DataWidth * 2) - 1) downto 0);
      ErrorCheck2 : out std_logic_vector (1 downto 0)
    );
  end component;

  component MemoryModule is
    generic (
      DataWidth : integer := {0};
      MemSize   : integer := {1});

    port (
      DataIn  : in signed ((DataWidth - 1) downto 0);
      Address : in integer range 0 to (MemSize - 1);
      WE      : in std_logic;
      RE      : in std_logic;
      Clk     : in std_logic;

      DataOut : out signed (DataWidth - 1 downto 0)
    );
  end component;

  component ROMW is
    generic (
      DataWidth : integer := {0};
      Columns   : integer := {1};

      -- These memory slots need to be hardcoded. HLS will have to deal with this.)VHDL",
                   Specs.T, Specs.N)
         << endl;

  // ROMW value generics.
  for (int i = 0; i < Specs.M; i++)
  {
    for (int j = 0; j < Specs.N; j++)
    {
      Output << format("      Slot{0}{1} : integer := {2}", i, j, ((i * Specs.N) + j));
      Output << (((i * Specs.N) + j == ((Specs.M * Specs.N) - 1)) ? (");") : (";")) << endl;
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

  // ROMW ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("      DataOut{} : out signed ((DataWidth - 1) downto 0)", i);
    Output << ((i == Specs.M - 1) ? ("\n    );") : (";")) << endl;
  }

  Output << R"VHDL(  end component;)VHDL" << endl;

  Output << R"VHDL(
  component ROMB is
    generic (
      DataWidth : integer := 8;

      -- Memory slots have to be hardcodded. HLS will deal with this.
    )VHDL"
         << endl;

  // ROMB value generics.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("      Slot{0} : integer := {0}", i);
    Output << ((i == Specs.M - 1) ? (");") : (";")) << endl;
  }

  Output << R"VHDL(
    port (
      Enable : in std_logic;
      Clk    : in std_logic;

      -- Each Row/value neds a separate output port.
      -- Number of output ports has to be hardcoded. HLS will have to deal with this.)VHDL"
         << endl;

  // ROMB Ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("      DataOut{} : out signed ((DataWidth - 1) downto 0)", i);
    Output << ((i == Specs.M - 1) ? ("\n    );") : (";")) << endl;
  }

  Output << "  end component;" << endl
         << endl;

  // Internal signals for ROMB DataOut.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(  signal DataInB{} : signed ((DataWidth - 1) downto 0);)VHDL", i) << endl;
  }

  Output << endl;

  // Internal signals for ROMW DataOut.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(  signal DataInW{} : signed ((DataWidth - 1) downto 0);)VHDL", i) << endl;
  }

  Output << endl;

  Output << R"VHDL(  signal DataInX : signed ((DataWidth - 1) downto 0);

begin

  MemoryW : ROMW
  generic map(
    DataWidth => DataWidth,
    Columns   => Columns,
)VHDL";

  // Hardcoding Matrix W values into ROMW.
  for (int i = 0; i < Specs.M; i++)
  {
    for (int j = 0; j < Specs.N; j++)
    {
      Output << format("    Slot{0}{1}    => {2}", i, j, Specs.WMatrix.at(i).at(j));
      Output << ((((i * Specs.N) + j == (Specs.M * Specs.N) - 1)) ? ("\n  )") : (",")) << endl;
    }
  }

  Output << R"VHDL(  port map
  (
    Address  => AddressW,
    Enable   => REW,
    Clk      => Clk,)VHDL"
         << endl;

  // Ports for ROMW.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{0} => DataInW{0})VHDL", i);
    Output << ((i == Specs.M - 1) ? ("\n  );") : (",")) << endl;
  }

  Output << R"VHDL(
  MemoryB : ROMB
  generic map(
    DataWidth => DataWidth,)VHDL"
         << endl;

  // Hardcoding Matrix B values into ROMB.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    Slot{0}     => {1})VHDL", i, Specs.BMatrix.at(i));
    Output << ((i == Specs.M - 1) ? ("\n  )") : (",")) << endl;
  }

  Output << R"VHDL(  port map
  (
    Enable   => REB,
    Clk      => Clk,)VHDL"
         << endl;

  // Ports for ROMB.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{0} => DataInB{0})VHDL", i);
    Output << ((i == Specs.M - 1) ? ("\n  );") : (",")) << endl;
  }

  Output << R"VHDL(
  MemoryX : MemoryModule
  generic map(
    DataWidth => DataWidth,
    MemSize   => Columns
  )
  port map
  (
    DataIn  => DataIn,
    Address => AddressX,
    WE      => WEX,
    RE      => REX,
    Clk     => Clk,
    DataOut => DataInX
  );
)VHDL" << endl;

  // MAC Units instantiation.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(  MACUNit{0} : MACUnit
  generic map(
    DataWidth => DataWidth
  )
  port map
  (
    DataIn1     => DataInW{0},
    DataIn2     => DataInX,
    DataIn3     => DataInB{0},
    Hold        => Hold,
    Clk         => Clk,
    Reset_L     => Reset_L,
    DataOut     => DataOut{0},
    ErrorCheck2 => ErrorCheck2{0}
  );
)VHDL",
                     i)
           << endl;
  }

  Output << R"VHDL(end DatapathModule1;)VHDL" << endl;

  Output.close();
}
//
//
void GenerateTopModule(const Parameters &Specs)
{
  ofstream Output;
  Output.open("TopModule.vhd");

  Output << Specs.Libraries;

  Output << format(R"VHDL(
entity TopModule is

  generic (
    DataWidth : integer := {2};
    Rows      : integer := {0};
    Columns   : integer := {1}
  );

  port (
    DataIn      : in signed ((DataWidth - 1) downto 0);
    InputValid  : in std_logic;
    OutputReady : in std_logic;
    Reset_L     : in std_logic;
    Clk         : in std_logic;

    OutputValid : out std_logic;
    InputReady  : out std_logic;
)VHDL",
                   Specs.M, Specs.N, Specs.T)
         << endl;

  // Output ports
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{} : out signed(((DataWidth * 2) - 1) downto 0);)VHDL", i) << endl;
  }

  Output << format(R"VHDL(
    ErrorCheck : out std_logic_vector (((Rows * 2) - 1) downto 0)
  );
end TopModule;

architecture TopModule1 of TopModule is

  component ControlModule is
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
      REB         : out std_logic;
      REX         : out std_logic;
      WEX         : out std_logic;
      Clear_L     : out std_logic;
      Hold        : out std_logic;
      OutputValid : out std_logic;
      InputReady  : out std_logic
    );
  end component;

  component DatapathModule is
    generic (
      DataWidth : integer := {2};
      Rows      : integer := {0};
      Columns   : integer := {1}
    );

    port (
      DataIn   : in signed ((DataWidth - 1) downto 0);
      AddressW : in integer range 0 to (Columns - 1);
      AddressX : in integer range 0 to (Columns - 1);
      REW      : in std_logic;
      REB      : in std_logic;
      REX      : in std_logic;
      WEX      : in std_logic;
      Hold     : in std_logic;
      Reset_L  : in std_logic;
      Clk      : in std_logic;
)VHDL",
                   Specs.M, Specs.N, Specs.T)
         << endl;

  // DatapathModule Data ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(      DataOut{} : out signed(((DataWidth * 2) - 1) downto 0);)VHDL", i) << endl;
  }

  Output << R"VHDL()VHDL" << endl;

  // DatapathModule Error ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(      ErrorCheck2{} : out std_logic_vector (1 downto 0))VHDL", i);
    Output << ((i == Specs.M - 1) ? ("\n    );") : (";")) << endl;
  }
  Output << "  end component;" << endl;

  Output << R"VHDL(
  signal AddressW : integer range 0 to (Columns - 1);
  signal AddressX : integer range 0 to (Columns - 1);
  signal REW      : std_logic;
  signal REB      : std_logic;
  signal REX      : std_logic;
  signal WEX      : std_logic;

  signal Hold    : std_logic;
  signal Clear_L : std_logic;

begin

  ControlModule1 : ControlModule
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
    Reset_L     => Reset_L,
    AddressW    => AddressW,
    AddressX    => AddressX,
    REW         => REW,
    REB         => REB,
    REX         => REX,
    WEX         => WEX,
    Clear_L     => Clear_L,
    Hold        => Hold,
    OutputValid => OutputValid,
    InputReady  => InputReady
  );

  DatapathModule_1 : DatapathModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    DataIn       => DataIn,
    AddressW     => AddressW,
    AddressX     => AddressX,
    REW          => REW,
    REB          => REB,
    REX          => REX,
    WEX          => WEX,
    Hold         => Hold,
    Reset_L      => Clear_L,
    Clk          => Clk,)VHDL"
         << endl;

  // DatapathModule Data ports assignment.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{0}     => DataOut{0},)VHDL", i) << endl;
  }

  // DatapathModule Error ports assignment.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    ErrorCheck2{0} => ErrorCheck({2} downto {1}))VHDL", i, (i * 2), (i * 2 + 1));
    Output << ((i == Specs.M - 1) ? ("\n  );") : (",")) << endl;
  }
  Output << "end TopModule1;" << endl;

  Output.close();
}
//
//
void GenerateTestbench(const Parameters &Specs)
{
  int ErrorCheckWidth = (Specs.M * 2) - 1;

  string InputTableWB;
  ofstream Output;
  Output.open(format("TB_TopModule{0}x{1}.vhd", Specs.M, Specs.N));

  Output << Specs.Libraries;

  Output << format(R"VHDL(use work.Tests{0}x{1}.all;
use ieee.std_logic_misc.all;

entity TB_TopModule_{0}x{1} is
  generic (
    DataWidth : integer := {2};
    Rows      : integer := {0};
    Columns   : integer := {1}
  );

end TB_TopModule_{0}x{1};

architecture TB_TopModule1_{0}x{1} of TB_TopModule_{0}x{1} is

  component TopModule is
    generic (
      DataWidth : integer := {2};
      Rows      : integer := {0};
      Columns   : integer := {1}
    );

    port (
      DataIn      : in signed ((DataWidth - 1) downto 0);
      InputValid  : in std_logic;
      OutputReady : in std_logic;
      Reset_L     : in std_logic;
      Clk         : in std_logic;

      OutputValid : out std_logic;
      InputReady  : out std_logic;
)VHDL",
                   Specs.M, Specs.N, Specs.T)
         << endl;

  // Output ports.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(      DataOut{} : out signed(((DataWidth * 2) - 1) downto 0);)VHDL", i) << endl;
  }

  Output << format(R"VHDL(
      ErrorCheck : out std_logic_vector ({0} downto 0)
    );
  end component;

  signal Clk        : std_logic               := '0';
  signal ClockCount : integer range 0 to 1023 := 0;

  signal InputValid  : std_logic := '0';
  signal OutputReady : std_logic := '0';
  signal Reset_L     : std_logic := '0';

  signal DataIn : signed ((DataWidth - 1) downto 0) := (others => '0');
)VHDL",
                   ErrorCheckWidth)
         << endl;

  // Output data signals.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(  signal DataOut{0}    : signed(((DataWidth * 2) - 1) downto 0) := (others => '0');)VHDL", i) << endl;
  }

  Output << format(R"VHDL(  signal OutputValid : std_logic                              := '0';
  signal InputReady  : std_logic                              := '0';
  signal ErrorCheck  : std_logic_vector ({0} downto 0)          := (others => '0');

begin

  DUT1 : TopModule
  generic map(
    DataWidth => DataWidth,
    Rows      => Rows,
    Columns   => Columns
  )
  port map
  (
    DataIn      => DataIn,
    InputValid  => InputValid,
    OutputReady => OutputReady,
    Reset_L     => Reset_L,
    Clk         => Clk,)VHDL",
                   ErrorCheckWidth)
         << endl;

  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    DataOut{0}    => DataOut{0},)VHDL", i) << endl;
  }

  Output << R"VHDL(    OutputValid => OutputValid,
    InputReady  => InputReady,
    ErrorCheck  => ErrorCheck
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
    wait until ClockCount >= 500;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;

  ------------------------------ Simulation Stimuli ----------------------------
  process
    variable i         : integer                        := 0;
    variable FinalPass : std_logic_vector (13 downto 0) := (others => '1');
    variable Pass      : boolean                        := true;
)VHDL"
         << endl;

  // Generating Input Tables string

  // Hardcoding W values.
  for (int i = 0; i < Specs.M; i++)
  {
    InputTableWB += "    (";

    for (int j = 0; j < Specs.N; j++)
    {
      InputTableWB += format("{}", Specs.WMatrix.at(i).at(j));

      InputTableWB += (j == (Specs.N - 1)) ? ("") : (", ");
    }

    InputTableWB += ((i == 0) ? "), -- This is W\n" : "),\n");
  }

  InputTableWB += "    (";

  // Hardcoding B values.
  for (int i = 0; i < Specs.N; i++)
  {
    InputTableWB += (i >= (2 * Specs.M - Specs.N) + 1) ? ("0") : (format("{}", Specs.BMatrix.at(i)));
    InputTableWB += (i == Specs.N - 1) ? ("), -- This is B\n") : (", ");
  }

  // Generating test value sets.
  for (int i = 0; i < Specs.XMatrix.size(); i++)
  {
    // Comments for each set.
    switch (i)
    {
    case 0:
      Output << R"VHDL(    -- No overflow/underflow.)VHDL" << endl;
      break;
    case 1:
      Output << R"VHDL(    -- Going to trigger an overflow in row 2.)VHDL" << endl;
      break;
    case 2:
      Output << R"VHDL(    -- Going to trigger an underflow in row 2.)VHDL" << endl;
      break;
    case 3:
      Output << R"VHDL(    -- Going to trigger both an overflow and an underflow for rows 1 and 3 respectively.)VHDL" << endl;
      break;
    case 4:
      Output << R"VHDL(    -- No overflow/underflow.)VHDL" << endl;
      break;

    default:
      cout << "This shouldn't have happened! i = " << i << endl;
    }

    Output << format(R"VHDL(    variable Input{0} : InputTable := ()VHDL", (i + 1)) << endl;

    Output << InputTableWB << "    (";

    // Hardcoding X values.
    for (int j = 0; j < Specs.N; j++)
    {
      Output << Specs.XMatrix.at(i).at(j);
      Output << ((j == Specs.N - 1) ? (") -- This is X\n") : (", "));
    }

    Output << "    );" << endl
           << endl;
  }

  // Output tables.
  for (int i = 0; i < Specs.XMatrix.size(); i++)
  {
    // Comments for each table.
    switch (i)
    {
    case 0:
      Output << R"VHDL(    -- Output without overflow/underflow.)VHDL" << endl;
      break;
    case 1:
      Output << R"VHDL(    -- Output with overflow in position 2.)VHDL" << endl;
      break;
    case 2:
      Output << R"VHDL(    -- Output with underflow in position 2.)VHDL" << endl;
      break;
    case 3:
      Output << R"VHDL(    -- Output with overflow and underflow in positions 1 and 3 respectively.)VHDL" << endl;
      break;
    case 4:
      Output << R"VHDL(    -- Output without overflow/underflow.)VHDL" << endl;
      break;

    default:
      cout << "This shouldn't have happened! i = " << i << endl;
    }

    Output << format(R"VHDL(    variable Output{} : OutputTable := ()VHDL", (i + 1));

    for (int j = 0; j < Specs.M; j++)
    {
      Output << "0";
      Output << ((j == Specs.M - 1) ? (");\n") : (", "));
    }
  }
  Output << endl;

  Output << R"VHDL(  begin

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Calculate the Expected Output @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@)VHDL"
         << endl;

  // Calculating all Outputs.
  for (int i = 0; i < Specs.XMatrix.size(); i++)
  {
    Output << format(R"VHDL(    Output{0} := CalculateOutput_{1}x{2}(Input{0});)VHDL", (i + 1), Specs.M, Specs.N) << endl;
  }

  Output << format(R"VHDL(
    -- i := 0;
    -- while i < Rows loop
    --   assert (false) report "Row " & integer'image(i) & ": " & integer'image(Output1(i)) severity note;

    --   i := i + 1;
    -- end loop;

    --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    report "Test 0 starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 0 : Resetting the system
    Test0_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Reset_L, InputValid, OutputReady, Pass);
    FinalPass(0) := Bool2Std(Pass);

    report "Test 1a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(1) := Bool2Std(Pass);

    report "Test 1b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 1b : Calculation. Regular operation.
    Test1b_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk,)VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_1b
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(2) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(3) := Bool2Std(Pass);

    report "Test 2a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2a : Calculation. Overflow detection test.
    
    Test2a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, )VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_2a
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(4) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(5) := Bool2Std(Pass);

    report "Test 2b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2b : Calculation. Overflow detection test.
    Test2b_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, )VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_2b
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(6) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(7) := Bool2Std(Pass);

    report "Test 2c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2c : Calculation. Simultaneous Overflow and Underflow detection test.
    Test2c_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, )VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_2c
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(8) := Bool2Std(Pass);

    report "Test 3a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3a : Memory Loading with abrupt InputValid deassertion
    Test3a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input5, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(9) := Bool2Std(Pass);

    report "Test 3c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3c : Abrupt reset assertion during Run state.
    Test3c_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, )VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_3c
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(10) := Bool2Std(Pass);

    report "Test 3b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3b : Memory Loading with abrupt reset assertion
    Test3b_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input5, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(11) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(12) := Bool2Std(Pass);

    report "Test 3d starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3d : Reset assertion during Done state
    Test3d_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, )VHDL",
                   Specs.M, Specs.N);

  // DataOut ports for Test_3d
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("DataOut{}, ", i);
  }

  Output << format(R"VHDL(Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(13) := Bool2Std(Pass);

    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    if (and_reduce(FinalPass) = '1') then
      report "PASS" severity error;
    else
      report "FAIL" severity error;
    end if;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;
    report "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" severity error;

    wait;
  end process;

end TB_TopModule1_{0}x{1};)VHDL",
                   Specs.M, Specs.N)
         << endl;

  Output.close();
}
//
//
void GenerateTests(const Parameters &Specs)
{

  int ErrorCheckWidth = (Specs.M * 2) - 1;
  int InputLowerBound = -1 * (1 << (Specs.T - 1));
  int InputUpperBound = (1 << (Specs.T - 1)) - 1;
  int OutputLowerBound = -1 * (1 << (2 * Specs.T)); // It's supposed to be able to take values higher than 2^(2N-1). We want to be able to see if it over/underflows.
  int OutputUpperBound = (1 << (2 * Specs.T)) - 1;  // It's supposed to be able to take values lower than -2^(2N-1). We want to be able to see if it over/underflows.

  ofstream Output;
  Output.open(format("Tests{0}x{1}.vhd", Specs.M, Specs.N));

  Output << Specs.Libraries;

  Output << format(R"VHDL(
package Tests{0}x{1} is

  constant DataWidth : integer := {2};
  constant Rows      : integer := {0};
  constant Columns   : integer := {1};

  type InputTable is array (0 to (Rows + 1), 0 to (Columns - 1)) of integer range {3} to {4};
  type OutputTable is array (0 to (Rows - 1)) of integer range {5} to {6};

  -- Calculate the expected output
  function CalculateOutput_{0}x{1}(Input : InputTable) return OutputTable;

  -- Conversion of booleans into std_logic
  function Bool2Std(Input : boolean) return std_logic;

  -- Test 0 : Resetting the system
  procedure Test0_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({7} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean
  );

  -- Test 1a : Memory Loading. Regular operation.
  procedure Test1a_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({7} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;
    variable Input1    : in InputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 1b: Calculation. Regular operation.
  procedure Test1b_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({7} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, Specs.T, InputLowerBound, InputUpperBound, OutputLowerBound, OutputUpperBound, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_1b prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2a : Calculation. Overflow detection test.
  procedure Test2a_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector(5 downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_2a prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2b : Calculation. Underflow detection test.
  procedure Test2b_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_2b prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 2c : Calculation. Simultaneous Overflow and Underflow detection test.
  procedure Test2c_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_2c prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 3a : Memory Loading with abrupt InputValid deassertion
  procedure Test3a_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;
    variable Input1    : in InputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 3b: Memory Loading with abrupt reset assertion
  procedure Test3b_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;
    variable Input1    : in InputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 3c: Abrupt reset assertion during Run state.
  procedure Test3c_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_3c prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

  -- Test 3d : Reset assertion during Done state
  procedure Test3d_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // DataOut ports for Test_3d prototype.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean
  );

end package Tests{0}x{1};
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
package body Tests{0}x{1} is

  -- Function to calculate the expected output when given the predetermined input.
  function CalculateOutput_{0}x{1}(Input : InputTable) return OutputTable is

    variable TempOutput : OutputTable                   := (0, 0, 0);
    variable i, j       : integer range 0 to 31         := 0;
    variable Sum        : integer range {3} to {4} := 0;
  begin

    -- Cycle through output matrix rows.
    i := 0;

    while i <= (Rows - 1) loop
      Sum := Input(Rows, i);
      j   := 0;
      while (j <= (Columns - 1)) loop

        Sum := Sum + (Input(i, j) * Input((Rows + 1), j));

        j := j + 1;
      end loop;

      TempOutput(i) := Sum;

      i := i + 1;
    end loop;

    return TempOutput;
  end function CalculateOutput_{0}x{1};

  function Bool2Std(Input : boolean) return std_logic is
  begin

    if Input then
      return '1';
    else
      return '0';
    end if;

  end function Bool2Std;

  --------------------------------------------------------------------
  -- Test 0 : Resetting the system
  --------------------------------------------------------------------
  procedure Test0_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;

    variable Pass : out boolean) is

    variable TempPass : boolean;
    variable i        : integer;

  begin

    TempPass := true;

    Reset_L <= '0';
    wait for 10 ns;

    i := 0;
    while i < Columns loop

      wait until Clk'event and Clk = '1';

      Reset_L <= '1';

      if (OutputValid /= '0') then
        report "OutputValid does not reset properly. Test0. Clock : " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      if (InputReady /= '0') then
        report "InputReady does not reset properly. Test0. Clock: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      if (ErrorCheck /= (ErrorCheck'range  => '0')) then
        report "ErrorCheck does not reset properly. Test0. Clock: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 0 : PASS" severity warning;
    else
      report "Test 0 : FAIL" severity error;
    end if;

  end procedure Test0_{0}x{1};
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- Test 1 : Testing regular operation.
  --------------------------------------------------------------------
  -- Test 1a : Memory Loading. Regular operation.
  --------------------------------------------------------------------
  procedure Test1a_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;
    variable Input1    : in InputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean                           := false;
    variable i, k, InputValue                : integer                           := 0;
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');
  begin

    -- Initial setup.
    TempPass        := true;
    TempOutputReady := '1';
    TempInputValid  := '1';

    wait for 10 ns;

    -- Loading Memory
    InputValid  <= TempInputValid;
    OutputReady <= TempOutputReady;
    DataIn      <= to_signed(0, DataIn'length);

    k := 1;
    wait until Clk'event and Clk = '1';

    -- Cycle through the X elements.
    i := 0;
    while i < Columns loop

      -- Pass the variable values to drive the signals.
      TempDataIn := to_signed(Input1((Input1'length(1) - 1), i), DataIn'length);
      DataIn <= TempDataIn;

      wait until Clk'event and Clk = '1';

      -- Output must remain low throughout the loading stage.
      if (OutputValid /= '0') then
        report "OutputValid does not remain low. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;
      -- InputReady must remain high throughout the loading stage.

      if (InputReady /= '1') and (i < (Columns - 2)) then
        report "InputReady went low prematurely. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      -- ErrorCheck must not be affected in any way while loading.
      if (ErrorCheck /= (ErrorCheck'range  => '0')) then
        report "ErrorCheck got raised erratically. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      if (TempInputValid = '1') then
        i := i + 1;
      end if;

      k := k + 1;
    end loop;

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1a : PASS" severity warning;
    else
      report "Test 1a : FAIL" severity error;
    end if;

  end procedure Test1a_{0}x{1};
  --------------------------------------------------------------------

  --------------------------------------------------------------------
  -- Test 1b : Calculation. Regular operation.
  --------------------------------------------------------------------
  procedure Test1b_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth, OutputLowerBound, OutputUpperBound)
         << endl;

  // Dataout ports for Test_1b.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << R"VHDL(    variable Output1   : in OutputTable;

    signal Reset_L     : out std_logic;
    signal InputValid  : out std_logic;
    signal OutputReady : out std_logic;
    signal DataIn      : out signed ((DataWidth - 1) downto 0);
    variable Pass      : out boolean) is

    variable TempPass                        : boolean                           := true;
    variable i, k, InputValue                : integer                           := 0;
    variable TempDataIn                      : signed ((DataWidth - 1) downto 0) := (others => '0');
    variable TempOutputReady, TempInputValid : std_logic                         := '0';
  begin

    TempPass := true;

    InputValid  <= '1';
    OutputReady <= '0';
    TempInputValid := '0';

    i := 0;
    while i < (Columns + 2) loop

      -- Deassert InputValid pseudorandomly.
      if (i mod 2 = 0) then
        TempInputValid := not TempInputValid;
      else
        TempInputValid := TempInputValid;
      end if;

      InputValid <= TempInputValid;

      wait until Clk'event and Clk = '1';

      -- InputReady must remain low throughout the loading stage.
      if (InputReady /= '0') then
        report "InputReady does not remain low. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      -- OutputValid must remain low throughout the calculation stage.
      if (OutputValid /= '0' and (i < (Columns + 1))) then
        report "OutputValid does not remain low. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      -- ErrorCheck must remain low in this test.
      if (ErrorCheck /= (ErrorCheck'range  => '0')) then
        report "ErrorCheck got raised erratically. ClockCount: " & integer'image(ClockCount) severity error;
        TempPass := false;
      end if;

      i := i + 1;
    end loop;

    -- Wait for 5 clock cycles in Done state before asserting OutputReady.
    k := 0;
    while k < 5 loop

      wait until Clk'event and Clk = '1';

      -- When OutputValid goes high, the correct Data must be output.)VHDL"
         << endl;

  // Checks for DataOut ports while the system is waiting for OutputReady.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(      if (DataOut{0} /= Output1({0})) then
        report "Incorrect DataOut at position {0}: " & integer'image(to_integer(DataOut{0})) & ". Expected : " & integer'image(Output1({0}))severity error;
        TempPass := false;
      else
        report "Output = " & integer'image(to_integer(DataOut{0})) severity note;
      end if;)VHDL",
                     i)
           << endl;
  }

  Output << R"VHDL(
      k := k + 1;
    end loop;

    OutputReady <= '1';
    InputValid  <= '0';
)VHDL" << endl;

  // Checks for DataOut ports during assertion of OutputReady.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format(R"VHDL(    if (DataOut{0} /= Output1({0})) then
      report "Incorrect DataOut at position {0}: " & integer'image(to_integer(DataOut{0})) & ". Expected : " & integer'image(Output1({0}))severity error;
      TempPass := false;
    else
      report "Output = " & integer'image(to_integer(DataOut{0})) severity note;
    end if;)VHDL",
                     i)
           << endl;
  }

  Output << format(R"VHDL(
    wait until Clk'event and Clk = '1';

    Pass := TempPass;

    if (TempPass = true) then
      report "Test 1b : PASS" severity warning;
    else
      report "Test 1b : FAIL" severity error;
    end if;

  end procedure Test1b_{0}x{1};

  --------------------------------------------------------------------
  --------------------------------------------------------------------
  -- Test 2 : Calculation. Overflow and Underflow detection.
  --------------------------------------------------------------------
  -- Test 2a : Calculation. Overflow detection test.
  --------------------------------------------------------------------
  procedure Test2a_{0}x{1}(
    signal OutputValid : in std_logic;
    signal InputReady  : in std_logic;
    signal ErrorCheck  : in std_logic_vector({2} downto 0);
    signal ClockCount  : in integer;
    signal Clk         : in std_logic;)VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  // Dataout ports for Test_2a.
  for (int i = 0; i < Specs.M; i++)
  {
    Output << format("    signal DataOut{0}    : in signed (((DataWidth * 2) - 1) downto 0);", i) << endl;
  }

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output << format(R"VHDL()VHDL",
                   Specs.M, Specs.N, ErrorCheckWidth)
         << endl;

  Output.close();
}
//
//