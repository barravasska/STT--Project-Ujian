LIBRARY ieee; USE ieee.std_logic_1164.all;
ENTITY decod4 IS PORT(a,b:in Std_logic; d0,d1,d2,d3:out Std_logic); END decod4;
ARCHITECTURE arch OF decod4 IS BEGIN
    d0 <= not a and not b; d1 <= a and not b; d2 <= not a and b; d3 <= a and b;
END arch;

LIBRARY ieee; USE ieee.std_logic_1164.all;
ENTITY sel4 IS PORT(s:in Std_logic_vector(1 downto 0); d:in Std_logic_vector(3 downto 0); y:out std_logic); END sel4;
ARCHITECTURE arch OF sel4 IS BEGIN
    y <= d(0) when s="00" else d(1) when s="01" else d(2) when s="10" else d(3) when s="11" else 'Z';
END arch;

LIBRARY ieee; USE ieee.std_logic_1164.all; USE ieee.std_logic_unsigned.all;
ENTITY keyps4 IS PORT(kb,clk:in Std_logic; ps,ltdp:out Std_logic); END keyps4;
ARCHITECTURE arch OF keyps4 IS 
    signal stk: std_logic_vector(2 downto 0) := "000"; 
    signal stdp: std_logic_vector(1 downto 0) := "00"; 
BEGIN
    ltdp <= stdp(0); ps <= stk(0);
    process(clk) begin if rising_edge(clk) then
        case stdp is 
            when "00" => if kb='1' then stdp <= "01"; end if;
            when "01" => stdp <= "10";
            when "10" => if kb='0' then stdp <= "00"; end if;
            when others => stdp <= "00";
        end case;
        case stk is 
            when "000" => if stdp(0)='1' then stk <= "001"; end if;
            when "111" => if stdp(0)='0' then stk <= "000"; end if;
            when others => stk <= stk + 1;
        end case;
    end if; end process;
END arch;