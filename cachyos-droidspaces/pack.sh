#!/usr/bin/env bash
# pack.sh — produce an Arch Linux rootfs .tar.gz (the CachyOS base) ready to
# import into DroidSpaces. Run cachyfy.sh inside the container afterwards to
# turn it into CachyOS.
#
# Run this where you have network + curl/xz/gzip (Mac, Termux, any Linux),
# NOT inside DroidSpaces.
#
# Usage:
#   ./pack.sh [--arch arm64|amd64] [--distro cachyos|archlinux] [-o FILE.tar.gz]
#
# Examples:
#   ./pack.sh --arch arm64            # Arch arm64 base for a phone container
#   ./pack.sh --distro archlinux      # plain Arch, skip the CachyOS intent
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/config/defaults.sh"
. "$HERE/scripts/common.sh"
. "$HERE/scripts/fetch-rootfs.sh"

OUT=""
FORCE_ARCH=""
while [ $# -gt 0 ]; do
    case "$1" in
        --release)   CACHY_RELEASE="$2"; shift 2 ;;
        --arch)      FORCE_ARCH="$2";    shift 2 ;;
        --distro)    DISTRO="$2";        shift 2 ;;
        -o|--output) OUT="$2";           shift 2 ;;
        -h|--help)   sed -n '2,18p' "$0"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

detect_arch
# The arch must match the DroidSpaces CONTAINER, not the build machine.
[ -n "$FORCE_ARCH" ] && LXC_ARCH="$FORCE_ARCH"
pick_source

have gzip || die "need 'gzip' to write the .tar.gz"
have xz   || die "need 'xz' to decompress the source rootfs (macOS: brew install xz)"

[ -n "$OUT" ] || OUT="${SRC_DISTRO}-${SRC_RELEASE}-${LXC_ARCH}.tar.gz"

resolve_rootfs_url
fetch_and_verify "$INSTALL_DIR/.cache"

info "recompressing rootfs .xz -> .gz (+baking in cachyfy.sh)..."
# Bake cachyfy.sh into /root of the rootfs so it's already there after import
# — no need to clone a private repo inside a bare Arch container. Decompress
# to a plain tar, append the file, then gzip. -r works on GNU tar and bsdtar.
_tar="$INSTALL_DIR/.cache/rootfs.tar"
xz -dc "$ROOTFS_TARBALL" > "$_tar"
_stage="$INSTALL_DIR/.cache/inject"; rm -rf "$_stage"; mkdir -p "$_stage/root"
cp "$HERE/cachyfy.sh" "$_stage/root/cachyfy.sh"; chmod +x "$_stage/root/cachyfy.sh"
tar -rf "$_tar" -C "$_stage" root
gzip -c "$_tar" > "$OUT"
rm -f "$_tar"; rm -rf "$_stage"

_size="$(du -h "$OUT" 2>/dev/null | awk '{print $1}')"
ok "wrote $OUT (${_size:-?})"
cat <<DONE

  Import it into DroidSpaces ("import rootfs"), then inside the container,
  as root (cachyfy.sh is already baked into /root — no cloning needed):
      cd /root
      ./cachyfy.sh              # brand + tuning + base tools
      ./cachyfy.sh --desktop    # also KDE Plasma (needs VNC to see it)

  Packed: $SRC_DISTRO/$SRC_RELEASE ($LXC_ARCH) — arch must match your container.
DONE
