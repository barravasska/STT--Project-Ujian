LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY debounceg IS
    PORT(clk, key_pressed: IN STD_LOGIC; pulse: OUT STD_LOGIC);
END debounceg;

ARCHITECTURE arch OF debounceg IS
    SIGNAL count: STD_LOGIC_VECTOR(15 downto 0);
BEGIN
    process(clk) begin
        if rising_edge(clk) then
            if key_pressed = '1' then count <= (others => '1');
            elsif count /= 0 then count <= count - 1; end if;
        end if;
    end process;
    pulse <= '1' when count = 1 else '0';
END arch;