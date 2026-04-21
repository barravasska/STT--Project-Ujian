# 🚦 Traffic Light Controller with Keypad & LCD — FPGA (Altera Cyclone)

> **Proyek Ujian Sistem Digital** — Simulasi Lampu Lalu Lintas dengan Autentikasi Keypad dan Tampilan LCD  
> Dibuat oleh **Ghifary Barra V** | Absen **09** | NIM **224443032** — POLMAN

---

## 📋 Deskripsi

Proyek ini mengimplementasikan sistem **traffic light controller** pada FPGA **Altera Cyclone EP1C12Q240C8** menggunakan bahasa **VHDL**. Sistem ini mensimulasikan lampu lalu lintas (hijau, kuning, merah) yang dilengkapi dengan fitur:

- **Keypad 4x4** sebagai input nomor absen
- **LCD 16x4** untuk menampilkan pesan selamat datang dan identitas
- **7-Segment Display (2 digit)** untuk countdown timer
- **LED Indikator** (hijau, kuning, merah)
- **Autentikasi**: Sistem hanya aktif setelah memasukkan nomor absen yang benar (`09`) melalui keypad dan menekan tombol `A` (konfirmasi)

---

## 🏗️ Arsitektur Sistem

```
┌──────────────┐      ┌──────────────────────────────┐      ┌────────────────┐
│  Keypad 4x4  │─────►│   Top-Level Entity           │─────►│  LCD 16x4      │
│  (colk/rowk) │      │  project_ghifary_absen09      │      │  (lcd_d/rs/rw) │
└──────────────┘      │                              │      └────────────────┘
                      │  ┌─────────────────────────┐ │      ┌────────────────┐
┌──────────────┐      │  │  State Machine:          │ │─────►│  7-Segment x2  │
│  sw_start    │─────►│  │  IDLE → GREEN → YELLOW  │ │      │  (s/selout)    │
│  (switch)    │      │  │       → RED → GREEN...  │ │      └────────────────┘
└──────────────┘      │  └─────────────────────────┘ │      ┌────────────────┐
                      │                              │─────►│  LED G/Y/R     │
┌──────────────┐      │                              │      └────────────────┘
│  clk (50MHz) │─────►│                              │
│  clr (reset) │─────►│                              │
└──────────────┘      └──────────────────────────────┘
```

---

## ⚙️ State Machine (FSM)

Sistem bekerja menggunakan **Finite State Machine** dengan 4 state:

| State | Durasi | LED Aktif | Keterangan |
|:------|:------:|:---------:|:-----------|
| `IDLE` | — | Semua OFF | Menunggu input keypad & switch |
| `GREEN_ST` | 5 detik | 🟢 Hijau | Lampu hijau menyala |
| `YELLOW_ST` | 10 detik | 🟡 Kuning (berkedip) | Lampu kuning berkedip 2Hz |
| `RED_ST` | 8 detik | 🔴 Merah | Lampu merah menyala |

### Alur Kerja

1. **IDLE** — Pengguna memasukkan nomor absen `09` via keypad, lalu tekan `A` untuk konfirmasi
2. LCD menampilkan identitas (nama & NIM)
3. Aktifkan `sw_start` (switch ON) → Sistem masuk ke **GREEN_ST**
4. Siklus berjalan secara otomatis: `GREEN → YELLOW → RED → GREEN → ...`
5. Matikan `sw_start` kapan saja untuk kembali ke **IDLE**

---

## 📂 Struktur File

```
Ujian/
├── project_ghifary_absen09.vhd   # Top-level entity (FSM, clock divider, 7-segment)
├── lcd_driver.vhd                # Driver LCD 16x4 (tampilan teks)
├── keybpg.vhd                    # Keypad scanner (scanning 4x4 matrix)
├── keypad_logic.vhd              # Logika pendukung keypad (decoder, selector, key press)
├── debounceg.vhd                 # Debounce filter untuk keypad
├── project_ghifary_absen09.qpf   # Quartus Project File
├── project_ghifary_absen09.qsf   # Quartus Settings File (pin assignments)
├── project_ghifary_absen09.sof   # SRAM Object File (programming file)
├── project_ghifary_absen09.pof   # Programmer Object File (flash programming)
└── README.md                     # Dokumentasi proyek
```

---

## 🧩 Modul VHDL

### 1. `project_ghifary_absen09` — Top-Level Entity
- **Clock divider**: Menghasilkan sinyal 1Hz dari clock 50MHz untuk countdown timer
- **State machine**: Mengontrol transisi antar state lampu lalu lintas
- **Keypad handler**: Menerima input 2 digit dan validasi terhadap absen `09`
- **7-Segment multiplexer**: Mengemudikan 2 digit 7-segment secara bergantian dengan teknik *anti-ghosting*
- **7-Segment decoder**: Konversi BCD ke pola segment (Active HIGH / Common Cathode)

### 2. `lcd_driver` — Driver LCD
- Menginisialisasi LCD dengan urutan perintah standar
- Menampilkan teks **"WELCOME POLMAN"** saat idle
- Menampilkan **"GHIFARY BARRA V"** dan **"224443032"** setelah autentikasi berhasil
- LCD dibersihkan (blank) saat lampu lalu lintas berjalan (`sw_start = '1'`)

### 3. `keybpg` — Keypad Scanner
- Melakukan scanning matrix keypad 4x4 menggunakan counter dan multiplexer
- Menggunakan modul `debounceg` untuk menghilangkan bounce pada tombol

### 4. `keypad_logic` — Komponen Pendukung Keypad
- **`decod4`**: 2-to-4 decoder untuk scan baris keypad
- **`sel4`**: 4-to-1 multiplexer untuk membaca kolom keypad
- **`keyps4`**: Detektor penekanan tombol dengan debounce lanjutan

### 5. `debounceg` — Debounce Filter
- Filter bouncing mekanis tombol keypad menggunakan counter 16-bit
- Menghasilkan pulsa bersih saat counter mencapai 1

---

## 📌 Pin Assignment (FPGA EP1C12Q240C8)

| Sinyal | Pin FPGA | Keterangan |
|:-------|:--------:|:-----------|
| `clk` | PIN_28 | Clock input 50MHz |
| `clr` | PIN_1 | Reset (active high) |
| `sw_start` | PIN_46 | Switch start traffic light |
| `s[6:0]` | PIN_11–17 | 7-Segment segments |
| `selout[3:0]` | PIN_131–134 | 7-Segment digit select |
| `colk[3:0]` | PIN_168–173 | Keypad column input |
| `rowk[3:0]` | PIN_164–167 | Keypad row output |
| `lcd_d[7:0]` | PIN_180–187 | LCD data bus |
| `lcd_rs` | PIN_193 | LCD register select |
| `lcd_rw` | PIN_188 | LCD read/write |
| `lcd_en` | PIN_197 | LCD enable |
| `led_g` | PIN_124 | LED hijau |
| `led_y` | PIN_201 | LED kuning |
| `led_r` | PIN_163 | LED merah |

---

## 🔧 Tools & Requirements

| Tool | Versi |
|:-----|:------|
| **Quartus II** | 9.0 SP2 (Web Edition) |
| **FPGA Device** | Altera Cyclone EP1C12Q240C8 |
| **Bahasa** | VHDL |
| **I/O Standard** | 3.3V LVTTL |

---

## 🚀 Cara Menggunakan

1. **Buka project** di Quartus II:
   ```
   File → Open Project → project_ghifary_absen09.qpf
   ```

2. **Compile** project:
   ```
   Processing → Start Compilation
   ```

3. **Program FPGA** menggunakan file `.sof` (SRAM) atau `.pof` (Flash):
   ```
   Tools → Programmer → Add File → project_ghifary_absen09.sof → Start
   ```

4. **Operasikan sistem**:
   - Masukkan `0` lalu `9` pada keypad
   - Tekan tombol `A` untuk konfirmasi → LCD menampilkan identitas
   - Aktifkan switch `sw_start` → Lampu lalu lintas mulai berjalan
   - 7-Segment menampilkan countdown timer
   - Matikan switch untuk menghentikan sistem

---

## 📊 Resource Utilization

| Resource | Used | Available | Utilization |
|:---------|-----:|----------:|:-----------:|
| Logic Elements | 450 | 12,060 | 4% |
| Pins | 36 | 173 | 21% |
| Memory Bits | 0 | 239,616 | 0% |
| PLLs | 0 | 2 | 0% |

---

## 📝 Catatan

- Sistem menggunakan clock **50MHz** (asumsi board Altera Cyclone standar)
- **Anti-ghosting** pada 7-segment display diterapkan dengan blanking period untuk mencegah bayangan digit
- Lampu kuning berkedip dengan frekuensi ±2Hz menggunakan counter `blink_cnt`
- Autentikasi bersifat sederhana — hanya memeriksa apakah 2 digit terakhir = `09`

---

## 👤 Author

**Ghifary Barra V**  
NIM: 224443032 | Absen: 09  
Politeknik Manufaktur (POLMAN)

---

<p align="center"><i>Proyek Ujian Sistem Digital — FPGA Traffic Light Controller</i></p>
