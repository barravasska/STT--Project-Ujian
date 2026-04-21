LIBRARY ieee,lpm; USE lpm.lpm_components.all; USE ieee.std_logic_1164.all;

ENTITY keybpg IS 
    PORT(clk:in std_logic; strobe, pck4: out std_logic; col: in std_logic_vector(3 downto 0); row, d: out std_logic_vector(3 downto 0)); 
END keybpg;

ARCHITECTURE arch OF keybpg IS
    SIGNAL key_pressed, ltd, cin: std_logic; SIGNAL dlt: std_logic_vector(3 downto 0);
    component debounceg port(clk, key_pressed: IN STD_LOGIC; pulse: OUT STD_LOGIC); end component;
    component decod4 PORT(a,b:in Std_logic; d0,d1,d2,d3:out Std_logic); end component;
    component sel4 PORT(s:in Std_logic_vector(1 downto 0); d:in Std_logic_vector(3 downto 0); y:out std_logic); end component;
    component keyps4 port(kb,clk:in Std_logic; ps,ltdp:out Std_logic); end component;
BEGIN
    cin <= not key_pressed; 
    count4: lpm_counter generic map(lpm_width => 4) port map(clock => clk, q => dlt, cnt_en => cin);
    u0: debounceg port map(clk, cin, ltd); 
    u1: sel4 port map(dlt(1 downto 0), col, key_pressed);
    u2: decod4 port map(dlt(2), dlt(3), row(3), row(2), row(1), row(0)); 
    u3: keyps4 port map(ltd, clk, pck4, strobe);
    process(clk) begin if rising_edge(clk) then if ltd='1' then d <= dlt; end if; end if; end process;
END arch;