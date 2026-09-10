#!/usr/bin/env bash
# Removes a mint-droidspaces install (rootfs + launcher + cache).
# Usage: ./scripts/uninstall.sh [--dir PATH]
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/config/defaults.sh"
. "$HERE/scripts/common.sh"

while [ $# -gt 0 ]; do
    case "$1" in
        --dir) INSTALL_DIR="$2"; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done

[ -d "$INSTALL_DIR" ] || die "nothing installed at $INSTALL_DIR"

warn "About to delete: $INSTALL_DIR"
printf '    are you sure? [y/N] '
read -r _ans
case "$_ans" in
    y|Y) ;;
    *) die "aborted" ;;
esac

# proot may leave read-only bits on extracted dirs; force them writable
# before rm so we don't fail halfway through.
chmod -R u+w "$INSTALL_DIR" 2>/dev/null || true
rm -rf "$INSTALL_DIR"
ok "removed $INSTALL_DIR"
