# Shared helpers for the mint-droidspaces scripts.
# Sourced, never executed directly.

# ---- logging -----------------------------------------------------------

# Colour only when stdout is a terminal, so logs stay clean in pipes.
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

# Sets HOST_ARCH (uname) and LXC_ARCH (image-server naming).
# If the guest arch matches the device, proot/chroot run the guest
# binaries natively — no QEMU, full speed. Pulling the wrong arch is the
# usual cause of "everything is 20x slower", so we never guess.
detect_arch() {
    HOST_ARCH="$(uname -m)"
    case "$HOST_ARCH" in
        aarch64|arm64)   LXC_ARCH=arm64 ;;
        x86_64|amd64)    LXC_ARCH=amd64 ;;
        armv7l|armv8l|armhf) LXC_ARCH=armhf ;;
        i686|i386)       LXC_ARCH=i386 ;;
        *) die "unsupported CPU arch '$HOST_ARCH' — no Mint rootfs for it" ;;
    esac
}

# ---- source selection --------------------------------------------------

# Picks a rootfs source that actually exists for the target arch and sets
# SRC_DISTRO / SRC_RELEASE. Linux Mint is built only for amd64 on the image
# server, so on any other arch we fall back to Ubuntu 24.04 (noble) — the
# exact base Mint 22 is built on — and leave the Mint desktop bits to
# mintify.sh. Call after detect_arch (and after any --arch override).
pick_source() {
    SRC_DISTRO="${DISTRO:-mint}"
    SRC_RELEASE="${MINT_RELEASE}"
    if [ "$SRC_DISTRO" = "mint" ] && [ "$LXC_ARCH" != "amd64" ]; then
        warn "Linux Mint has no $LXC_ARCH build on the image server (amd64-only)."
        warn "Falling back to Ubuntu noble ($LXC_ARCH) — Mint 22's own base."
        warn "Turn it Mint-flavoured later: run  ./mintify.sh  inside the container."
        SRC_DISTRO="ubuntu"; SRC_RELEASE="noble"
    fi
    info "source: $SRC_DISTRO/$SRC_RELEASE/$LXC_ARCH"
}

# ---- download ----------------------------------------------------------

# dl <url> [outfile]   — curl or wget, with retries. No outfile => stdout.
dl() {
    _url="$1"; _out="${2:-}"
    if have curl; then
        if [ -n "$_out" ]; then
            curl -fL --retry 4 --retry-delay 2 --connect-timeout 20 \
                 -o "$_out" "$_url"
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

# sha256_of <file>  — echoes the hex digest, cross-tool.
sha256_of() {
    if have sha256sum; then sha256sum "$1" | awk '{print $1}'
    elif have shasum;   then shasum -a 256 "$1" | awk '{print $1}'
    else die "need sha256sum or shasum to verify the download"; fi
}
