# Customization guide

## Branding

Custom images are intentionally disabled while the live desktop and installer
flows are stabilized. GNOME, GDM, Plymouth, and Syslinux currently use neutral
defaults. Future assets belong under `branding/` and must be tested at the
actual GDM, desktop, Plymouth, Syslinux, and Calamares resolutions before being
enabled.

Do not patch GDM Shell resources. GDM should retain upstream GNOME behavior;
only supported logo/background mechanisms should be used.

Starlight registers its own wallpaper as the GNOME default and as the
`desktop-base` wallpaper and lock-screen fallback. During image configuration,
`starlight-remove-debian-wallpapers` removes Debian `desktop-base` background
entries from the GNOME wallpaper picker and deletes the explicit
`wallpaper-withlogo` variants, while preserving upstream GNOME wallpapers and
leaving bootloader assets untouched.

## Services

Place system services in `sosd/etc/systemd/system/`, executables in
`sosd/usr/local/sbin/`, and enable them in a numbered hook. Services must be
idempotent, log without secrets, tolerate missing optional network services, and
have an explicit state directory.

## GNOME Shell extensions

System extensions should come from Debian packages whenever possible and must be
enabled through the Starlight dconf defaults, not by mutating a live user's
profile. Starlight enables Blur my Shell, Dash to Dock, AppIndicator support,
Caffeine, Tiling Assistant, and the local Starlight Clock Right extension by
default. Desktop Icons NG is intentionally not shipped because it can cover the
configured wallpaper with a solid colour on the current Starlight GNOME session.
Blur my Shell uses a dedicated `pipeline_starlight_app_grid` pipeline for the
GNOME overview/app-grid tint (`#0e1f4b` at 5% opacity). Do not add that tint to
`pipeline_default`: the top panel and Dash to Dock also consume shared Blur my
Shell pipelines, and the dock's own translucent navy styling is managed by Dash
to Dock defaults.

Clipboard Indicator (`clipboard-indicator@tudmotu.com`) and Quick Settings
Audio Panel (`quick-settings-audio-panel@rayzeq.github.io`) are compatible with
GNOME Shell 48 according to GNOME Extensions, but they are not present as direct
Debian packages in the local Debian 13 package indices used by this build.
Do not vendor those extensions from extensions.gnome.org or GitHub until the
project decides the packaging, license review, update policy, and checksum
pinning strategy.

## Drivers

Firmware and CPU microcode are package-list concerns. Proprietary drivers must
not be embedded silently. The first-boot service detects PCI vendor `10de` and
installs Debian's NVIDIA Wayland stack (`nvidia-driver`,
`nvidia-open-kernel-dkms`, `libnvidia-egl-wayland1`, `nvidia-vaapi-driver`,
`nvidia-settings`, and `firmware-misc-nonfree`). Add future driver families as
independent functions with separate logs and failure handling.

GNOME's native "Launch using Dedicated Graphics Card" integration is provided
by `switcheroo-control`, which is installed and enabled in the image. The menu
entry is intentionally left to GNOME Shell and appears only when
switcheroo-control reports a non-default GPU and the application is not already
running. It will not appear in VirtualBox or on machines exposing only one GPU.
`PrefersNonDefaultGPU=true` should be added only to individual
`.desktop` files for applications that should always prefer the discrete GPU;
do not set it globally because that would keep hybrid laptops on the dedicated
GPU unnecessarily.

GNOME Software must support both Debian packages and Flatpaks. Because live-build
runs with package recommendations disabled, the Debian backend is requested
explicitly through `gnome-software-plugin-deb`, PackageKit, AppStream, and APT
icon metadata packages instead of relying on `gnome-software` recommendations.

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
support includes GStreamer base/good/bad/ugly, FFmpeg, libav, VA-API, VDPAU,
LAME, DVD read/navigation libraries, RAR support, VLC, MPV, and GNOME metadata
extraction plugins. Intel/Mesa VA-API drivers and `vainfo` are selected
explicitly so video acceleration can be inspected without changing the NVIDIA
first-boot driver policy.

EasyEffects is available for user-controlled PipeWire effects. Starlight
reserves `/usr/share/starlight/easyeffects/presets/` for future validated
presets, but ships no preset JSON and enables no effects automatically.

`ubuntu-restricted-extras` is intentionally not used because it can pull
EULA-gated fonts and non-redistributable extras; encrypted DVD CSS support is
not bundled. The selected codec packages still require legal review before
commercial release in each target jurisdiction.

## Files, network, and devices

Nautilus remains the file manager and File Roller remains the archive UI.
`gnome-core` supplies GVFS backends and Sushi integration. Starlight adds
explicit Debian packages for Avahi/mDNS discovery, `.local` resolution, SMB/CIFS
clients and mounts, exFAT, NTFS, MTP tools, and 7-Zip archive support. These
packages complement GNOME and do not replace Nautilus, File Roller, or the
existing MIME defaults.
