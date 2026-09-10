# cachyos-droidspaces

Get a **CachyOS-flavoured** Linux running inside **DroidSpaces** on a phone —
by packing an **Arch Linux** rootfs as a `.tar.gz` you import, then
`cachyfy.sh` inside to brand and tune it.

## Read this first — the honest limits

CachyOS ships **no rootfs for any arch** (it's an x86-only project), and its
identity is three things that mostly can't cross into an arm64 container:

| CachyOS thing            | In an arm64 DroidSpaces container            |
|--------------------------|----------------------------------------------|
| x86-64-v3/v4 binaries    | ❌ wrong arch — those levels don't exist on ARM |
| CachyOS pacman repos     | ❌ x86-only — packages come from Arch ARM      |
| Custom kernel (BORE/…)   | ❌ containers share the DroidSpaces host kernel |
| Rolling Arch userspace   | ✅ native on arm64                             |
| makepkg build tuning     | ✅ native arch + all cores + LTO (real win)    |
| Branding / sysctl / zram | ⚠️ branding yes; sysctl/zram only where the container allows |

So this is **Arch Linux ARM wearing CachyOS's coat**, with the one performance
bit that genuinely applies in a container (optimized local builds). If you want
the *real* CachyOS kernel + optimized binaries, that needs an x86 machine with
its own kernel — not a phone container. No tool can change that.

## Quick start

Build the base (on your Mac, Termux, any networked Linux — **not** in DroidSpaces):

```sh
git clone <this-repo>/cachyos-droidspaces && cd cachyos-droidspaces
chmod +x pack.sh
./pack.sh --arch arm64        # -> archlinux-current-arm64.tar.gz
```

Move the `.tar.gz` to your phone, import it in DroidSpaces, then inside the
container as root:

```sh
./cachyfy.sh              # brand + tuning + base tools
./cachyfy.sh --desktop    # also KDE Plasma (CachyOS's default; view via VNC)
```

## Options

```
./pack.sh [--arch arm64|amd64] [--distro cachyos|archlinux] [-o FILE.tar.gz]
```

- `--arch` must match the DroidSpaces **container** (a phone is almost always
  `arm64`).
- `--distro archlinux` skips the CachyOS intent and just gives you plain Arch.

## Layout

```
pack.sh                 build the Arch base .tar.gz for DroidSpaces import
cachyfy.sh              run inside the container: Arch -> CachyOS-flavoured
config/defaults.sh      tunables (release, dir, dns)
scripts/common.sh       logging, arch detection, source selection, download
scripts/fetch-rootfs.sh resolve + download + verify the newest rootfs
```

## License

MIT — same as the sibling `mint-droidspaces`.
