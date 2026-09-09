# mint-droidspaces

Bootstrap a **Linux Mint** userspace and run it inside **DroidSpaces** (or any
proot/chroot-capable Android environment) — one script, no manual rootfs
wrangling.

It auto-detects your CPU, pulls a matching Mint rootfs, verifies it, and
generates a launcher that drops you straight into a Mint shell.

## Why this exists

Linux Mint ships **no official ARM image**, and phones are ARM. So instead of
a Mint ISO, this pulls Mint from the **LXC community image server**, which
builds Mint for both `arm64` and `amd64`. That's the whole trick — a real Mint
rootfs your phone's CPU can run natively.

## Quick start

```sh
git clone <this-repo> mint-droidspaces && cd mint-droidspaces
chmod +x install.sh
./install.sh          # detect arch + backend, download, build launcher
./start.sh            # enter Mint
```

Inside Mint:

```sh
apt update && apt -y upgrade
```

## Options

```
./install.sh [--release CODENAME] [--dir PATH]
             [--backend auto|proot|chroot] [--arch amd64|arm64]
```

| Flag         | Default                 | Meaning                                  |
|--------------|-------------------------|------------------------------------------|
| `--release`  | `wilma` (Mint 22)       | Mint codename on the image server        |
| `--dir`      | `$HOME/mint-droidspaces`| Where the rootfs is installed            |
| `--backend`  | `auto`                  | `proot` (no root) or `chroot` (root/VM)  |
| `--arch`     | auto (`uname -m`)       | Override only if you know you need to     |

All flags have env equivalents (`MINT_RELEASE`, `INSTALL_DIR`, `BACKEND`), e.g.:

```sh
MINT_RELEASE=virginia GUEST_DNS=1.1.1.1 ./install.sh
```

Mint releases: `wilma` (22), `virginia` (21.3), `victoria` (21.2), `vera`
(21.1), `vanessa` (21). See <https://images.linuxcontainers.org/images/mint/>.

## How it works

1. `uname -m` → maps your CPU to the image-server arch (`aarch64`→`arm64`).
2. Reads the server's build index for `mint/<release>/<arch>` and picks the
   newest build.
3. Downloads `rootfs.tar.xz` and checks it against the server `SHA256SUMS`.
4. Extracts it (under proot when available, so ownership/device entries don't
   error on an unprivileged filesystem).
5. Writes `resolv.conf` / `hosts`, then generates `start.sh`, which launches
   the rootfs with the right backend — proot when unrooted, chroot when root.

## Backends

- **proot** — userspace, no root. The normal case inside an Android sandbox.
- **chroot** — needs root or a real VM. Faster; used automatically when you're
  root.

Not sure which DroidSpaces gives you? See [`docs/droidspaces.md`](docs/droidspaces.md).

## Layout

```
install.sh              main installer (generates start.sh)
config/defaults.sh      tunables (release, dir, dns, backend)
scripts/common.sh       logging, arch detection, download + sha256
scripts/fetch-rootfs.sh resolves + downloads the newest rootfs
scripts/uninstall.sh    wipes an install
docs/droidspaces.md     DroidSpaces-specific setup + troubleshooting
```

## Uninstall

```sh
./scripts/uninstall.sh
```

## Requirements

The sandbox must provide `curl`/`wget`, `tar`+`xz`, and either `proot` (unrooted)
or `chroot`+root. See the table in [`docs/droidspaces.md`](docs/droidspaces.md).

## License

MIT — see [LICENSE](LICENSE).
