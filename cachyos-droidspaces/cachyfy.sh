#!/usr/bin/env bash
# cachyfy.sh — turn an Arch Linux base into a CachyOS-flavoured userspace.
# Run INSIDE the container (after DroidSpaces imports the rootfs), as root.
#
# Honest scope: CachyOS = optimized x86 binaries + its own repos + a custom
# kernel. None of that ports to an arm64 container (wrong arch, and a
# container shares the host kernel). What DOES port, and what this applies:
#   - rolling Arch, fully updated
#   - CachyOS branding (os-release / neofetch)
#   - makepkg tuned like CachyOS: native arch, all cores, LTO  <- real win
#   - CachyOS sysctl profile + zram config (applied where the container allows)
#
# Usage (inside the container):
#   ./cachyfy.sh              # brand + tuning + base tools
#   ./cachyfy.sh --desktop    # also install KDE Plasma (CachyOS default; VNC)
set -eu

WANT_DESKTOP=0
[ "${1:-}" = "--desktop" ] && WANT_DESKTOP=1

[ "$(id -u)" = "0" ] || { echo "run as root inside the container" >&2; exit 1; }
command -v pacman >/dev/null 2>&1 || { echo "this isn't an Arch base" >&2; exit 1; }

log() { printf '\033[34m[*]\033[0m %s\n' "$*"; }

# ---- disable pacman download sandbox ----------------------------------

# pacman 7 sandboxes downloads with Landlock + an 'alpm' user. Container
# host kernels usually lack Landlock and the user switch fails, breaking
# every -Sy. Turn the sandbox off — safe here, the container is the boundary.
log "disabling pacman download sandbox (no Landlock in a container)..."
sed -i 's/^[[:space:]]*DownloadUser/#DownloadUser/' /etc/pacman.conf
grep -q '^DisableSandbox' /etc/pacman.conf || sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf

# ---- keyring + full update --------------------------------------------

log "initialising pacman keyring..."
pacman-key --init 2>/dev/null || true
# arm64 images are Arch Linux ARM; amd64 is Arch proper.
if [ "$(uname -m)" = "aarch64" ]; then
    pacman -Sy --noconfirm --needed archlinuxarm-keyring 2>/dev/null || true
    pacman-key --populate archlinuxarm 2>/dev/null || true
else
    pacman-key --populate archlinux 2>/dev/null || true
fi

log "full system update (rolling Arch)..."
pacman -Syu --noconfirm

# ---- base tools -------------------------------------------------------

log "base tools..."
# neofetch was removed from the Arch repos in 2024 — fastfetch replaces it.
pacman -S --noconfirm --needed \
    base-devel git sudo nano vi fastfetch wget curl which less
# Nice-to-haves; don't abort if a package is missing for this arch.
pacman -S --noconfirm --needed zram-generator reflector htop 2>/dev/null || true

# ---- CachyOS branding -------------------------------------------------

log "branding as CachyOS..."
cat > /etc/os-release <<'EOF'
NAME="CachyOS"
PRETTY_NAME="CachyOS"
ID=cachyos
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://cachyos.org/"
DOCUMENTATION_URL="https://wiki.cachyos.org/"
SUPPORT_URL="https://discord.gg/cachyos"
LOGO=cachyos
EOF
printf 'CachyOS \\r (\\l)\n' > /etc/issue

# ---- makepkg: build like CachyOS (this one genuinely works) -----------

log "tuning makepkg (native arch, all cores, LTO)..."
# Appended overrides win because makepkg.conf is sourced top-to-bottom.
# Guard against duplicate blocks on a re-run.
if ! grep -q 'cachyfy: CachyOS-style build optimization' /etc/makepkg.conf; then
cat >> /etc/makepkg.conf <<'EOF'

# --- cachyfy: CachyOS-style build optimization ---
CFLAGS="-march=native -O2 -pipe -fno-plt -fexceptions -Wformat -Werror=format-security"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C target-cpu=native -C opt-level=2"
MAKEFLAGS="-j$(nproc)"
LTOFLAGS="-flto=auto"
OPTIONS+=(lto)
COMPRESSZST=(zstd -c -T0 -19 -)
EOF
fi

# ---- CachyOS sysctl + zram (applied where the container permits) ------

log "writing CachyOS sysctl profile + zram config..."
cat > /etc/sysctl.d/99-cachyos.conf <<'EOF'
vm.swappiness = 100
vm.vfs_cache_pressure = 50
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.page-cluster = 0
kernel.nmi_watchdog = 0
net.core.netdev_max_backlog = 4096
EOF
# Most vm.*/kernel.* keys aren't namespaced, so a container can't set them —
# apply what's allowed and swallow the rest.
sysctl --system >/dev/null 2>&1 || true

cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

# ---- optional KDE Plasma (CachyOS default desktop) --------------------

if [ "$WANT_DESKTOP" = "1" ]; then
    log "installing KDE Plasma + VNC (big)..."
    pacman -S --noconfirm --needed \
        plasma-desktop konsole dolphin kate \
        xorg-server xorg-xinit tigervnc dbus || true
    mkdir -p /root/.vnc
    cat > /root/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
exec dbus-run-session startplasma-x11
EOF
    chmod +x /root/.vnc/xstartup
    cat <<'NOTE'

[+] KDE installed. Start a desktop:
      vncserver :1 -geometry 1280x720   # set a VNC password on first run
    Connect a VNC viewer to localhost:5901. Stop with: vncserver -kill :1
NOTE
fi

# ---- summary ----------------------------------------------------------

fastfetch 2>/dev/null || true
cat <<'DONE'

[+] cachyfied. It reports as CachyOS (Arch ARM base), fully updated, with
    CachyOS-style makepkg tuning applied.

    Honest notes for a container:
      - No CachyOS kernel here — the container uses the DroidSpaces host
        kernel, so CachyOS's scheduler/kernel tuning does not apply.
      - No CachyOS x86 repos on arm64 — packages come from Arch ARM.
      - sysctl keys the container can't touch are skipped (that's normal).
      - AUR: makepkg won't run as root. Make a user first:
          useradd -m -G wheel builder && passwd builder
          # then build paru/yay as that user
DONE
