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
    ClockCount <= ClockCount + 1;
  end process;

  process
  begin
    wait until ClockCount >= 50;
    assert FALSE report "Simulation completed successfully" severity failure;
  end process;
  ------------------------------------------------------------
  -----------------Simulation Stimuli-------------------------
  process
  begin

    Reset <= '1';
    wait for 19 ns; -- 19ns

    Reset <= '0';
    -- Test 1: Normal operation.
    assert FALSE report "Testing normal operation and whether the output remains stable after deassertion of the ValidIn signal." severity warning;

    DataInAC <= to_signed(5, DataInAC'length);
    DataInBC <= to_signed(2, DataInBC'length);

    ValidInC <= '1';

    assert (ValidOutC = '0') report "ValidOut got raised prematurely. Test 1" severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 1" severity error;

    wait for 15 ns; -- 34ns

    assert (ValidOutC = '0') report "ValidOut got raised prematurely. Test 1" severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 1" severity error;

    wait for 15 ns; -- 49ns

    assert (ValidOutC = '1') report "ValidOut did not get raised. Test 1" severity error;
    assert (to_integer(DataOutC) = 10) report "Data mismatch. Test 1" severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 1" severity error;

    -- Test 2: ValidIn deassertion and value retention.

    ValidInC <= '0';

    wait for 10 ns; -- 59ns
    assert (ValidOutC = '1') report "ValidOut did not get raised. Test 2" severity error;
    assert (to_integer(DataOutC) = 20) report "Data mismatch. Test 2" severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 2" severity error;

    wait for 30 ns; -- 89ns

    assert (ValidOutC = '0') report "ValidOut got raised prematurely. Test 2" severity error;
    assert (to_integer(DataOutC) = 30) report "Data mismatch. Test 2" severity error;
    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 2" severity error;

    -- Test 3: Testing overflow indication triggerring

    ValidInC <= '1';

    DataInAC <= to_signed(125, DataInAC'length);
    DataInBC <= to_signed(125, DataInBC'length);

    wait for 50 ns; -- 139ns

    assert (ErrorCheckC = "10") report "ErrorCheck did not get raised in time. Test 3" severity error;
    assert (ValidOutC = '0') report "ValidOut did not go low in time. Test 3" severity error;

    wait for 10 ns; -- 149ns

    assert (ErrorCheckC = "10") report "ErrorCheck did not stay raised. Test 3" severity error;
    assert (ValidOutC = '0') report "ValidOut got stay low. Test 3" severity error;

    -- Test 4: Resetting from Error state

    Reset <= '1';

    wait for 15 ns; -- 164 ns

    assert (ErrorCheckC = "00") report "ErrorCheck did not reset properly. Test 4" severity error;
    assert (ValidOutC = '0') report "ValidOut did not reset properly. Test 4" severity error;
    assert (to_integer(DataOutC) = 0) report "DataOut did not reset properly. Test 4" severity error;

    Reset <= '0';

    -- Test 5: Testing undeflow indication trigerring

    DataInAC <= to_signed(127, DataInAC'length);
    DataInBC <= to_signed(-127, DataInBC'length);

    wait for 25 ns; -- 189 ns;

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 5" severity error;
    assert (ValidOutC = '1') report "ValidOut did not get raised in time. Test 5" severity error;

    wait for 20 ns; -- 209 ns

    assert (ErrorCheckC = "01") report "ErrorCheck did not get raised in time. Test 5" severity error;
    assert (ValidOutC = '0') report "ValidOut did not go low in time. Test 5" severity error;

    wait for 30 ns; -- 239 ns

    assert (ErrorCheckC = "01") report "ErrorCheck did not remain raised while in Error State. Test 5" severity error;
    assert (ValidOutC = '0') report "ValidOut did not remain low while in Error State. Test 5" severity error;

    -- Test 4: Resetting from Error state

    Reset <= '1';

    wait for 15 ns; -- 254 ns

    assert (ErrorCheckC = "00") report "ErrorCheck did not reset properly. Test 4" severity error;
    assert (ValidOutC = '0') report "ValidOut did not reset properly. Test 4" severity error;
    assert (to_integer(DataOutC) = 0) report "DataOut did not reset properly. Test 4" severity error;

    Reset <= '0';

    -- Test 6: Further normal operation testing

    DataInAC <= to_signed(127, DataInAC'length);
    DataInBC <= to_signed(-1, DataInBC'length);

    wait for 15 ns; -- 269 ns

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 6" severity error;
    assert (ValidOutC = '0') report "ValidOut got raised too soon. Test 6" severity error;
    assert (to_integer(DataOutC) = 0) report "Data mismatch. Test 6" severity error;

    DataInAC <= to_signed(100, DataInAC'length);
    DataInBC <= to_signed(-1, DataInBC'length);

    wait for 10 ns; -- 279 ns

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 6" severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon. Test 6" severity error;
    assert (to_integer(DataOutC) = (-127)) report "Data mismatch. Test 6" severity error;

    DataInAC <= to_signed(-100, DataInAC'length);
    DataInBC <= to_signed(1, DataInBC'length);

    wait for 10 ns; -- 289 ns

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 6" severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon. Test 6" severity error;
    assert (to_integer(DataOutC) = (-227)) report "Data mismatch. Test 6" severity error;

    wait for 10 ns; -- 299 ns

    assert (ErrorCheckC = "00") report "ErrorCheck got raised mistakenly. Test 6" severity error;
    assert (ValidOutC = '1') report "ValidOut got raised too soon. Test 6" severity error;
    assert (to_integer(DataOutC) = (-327)) report "Data mismatch. Test 6" severity error;

    wait;
  end process;
  ------------------------------------------------------------
end TB_MACUnit1;