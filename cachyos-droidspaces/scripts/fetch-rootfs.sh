# Resolves and downloads the newest rootfs for SRC_DISTRO/SRC_RELEASE/arch.
# Sourced by pack.sh; expects common.sh sourced and pick_source already run.

resolve_rootfs_url() {
    _distro="${SRC_DISTRO:-archlinux}"
    _release="${SRC_RELEASE:-current}"
    _base="$IMAGE_SERVER/images/$_distro/$_release/$LXC_ARCH/$IMAGE_VARIANT"
    info "querying image index: $_base/"

    _index="$(dl "$_base/" || true)"
    [ -n "$_index" ] || die "no image index for $_distro/$_release/$LXC_ARCH — arch not built?"

    # Build folders are named YYYYMMDD_HH:MM. Newest wins.
    _stamp="$(printf '%s\n' "$_index" \
        | grep -oE '[0-9]{8}_[0-9]{2}:[0-9]{2}' \
        | sort -u | tail -n1)"
    [ -n "$_stamp" ] || die "could not find a build timestamp in the index"

    ROOTFS_URL="$_base/$_stamp/rootfs.tar.xz"
    SUMS_URL="$_base/$_stamp/SHA256SUMS"
    info "selected build $_stamp for $_distro/$_release/$LXC_ARCH"
}

fetch_and_verify() {
    _dir="$1"; mkdir -p "$_dir"
    ROOTFS_TARBALL="$_dir/rootfs.tar.xz"

    info "downloading rootfs (this is the big one)..."
    dl "$ROOTFS_URL" "$ROOTFS_TARBALL" || die "rootfs download failed"

    _sums="$(dl "$SUMS_URL" 2>/dev/null || true)"
    if [ -z "$_sums" ]; then
        warn "no SHA256SUMS on server — skipping integrity check"
        return 0
    fi

    _want="$(printf '%s\n' "$_sums" | grep -E 'rootfs\.tar\.xz$' | awk '{print $1}' | head -n1)"
    if [ -z "$_want" ]; then
        warn "SHA256SUMS had no rootfs entry — skipping integrity check"
        return 0
    fi

    info "verifying sha256..."
    _got="$(sha256_of "$ROOTFS_TARBALL")"
    [ "$_got" = "$_want" ] || die "sha256 mismatch — download corrupt (want $_want, got $_got)"
    ok "checksum verified"
}
