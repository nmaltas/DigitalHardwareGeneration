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

entity MACUnit is

  generic (
    InputBitWidth : integer := 8
  );

  port (
    DataInA : in signed(InputBitWidth - 1 downto 0);
    DataInB : in signed(InputBitWidth - 1 downto 0);
    ValidIn : in std_logic;
    Clk     : in std_logic;
    Reset   : in std_logic;

    DataOut     : out signed(((InputBitWidth * 2) - 1) downto 0);
    ValidOut2   : out std_logic;
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
  signal ValidOut1   : std_logic;
  signal ErrorCheck1 : std_logic_vector (1 downto 0);

  type StateName is (Standby, Run, Done, Error);
  signal CurrentState : StateName;

begin

  Product1 <= DataInA * DataInB;

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

    if ((Clk'event) and (Clk = '1')) then

      ----------------------------Synchronous Reset--------------------------------------
      if (Reset = '1') then
        Product2    <= (others => '0');
        SumFeedback <= (others => '0');
        ErrorCheck1 <= "00";
        ValidOut1   <= '0';
        ValidOut2   <= '0';

        CurrentState <= Standby;
        ---------------------------------------------------------------------------------
      else

        case CurrentState is
            ------------------------Standby State----------------------------------
          when Standby =>

            Product2    <= (others => '0');
            SumFeedback <= Sum;
            ValidOut1   <= '0';
            ValidOut2   <= ValidOut1;
            ErrorCheck1 <= "00";

            if (ValidIn = '1') then
              CurrentState <= Run;
            end if;
            -----------------------------------------------------------------------
            --------------------------Run State------------------------------------
          when Run =>

            Product2    <= Product1;
            SumFeedback <= Sum;
            ValidOut1   <= '1';
            ErrorCheck1 <= (Overflow, Underflow);

            if ((Overflow = '1') or (Underflow = '1')) then
              CurrentState <= Error;
              ValidOut2    <= '0';

            else
              ValidOut2 <= ValidOut1;

              if (ValidIn = '1') then
                CurrentState <= Run;
              else
                CurrentState <= Standby;
              end if;
            end if;
            ----------------------------------------------------------------------
            ------------------------Error State-----------------------------------
          when Error             =>
            Product2    <= (others => '0');
            SumFeedback <= Sum;
            ValidOut1   <= '0';
            ValidOut2   <= '0';
            ErrorCheck1 <= ErrorCheck1;

            CurrentState <= Error;
            ----------------------------------------------------------------------
            -------------------------Others---------------------------------------
          when others            =>
            Product2    <= (others => '0');
            SumFeedback <= Sum;
            ValidOut1   <= '0';
            ValidOut2   <= ValidOut1;
            ErrorCheck1 <= "11";

            CurrentState <= Error;
            ----------------------------------------------------------------------
        end case;

      end if;
    end if;

  end process;

end MACUnit1;