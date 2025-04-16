library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity ROMB is

  generic (
    DataWidth : integer := 8;

    -- Memory slots have to be hardcodded. HLS will deal with this.
    Slot0 : integer := 0;
    Slot1 : integer := 1;
    Slot2 : integer := 2);

  port (
    Enable : in std_logic;
    Clk    : in std_logic;

    -- Each Row/value needs a separate output port.
    -- Number of output ports has to be hardcoded. HLS will have to deal with this.
    DataOut0 : out signed ((DataWidth - 1) downto 0);
    DataOut1 : out signed ((DataWidth - 1) downto 0);
    DataOut2 : out signed ((DataWidth - 1) downto 0)
  );
end ROMB;

architecture ROMB1 of ROMB is

  -- Hardcoded by HLS.
  signal MemSlot0 : signed ((DataWidth - 1) downto 0);
  signal MemSlot1 : signed ((DataWidth - 1) downto 0);
  signal MemSlot2 : signed ((DataWidth - 1) downto 0);

begin

  -- Values are assigned to the signals here.
  -- Hardcoded by HLS.
  MemSlot0 <= to_signed(Slot0, MemSlot0'length);
  MemSlot1 <= to_signed(Slot1, MemSlot1'length);
  MemSlot2 <= to_signed(Slot2, MemSlot2'length);

  process (Clk) is
  begin
    if ((Clk'event) and (Clk = '1')) then

      -- Only output when Enable is asserted.
      if (Enable = '1') then
        DataOut0 <= MemSlot0;
        DataOut1 <= MemSlot1;
        DataOut2 <= MemSlot2;

      else
        DataOut0 <= (others => 'Z');
        DataOut1 <= (others => 'Z');
        DataOut2 <= (others => 'Z');
      end if;
    end if;
  end process;

end ROMB1;