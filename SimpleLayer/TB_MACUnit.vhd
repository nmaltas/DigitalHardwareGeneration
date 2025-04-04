library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity TB_MACUnit is
  generic (
    StandardWidth : integer := 8
  );
end TB_MACUnit;

architecture TB_MACUnit1 of TB_MACUnit is

  component MACUnit is
    generic (
      InputBitWidth : integer := 8
    );

    port (
      DataInA : in signed(InputBitWidth - 1 downto 0);
      DataInB : in signed(InputBitWidth - 1 downto 0);
      Hold    : in std_logic;
      Clk     : in std_logic;
      Reset   : in std_logic;

      DataOut     : out signed(((InputBitWidth * 2) - 1) downto 0);
      ErrorCheck2 : out std_logic_vector (1 downto 0)
    );
  end component;

  --------------------------------Carrier Signals------------------------------------------------------------
  signal DataInA    : signed((StandardWidth - 1) downto 0)       := (others => '0');
  signal DataInB    : signed((StandardWidth - 1) downto 0)       := (others => '0');
  signal Hold       : std_logic                                  := '0';
  signal Clk        : std_logic                                  := '0';
  signal Reset      : std_logic                                  := '0';
  signal DataOut    : signed(((StandardWidth * 2) - 1) downto 0) := (others => '0');
  signal ErrorCheck : std_logic_vector (1 downto 0)              := (others => '0');

  signal ClockCount : integer range 0 to 300 := 0;
  -----------------------------------------------------------------------------------------------------------
begin
  -----------------------------------------DUT Instantiation------------------------------------------
  DUT1 : MACUnit
  generic map(
    InputBitWidth => StandardWidth
  )
  port map
  (
    DataInA     => DataInA,
    DataInB     => DataInB,
    Hold        => Hold,
    Clk         => Clk,
    Reset       => Reset,
    DataOut     => DataOut,
    ErrorCheck2 => ErrorCheck
  );
  ----------------------------------------------------------------------------------------------------
  -------------------Clock and Reset--------------------------
  Clk <= not Clk after 5 ns;
  process
  begin
    wait until Clk'event and Clk = '1';
    wait for 1 ns;
    ClockCount <= ClockCount + 1;
  end process;

  process
  begin
    wait until ClockCount >= 50;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;
  ------------------------------------------------------------
  -----------------Simulation Stimuli----------------------------------------------------------------------------------------
  process
  begin

    Reset <= '1';
    wait until (CLockCount = 1);
    Reset <= '0';

    -- Test 1 : Normal operation.
    assert FALSE report "Test 1 : Normal Operation" severity warning;

    DataInA <= to_signed(5, DataInA'length);
    DataInB <= to_signed(2, DataInB'length);

    wait until (CLockCount = 3);

    assert (to_integer(DataOut) = 10) report "Data mismatch. Expected: 10. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 5);

    assert (to_integer(DataOut) = 30) report "Data mismatch. Expected: 30. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 6);

    assert (to_integer(DataOut) = 40) report "Data mismatch. Expected: 40. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck got raised mistakenly." severity error;

    -- Test 2 : Hold a static output
    assert FALSE report "Test 2 : Hold a static output" severity warning;

    Hold <= '1';

    wait until (CLockCount = 7);

    assert (to_integer(DataOut) = 40) report "Data mismatch. Expected: 40. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 13);

    assert (to_integer(DataOut) = 40) report "Data mismatch. Expected: 40. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck got raised mistakenly." severity error;

    Hold <= '0';

    -- Test 3a : Error State - Overflow
    assert FALSE report "Test 3a : Error State - Overflow" severity warning;

    DataInA <= to_signed(127, DataInA'length);
    DataInB <= to_signed(127, DataInB'length);

    wait until (CLockCount = 17);

    assert (ErrorCheck = "10") report "Overflow was not detected." severity error;

    wait until (CLockCount = 27);

    assert (ErrorCheck = "10") report "Error indication does not remain high." severity error;

    -- Test 0 : System Reset
    assert FALSE report "Test 0 : System Reset" severity warning;

    Reset <= '1';
    wait until (CLockCount = 28);

    assert (to_integer(DataOut) = 0) report "DataOut does not reset properly. Expected: 0. Actual: " & integer'image(to_integer(DataOut)) severity error;
    assert (ErrorCheck = "00") report "ErrorCheck does not reset properly." severity error;

    Reset <= '0';

    -- Test 3b : Error State - Underflow
    assert FALSE report "Test 3b : Error State - Underflow" severity warning;

    DataInA <= to_signed(127, DataInA'length);
    DataInB <= to_signed(-125, DataInB'length);

    wait until (CLockCount = 32);

    assert (ErrorCheck = "01") report "Underflow was not detected." severity error;

    wait until (CLockCount = 48);

    assert (ErrorCheck = "01") report "Error indication does not remain high." severity error;

    wait;
  end process;
  ---------------------------------------------------------------------------------------------------------------------------
end TB_MACUnit1;