#!/usr/bin/env bash
# ==============================================================================
# Cosmic Byte Ares Pro & GameSir Cyclone — Master Linux Installer
# Configures persistent XInput (Yellow LED) mode, Force-Feedback, and custom naming.
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVER="$(uname -r)"
UPDATES_DIR="/lib/modules/$KVER/updates"
QUIRKS="045e:02fd:r,3537:0575:r,3537:100b:r,3537:1052:r,3537:1053:r,20bc:5001:r,2563:0575:r,2563:028e:r,2c16:a2b3:r"

# Color helpers
if [ -t 1 ]; then
    GREEN="\033[1;32m"
    YELLOW="\033[1;33m"
    CYAN="\033[1;36m"
    BOLD="\033[1m"
    RESET="\033[0m"
else
    GREEN=""
    YELLOW=""
    CYAN=""
    BOLD=""
    RESET=""
fi

echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
echo -e "${BOLD}Cosmic Byte Ares Pro — Linux System Setup${RESET}"
echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

# Check root / sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[*] Root permissions required. Requesting sudo access...${RESET}"
    sudo -v
fi

# 1. Apply runtime USB quirk immediately
echo -e "[1/6] Applying USB descriptor quirk 'r' (Windows 255-byte config)..."
echo -n "$QUIRKS" | sudo tee /sys/module/usbcore/parameters/quirks > /dev/null

# 2. Install early-boot systemd persistence service
echo -e "[2/6] Installing boot service (/etc/systemd/system/usbcore-quirks.service)..."
sudo cp "$DIR/config/usbcore-quirks.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable usbcore-quirks.service > /dev/null 2>&1 || true

# 3. Install udev access rules
echo -e "[3/6] Installing udev rules (/etc/udev/rules.d/70-cosmicbyte-ares.rules)..."
sudo cp "$DIR/config/70-cosmicbyte-ares.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# 4. Compile and install custom xpad driver
echo -e "[4/6] Compiling xpad driver with 'Cosmic Byte Ares Pro' naming..."
make -C "$DIR/driver" clean > /dev/null 2>&1 || true
make -C "$DIR/driver" > /dev/null

echo -e "[5/6] Installing kernel module override to $UPDATES_DIR..."
sudo mkdir -p "$UPDATES_DIR"
zstd -f -q -19 "$DIR/driver/xpad.ko" -o "/tmp/xpad.ko.zst"
sudo cp "/tmp/xpad.ko.zst" "$UPDATES_DIR/xpad.ko.zst"
rm -f "/tmp/xpad.ko.zst"
sudo depmod -a "$KVER"

# Reload kernel module
sudo rmmod xpad 2>/dev/null || true
sudo modprobe xpad

# 5. Link CLI tools to PATH
echo -e "[6/6] Installing CLI utilities to /usr/local/bin/..."
sudo ln -sf "$DIR/bin/ares-ctl" /usr/local/bin/ares-ctl
sudo ln -sf "$DIR/bin/ares-exam" /usr/local/bin/ares-exam
sudo ln -sf "$DIR/bin/test_rumble.py" /usr/local/bin/ares-rumble-test

echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
echo -e "${BOLD}${GREEN}[✔] INSTALLATION COMPLETE!${RESET}"
echo -e "${BOLD}${GREEN}======================================================================${RESET}"
echo -e "\n${BOLD}Next steps:${RESET}"
echo -e "  1. If your controller is currently plugged in, ${BOLD}unplug it and plug it back in${RESET}."
echo -e "  2. The center CB diamond will illuminate ${BOLD}${YELLOW}YELLOW${RESET} (genuine XInput mode)!"
echo -e "  3. Check status anytime with:  ${CYAN}ares-ctl status${RESET}"
echo -e "  4. Test haptic rumble with:   ${CYAN}ares-ctl test${RESET} (or ${CYAN}ares-rumble-test${RESET})\n"
