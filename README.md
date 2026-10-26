<div align="center">

# Cosmic Byte Ares Pro — Linux Native XInput Driver & Tooling

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20Kernel%206.x%20--%207.x-orange.svg)](#)
[![Hardware: Cosmic Byte Ares Pro](https://img.shields.io/badge/Hardware-Cosmic%20Byte%20Ares%20Pro-yellow.svg)](#)
[![Status: Production Ready](https://img.shields.io/badge/Status-Plug%20%26%20Play-brightgreen.svg)](#)

> **Plug-and-play Genuine Hardware XInput (Solid Yellow LED) with full Force-Feedback Rumble on Linux.**  
> Solves the Linux USB enumeration protocol crash (`error -71`), enforces native Xbox 360 controller identity, and provides full haptic motor control.

</div>

---

## Table of Contents

- [Overview](#overview)
- [The Root Cause & Solution](#the-root-cause--solution)
- [LED Mode Reference](#led-mode-reference)
- [Quickstart](#quickstart)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [CLI Utilities](#cli-utilities)
  - [ares-ctl](#1-ares-ctl--management--diagnostics)
  - [ares-exam](#2-ares-exam--20-point-system--hardware-diagnostic-exam)
  - [ares-rumble-test](#3-ares-rumble-test--force-feedback-verification)
- [Repository Structure](#repository-structure)
- [Architecture & System Configuration](#architecture--system-configuration)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Uninstallation](#uninstallation)
- [License](#license)

---

## Overview

### What Does This Do? (In Plain English)

If you plug a **Cosmic Byte Ares Pro** (or similar wireless gamepad) into a Linux PC, it behaves unexpectedly out of the box:
* The center diamond light turns **Green** instead of **Yellow**.
* **Vibration (rumble) does not work** in games.
* Analog triggers act like basic on/off switches instead of smooth pressure-sensitive pedals.
* Linux mistakes it for a generic phone gamepad instead of a real PC controller.

**This project fixes everything with one simple command:**
* **Solid Yellow Light (Genuine PC Mode):** Forces Linux to communicate properly with the controller so it always boots into true Xbox / PC mode — both over USB-C cable and the 2.4GHz wireless dongle.
* **Full Haptic Rumble:** Restores dual-motor vibration in Steam, Proton, Heroic, Lutris, emulators, and native Linux games.
* **Proper Device Name:** Displays cleanly as `"Cosmic Byte Ares Pro"` across your system and games instead of generic placeholder text.
* **Survives Reboots:** Sets up early boot persistence so it stays fixed permanently without needing manual tweaks.

---

### Technical Background

The **Cosmic Byte Ares Pro** (built on the GameSir Cyclone OEM / ShanWan microcontroller platform) is designed to operate as a native XInput device on Windows. However, out of the box on Linux, connecting via USB-C or the 2.4GHz wireless dongle results in:

1. **The Fallback Bug:** The controller drops out of XInput mode and locks into **Android HID mode (Green LED)** or generic fallback mode (`20bc:5001`), cutting motor rumble and breaking trigger analog axes.
2. **The Name Bug:** The kernel's default `xpad` driver labels the controller as `"Generic X-Box pad"`.
3. **Lost Settings on Boot:** Standard runtime quirk tweaks disappear when the system reboots.

This repository provides an automated, production-grade solution that **fixes all three issues permanently**.

---

## The Root Cause & Solution

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        USB ENUMERATION SEQUENCE                        │
└────────────────────────────────────────────────────────────────────────┘

  [HOST: Windows]  ─── GET_DESCRIPTOR (CONFIG, 255 bytes) ───►  [ARES PRO]
                   ◄── 255-byte full descriptor response  ────  (Firmware Happy!)
                   ════════════════════════════════════════════  Mode: YELLOW (XInput)

  [HOST: Linux]    ─── GET_DESCRIPTOR (CONFIG, 9 bytes)   ───►  [ARES PRO]
                   ◄── -EPROTO (Error -71: Protocol Stall) ───  (Firmware Crash!)
                   ─── Bus Reset / Fallback Triggered ────────  Mode: GREEN (Android HID)
```

* **Why Linux failed:** The controller firmware rigidly expects a Windows-style **255-byte** configuration descriptor request. The standard Linux kernel sends a strict 9-byte header request (`USB_DT_CONFIG_SIZE`), causing a protocol error (`-EPROTO` / `-71`).
* **The Fix:** Linux kernel quirk flag **`'r'`** (`USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE`) forces Linux to request 255 bytes directly, matching Windows byte-for-byte.
* **The Name:** A patched `xpad` module override identifies the controller natively as **`"Cosmic Byte Ares Pro"`** across the OS, Steam, and browsers.

---

## LED Mode Reference

The center **CB diamond** indicates the controller's active hardware state:

| Center LED | Mode | Reported ID | Linux Driver | Rumble / Force Feedback |
| :---: | :--- | :---: | :---: | :---: |
| **Yellow** | **Genuine PC XInput (Target)** | `045e:02fd` / `2c16:a2b3` / `3537:100b` | `xpad` | **Full Dual Motor Hardware Power** |
| **Green** | Android HID Fallback | `3537:1052` / `20bc:5001` | `hid-generic` | Disabled (Firmware Cut) |
| **Red** | DirectInput / Nintendo Switch | `057e:2009` | `hid-nintendo` | Digital Triggers / Swapped Face Buttons |

---

## Quickstart

### Prerequisites

* Linux distribution running kernel 6.x or 7.x (Arch Linux, CachyOS, Fedora, Ubuntu, Debian, etc.).
* Standard build tools and kernel headers installed (`linux-headers`, `gcc` or `clang`, `make`).
* `python-evdev` (for testing haptic vibration).

### Installation

Clone this repository and run the unified installer:

```bash
git clone https://github.com/hamza/ares-gamepad-linux.git
cd ares-gamepad-linux
sudo ./install.sh
```

Next steps:
1. **Unplug** the controller (or 2.4G wireless dongle) and **plug it back in**.
2. Verify the center CB diamond glows **Solid Yellow**.
3. Run the hardware check:
   ```bash
   ares-ctl status
   ```

---

## CLI Utilities

This repository installs three system-wide command line tools to `/usr/local/bin`:

### 1. `ares-ctl` — Management & Diagnostics

```bash
# Check active connection, driver, and LED mode:
ares-ctl status

# Run automated haptic motor tests:
ares-ctl test

# Live re-apply USB quirks if ever needed:
ares-ctl fix
```

### 2. `ares-exam` — 20-Point System & Hardware Diagnostic Exam

Comprehensive diagnostic battery certifying the entire kernel, driver, udev, and hardware stack:

```bash
# Run the complete 20-point diagnostic exam:
ares-exam
```

Example Scorecard:
```text
========================================================================
FINAL EXAM SCORECARD & DIAGNOSTIC GRADE
========================================================================
 Passed:   20 / 20 (100.0%)
 Failed:    0 / 20
 Warnings:  0 / 20
 Skipped:   0 / 20
 Grade:    GRADE A (Exemplary Production Readiness)
========================================================================
```

### 3. `ares-rumble-test` — Force Feedback Verification

Test the controller's dual eccentric rotating mass (ERM) motors directly via Linux kernel `FF_RUMBLE`:

```bash
# Full automated sequence (Left, Right, Dual, Heartbeat):
ares-rumble-test

# Test individual motors:
ares-rumble-test --left        # Heavy / low-frequency motor
ares-rumble-test --right       # Light / high-frequency motor
ares-rumble-test --both        # Maximum dual vibration
ares-rumble-test --pulse       # Rapid pulse pattern
```

---

## Repository Structure

```text
├── bin/
│   ├── ares-ctl                   # Main hardware management CLI
│   ├── ares-exam                  # 20-point diagnostic certification suite
│   └── test_rumble.py             # Force feedback verification utility
├── config/
│   ├── 70-cosmicbyte-ares.rules   # Udev permission rules (input/hidraw uaccess)
│   └── usbcore-quirks.service     # Systemd early-boot service for quirks
├── driver/
│   ├── Makefile                   # Clang/GCC auto-detecting kernel module Makefile
│   ├── dkms.conf                  # DKMS package descriptor
│   └── xpad.c                     # Patched xpad kernel driver
├── install.sh                     # Automated setup script
├── uninstall.sh                   # Complete system restoration script
├── LICENSE                        # GPL v2.0
└── README.md
```

---

## Architecture & System Configuration

1. **Early Boot Service ([`/etc/systemd/system/usbcore-quirks.service`](config/usbcore-quirks.service)):**  
   Runs during `sysinit.target` before `systemd-udevd` initializes USB devices. Guarantees that the Windows 255-byte descriptor quirk (`'r'`) is injected into `/sys/module/usbcore/parameters/quirks` on every boot.
2. **Device Permissions ([`/etc/udev/rules.d/70-cosmicbyte-ares.rules`](config/70-cosmicbyte-ares.rules)):**  
   Grants active desktop users (`TAG+="uaccess"`) direct read/write permissions to `/dev/input/event*`, enabling non-root force feedback in games and emulators.
3. **Driver Override ([`/lib/modules/$(uname -r)/updates/xpad.ko.zst`](driver/)):**  
   Prioritized over the stock kernel driver, naming the device `"Cosmic Byte Ares Pro"` for Steam, Wine, Proton, and Web Gamepad APIs.
4. **Automated Kernel Upgrade Hook ([`/etc/pacman.d/hooks/95-ares-gamepad-xpad.hook`](install.sh)):**  
   On Arch and CachyOS systems, an ALPM post-transaction hook automatically triggers during kernel upgrades (`linux`, `linux-cachyos`, etc.), recompiling and installing the patched module into the new kernel so the driver never breaks on reboot.

---

## Frequently Asked Questions

### Why does Gamepad Tester (HardwareTester) say "VIBRATION: n/a"?

* **Firefox on Linux:** The Mozilla team has not implemented the Web Gamepad Haptics API (`GamepadHapticActuator`) on Linux. It shows `VIBRATION n/a` for *all* controllers on Linux in Firefox.
* **Chromium / Chrome:** The tab must be actively focused and buttons pressed for the browser to initialize haptics.
* **Games (Steam / Proton / Wine / Native):** Games do **not** use browser APIs. They communicate directly with the Linux kernel via `evdev` `FF_RUMBLE`, which is verified and working.

### How do I test the 2.4GHz wireless dongle?

Simply plug the 2.4GHz USB dongle into your computer and turn the controller on. The installer applies quirk `'r'` to dongle IDs `2c16:a2b3`, `3537:0575`, and `3537:100b`, ensuring the wireless connection initializes directly into Yellow XInput mode with full dual-motor haptics.

---

## Uninstallation

To restore your system completely to factory defaults:

```bash
sudo ./uninstall.sh
```

---

## License

This project is licensed under the **GNU General Public License v2.0** (`GPL-2.0`), matching the Linux kernel and `xpad` driver licensing terms. See the [LICENSE](LICENSE) file for details.
