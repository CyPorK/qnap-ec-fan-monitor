# CLAUDE.md — qnap-ec-fan-monitor

## Project

Linux hwmon driver + fan control + live dashboard for QNAP TVS-h1288X running Proxmox VE.
Public GitHub repo: https://github.com/CyPorK/qnap-ec-fan-monitor

## Environment

The driver runs on the **PVE host** (not inside a VM). Development may happen on a separate machine with the repo cloned on both.

Sudo on the PVE host requires a password — use `ssh -t` for interactive sudo commands.

## Key files

| File | Purpose |
|---|---|
| `qnap-ec.c` | Kernel module source (IT8528 hwmon driver) |
| `qnap-monitor` | Live terminal dashboard (bash) |
| `fancontrol` | fancontrol config (temp→PWM curves) |
| `qnap-ec.conf` | modprobe config (`sim_pwm_enable=yes`) |
| `install.sh` | Full install script (driver + fancontrol + qnap-monitor) |
| `PROJECT.md` | Sensor map, channel mapping, installation details |

## Deploying to PVE host

After any change, update the host:

```bash
# Pull repo on host and reinstall qnap-monitor
ssh -t <pve-host> "cd ~/qnap-ec-fan-monitor && git pull && sudo install -m 755 qnap-monitor /usr/local/bin/qnap-monitor"

# After kernel module changes — full rebuild:
ssh -t <pve-host> "cd ~/qnap-ec-fan-monitor && git pull && sudo make install && sudo systemctl restart fancontrol"
```

## Commit language

English. Use Conventional Commits (see global git rules).
