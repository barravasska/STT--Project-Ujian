LIBRARY ieee; 
USE ieee.std_logic_1164.all; 
USE ieee.std_logic_arith.all; 
USE ieee.std_logic_unsigned.all;

ENTITY project_ghifary_absen09 IS 
PORT(
    clk, clr: in Std_logic; 
    colk: in std_logic_vector(3 downto   0); 
    s: out std_logic_vector(6 downto 0); 
    rowk, selout: out std_logic_vector(3 downto 0); 
    sw_start: in std_logic; 
    led_g, led_y, led_r: out std_logic;
    lcd_rs, lcd_rw, lcd_en: out std_logic; 
    lcd_d: out std_logic_vector(7 downto 0)
);
END project_ghifary_absen09;

ARCHITECTURE arch OF project_ghifary_absen09 IS
    type main_state is (IDLE, GREEN_ST, YELLOW_ST, RED_ST);
    signal current_st: main_state := IDLE;
    
    signal clk_1hz_en, p_strobe, show_profile, key_lock: std_logic := '0';
    signal blink_cnt, timer_cnt: integer := 0;
    signal key_d, d1, d2: std_logic_vector(3 downto 0) := x"F";
    
    -- Inisialisasi awal penting untuk Anti-Ghosting
    signal scan_clk_cnt: std_logic_vector(16 downto 0) := (others => '0');
    signal sel_cnt: std_logic;
    signal val_tens, val_ones, digit_val: integer range 0 to 15;

    component keybpg PORT(clk: in std_logic; strobe, pck4: out std_logic; col: in std_logic_vector(3 downto 0); row, d: out std_logic_vector(3 downto 0)); END component;
    component lcd_driver PORT(clk, show_abs, sw_start: in std_logic; rs, rw, en: out std_logic; d: out std_logic_vector(7 downto 0)); END component;

BEGIN
    u_key: keybpg port map(clk, p_strobe, open, colk, rowk, key_d);
    u_lcd: lcd_driver port map(clk, show_profile, sw_start, lcd_rs, lcd_rw, lcd_en, lcd_d);

    -- Clock Divider (1Hz untuk Timer, scan_clk_cnt untuk Multiplexing)
    process(clk) variable count: integer := 0; begin if rising_edge(clk) then
        scan_clk_cnt <= scan_clk_cnt + 1; -- Clock super cepat untuk scan 7-segment
        
        if blink_cnt < 25000000 then blink_cnt <= blink_cnt + 1; else blink_cnt <= 0; end if;
        clk_1hz_en <= '0'; 
        if count < 50000000 then count := count + 1; else count := 0; clk_1hz_en <= '1'; end if;
    end if; end process;
    
    sel_cnt <= scan_clk_cnt(16); -- Toggle antara digit 0 dan 1

    -- State Machine Logic Utama
    process(clk, clr) begin 
        if clr='1' then 
            current_st <= IDLE; d1 <= x"F"; d2 <= x"F"; show_profile <= '0'; key_lock <= '0';
        elsif rising_edge(clk) then
            case current_st is
                when IDLE => 
                    led_r <= '0'; led_y <= '0'; led_g <= '0';
                    if p_strobe = '1' and key_lock = '0' then 
                        key_lock <= '1';
                        if key_d = x"A" then 
                            if d1 = x"0" and d2 = x"9" then show_profile <= '1'; end if;
                        elsif key_d <= x"9" then d1 <= d2; d2 <= key_d; end if;
                    elsif p_strobe = '0' then key_lock <= '0'; end if;

                    -- Langsung ke GREEN_ST jika SW ON dan profil aktif
                    if sw_start = '1' and show_profile = '1' then 
                        current_st <= GREEN_ST; timer_cnt <= 5; 
                    end if;
                
                when GREEN_ST => 
                    led_g <= '1'; led_y <= '0'; led_r <= '0';
                    if sw_start = '0' then current_st <= IDLE; end if;
                    if clk_1hz_en = '1' then 
                        if timer_cnt > 0 then timer_cnt <= timer_cnt - 1; 
                        else current_st <= YELLOW_ST; timer_cnt <= 10; end if; 
                    end if;
                
                when YELLOW_ST => 
                    led_g <= '0'; led_r <= '0'; 
                    if sw_start = '0' then current_st <= IDLE; end if;
                    if blink_cnt < 12500000 then led_y <= '1'; else led_y <= '0'; end if;
                    if clk_1hz_en = '1' then 
                        if timer_cnt > 0 then timer_cnt <= timer_cnt - 1; 
                        else current_st <= RED_ST; timer_cnt <= 8; end if; 
                    end if;
                
                when RED_ST => 
                    led_g <= '0'; led_y <= '0'; led_r <= '1';
                    if sw_start = '0' then current_st <= IDLE; end if;
                    if clk_1hz_en = '1' then 
                        if timer_cnt > 0 then timer_cnt <= timer_cnt - 1; 
                        else current_st <= GREEN_ST; timer_cnt <= 5; end if; 
                    end if;
                when others => current_st <= IDLE;
            end case;
        end if; 
    end process;

    -- Logika Penentuan Angka untuk Puluhan dan Satuan
    process(current_st, show_profile, timer_cnt) begin
        if current_st = IDLE then
            if show_profile = '1' then
                val_tens <= 0; val_ones <= 9; -- Tampil 09 saat IDLE setelah login
            else
                val_tens <= 15; val_ones <= 15; -- Blank jika belum login
            end if;
        else
            if timer_cnt = 10 then
                val_tens <= 1; val_ones <= 0; -- Tampil 10
            else
                val_tens <= 15; val_ones <= timer_cnt; -- Blank di puluhan, angka di satuan
            end if;
        end if;
    end process;

    -- Multiplexer Output ke 7-Segment (Versi Synchronous, Anti-Ghosting & Active HIGH)
    process(clk) begin
        if rising_edge(clk) then
            if sel_cnt = '1' then
                -- Jeda sebentar mematikan layar (Blanking - semua digit dikasih 0)
                if scan_clk_cnt(15 downto 14) = "00" then
                    selout <= "0000"; 
                else
                    selout <= "0010"; -- Aktifkan Digit 1 (Puluhan) dengan logika 1
                    digit_val <= val_tens;
                end if;
            else
                -- Jeda sebentar mematikan layar (Blanking)
                if scan_clk_cnt(15 downto 14) = "00" then
                    selout <= "0000";
                else
                    selout <= "0001"; -- Aktifkan Digit 0 (Satuan) dengan logika 1
                    digit_val <= val_ones;
                end if;
            end if;
        end if;
    end process;

    -- Decoder 7-Segment (Versi Active HIGH / Common Cathode)
    -- Logika: 1 = Nyala, 0 = Mati
    s <= "0111111" when digit_val = 0 else 
         "0000110" when digit_val = 1 else
         "1011011" when digit_val = 2 else 
         "1001111" when digit_val = 3 else
         "1100110" when digit_val = 4 else 
         "1101101" when digit_val = 5 else
         "1111101" when digit_val = 6 else 
         "0000111" when digit_val = 7 else
         "1111111" when digit_val = 8 else 
         "1101111" when digit_val = 9 else 
         "0000000"; -- Blank (Semua lampu mati dikasih 0)
END arch;