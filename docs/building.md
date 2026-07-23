# Building and testing

## Host requirements

Use an amd64 Debian or Ubuntu host with at least 30 GB of free disk space, 8 GB
of RAM, hardware virtualization when available, and network access to the
configured Debian mirrors, Element's APT repository, Flathub, Linux Mint's
package pool, and pinned third-party asset URLs.

Install:

```bash
sudo apt-get update
sudo apt-get install live-build debootstrap squashfs-tools xorriso \
  isolinux syslinux-common qemu-system-x86 ovmf shellcheck rsync
```

## Workflow

```bash
make validate
./tests/static.sh
sudo make build
make test
sudo make clean
sudo make clean-purge
```

The build uses root only for debootstrap, mounts, and chroot. Sources remain
owned by the invoking checkout; generated state lives under `build/`.

Debian's packaged `live-build` 3 produces the live filesystem and boot tree.
The final BIOS-bootable hybrid ISO is assembled with `xorriso` and a Syslinux
MBR taken from the chroot, then extended with a GRUB `BOOTX64.EFI` image for
UEFI live boots. This avoids obsolete `isohybrid` package mappings while still
covering BIOS and UEFI USB firmware. The live image keeps Debian's
parallel-installable GRUB module packages (`grub-pc-bin` and
`grub-efi-amd64-bin`) because the firmware-specific metapackages conflict with
each other; Calamares runs `grubcfg` before `starlight-bootloader` so the
installed target gets `/etc/default/grub` and then receives the correct BIOS or
UEFI bootloader work. UEFI installs avoid NVRAM writes and implicit Secure Boot
assets; the Starlight module generates the removable `EFI/BOOT/BOOTX64.EFI`
loader directly with `grub-mkstandalone` and embeds a direct kernel entry using
the installed root filesystem UUID.

The kernel and firmware are selected explicitly. Firmware autodetection from
Debian's package contents is disabled because legacy parsers can mishandle
modern firmware filenames containing spaces; firmware and both CPU microcode
packages remain mandatory package-list entries.

The pipeline builds the chroot before the binary stage and copies the Syslinux
modules from that chroot into the ISO template. This avoids depending on
bootloader paths or versions from the build host.

The final live and installed systems keep active online Debian APT sources in
`/etc/apt/sources.list`, pointing at `deb.debian.org` for `trixie` and
`trixie-updates`, and `security.debian.org` for `trixie-security`. Active
`cdrom:` repositories are removed during image configuration.

The boot menu currently has no background image. Visual branding remains
disabled until it can be tested independently from login and installer flows.

`make test` starts the newest ISO in QEMU, captures the serial console under
`build/test-results/`, and requires the guest to reach a normal systemd boot
target. Test output is kept separate because root owns release artifacts.

The live image logs in automatically as `starlight`. If automatic login fails,
use username `starlight` and password `starlight`. These credentials are set by
a service conditioned on `/run/live/medium` and are never applied to an
installed system.

## Adding packages

Add package names to the responsibility-specific file in `packages/`, one per
line. Do not add desktop metapackages. Run validation, build the ISO, then
inspect the package manifest and boot-test it.

Chromium and Firefox ESR are installed from Debian packages. Chromium is the
default browser and dock favourite. GNOME Web/Epiphany and the generic `Web
Browser` launcher are excluded. Firefox ESR uses a Starlight `policies.json`
file to disable default bookmarks and remove the Debian package search shortcut
for new profiles. No Snap, Google repository, or Chrome binary is included.

## Cleaning

`sudo make clean` asks live-build to unmount and purge generated chroot state,
then removes disposable artifacts while preserving downloaded packages in a
release-specific directory under `build/cache/`. `sudo make clean-purge` also
removes all persistent release caches.
Never manually reuse a partially built chroot for a release build.

The pinned Nerd Fonts archive is cached separately in `build/downloads/` and
verified on every build. `clean-purge` removes it; ordinary cleaning preserves
it.

Caches are keyed by Debian codename and architecture. Changing from one Debian
release to another never reuses bootstrap state or binary packages from the
previous release.
