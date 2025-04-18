library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity MemoryModule is

  generic (
    DataWidth : integer := 8;
    MemSize   : integer := 20);

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
