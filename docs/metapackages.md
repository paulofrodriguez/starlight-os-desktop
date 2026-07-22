# Package lists, metapackages, and app integration

Starlight OS Vega builds the live image from `packages/*.list.chroot`.
The `metapackages/*.depends` files mirror the same product groups for future
Debian metapackages and post-install installers.

## Metapackage groups

- `distro-desktop-gnome`: GNOME, Wayland, portals, PipeWire, office and common
  desktop applications.
- `distro-codecs-media`: codecs, GStreamer plugin set, VLC, MPV, and GIMP.
- `distro-gaming`: Steam, Vulkan, GameMode, MangoHud, GOverlay, and vkBasalt.
- `distro-nvidia`: Debian NVIDIA driver stack with EGL Wayland and VA-API.
- `distro-devtools`: developer tools, virtualization, containers, shells, and
  terminal utilities.
- `distro-shell-defaults`: shell utilities, Starship, terminal fonts, and
  prerequisites for Homebrew/SDKMAN/Oh My Bash.
- `distro-system-polish`: firmware update, power, maintenance, and GUI package
  management helpers.
- `distro-incus`: Incus runtime, client, extra tools, and common storage/network
  helpers.
- `distro-firmware`: firmware and CPU microcode packages.
- `distro-communication`: Thunderbird from Debian plus Element from the official
  Element APT repository.

## Live image policy

Debian packages should come from `main contrib non-free non-free-firmware`
whenever possible. `starlight-enable-debian-components` adds a managed Debian
source file only if the required components are missing.

Thunderbird, Steam, Incus, GNOME/Wayland components, GNOME Tweaks, terminal
tools, firmware, and common desktop applications are requested directly through
`packages/*.list.chroot`.

Steam requires `i386` on amd64 systems. The build enables the foreign `i386`
architecture before `lb chroot` so `steam-installer` can resolve its i386
runtime dependencies. `starlight-enable-steam-i386` remains available for
installed systems that need repair.

Element Desktop is not in Debian trixie. The image build pins the official
Element repository key, writes the Element APT source into live-build, and then
installs `element-desktop` through APT. `starlight-enable-element-repo` remains
available for installed systems.

ZapZap is installed as a system Flatpak (`com.rtosta.zapzap`) from Flathub
during image creation. First boot still attempts to repair/update the same
Flatpak if networking was unavailable during a custom build.

LinuxToys is bundled from the upstream Debian package and the matching source
artifacts are kept under `assets/third-party/` for redistribution traceability.

WPS Office is bundled only when the local
`assets/third-party/wps-office_12.1.2.26885_amd64.deb` vendor package is present.
The file is intentionally ignored by Git because it is too large for a normal
GitHub repository.

Linux Mint WebApp Manager is bundled from the official Mint Debian package and
source archive. Its Debian XApp/Python dependencies are declared in
`packages/webapps-support.list.chroot`.

JetBrainsMono Nerd Font and Oh My Bash are installed in the live image. The
default Bash profile uses the `agnoster` Oh My Bash theme with a Starship
fallback. Homebrew and SDKMAN remain explicit user-level installers because
they install into the target user's home or `/home/linuxbrew`.

## Known package notes

- `steam-installer` cannot be resolved until `i386` is enabled and i386 package
  indices are refreshed; the build handles this for amd64 images.
- `element-desktop` is external APT, not Debian stable.
- `com.rtosta.zapzap` is Flatpak, not a Debian package dependency.
- `linuxtoys` is installed from a bundled upstream `.deb`, not from Debian.
- `webapp-manager` is installed from a bundled Linux Mint `.deb`, not from
  Debian.
- `nvidia-open-kernel-dkms` resolved with `nvidia-driver` in Debian trixie
  during local APT simulation, but legacy NVIDIA GPUs may still need a different
  branch selected by Debian's NVIDIA packages.
