#!/usr/bin/env bash
# ==============================================================================
# Cosmic Byte Ares Pro — Uninstaller Script
# Restores original system configuration and removes all overrides.
# ==============================================================================

set -e

KVER="$(uname -r)"

if [ "$EUID" -ne 0 ]; then
    echo "[*] Requesting sudo rights to remove system components..."
    sudo -v
fi

echo "[1/4] Disabling and removing boot service..."
sudo systemctl stop usbcore-quirks.service 2>/dev/null || true
sudo systemctl disable usbcore-quirks.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/usbcore-quirks.service
sudo systemctl daemon-reload

echo "[2/4] Removing udev rules..."
sudo rm -f /etc/udev/rules.d/70-cosmicbyte-ares.rules /etc/udev/rules.d/70-ares-gamesir.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "[3/4] Removing custom xpad module override..."
sudo rm -f "/lib/modules/$KVER/updates/xpad.ko*"
sudo depmod -a "$KVER"
sudo rmmod xpad 2>/dev/null || true
sudo modprobe xpad

echo "[4/4] Removing command-line shortcuts..."
sudo rm -f /usr/local/bin/ares-ctl /usr/local/bin/ares-exam /usr/local/bin/ares-rumble-test

echo ""
echo "[✔] Uninstallation complete! System restored to factory defaults."
