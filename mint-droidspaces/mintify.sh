#!/usr/bin/env bash
# mintify.sh — turn an Ubuntu-noble base into a Mint-flavoured userspace.
# Run this INSIDE the container (after DroidSpaces imports the rootfs), as
# root. Needed only for the arm64 fallback, where a real Mint rootfs does
# not exist and we ship Ubuntu 24.04 (Mint 22's base) instead.
#
# What it does: adds the Cinnamon desktop, the Mint-Y themes/icons, Nemo,
# and a few Mint staples. Everything here is arch-independent (arm64 too).
#
# Usage (inside the container):
#   ./mintify.sh          # full: Cinnamon desktop + Mint look + tools
#   ./mintify.sh --cli    # no desktop, just Mint-ish CLI tools + theming pkgs
set -eu

MODE=full
[ "${1:-}" = "--cli" ] && MODE=cli

[ "$(id -u)" = "0" ] || { echo "run as root inside the container" >&2; exit 1; }
command -v apt >/dev/null 2>&1 || { echo "this isn't an apt/Ubuntu base" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive

echo "[*] enabling universe + refreshing..."
apt update -y
apt install -y software-properties-common ca-certificates
add-apt-repository -y universe || true
apt update -y

echo "[*] base tools..."
apt install -y sudo nano curl wget less locales neofetch

# Mint theme packages live in Ubuntu universe and are arch-independent.
echo "[*] Mint look (themes/icons)..."
apt install -y mint-y-icons mint-themes 2>/dev/null || \
    echo "[!] mint-y-icons/mint-themes not in this repo — skipping theming"

if [ "$MODE" = "full" ]; then
    echo "[*] Cinnamon desktop (this one's big)..."
    # cinnamon-core pulls the desktop without the full Ubuntu app stack.
    apt install -y cinnamon-core nemo || apt install -y cinnamon nemo
    cat <<NOTE

[+] Cinnamon installed. A desktop needs a display server — inside a
    container that means a VNC/X path, not the app's own window. Quick VNC:
        apt install -y tigervnc-standalone-server dbus-x11
        vncserver :1 -geometry 1280x720
        # then set ~/.vnc/xstartup to launch: exec cinnamon-session
    Connect from a VNC viewer to localhost:5901.
NOTE
fi

echo "[+] mintified ($MODE). base is Ubuntu $(. /etc/os-release; echo "$VERSION_ID"), Mint-flavoured."
