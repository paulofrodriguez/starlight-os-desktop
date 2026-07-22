# Architecture

SOSD is assembled from a Debian Stable archive by `live-build`. The build host
does not become part of the resulting operating system.

The current development base is Debian 13 (`trixie`) for current kernel, GNOME,
virtualization, container, and development toolchains.

## Layers

- `config/` fixes the release, architecture, mirrors, and image metadata.
- `packages/` declares packages by responsibility.
- `sosd/` is the filesystem overlay for Starlight runtime components.
- `branding/` contains replaceable visual assets.
- `hooks/` performs deterministic chroot configuration and final sanitization.
- `installer/` owns Calamares independently from the live desktop.
- `scripts/` is the public build, validation, test, and cleanup interface.
- `tests/` contains repository-level tests.
- `build/` is disposable and never a source of truth.

The structure reserves `/var/lib/starlight` for local product state and
`/usr/lib/starlight` for future Cloud, backup, synchronization, account,
application, and opt-in telemetry agents. Future products should be packaged as
independent services and must not add logic directly to the ISO builder.

## Reproducibility

The release, architecture, archive areas, mirrors, and source date epoch are
versioned in `config/build.env`. Package names and all filesystem changes are
tracked. Debian archive contents can still change between builds; release builds
must additionally publish an artifact checksum and record the package manifest.
A future production milestone should use dated Debian snapshot mirrors.

`SOURCE_DATE_EPOCH` is also passed inside the chroot so SquashFS normalizes its
filesystem timestamp, and `xorriso` receives fixed image and file dates.

## Desktop policy

SOSD installs individual GNOME packages, not the Ubuntu Desktop metapackage.
The GNOME session, GDM, Adwaita, Wayland, PipeWire, WirePlumber, and
NetworkManager are selected explicitly. Ubuntu Dock, Ubuntu Session, and Yaru
themes are excluded. Starlight changes identity assets and defaults but does not
fork GNOME Shell behavior.

The upstream-oriented `gnome-core` application set supplies the normal desktop
utilities without the Ubuntu Desktop metapackage. GNOME Web provides a small
desktop browser fallback, while Chromium and Firefox ESR are installed from the
Debian package archive. Snap is intentionally excluded from the image.

The live environment and installed system use systemd explicitly; legacy SysV
live-config integration is neither selected nor required.
