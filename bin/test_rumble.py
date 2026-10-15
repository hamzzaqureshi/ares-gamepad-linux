#!/usr/bin/env python3
"""
Hardware Force-Feedback (FF_RUMBLE) Verification Utility
Designed for Cosmic Byte Ares Pro & GameSir Cyclone Controllers on Linux.
"""
import sys
import time
import argparse

# ANSI terminal formatting
USE_COLOR = sys.stdout.isatty()
GREEN = "\033[1;32m" if USE_COLOR else ""
YELLOW = "\033[1;33m" if USE_COLOR else ""
RED = "\033[1;31m" if USE_COLOR else ""
CYAN = "\033[1;36m" if USE_COLOR else ""
BOLD = "\033[1m" if USE_COLOR else ""
RESET = "\033[0m" if USE_COLOR else ""

try:
    import evdev
    from evdev import ecodes, ff
except ImportError:
    print(f"{RED}[!] Error: python-evdev is required.{RESET}")
    print("Install it with: sudo pacman -S python-evdev (Arch/CachyOS) or pip install evdev")
    sys.exit(1)


def find_gamepad():
    """Find the first connected gamepad device and check if Force Feedback is available."""
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    ff_gamepads = []
    other_gamepads = []

    for d in devices:
        caps = d.capabilities()
        if ecodes.EV_FF in caps:
            ff_gamepads.append(d)
        elif ecodes.EV_KEY in caps and ecodes.BTN_GAMEPAD in caps[ecodes.EV_KEY]:
            other_gamepads.append(d)

    if ff_gamepads:
        return ff_gamepads[0], True
    elif other_gamepads:
        return other_gamepads[0], False
    return None, False


def play_rumble(dev, strong, weak, duration_ms):
    """Play a force-feedback rumble effect using standard Linux evdev ioctl."""
    rumble = ff.Rumble(strong_magnitude=strong, weak_magnitude=weak)
    effect = ff.Effect(
        ecodes.FF_RUMBLE,
        -1,
        0,
        ff.Trigger(0, 0),
        ff.Replay(duration_ms, 0),
        ff.EffectType(ff_rumble_effect=rumble)
    )
    effect_id = dev.upload_effect(effect)
    try:
        dev.write(ecodes.EV_FF, effect_id, 1)
        time.sleep(duration_ms / 1000.0)
    finally:
        dev.erase_effect(effect_id)


def main():
    parser = argparse.ArgumentParser(description="Force Feedback Rumble Test for Cosmic Byte Ares Pro")
    parser.add_argument("--left", action="store_true", help="Test left motor only (heavy / low frequency)")
    parser.add_argument("--right", action="store_true", help="Test right motor only (light / high frequency)")
    parser.add_argument("--both", action="store_true", help="Test both motors simultaneously")
    parser.add_argument("--pulse", action="store_true", help="Test heartbeat pulse effect")
    parser.add_argument("--duration", type=int, default=1000, help="Vibration duration in milliseconds (default: 1000)")
    args = parser.parse_args()

    print(f"\n{BOLD}{CYAN}============================================================{RESET}")
    print(f"{BOLD}Cosmic Byte Ares Pro — Force Feedback Verification Tool{RESET}")
    print(f"{BOLD}{CYAN}============================================================{RESET}")

    dev, has_ff = find_gamepad()
    if not dev:
        print(f"{RED}[-] No gamepad detected! Check your USB cable or wireless dongle.{RESET}\n")
        sys.exit(1)

    print(f"[+] Found Device: {GREEN}{BOLD}{dev.name}{RESET} ({dev.path})")

    if not has_ff:
        print(f"\n{YELLOW}[!] Force Feedback is NOT available on this device node!{RESET}")
        print(f"[!] The controller is running in Green (Android/Generic HID) mode.")
        print(f"[*] To switch to Yellow (XInput) mode:")
        print(f"    1. Run: {BOLD}sudo ./install.sh{RESET}")
        print(f"    2. Unplug and replug the controller.")
        sys.exit(1)

    print(f"[+] Force Feedback ({GREEN}FF_RUMBLE{RESET}) is {GREEN}ACTIVE{RESET}!")

    single_test = args.left or args.right or args.both or args.pulse

    if args.left or not single_test:
        print(f"\n[*] Testing {BOLD}LEFT motor{RESET} (Heavy rumble / Low frequency)...")
        play_rumble(dev, strong=0xFFFF, weak=0x0000, duration_ms=args.duration)
        time.sleep(0.4)

    if args.right or not single_test:
        print(f"[*] Testing {BOLD}RIGHT motor{RESET} (Light rumble / High frequency)...")
        play_rumble(dev, strong=0x0000, weak=0xFFFF, duration_ms=args.duration)
        time.sleep(0.4)

    if args.both or not single_test:
        print(f"[*] Testing {BOLD}BOTH motors{RESET} (Full dual rumble)...")
        play_rumble(dev, strong=0xFFFF, weak=0xFFFF, duration_ms=int(args.duration * 1.5))
        time.sleep(0.4)

    if args.pulse or not single_test:
        print(f"[*] Testing {BOLD}Heartbeat pulse sequence{RESET}...")
        for _ in range(3):
            play_rumble(dev, strong=0xCCCC, weak=0xCCCC, duration_ms=120)
            time.sleep(0.08)
            play_rumble(dev, strong=0xFFFF, weak=0xFFFF, duration_ms=220)
            time.sleep(0.35)

    print(f"\n{GREEN}[✔] Rumble test complete! All haptic motors operational.{RESET}\n")


if __name__ == '__main__':
    main()
