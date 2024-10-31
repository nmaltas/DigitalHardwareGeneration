library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
      DataInA : in signed((StandardWidth - 1) downto 0);
      DataInB : in signed((StandardWidth - 1) downto 0);
      ValidIn : in std_logic;
      Clk     : in std_logic;
      Reset   : in std_logic;

      DataOut     : out signed(((StandardWidth * 2) - 1) downto 0);
      ValidOut2   : out std_logic;
      ErrorCheck2 : out std_logic_vector (1 downto 0));
  end component;
  --------------------------------Carrier Signals------------------------------------------------------------
  signal DataInAC : signed((StandardWidth - 1) downto 0) := (others => '0');
  signal DataInBC : signed((StandardWidth - 1) downto 0) := (others => '0');
  signal ValidInC : std_logic                            := '0';
  signal Clk      : std_logic                            := '0';
  signal Reset    : std_logic                            := '0';

  signal DataOutC    : signed(((StandardWidth * 2) - 1) downto 0) := (others => '0');
  signal ValidOutC   : std_logic                                  := '0';
  signal ErrorCheckC : std_logic_vector (1 downto 0)              := (others => '0');

  signal ClockCount : integer range 0 to 300 := 0;
  -----------------------------------------------------------------------------------------------------------
begin
  -----------------------------------------DUT Instantiation------------------------------------------
  DUT1 : MACUnit
  generic map(InputBitWidth => StandardWidth)
  port map
  (
    DataInA     => DataInAC,
    DataInB     => DataInBC,
    ValidIn     => ValidInC,
    Clk         => Clk,
    Reset       => Reset,
    DataOut     => DataOutC,
    ValidOut2   => ValidOutC,
    ErrorCheck2 => ErrorCheckC
  );
  ----------------------------------------------------------------------------------------------------
  -------------------Clock and Reset--------------------------
  Clk <= not Clk after 5 ns;
  process
  begin
    wait until Clk'event and Clk = '1';
    wait for 2 ns;
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
    wait until (CLockCount = 2);

    Reset <= '0';
    -- Test 1: Normal operation.
    assert FALSE report "Test 1" severity warning;

    DataInAC <= to_signed(5, DataInAC'length);
    DataInBC <= to_signed(2, DataInBC'length);

    ValidInC <= '1';

    assert (ValidOutC = '0') report "ValidOut got raised prematurely." severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 3);

    assert (ValidOutC = '0') report "ValidOut got raised prematurely." severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 5);

    assert (ValidOutC = '1') report "ValidOut did not get raised." severity error;
    assert (to_integer(DataOutC) = 10) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;

    -- Test 2: ValidIn deassertion and value retention.
    assert FALSE report "Test 2" severity warning;

    ValidInC <= '0';

    wait until (CLockCount = 6);
    assert (ValidOutC = '1') report "ValidOut did not get raised." severity error;
    assert (to_integer(DataOutC) = 20) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;

    wait until (CLockCount = 9);

    assert (ValidOutC = '0') report "ValidOut got raised prematurely." severity error;
    assert (to_integer(DataOutC) = 30) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;

    -- Test 3: Testing overflow indication triggerring
    assert FALSE report "Test 3" severity warning;

    ValidInC <= '1';

    DataInAC <= to_signed(125, DataInAC'length);
    DataInBC <= to_signed(125, DataInBC'length);

    wait until (CLockCount = 14);

    assert (ErrorCheckC = "10") report "ErrorCheck did not get raised in time." severity error;
    assert (ValidOutC = '0') report "ValidOut did not go low in time." severity error;

    wait until (CLockCount = 15);

    assert (ErrorCheckC = "10") report "ErrorCheck did not stay raised." severity error;
    assert (ValidOutC = '0') report "ValidOut got stay low." severity error;

    -- Test 4: Resetting from Error state
    assert FALSE report "Test 4" severity warning;
    Reset <= '1';

    wait until (CLockCount = 16);

    assert (ErrorCheckC = "00") report "ErrorCheck did not reset properly." severity error;
    assert (ValidOutC = '0') report "ValidOut did not reset properly." severity error;
    assert (to_integer(DataOutC) = 0) report "DataOut did not reset properly. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    Reset <= '0';

    -- Test 5: Testing undeflow indication trigerring
    assert FALSE report "Test 5" severity warning;

    DataInAC <= to_signed(127, DataInAC'length);
    DataInBC <= to_signed(-127, DataInBC'length);

    wait until (CLockCount = 19);

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;
    assert (ValidOutC = '1') report "ValidOut did not get raised in time." severity error;

    wait until (CLockCount = 21);

    assert (ErrorCheckC = "01") report "ErrorCheck did not get raised in time." severity error;
    assert (ValidOutC = '0') report "ValidOut did not go low in time." severity error;

    wait until (CLockCount = 24);

    assert (ErrorCheckC = "01") report "ErrorCheck did not remain raised while in Error State." severity error;
    assert (ValidOutC = '0') report "ValidOut did not remain low while in Error State." severity error;

    -- Test 4: Resetting from Error state
    assert FALSE report "Test 4" severity warning;

    Reset <= '1';

    wait until (CLockCount = 25);

    assert (ErrorCheckC = "00") report "ErrorCheck did not reset properly." severity error;
    assert (ValidOutC = '0') report "ValidOut did not reset properly." severity error;
    assert (to_integer(DataOutC) = 0) report "DataOut did not reset properly. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    Reset <= '0';

    -- Test 6: Further regular operation testing
    assert FALSE report "Test 6" severity warning;

    DataInAC <= to_signed(127, DataInAC'length);
    DataInBC <= to_signed(-1, DataInBC'length);

    wait until (CLockCount = 27);

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;
    assert (ValidOutC = '0') report "ValidOut got raised too soon." severity error;
    assert (to_integer(DataOutC) = 0) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    DataInAC <= to_signed(100, DataInAC'length);
    DataInBC <= to_signed(-1, DataInBC'length);

    wait until (CLockCount = 28);

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon." severity error;
    assert (to_integer(DataOutC) = (-127)) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    DataInAC <= to_signed(-100, DataInAC'length);
    DataInBC <= to_signed(1, DataInBC'length);

    wait until (CLockCount = 29);

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon." severity error;
    assert (to_integer(DataOutC) = (-227)) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    wait until (CLockCount = 30);

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly." severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon." severity error;
    assert (to_integer(DataOutC) = (-327)) report "Data mismatch. DataOutC = " & integer'image(to_integer(DataOutC)) severity error;

    wait;
  end process;
  ---------------------------------------------------------------------------------------------------------------------------
end TB_MACUnit1;