library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity MACUnit is

  generic (
    InputBitWidth : integer := 8
  );

  port (
    DataIn1 : in signed(InputBitWidth - 1 downto 0);
    DataIn2 : in signed(InputBitWidth - 1 downto 0);
    DataIn3 : in signed(InputBitWidth - 1 downto 0);
    Hold    : in std_logic;
    Clk     : in std_logic;
    Reset   : in std_logic;

    DataOut     : out signed(((InputBitWidth * 2) - 1) downto 0);
    ErrorCheck2 : out std_logic_vector (1 downto 0)
  );
end MACUnit;

architecture MACUnit1 of MACUnit is

  signal Product1    : signed(((InputBitWidth * 2) - 1) downto 0);
  signal Product2    : signed(((InputBitWidth * 2) - 1) downto 0);
  signal Sum         : signed(((InputBitWidth * 2) - 1) downto 0);
  signal SumFeedback : signed(((InputBitWidth * 2) - 1) downto 0);
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
    if (Reset = '1') then
      Product2 <= (others => '0');

      SumFeedback <= (((InputBitWidth * 2) - 1) downto InputBitWidth => DataIn3(InputBitWidth - 1)) & DataIn3;
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