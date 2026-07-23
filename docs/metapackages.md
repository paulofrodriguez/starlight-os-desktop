# Package lists, metapackages, and app integration

Starlight OS Vega builds the live image from `packages/*.list.chroot`.
The `metapackages/*.depends` files mirror the same product groups for future
Debian metapackages and post-install installers.

## Metapackage groups

- `distro-desktop-gnome`: GNOME, Wayland, portals, PipeWire, and common
  desktop applications plus the Debian-packaged default GNOME Shell extensions.
  LibreOffice is intentionally excluded because the image bundles WPS Office.
- `distro-codecs-media`: codecs, GStreamer plugin set, VLC, MPV, and GIMP.
- `distro-files-devices`: network discovery, Windows share clients, exFAT,
  NTFS, MTP, and 7-Zip support for the file manager and command-line tools.
- `distro-gaming`: Steam, Vulkan, GameMode, MangoHud, GOverlay, and vkBasalt.
- `distro-nvidia`: Debian NVIDIA driver stack with EGL Wayland and VA-API.
- `distro-devtools`: developer tools, virtualization, containers, shells,
  terminal utilities, and the DKMS/kernel-header prerequisites needed to build
  VirtualBox Guest Additions inside a VM.
- `distro-shell-defaults`: shell utilities, Starship, terminal fonts, and
  prerequisites for Homebrew/SDKMAN/Oh My Bash.
- `distro-system-polish`: firmware update, Flatpak permission review, power,
  maintenance, and GUI package management helpers.
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
`packages/*.list.chroot`. LibreOffice is not requested in the GNOME package
group; WPS Office is the bundled office suite.

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
GitHub repository. Its upstream `postinst` may fail in a live-build chroot after
the package is unpacked; the bundled asset installer records the original
maintainer script, marks the package configured, and refreshes desktop, MIME,
icon, and font caches manually.

Linux Mint WebApp Manager is bundled from the official Mint Debian package and
source archive. Its Debian XApp/Python dependencies are declared in
`packages/webapps-support.list.chroot`.

JetBrainsMono Nerd Font and Oh My Bash are installed in the live image. The
default Bash profile uses the `agnoster` Oh My Bash theme with a Starship
fallback. Homebrew and SDKMAN remain explicit user-level installers because
they install into the target user's home or `/home/linuxbrew`.

File and device integration is kept in `packages/files-devices.list.chroot`.
GNOME's `gvfs-backends` remains the desktop integration layer from
`gnome-core`; the explicit file/device list adds mDNS discovery, `.local` name
resolution, CIFS/SMB tools, exFAT, NTFS, MTP runtime/tools, and 7-Zip support
without replacing Nautilus or File Roller.

GNOME Shell extension defaults are kept in `packages/gnome.list.chroot` and the
Starlight dconf database. AppIndicator support, Caffeine, and Tiling Assistant
are Debian packages and are enabled by default. Desktop Icons NG is not shipped
because it can hide the Starlight wallpaper with a solid desktop-colour surface.
Clipboard Indicator and Quick Settings Audio Panel are not added yet because
the local Debian 13 indices do not provide direct packages for those exact
extensions.

GNOME Software includes both Flatpak and Debian/APT support. The Debian backend
is explicit (`gnome-software-plugin-deb`, PackageKit, AppStream, and APT icon
metadata) because package recommendations are disabled during live-build and the
Flatpak plugin alone can satisfy GNOME Software's generic plugin dependency.

VirtualBox Guest Additions are not bundled as Oracle software, but the image
ships `build-essential`, `dkms`, `linux-headers-amd64`, `perl`, and `bzip2` so
the standard Guest Additions installer can build modules inside a VirtualBox VM.

## Known package notes

- `steam-installer` cannot be resolved until `i386` is enabled and i386 package
  indices are refreshed; the build handles this for amd64 images.
- `element-desktop` is external APT, not Debian stable.
- `com.rtosta.zapzap` is Flatpak, not a Debian package dependency.
- `linuxtoys` is installed from a bundled upstream `.deb`, not from Debian.
- `webapp-manager` is installed from a bundled Linux Mint `.deb`, not from
  Debian.
- `timeshift` is the current installed-system backup/restore tool. Pika Backup
  is not present in the Debian 13 package indices used by this build, and
  Deja Dup is not added while Timeshift remains the selected solution.
- EasyEffects is installed for optional PipeWire effects, but Starlight ships
  only an empty preset directory and does not enable or publish audio presets by
  default.
- `switcheroo-control` is installed and enabled for GNOME's native dedicated
  GPU launch menu. Starlight does not add launcher wrappers or global
  `PrefersNonDefaultGPU=true` entries. The menu is expected to be absent in
  VirtualBox and other single-GPU environments.
- `nvidia-open-kernel-dkms` resolved with `nvidia-driver` in Debian trixie
  during local APT simulation, but legacy NVIDIA GPUs may still need a different
  branch selected by Debian's NVIDIA packages.
