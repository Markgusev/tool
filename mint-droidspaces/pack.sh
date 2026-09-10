#!/usr/bin/env bash
# pack.sh — produce a Linux Mint rootfs as a .tar.gz ready to import into
# DroidSpaces ("import rootfs"). DroidSpaces builds the container itself,
# so all it wants is the rootfs tarball — this makes it.
#
# Run this wherever you have network + curl/xz/gzip (your Mac, a Termux
# shell, any Linux box), NOT inside DroidSpaces. Then hand the resulting
# .tar.gz to DroidSpaces.
#
# Usage:
#   ./pack.sh [--release CODENAME] [--arch arm64|amd64] [-o FILE.tar.gz]
#
# Examples:
#   ./pack.sh                         # Mint 22 for THIS machine's arch
#   ./pack.sh --arch arm64            # force arm64 (phone container)
#   ./pack.sh --release virginia -o mint2134.tar.gz
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/config/defaults.sh"
. "$HERE/scripts/common.sh"
. "$HERE/scripts/fetch-rootfs.sh"

OUT=""
FORCE_ARCH=""
while [ $# -gt 0 ]; do
    case "$1" in
        --release)   MINT_RELEASE="$2"; shift 2 ;;
        --arch)      FORCE_ARCH="$2";   shift 2 ;;
        --distro)    DISTRO="$2";       shift 2 ;;
        -o|--output) OUT="$2";          shift 2 ;;
        -h|--help)   sed -n '2,17p' "$0"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

detect_arch
# The arch must match the DroidSpaces CONTAINER, not the machine building
# the tarball. On a phone that's almost always arm64.
[ -n "$FORCE_ARCH" ] && LXC_ARCH="$FORCE_ARCH"
# Mint is amd64-only upstream; on arm64 this swaps in Ubuntu noble (Mint's base).
pick_source

have gzip || die "need 'gzip' to write the .tar.gz"
have xz   || die "need 'xz' to decompress the source rootfs (macOS: brew install xz)"

[ -n "$OUT" ] || OUT="${SRC_DISTRO}-${SRC_RELEASE}-${LXC_ARCH}.tar.gz"

resolve_rootfs_url
fetch_and_verify "$INSTALL_DIR/.cache"

# Bake mintify.sh into /root of the rootfs so it's already there after import
# — no need to clone a private repo inside the container. Decompress to a
# plain tar, append the file, then gzip. -r works on GNU tar and bsdtar.
info "recompressing rootfs .xz -> .gz (+baking in mintify.sh)..."
_tar="$INSTALL_DIR/.cache/rootfs.tar"
xz -dc "$ROOTFS_TARBALL" > "$_tar"
_stage="$INSTALL_DIR/.cache/inject"; rm -rf "$_stage"; mkdir -p "$_stage/root"
cp "$HERE/mintify.sh" "$_stage/root/mintify.sh"; chmod +x "$_stage/root/mintify.sh"
tar -rf "$_tar" -C "$_stage" root
gzip -c "$_tar" > "$OUT"
rm -f "$_tar"; rm -rf "$_stage"

_size="$(du -h "$OUT" 2>/dev/null | awk '{print $1}')"
ok "wrote $OUT (${_size:-?})"
cat <<DONE

  Import it into DroidSpaces:
    Move $OUT to your phone, then in DroidSpaces choose "import rootfs"
    (or equivalent) and point it at this file.

  Packed: $SRC_DISTRO/$SRC_RELEASE ($LXC_ARCH) — arch must match your container.
  If DroidSpaces rejects it, re-pack with the other arch: --arch amd64
DONE
if [ "$SRC_DISTRO" != "mint" ]; then
cat <<MINTIFY

  This is the Ubuntu base (Mint has no $LXC_ARCH build). mintify.sh is baked
  into /root — inside the container, as root:
      cd /root
      ./mintify.sh              # Cinnamon + Mint themes/tools
      ./mintify.sh --cli        # skip the desktop, just Mint CLI bits
MINTIFY
fi
