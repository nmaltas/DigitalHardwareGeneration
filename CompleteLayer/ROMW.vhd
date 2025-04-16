library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ROMW is

  generic (
    DataWidth : integer := 8;
    Columns   : integer := 4;

    -- These memory slots need to be hardcoded. HLS will have to deal with this.
    Slot00 : integer := 1;
    Slot01 : integer := 2;
    Slot02 : integer := 3;
    Slot03 : integer := 4;
    Slot10 : integer := 5;
    Slot11 : integer := 6;
    Slot12 : integer := 7;
    Slot13 : integer := 8;
    Slot20 : integer := 9;
    Slot21 : integer := 10;
    Slot22 : integer := 11;
    Slot23 : integer := 12);

  port (
    Address : in integer range 0 to (Columns - 1);
    Enable  : in std_logic;
    Clk     : in std_logic;

    -- One output port is needed for each Row in order to support full parallelization.
    -- Number of output ports has to be hardcoded. HLS will have to deal with this.
    DataOut0 : out signed ((DataWidth - 1) downto 0);
    DataOut1 : out signed ((DataWidth - 1) downto 0);
    DataOut2 : out signed ((DataWidth - 1) downto 0)
  );
end ROMW;

architecture ROMW1 of ROMW is
  type MemoryArray is array ((Columns - 1) downto 0) of signed ((DataWidth - 1) downto 0);

  -- Hardcoded by HLS
  signal Row0 : MemoryArray;
  signal Row1 : MemoryArray;
  signal Row2 : MemoryArray;

begin

  -- Values are assigned to the arrays here.

  -- Hardcoded by HLS.
  Row0(0) <= to_signed(Slot00, DataWidth);
  Row0(1) <= to_signed(Slot01, DataWidth);
  Row0(2) <= to_signed(Slot02, DataWidth);
  Row0(3) <= to_signed(Slot03, DataWidth);

  Row1(0) <= to_signed(Slot10, DataWidth);
  Row1(1) <= to_signed(Slot11, DataWidth);
  Row1(2) <= to_signed(Slot12, DataWidth);
  Row1(3) <= to_signed(Slot13, DataWidth);

  Row2(0) <= to_signed(Slot20, DataWidth);
  Row2(1) <= to_signed(Slot21, DataWidth);
  Row2(2) <= to_signed(Slot22, DataWidth);
  Row2(3) <= to_signed(Slot23, DataWidth);

  process (Clk) is
  begin
    if ((Clk'event) and (Clk = '1')) then

      -- Only output when Enable is asserted.
      if (Enable = '1') then

        -- Guarding against Invalid Address values.
        if (Address < Columns) then
          DataOut0 <= Row0(Address);
          DataOut1 <= Row1(Address);
          DataOut2 <= Row2(Address);
        else
          DataOut0 <= (others => '1');
          DataOut1 <= (others => '1');
          DataOut2 <= (others => '1');
        end if;

      else
        DataOut0 <= (others => 'Z');
        DataOut1 <= (others => 'Z');
        DataOut2 <= (others => 'Z');
      end if;
    end if;
  end process;
end ROMW1;
