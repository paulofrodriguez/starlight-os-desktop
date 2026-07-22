# Customization guide

## Branding

Custom images are intentionally disabled while the live desktop and installer
flows are stabilized. GNOME, GDM, Plymouth, and Syslinux currently use neutral
defaults. Future assets belong under `branding/` and must be tested at the
actual GDM, desktop, Plymouth, Syslinux, and Calamares resolutions before being
enabled.

Do not patch GDM Shell resources. GDM should retain upstream GNOME behavior;
only supported logo/background mechanisms should be used.

## Services

Place system services in `sosd/etc/systemd/system/`, executables in
`sosd/usr/local/sbin/`, and enable them in a numbered hook. Services must be
idempotent, log without secrets, tolerate missing optional network services, and
have an explicit state directory.

## Drivers

Firmware and CPU microcode are package-list concerns. Proprietary drivers must
not be embedded silently. The first-boot service detects PCI vendor `10de` and
installs Debian's NVIDIA Wayland stack (`nvidia-driver`,
`nvidia-open-kernel-dkms`, `libnvidia-egl-wayland1`, `nvidia-vaapi-driver`,
`nvidia-settings`, and `firmware-misc-nonfree`). Add future driver families as
independent functions with separate logs and failure handling.

## Optional applications

Proprietary applications such as Google Chrome and VS Code must use a later,
consent-driven installer that:

1. displays the vendor and license source;
2. verifies the repository signing key fingerprint;
3. installs through a signed repository;
4. records user consent and result;
5. remains absent from the ISO itself.

SOSD applies this model to Insync. WPS Office for amd64 is bundled from the
official vendor Debian package and installed during image creation when the
local `assets/third-party/wps-office_12.1.2.26885_amd64.deb` asset is present.
That large vendor binary is intentionally not tracked in Git. LinuxToys is
bundled from the upstream Debian package with matching source artifacts kept in
`assets/third-party/`. Linux Mint WebApp Manager is bundled from Mint's official
Debian package with its source archive and `.dsc` kept alongside it. Insync
verifies the official repository key fingerprint before adding its Ubuntu 26.04
repository. ZapZap is open source and is installed as a system Flatpak from
Flathub during image creation, with first boot kept as a repair/update path.

## Terminal, fonts, audio, and codecs

Ptyxis is the preferred GNOME terminal and GNOME Terminal remains available as a
conservative fallback. JetBrainsMono Nerd Font is downloaded from a pinned
upstream release, verified against the versioned SHA-256 in `config/assets.env`,
and cached under `build/downloads/`. Oh My Bash is bundled into
`/usr/share/oh-my-bash`; new users receive a Bash profile using the `agnoster`
theme and SDKMAN integration when present.

The audio layer includes PipeWire, WirePlumber, ALSA compatibility, PulseAudio
client tools, Bluetooth audio, and graphical routing/volume tools. Multimedia
support includes GStreamer base/good/bad/ugly, FFmpeg, libav, VA-API, and GNOME
metadata extraction plugins. `ubuntu-restricted-extras` is intentionally not
used because it can pull EULA-gated fonts and non-redistributable extras. The
selected codec packages still require legal review before commercial release
in each target jurisdiction.
