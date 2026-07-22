# Installer

SOSD uses Calamares as an independent installer layer. Configuration is copied
to `/etc/calamares` during the image build. The installer consumes the same
live filesystem produced by the core pipeline.

The visible launcher is `Install Starlight OS`. It runs
`/usr/local/bin/starlight-launch-installer`, which logs to
`/tmp/starlight-installer.log` and uses a Starlight-specific polkit action to
start `/usr/local/sbin/starlight-run-installer` as root. The root wrapper
refuses to run outside the live environment and starts Calamares through XWayland
with `QT_QPA_PLATFORM=xcb` for predictable GNOME Wayland behavior.

The user module intentionally accepts simple local passwords. Starlight does not
enforce password complexity or an 8-character minimum during installation, so a
numeric 6-digit password is valid when the user chooses that tradeoff.

The `starlight-user-avatar` module runs after `displaymanager` and writes the
Starlight AccountsService avatar for the installed user. The image is staged
from the same white empress asset used by Calamares branding.

The installer keeps the live system compatible with both BIOS and UEFI by
shipping Debian's non-conflicting GRUB module packages. The `grubcfg` module
creates `/etc/default/grub` in the target before the Starlight bootloader module
runs `grub-install` and `grub-mkconfig`. UEFI installs avoid NVRAM and implicit
Secure Boot assets, then generate the removable `EFI/BOOT/BOOTX64.EFI` path
with `grub-mkstandalone`. That standalone loader contains a direct kernel entry
using the installed root filesystem UUID, so VirtualBox can boot even when its
firmware ignores NVRAM entries or cannot find `/boot/grub/grub.cfg`.
