# cachyos-droidspaces default configuration.
# Override from the environment or CLI flags, e.g.
#   INSTALL_DIR=/data/cachy ./pack.sh --arch arm64

# CachyOS has no rootfs on the image server (x86-only project), so the base
# is Arch Linux, whose only "release" on the server is the rolling 'current'.
: "${CACHY_RELEASE:=current}"

# Target directory. Rootfs -> $INSTALL_DIR/rootfs, launcher -> start.sh
: "${INSTALL_DIR:=$HOME/cachyos-droidspaces}"

# LXC community image server. Arch is built here for arm64 AND amd64.
: "${IMAGE_SERVER:=https://images.linuxcontainers.org}"

# Image variant. 'default' is the minimal rootfs.
: "${IMAGE_VARIANT:=default}"

# Source intent. 'cachyos' always resolves to an Arch base + cachyfy.sh,
# because no CachyOS rootfs exists for any arch. Set 'archlinux' to be
# explicit and skip the branding intent.
: "${DISTRO:=cachyos}"

# DNS written into the guest resolv.conf (Android hides the host's).
: "${GUEST_DNS:=8.8.8.8}"

# Launch backend for install.sh: auto | proot | chroot
: "${BACKEND:=auto}"
