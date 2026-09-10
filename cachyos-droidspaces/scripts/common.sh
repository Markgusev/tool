# Shared helpers for the cachyos-droidspaces scripts. Sourced, not executed.

# ---- logging -----------------------------------------------------------

if [ -t 1 ]; then
    _C_RESET=$'\033[0m'; _C_BLUE=$'\033[34m'; _C_YEL=$'\033[33m'
    _C_RED=$'\033[31m';  _C_GRN=$'\033[32m'
else
    _C_RESET=; _C_BLUE=; _C_YEL=; _C_RED=; _C_GRN=
fi

info() { printf '%s[*]%s %s\n'  "$_C_BLUE" "$_C_RESET" "$*"; }
ok()   { printf '%s[+]%s %s\n'  "$_C_GRN"  "$_C_RESET" "$*"; }
warn() { printf '%s[!]%s %s\n'  "$_C_YEL"  "$_C_RESET" "$*" >&2; }
err()  { printf '%s[x]%s %s\n'  "$_C_RED"  "$_C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---- architecture ------------------------------------------------------

detect_arch() {
    HOST_ARCH="$(uname -m)"
    case "$HOST_ARCH" in
        aarch64|arm64)   LXC_ARCH=arm64 ;;
        x86_64|amd64)    LXC_ARCH=amd64 ;;
        riscv64)         LXC_ARCH=riscv64 ;;
        loongarch64)     LXC_ARCH=loong64 ;;
        *) die "unsupported CPU arch '$HOST_ARCH' — no Arch rootfs for it" ;;
    esac
}

# ---- source selection --------------------------------------------------

# CachyOS ships no rootfs (x86-only project) and, more to the point, a
# container can't load its custom kernel — the biggest part of CachyOS. So
# the "cachyos" intent always resolves to an Arch Linux base of the target
# arch; cachyfy.sh then applies the CachyOS bits that actually port
# (branding, rolling Arch, makepkg build optimization, portable sysctls).
pick_source() {
    SRC_DISTRO="${DISTRO:-cachyos}"
    SRC_RELEASE="${CACHY_RELEASE:-current}"
    if [ "$SRC_DISTRO" = "cachyos" ]; then
        warn "CachyOS has no rootfs on the image server, and a container can't"
        warn "run its custom kernel. Using Arch Linux ($LXC_ARCH) as the base —"
        warn "cachyfy.sh adds the CachyOS userspace bits that port to $LXC_ARCH."
        SRC_DISTRO="archlinux"; SRC_RELEASE="current"
    fi
    info "source: $SRC_DISTRO/$SRC_RELEASE/$LXC_ARCH"
}

# ---- download ----------------------------------------------------------

dl() {
    _url="$1"; _out="${2:-}"
    if have curl; then
        if [ -n "$_out" ]; then
            curl -fL --retry 4 --retry-delay 2 --connect-timeout 20 -o "$_out" "$_url"
        else
            curl -fsSL --retry 4 --retry-delay 2 --connect-timeout 20 "$_url"
        fi
    elif have wget; then
        if [ -n "$_out" ]; then
            wget -q --tries=4 --timeout=20 -O "$_out" "$_url"
        else
            wget -q --tries=4 --timeout=20 -O - "$_url"
        fi
    else
        die "need curl or wget to download the rootfs"
    fi
}

sha256_of() {
    if have sha256sum; then sha256sum "$1" | awk '{print $1}'
    elif have shasum;   then shasum -a 256 "$1" | awk '{print $1}'
    else die "need sha256sum or shasum to verify the download"; fi
}
