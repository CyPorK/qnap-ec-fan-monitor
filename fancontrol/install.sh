#!/bin/bash
# Instalacja fancontrol dla QNAP TVS-h1288X + PVE
# Uruchom jako: sudo bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 1. Instalacja pakietu fancontrol ==="
apt-get install -y fancontrol

echo ""
echo "=== 2. Konfiguracja modprobe (sim_pwm_enable) ==="
cp "$SCRIPT_DIR/qnap-ec.conf" /etc/modprobe.d/qnap-ec.conf
echo "Zapisano: /etc/modprobe.d/qnap-ec.conf"

echo ""
echo "=== 3. Przeładowanie modułu qnap-ec z sim_pwm_enable=yes ==="
modprobe -r qnap-ec
modprobe qnap-ec sim_pwm_enable=yes
sleep 1

echo ""
echo "=== 4. Weryfikacja pwm_enable ==="
for pwm in pwm1_enable pwm7_enable; do
    val=$(cat /sys/class/hwmon/hwmon19/$pwm 2>/dev/null || echo "BRAK")
    echo "  $pwm = $val"
done

echo ""
echo "=== 5. Instalacja konfiguracji fancontrol ==="
cp "$SCRIPT_DIR/fancontrol" /etc/fancontrol
echo "Zapisano: /etc/fancontrol"

echo ""
echo "=== 6. Uruchomienie serwisu ==="
systemctl enable fancontrol
systemctl start fancontrol
sleep 2
systemctl status fancontrol --no-pager

echo ""
echo "=== 7. Test odczytu wentylatorów ==="
for fan in fan1_input fan2_input fan3_input fan4_input fan7_input fan8_input; do
    rpm=$(cat /sys/class/hwmon/hwmon19/$fan 2>/dev/null || echo "?")
    echo "  $fan: $rpm RPM"
done
