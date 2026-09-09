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
apt install -y sudo nano curl wget less locales neofetch git

echo "[*] rebranding to Linux Mint..."
cat > /etc/os-release <<'EOF'
NAME="Linux Mint"
VERSION="22 (Wilma)"
ID=linuxmint
ID_LIKE=ubuntu
PRETTY_NAME="Linux Mint 22"
VERSION_ID="22"
VERSION_CODENAME=wilma
UBUNTU_CODENAME=noble
HOME_URL="https://www.linuxmint.com/"
EOF
cat > /etc/lsb-release <<'EOF'
DISTRIB_ID=LinuxMint
DISTRIB_RELEASE=22
DISTRIB_CODENAME=wilma
DISTRIB_DESCRIPTION="Linux Mint 22 Wilma"
EOF
printf 'Linux Mint 22 Wilma \\n \\l\n' > /etc/issue

# Mint's own theme/icon repos are just data (Architecture: all), so they
# install fine on arm64 — unlike the amd64-only apt packages of the same
# name. Pull them straight from source.
echo "[*] Mint-Y themes + icons (from git, arch-independent)..."
git clone --depth 1 https://github.com/linuxmint/mint-themes.git /tmp/mint-themes \
    && cp -r /tmp/mint-themes/usr/share/themes/* /usr/share/themes/ 2>/dev/null || true
git clone --depth 1 https://github.com/linuxmint/mint-y-icons.git /tmp/mint-y-icons \
    && cp -r /tmp/mint-y-icons/usr/share/icons/* /usr/share/icons/ 2>/dev/null || true
rm -rf /tmp/mint-themes /tmp/mint-y-icons

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

echo "[+] mintified ($MODE). now reports as $(. /etc/os-release; echo "$PRETTY_NAME") (Ubuntu noble base)."
