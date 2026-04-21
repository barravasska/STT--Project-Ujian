LIBRARY ieee; 
USE ieee.std_logic_1164.all; 
USE ieee.std_logic_unsigned.all;

ENTITY lcd_driver IS 
    PORT(clk, show_abs, sw_start:in std_logic; rs, rw, en:out std_logic; d:out std_logic_vector(7 downto 0)); 
END lcd_driver;

ARCHITECTURE behavior OF lcd_driver IS
    type state_t is (POWER_UP, INIT, REFRESH_WAIT, SEND_CHAR); 
    signal state: state_t := POWER_UP;
    signal delay_cnt: integer := 0; 
    signal init_step: integer range 0 to 7 := 0; 
    signal char_index: integer range 0 to 69 := 0;
    signal saved_show_abs: std_logic := '0';
    signal saved_sw_start: std_logic := '0';
    type char_array is array (0 to 67) of std_logic_vector(7 downto 0);
    
    constant text_def : char_array := (
        x"80", x"57",x"45",x"4C",x"43",x"4F",x"4D",x"45",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20", -- Welcome
        x"90", x"50",x"4F",x"4C",x"4D",x"41",x"4E",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20", -- POLMAN
        x"88", x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
        x"98", x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20"
    );

    constant text_abs : char_array := (
        x"80", x"57",x"45",x"4C",x"43",x"4F",x"4D",x"45",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
        x"90", x"50",x"4F",x"4C",x"4D",x"41",x"4E",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
        x"88", x"47",x"48",x"49",x"46",x"41",x"52",x"59",x"20",x"42",x"41",x"52",x"52",x"41",x"20",x"56",x"20", -- GHIFARY BARRA V
        x"98", x"32",x"32",x"34",x"34",x"34",x"33",x"30",x"33",x"32",x"20",x"20",x"20",x"20",x"20",x"20",x"20"  -- 224443032
    );
BEGIN
    rw <= '0';
    process(clk) begin 
        if rising_edge(clk) then
            case state is
                when POWER_UP => 
                    if delay_cnt < 15000000 then delay_cnt <= delay_cnt + 1; en <= '0'; 
                    else delay_cnt <= 0; state <= INIT; end if;
                
                when INIT => 
                    if delay_cnt = 0 then rs <= '0';
                        case init_step is 
                            when 0=>d<=x"30"; when 1=>d<=x"0C"; when 2=>d<=x"01"; when 3=>d<=x"06"; 
                            when others=>state<=REFRESH_WAIT; char_index<=0; 
                        end case; 
                        en <= '1'; delay_cnt <= delay_cnt + 1;
                    elsif delay_cnt = 2000 then en <= '0'; delay_cnt <= delay_cnt + 1; 
                    elsif delay_cnt = 1000000 then delay_cnt <= 0; init_step <= init_step + 1; 
                    else delay_cnt <= delay_cnt + 1; end if;
                
when REFRESH_WAIT => 
                if char_index < 68 then 
                    if char_index=0 or char_index=17 or char_index=34 or char_index=51 then 
                        rs <= '0'; d <= text_def(char_index); -- Mengirim command pindah baris
                    else 
                        rs <= '1'; -- Mengirim data/karakter
                        
                        -- REVISI LCD MATI: 
                        -- Timpa semua huruf dengan SPASI (x"20") jika saklar ON
                        if sw_start = '1' then 
                            d <= x"20"; 
                        elsif show_abs='1' then 
                            d <= text_abs(char_index); 
                        else 
                            d <= text_def(char_index); 
                        end if;
                    end if;
                    
                    en <= '1'; delay_cnt <= 0; state <= SEND_CHAR;
                else 
                    if (saved_show_abs /= show_abs) or (saved_sw_start /= sw_start) then 
                        saved_show_abs <= show_abs; saved_sw_start <= sw_start; char_index <= 0; 
                    end if; 
                end if;
                    
                when SEND_CHAR => 
                    if delay_cnt = 2000 then en <= '0'; delay_cnt <= delay_cnt + 1;
                    elsif delay_cnt = 200000 then delay_cnt <= 0; char_index <= char_index + 1; state <= REFRESH_WAIT; 
                    else delay_cnt <= delay_cnt + 1; end if;
            end case;
        end if; 
    end process;
END behavior;