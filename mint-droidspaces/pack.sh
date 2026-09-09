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
        -o|--output) OUT="$2";          shift 2 ;;
        -h|--help)   sed -n '2,17p' "$0"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

detect_arch
# The arch must match the DroidSpaces CONTAINER, not the machine building
# the tarball. On a phone that's almost always arm64.
[ -n "$FORCE_ARCH" ] && LXC_ARCH="$FORCE_ARCH"

have gzip || die "need 'gzip' to write the .tar.gz"
have xz   || die "need 'xz' to decompress the source rootfs (macOS: brew install xz)"

[ -n "$OUT" ] || OUT="mint-${MINT_RELEASE}-${LXC_ARCH}.tar.gz"

resolve_rootfs_url
fetch_and_verify "$INSTALL_DIR/.cache"

# Stream xz -> gz so we never hold a full uncompressed tar on disk. The tar
# payload is untouched (LXC rootfs at top level, exactly what an importer
# expects) — only the outer compression changes from .xz to .gz.
info "recompressing rootfs .xz -> .gz ..."
xz -dc "$ROOTFS_TARBALL" | gzip -c > "$OUT"

_size="$(du -h "$OUT" 2>/dev/null | awk '{print $1}')"
ok "wrote $OUT (${_size:-?})"
cat <<DONE

  Import it into DroidSpaces:
    Move $OUT to your phone, then in DroidSpaces choose "import rootfs"
    (or equivalent) and point it at this file.

  Arch packed: $LXC_ARCH  — must match your DroidSpaces container.
  If DroidSpaces rejects it, re-pack with the other arch: --arch amd64

DONE
