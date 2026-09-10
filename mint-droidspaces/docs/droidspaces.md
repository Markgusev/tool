# Running mint-droidspaces inside DroidSpaces

## The DroidSpaces way: import a rootfs .tar.gz

DroidSpaces runs a real container off the kernel with root, and imports its
guest as a **rootfs `.tar.gz`** — it builds and manages the container itself,
handling mounts and networking. So the clean path is: build the tarball, then
import it.

```sh
./pack.sh --arch arm64        # -> mint-wilma-arm64.tar.gz
```

Run `pack.sh` on any machine with network + `curl`/`xz`/`gzip` (your Mac needs
`brew install xz`; Termux has it). Copy the resulting `.tar.gz` to your phone
and use DroidSpaces' "import rootfs". `--arch` must match the DroidSpaces
container arch (a phone container is almost always `arm64`).

Because DroidSpaces owns the container, you do **not** run `install.sh`,
`start.sh`, proot, or chroot yourself in this mode — it's all handled once the
rootfs is imported. The rest of this doc covers the alternate "I have a bare
Linux shell" path.

---

## Alternate path: bootstrap in an existing shell

If instead you're dropped into a plain Linux shell (Termux, some other
container) and want to set Mint up in place, `install.sh` supports two ways to
expose the userspace — you just need to know which one you have.

## Which backend do I have?

Run this inside the DroidSpaces terminal/shell:

```sh
id -u
command -v proot chroot
```

- `id -u` prints **0** and `chroot` exists → you have a rooted / real-VM
  environment. Use **chroot** (faster, closest to bare metal).
- `id -u` prints a **non-zero** number → unprivileged sandbox. Use **proot**.
  This is the common case.

`install.sh` picks automatically (`--backend auto`), but you can force it:

```sh
./install.sh --backend proot     # unrooted sandbox
./install.sh --backend chroot    # rooted / VM
```

## Prerequisites the sandbox must provide

The installer downloads and unpacks a rootfs; it does **not** ship a kernel or
a proot binary. The DroidSpaces environment needs:

| Tool          | proot backend | chroot backend | How to get it                     |
|---------------|:-------------:|:--------------:|-----------------------------------|
| `curl`/`wget` | yes           | yes            | usually present; else install it  |
| `tar` + `xz`  | yes           | yes            | usually present                   |
| `proot`       | **required**  | no             | `pkg install proot` (Termux-like) |
| `chroot`+root | no            | **required**   | root / a real VM                  |

If DroidSpaces is Termux-based, `pkg install proot curl` covers it. If it is a
minimal busybox shell, you may need to point it at a package source first.

## Architecture note (read this)

Most phones are **arm64 (aarch64)**. Linux Mint publishes no official ARM
build, so the rootfs comes from the LXC community image server, which *does*
build Mint for arm64 and amd64. The installer detects your CPU with `uname -m`
and pulls the matching image. If you force the wrong arch with `--arch`,
everything runs under emulation and crawls — don't, unless DroidSpaces itself
emulates x86 and you know that's what you want.

## Typical session

```sh
./install.sh                 # detect arch, pull Mint 22, build launcher
./start.sh                   # drop into the Mint shell
# inside Mint:
apt update && apt -y upgrade
apt -y install neofetch
neofetch
```

## Troubleshooting

- **`proot not found`** → install proot in the DroidSpaces environment first.
- **DNS fails (`Temporary failure resolving`)** → re-run with a different
  resolver: `GUEST_DNS=1.1.1.1 ./install.sh`, or edit
  `rootfs/etc/resolv.conf`.
- **`cannot change ownership` spam during extract** → harmless on unprivileged
  filesystems; the installer already suppresses most of it.
- **Slow as molasses** → you're on emulation. Check `uname -m` inside Mint
  matches your device arch.
- **No `/sdcard` inside Mint** → DroidSpaces didn't grant storage to the
  sandbox; the launcher binds it only when visible.
