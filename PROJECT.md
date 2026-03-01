# QNAP-EC na TVS-h1288X + Proxmox VE

## Co zostało zrobione

### Problem wyjściowy
QNAP TVS-h1288X z zainstalowanym Proxmox VE nie miał dostępu do sensorów
embedded controllera IT8528 — brak odczytu prędkości wentylatorów i sterowania PWM.

### Rozwiązanie
Zainstalowano sterownik [QNAP-EC](https://github.com/Stonyx/QNAP-EC) (Stonyx)
— otwartoźródłowy moduł kernela dla układu IT8528.

### Środowisko
- **Sprzęt**: QNAP TVS-h1288X, Intel Xeon W-1250, EC chip: ITE IT8528
- **System**: Proxmox VE, Debian 12.10, kernel `6.8.12-9-pve`
- **Host PVE**: `<pve-host>`

### Przebieg instalacji

1. **Analiza kodu źródłowego** — weryfikacja bezpieczeństwa sterownika
2. **Wykrycie architektury** — ustalenie, że sterownik musi działać na hoście PVE,
   nie wewnątrz VM
3. **Instalacja zależności** na hoście PVE:
   ```
   sudo apt install pve-headers-$(uname -r) gcc make
   ```
4. **Kompilacja i instalacja**:
   ```
   sudo make install
   ```
5. **Weryfikacja** — moduł załadował się, chip IT8528 wykryty automatycznie
6. **Autostart** — dodano `qnap-ec` do `/etc/modules`

### Kluczowe odkrycie
Biblioteka `libuLinux_hal.so` dołączona do repo (pobrana z QNAP TS-873A)
**działa poprawnie** na TVS-h1288X bez żadnych modyfikacji.
Możliwe dlatego, że obie platformy używają tego samego układu IT8528 i
zależności od QTS-specyficznych plików (`/etc/model.conf`) są zamockowane
w helperze przez flagę `-export-dynamic`.

---

## Aktywne sensory

Urządzenie `qnap_ec` (`/sys/class/hwmon/hwmon19/`) — numer `hwmon19` może się zmienić po restarcie.
Wykryj dynamicznie: `grep -rl qnap_ec /sys/class/hwmon/*/name | head -1 | xargs dirname`

### Temperatury
| Sensor | Kanał EC | Typowa wartość | Opis |
|---|---|---|---|
| temp1_input | EC #1 | ~67°C | CPU zone (thermistor EC przy CPU) |
| temp6_input | EC #6 | ~35°C | Strefa dysków |
| temp7_input | EC #7 | ~35°C | Strefa dysków 2 |
| temp8_input | EC #8 | ~20°C | Ambient / wlot powietrza |

### Wentylatory
| Sensor | Kanał EC | Typowa wartość | Opis |
|---|---|---|---|
| fan1_input | EC fan1 | ~1900 RPM | Wentylator chassis 1 |
| fan2_input | EC fan2 | ~1900 RPM | Wentylator chassis 2 |
| fan3_input | EC fan3 | ~1875 RPM | Wentylator chassis 3 |
| fan4_input | EC fan4 | ~1880 RPM | Wentylator chassis 4 |
| fan7_input | EC fan7 | ~750 RPM | Wentylator CPU 1 |
| fan8_input | EC fan8 | ~720 RPM | Wentylator CPU 2 |

### PWM (sterowanie)
| Sensor | Wartość (0-255) | Duty cycle | Steruje |
|---|---|---|---|
| pwm1 | 102 | ~40% | fan1-4 (chassis) |
| pwm7 | 73 | ~29% | fan7-8 (CPU) |

---

## Zainstalowane pliki

| Plik | Lokalizacja | Opis |
|---|---|---|
| `qnap-ec.ko` | `/lib/modules/6.8.12-9-pve/updates/` | Moduł kernela |
| `qnap-ec` | `/usr/local/sbin/` | Helper (user-space bridge) |
| `libuLinux_hal.so` | `/usr/local/lib/` | Biblioteka QNAP (z TS-873A) |
| `qnap-ec.conf` | `/etc/modprobe.d/` | Parametry modułu (`sim_pwm_enable=yes`) |
| `fancontrol` | `/etc/fancontrol` | Konfiguracja sterowania wentylatorami |
| `qnap-monitor` | `/usr/local/bin/` | Live dashboard termiczny (bash) |

Autostart: wpis `qnap-ec` w `/etc/modules`; `fancontrol` jako serwis systemd.

---

## TODO

### 1. Fancontrol — automatyczne sterowanie wentylatorami ✅ GOTOWE

Zainstalowane i działające od 2026-02-28.

#### Pliki konfiguracyjne
- `/etc/modprobe.d/qnap-ec.conf` — włącza `sim_pwm_enable=yes` (wymagane przez fancontrol)
- `/etc/fancontrol` — krzywe temp→PWM
- `fancontrol/install.sh` — skrypt instalacyjny (do ponownego użycia po reinstalacji)

#### Mapowanie kanałów
| PWM | Sensor sterujący | Min temp | Max temp | Min PWM | Max PWM |
|---|---|---|---|---|---|
| pwm1 (fan1-4, chassis) | temp6_input (dyski) | 30°C | 50°C | 80/255 | 255/255 |
| pwm7 (fan7-8, CPU) | temp1_input (CPU zone) | 45°C | 85°C | 60/255 | 255/255 |

#### Przykładowe wartości w działaniu
- Dyski 32°C → chassis fans ~1800 RPM (37% PWM)
- CPU zone 79°C → CPU fans ~2330 RPM (80% PWM)

#### Przywracanie po aktualizacji kernela
Po każdej aktualizacji PVE kernel należy przebudować moduł:
```bash
cd ~/QNAP-EC && sudo make install
sudo systemctl restart fancontrol
```

### 2. Live dashboard — qnap-monitor ✅ GOTOWE

Plik: `fancontrol/qnap-monitor` (bash, instalacja: `/usr/local/bin/qnap-monitor`)

Dashboard odświeżany co N sekund (domyślnie 2s), pokazuje:
- temperatury CPU (Package + per-core) z paskami `█░`
- obciążenie każdego wątku HT (cpu0+cpu6, cpu1+cpu7, …)
- temperatury EC Chip (CPU zone, dyski, ambient)
- prędkości wentylatorów + aktualny PWM%
- top 5 najgorętszych dysków
- status serwisu fancontrol

```bash
qnap-monitor        # co 2s
qnap-monitor 5      # co 5s
q                   # wyjście
```

Hwmon wykrywane dynamicznie po nazwie (`qnap_ec`, `coretemp`) —
odporne na zmiany numeracji po aktualizacji kernela.

### 3. Monitoring długoterminowy — Grafana + node_exporter

Cel: wykresy temperatur, RPM i PWM w czasie.

```bash
# Na hoście PVE — node_exporter eksponuje /sys/class/hwmon/*
sudo apt install prometheus-node-exporter
# Metryki: http://<pve-host>:9100/metrics  (node_hwmon_*)
```

Dashboard Grafana: importuj ID `1860` (Node Exporter Full).

### 4. Identyfikacja nieaktywnych kanałów

Kanały EC które nie zwróciły danych (temp2-5, fan5-6):
- Mogą odpowiadać nieobecnym czujnikom (np. dodatkowe klatki)
- Warto sprawdzić z parametrem `val_pwm_channels=n`:
  ```bash
  sudo modprobe -r qnap-ec
  sudo modprobe qnap-ec val_pwm_channels=n
  ```

### 5. Aktualizacja libuLinux_hal.so (opcjonalnie)

Jeśli pojawią się problemy z odczytami — można spróbować wyciągnąć
natywną bibliotekę z firmware TVS-h1288X:

```bash
sudo apt install binwalk squashfs-tools
# Pobierz firmware TVS-h1288X z support.qnap.com
binwalk TVS-h1288X_*.img
# Wyciągnij squashfs i znajdź /usr/lib/libuLinux_hal.so
```
