# Starlight Fedora RPM

This is a Fedora GNOME conversion of the Starlight OS Vega customizations. It
does not attempt to transform Fedora into Debian or replace Fedora boot, GDM,
or package-management components.

Dash to Dock, AppIndicator, Caffeine, Blur My Shell, Kiwi Menu, and the local
Starlight Clock Right extension are installed with the RPM. The optional
Starlight Brighter extension is also installed and can be enabled in GNOME
Extensions on notebooks whose displays render the standard navy palette too
dark. Tiling Assistant is not currently available in the enabled Fedora
repositories, so the package reports it as intentionally unavailable rather
than downloading it from an unpinned source.

Build it on Fedora:

```bash
sudo dnf install rpm-build rpmdevtools gtk3 python3
./packaging/fedora/build-rpm.sh
sudo dnf install ./dist/RPMS/noarch/starlight-fedora-1.0.0-13.fc44.noarch.rpm
```

The build also places a companion installer beside the RPM. It installs the
local package and applies the optional application profile for the selected
local user:

```bash
./dist/RPMS/noarch/install-and-apply-starlight-fedora-1.0.0-13.fc44.noarch.sh "$USER"
```

After the RPM is installed, the **Install Starlight profile** icon appears in
the GNOME dock and application grid. It applies the optional application set,
shows progress, assigns the avatar to the current user and then changes into
**Remove Starlight profile**. The removal view can restore the previous
applications while keeping the visual profile, or remove the Starlight RPM too.
The application set includes Bazaar, ZapZap and Telegram from Flathub.
The equivalent command-line operation remains available:

```bash
sudo starlight-fedora-apply --user "$USER"
```

The Fedora profile preserves the user's existing GNOME and terminal monospace
font. Installing the bundled programming fonts does not select one globally.
It also hides only the duplicate power button in Quick Settings; network,
sound and Bluetooth remain available, while shutdown and restart stay inside
the system menus. Firefox starts on a blank page with an empty new tab instead
of Fedora's start page, bookmarks, and pinned shortcut.

The RPM installs DNF5 defaults for the fastest mirror, ten parallel downloads,
automatic confirmation and retained cache. Enable RPM Fusion, install the
multimedia codec profile, and add the system-wide Flathub remote with:

```bash
sudo starlight-fedora-enable-rpmfusion
```

Set the Starlight light logo manually for another local user:

```bash
sudo starlight-fedora-set-user-avatar <usuario>
```

The RPM applies the complete GDM integration during installation: its 4K
background keeps the original aspect ratio, and it installs the rounded login
card and amber controls. The command below can be used to reapply it after a
GNOME Shell update; it saves the original GNOME Shell resources:

```bash
sudo /usr/libexec/starlight-fedora/apply-gdm-theme
```

The RPM also selects a dedicated Starlight Plymouth theme for boot, reboot and
shutdown and rebuilds the initramfs. Removing the RPM restores the Plymouth
theme that was active before Starlight.

Applying the profile downloads the official WPS Office 12 x86_64 RPM, verifies
its pinned SHA-256, installs it, and removes Epiphany, Chromium, and LibreOffice.
The supplied desktop launchers keep WPS in English without changing the system
locale. Both the application installation set and those removals are recorded
under `/var/lib/starlight-fedora` and can be reversed:

```bash
sudo starlight-fedora-rollback
sudo starlight-fedora-rollback --purge-assets
```

The package map installed at `/usr/share/starlight-fedora/fedora-package-map.txt`
lists all Debian-specific components intentionally left out.
