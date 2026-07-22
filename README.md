# Starlight OS Vega

Starlight OS Vega is a reproducible Debian Stable-based Linux distribution with
a close-to-upstream GNOME experience and Starlight branding.

The repository builds a bootable amd64 ISO from declarative package lists,
filesystem overlays, hooks, and installer configuration. It never modifies an
existing installation to turn it into SOSD.

## Quick start

On a supported Debian or Ubuntu build host:

```bash
sudo apt install live-build debootstrap squashfs-tools xorriso \
  isolinux syslinux-common qemu-system-x86 ovmf shellcheck
make validate
sudo make build
make test
```

The ISO and checksum are written to `build/artifacts/`.

See [docs/architecture.md](docs/architecture.md) and
[docs/building.md](docs/building.md) for the design and complete workflow.
