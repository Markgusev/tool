# mint-droidspaces

Bootstrap a **Linux Mint** userspace and run it inside **DroidSpaces** (or any
proot/chroot-capable Android environment) — one script, no manual rootfs
wrangling.

It auto-detects your CPU, pulls a matching Mint rootfs, verifies it, and
generates a launcher that drops you straight into a Mint shell.

## Why this exists

Linux Mint ships **no ARM build at all** — not an ISO, and not a rootfs on the
LXC image server, where Mint is **amd64-only**. Phones are arm64. So:

- **amd64 target** → a real Linux Mint rootfs, straight from the image server.
- **arm64 target** (phones) → the scripts fall back to **Ubuntu 24.04 (noble)**,
  which *is* built for arm64 and is the exact base Mint 22 is made from. Run
  [`mintify.sh`](mintify.sh) inside the container to add Cinnamon + the Mint-Y
  themes on top. That's "Mint on ARM" done honestly: same base, same desktop,
  native speed — no x86 emulation.

Want the genuine Mint amd64 bits on a phone anyway? Only workable if your
DroidSpaces container emulates x86, and it'll be slow — pack with
`--arch amd64` and skip `mintify.sh`.

## Two ways to use it

**A. DroidSpaces imports a rootfs `.tar.gz`** (the usual DroidSpaces flow —
it builds the container for you). Make the tarball on any networked machine
(your Mac, Termux, any Linux box), then import it:

```sh
git clone <this-repo> mint-droidspaces && cd mint-droidspaces
chmod +x pack.sh
./pack.sh --arch arm64        # -> mint-wilma-arm64.tar.gz
# move that file to your phone, then in DroidSpaces: "import rootfs"
```

`--arch` must match your DroidSpaces **container**, not the machine building
the tarball — on a phone that's almost always `arm64`.

**B. You already have a Linux shell** (Termux, a rooted container, a real VM)
and want the whole thing set up in place:

```sh
chmod +x install.sh
./install.sh          # detect arch + backend, download, build launcher
./start.sh            # enter Mint
```

Either way, first thing inside Mint:

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
pack.sh                 build a Mint rootfs .tar.gz for DroidSpaces import
install.sh              in-place installer (generates start.sh)
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
