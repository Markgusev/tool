# mint-droidspaces default configuration.
# Everything here can be overridden from the environment or CLI flags,
# e.g.  MINT_RELEASE=virginia INSTALL_DIR=/data/mint ./install.sh
#
# The ':=' form means "use this value only if the variable is unset",
# so exported env vars and install.sh flags always win.

# Linux Mint release codename as published on the LXC image server.
#   wilma    -> Mint 22   (Ubuntu 24.04 base)   [default]
#   virginia -> Mint 21.3 (Ubuntu 22.04 base)
#   vera/victoria/vanessa -> older 21.x
# Full list: https://images.linuxcontainers.org/images/mint/
: "${MINT_RELEASE:=wilma}"

# Target directory. The rootfs lands in $INSTALL_DIR/rootfs and the
# generated launcher in $INSTALL_DIR/start.sh
: "${INSTALL_DIR:=$HOME/mint-droidspaces}"

# LXC community image server. Mint is built here for amd64 AND arm64,
# which is the whole reason this works on a phone — Mint ships no
# official ARM image of its own.
: "${IMAGE_SERVER:=https://images.linuxcontainers.org}"

# Image variant on the server. 'default' is the minimal rootfs.
: "${IMAGE_VARIANT:=default}"

# DNS written into the guest's /etc/resolv.conf. Android hides the real
# resolv.conf from unprivileged apps, so we hardcode a resolver.
: "${GUEST_DNS:=8.8.8.8}"

# Launch backend:
#   auto   -> chroot when running as root, otherwise proot
#   proot  -> force userspace proot (no root needed)
#   chroot -> force chroot (needs root / a real VM)
: "${BACKEND:=auto}"
