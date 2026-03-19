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
void GenerateMemoryX(const Parameters &Specs);
void GenerateROMW(const Parameters &Specs);
void GenerateControlModule(const Parameters &Specs);
void GenerateMACUnit(const Parameters &Specs);
void GenerateDataPathModule(const Parameters &Specs);
void GenerateTopModule(const Parameters &Specs);
void GenerateTestbench(const Parameters &Specs);
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
                   ((Specs.M * 2) - 1))
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
                   ((Specs.M * 2) - 1))
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
    Test1b_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(2) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(3) := Bool2Std(Pass);

    report "Test 2a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2a : Calculation. Overflow detection test.
    Test2a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output2, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(4) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(5) := Bool2Std(Pass);

    report "Test 2b starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2b : Calculation. Overflow detection test.
    Test2b_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output3, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(6) := Bool2Std(Pass);

    -- Test 1a: Memory Loading. Regular operation.
    Test1a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(7) := Bool2Std(Pass);

    report "Test 2c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 2c : Calculation. Simultaneous Overflow and Underflow detection test.
    Test2c_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(8) := Bool2Std(Pass);

    report "Test 3a starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3a : Memory Loading with abrupt InputValid deassertion
    Test3a_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, Input5, Reset_L, InputValid, OutputReady, DataIn, Pass);
    FinalPass(9) := Bool2Std(Pass);

    report "Test 3c starting at clock cycle: " & integer'image(ClockCount + 1) severity warning;
    -- Test 3c : Abrupt reset assertion during Run state.
    Test3c_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output1, Reset_L, InputValid, OutputReady, DataIn, Pass);
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
    Test3d_{0}x{1}(OutputValid, InputReady, ErrorCheck, ClockCount, Clk, DataOut0, DataOut1, DataOut2, Output4, Reset_L, InputValid, OutputReady, DataIn, Pass);
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