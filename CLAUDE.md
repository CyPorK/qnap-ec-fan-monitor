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
# Pull repo on host and reinstall qnap-monitor (with version embedding)
ssh -t <pve-host> "cd ~/qnap-ec-fan-monitor && git pull && VER=\$(git describe --tags --always 2>/dev/null || echo dev) && sed \"s/@VERSION@/\$VER/g\" qnap-monitor | sudo tee /usr/local/bin/qnap-monitor > /dev/null && sudo chmod 755 /usr/local/bin/qnap-monitor"

# After kernel module changes — full rebuild:
ssh -t <pve-host> "cd ~/qnap-ec-fan-monitor && git pull && sudo make install && sudo systemctl restart fancontrol"
```

## Sensitive data — never commit

- Real IP addresses or hostnames (use `<pve-host>` as placeholder in docs)
- Usernames specific to a machine
- Passwords, tokens, API keys
- Local file paths specific to a single machine

## Commit language

English. Use Conventional Commits (see global git rules).
