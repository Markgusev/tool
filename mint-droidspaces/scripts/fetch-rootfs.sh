# Resolves and downloads the newest Mint rootfs for the detected arch.
# Sourced by install.sh; expects common.sh already sourced and
# detect_arch already called (LXC_ARCH set).

# resolve_rootfs_url
#   Reads the server's autoindex for the chosen release/arch, picks the
#   most recent build folder, and sets:
#     ROOTFS_URL  -> full URL of rootfs.tar.xz
#     SUMS_URL    -> full URL of the matching SHA256SUMS
resolve_rootfs_url() {
    _distro="${SRC_DISTRO:-mint}"
    _release="${SRC_RELEASE:-$MINT_RELEASE}"
    _base="$IMAGE_SERVER/images/$_distro/$_release/$LXC_ARCH/$IMAGE_VARIANT"
    info "querying image index: $_base/"

    _index="$(dl "$_base/" || true)"
    [ -n "$_index" ] || die "no image index for $_distro/$_release/$LXC_ARCH — wrong release or arch not built?"

    # Build folders are named YYYYMMDD_HH:MM. Newest wins.
    _stamp="$(printf '%s\n' "$_index" \
        | grep -oE '[0-9]{8}_[0-9]{2}:[0-9]{2}' \
        | sort -u | tail -n1)"
    [ -n "$_stamp" ] || die "could not find a build timestamp in the index"

    ROOTFS_URL="$_base/$_stamp/rootfs.tar.xz"
    SUMS_URL="$_base/$_stamp/SHA256SUMS"
    info "selected build $_stamp for $_distro/$_release/$LXC_ARCH"
}

# fetch_and_verify <dest_dir>
#   Downloads rootfs.tar.xz into dest_dir and checks its sha256 against
#   the server's SHA256SUMS. Sets ROOTFS_TARBALL to the local path.
fetch_and_verify() {
    _dir="$1"; mkdir -p "$_dir"
    ROOTFS_TARBALL="$_dir/rootfs.tar.xz"

    info "downloading rootfs (this is the big one)..."
    dl "$ROOTFS_URL" "$ROOTFS_TARBALL" || die "rootfs download failed"

    # SHA256SUMS is small and not always present; treat its absence as a
    # soft warning rather than a hard stop.
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
