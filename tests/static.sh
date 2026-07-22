#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "${PROJECT_ROOT}/sosd/etc/os-release"
test -f "${PROJECT_ROOT}/sosd/etc/systemd/system/starlight-firstboot.service"
test -f "${PROJECT_ROOT}/config/assets.env"
test -s "${PROJECT_ROOT}/branding/starlight-wallpaper.png"
test -f "${PROJECT_ROOT}/installer/modules/unpackfs.conf"
test -f "${PROJECT_ROOT}/installer/modules/welcome.conf"
test -f "${PROJECT_ROOT}/installer/modules/grubcfg.conf"
test -f "${PROJECT_ROOT}/installer/modules/starlight-bootloader/module.desc"
test -f "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
test -f "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/module.desc"
test -f "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py"
test -f "${PROJECT_ROOT}/installer/modules/users.conf"
test -s "${PROJECT_ROOT}/branding/starlight-calamares.png"
test -s "${PROJECT_ROOT}/branding/starlight-calamares-light.png"
test -s "${PROJECT_ROOT}/branding/starlight-calamares-dark.png"
test -f "${PROJECT_ROOT}/sosd/etc/systemd/system/starlight-live-session.service"
test -f "${PROJECT_ROOT}/sosd/lib/live/config/0035-starlight-user"
test -f "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-launch-installer"
test -f "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-run-installer"
test -f "${PROJECT_ROOT}/docs/metapackages.md"
test -f "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
test -f "${PROJECT_ROOT}/flatpaks/system-apps.txt"
test -f "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
test -f "${PROJECT_ROOT}/sosd/etc/skel/.profile"
for helper_script in \
    starlight-enable-debian-components \
    starlight-enable-steam-i386 \
    starlight-configure-flathub \
    starlight-enable-element-repo \
    starlight-install-homebrew \
    starlight-install-sdkman \
    starlight-install-oh-my-bash \
    starlight-install-jetbrainsmono-nerd-font \
    starlight-configure-terminals; do
    test -x "${PROJECT_ROOT}/sosd/usr/local/sbin/${helper_script}"
done

rg -q '^ID=starlight$' "${PROJECT_ROOT}/sosd/etc/os-release"
rg -q '^WaylandEnable=true$' "${PROJECT_ROOT}/sosd/etc/gdm3/custom.conf"
rg -q '^SOSD_LIVE_AUTOLOGIN=true$' "${PROJECT_ROOT}/config/build.env"
rg -q '^SOSD_ENABLE_I386=true$' "${PROJECT_ROOT}/config/build.env"
rg -q 'GDM_CONFIG=/etc/gdm3/custom.conf' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-live-session"
rg -q "starlight:starlight" \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-live-session"
rg -Fq '${LIVE_USERNAME}:${LIVE_USERNAME}' \
    "${PROJECT_ROOT}/sosd/lib/live/config/0035-starlight-user"
rg -q '^After=live-config.service$' \
    "${PROJECT_ROOT}/sosd/etc/systemd/system/starlight-live-session.service"
rg -q '^SOSD_BUILD_JOBS=2$' "${PROJECT_ROOT}/config/build.env"
rg -Fq "picture-uri='file:///usr/share/backgrounds/starlight/starlight-wallpaper.png'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "accent-color='yellow'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "color-scheme='prefer-dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "gtk-theme='Adwaita-dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "icon-theme='Starlight-Colloid-Yellow-Dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "monospace-font-name='JetBrainsMono Nerd Font 11'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "exec='ptyxis'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
! rg -q 'padding-left: 42%;' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -q '//RIGHT' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/scripts/install-gdm-theme.sh"
rg -Fq '.quick-toggle:checked' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq 'background-gradient-start: #f3c653;' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq '.calendar .calendar-day.calendar-today' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq '.calendar-day-base' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
test -s "${PROJECT_ROOT}/sosd/etc/gtk-3.0/gtk.css"
test -s "${PROJECT_ROOT}/sosd/etc/gtk-4.0/gtk.css"
test -s "${PROJECT_ROOT}/sosd/etc/skel/.config/gtk-3.0/gtk.css"
test -s "${PROJECT_ROOT}/sosd/etc/skel/.config/gtk-4.0/gtk.css"
rg -Fq 'headerbar.titlebar' "${PROJECT_ROOT}/sosd/etc/gtk-4.0/gtk.css"
rg -Fq '@define-color headerbar_bg_color #08111e;' \
    "${PROJECT_ROOT}/sosd/etc/gtk-4.0/gtk.css"
rg -Fq '/home/starlight/.config/gtk-${gtk_version}/gtk.css' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-live-session"
rg -q '^LIVE_USER_FULLNAME="Starlight"$' "${PROJECT_ROOT}/sosd/etc/live/config.conf"
for bundled_asset in starlight-colloid-icon-theme.tar.gz tela-circle-icon-theme.tar.gz \
    wps-office_12.1.2.26885_amd64.deb linuxtoys_6.4.8-1_amd64.deb \
    linuxtoys_6.4.8.orig.tar.xz linuxtoys_6.4.8-1.debian.tar.xz \
    linuxtoys_6.4.8-1.dsc webapp-manager_1.4.6_all.deb \
    webapp-manager_1.4.6.tar.xz webapp-manager_1.4.6.dsc \
    oh-my-bash-627913b75855036cb5af2f3ad130c66a335e7382.tar.gz; do
    test -s "${PROJECT_ROOT}/assets/third-party/${bundled_asset}"
done
test "$(dpkg-deb -f "${PROJECT_ROOT}/assets/third-party/wps-office_12.1.2.26885_amd64.deb" Version)" = \
    "12.1.2.26885.AK.preread.sw"
sha256sum -c <<EOF
55da5149467a1584b4b6d1280cb5ab04c061453974810fac9679b33bd8664e51  ${PROJECT_ROOT}/assets/third-party/wps-office_12.1.2.26885_amd64.deb
EOF
rg -q '^menu background splash.png$' \
    "${PROJECT_ROOT}/config/bootloaders/isolinux/stdmenu.cfg"
test ! -e "${PROJECT_ROOT}/sosd/etc/dconf/db/gdm.d/00-starlight"
rg -q 'flathub.org/repo/flathub.flatpakrepo' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'com.rtosta.zapzap' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'AEEB94E9C5A3B54ECFA4A66AA684470CACCAF35C' \
    "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-install-insync"
rg -q 'package_name.*wps-office' \
    "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-install-wps"
rg -q 'com.mitchellh.ghostty' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'nvidia-open-kernel-dkms' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'libnvidia-egl-wayland1' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q '^com.rtosta.zapzap$' "${PROJECT_ROOT}/flatpaks/system-apps.txt"
rg -Fq 'flatpak install --system --noninteractive --or-update flathub' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq '/usr/local/sbin/starlight-install-bundled-assets' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"
rg -q 'LINUXTOYS_PACKAGE' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -q 'WEBAPP_MANAGER_PACKAGE' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'rm -rf "${ASSET_ROOT}"' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'apt-mark manual' "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"
rg -Fq 'grub-efi-amd64-bin' "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"
rg -q '/usr/share/oh-my-bash' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'OSH_THEME=${STARLIGHT_OMB_THEME:-agnoster}' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
rg -Fq '/usr/share/oh-my-bash' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
rg -Fq '.sdkman/bin/sdkman-init.sh' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
rg -Fq 'raw.githubusercontent.com/Homebrew/install/HEAD/install.sh' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-homebrew"
rg -Fq 'get.sdkman.io' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-sdkman"
rg -Fq 'dpkg --add-architecture i386' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'https://packages.element.io/debian/ default main' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -q '^ELEMENT_KEY_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '^LINUXTOYS_PACKAGE_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '^WEBAPP_MANAGER_PACKAGE_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '^WEBAPP_MANAGER_SOURCE_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '^OH_MY_BASH_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '^thunderbird$' "${PROJECT_ROOT}/packages/communication.list.chroot"
rg -q '^element-desktop$' "${PROJECT_ROOT}/packages/communication.list.chroot"
rg -q '^steam-installer$' "${PROJECT_ROOT}/packages/gaming.list.chroot"
rg -q '^steam-devices$' "${PROJECT_ROOT}/packages/gaming.list.chroot"
rg -q '^gamemode$' "${PROJECT_ROOT}/packages/gaming.list.chroot"
rg -q '^mangohud$' "${PROJECT_ROOT}/packages/gaming.list.chroot"
rg -q '^incus$' "${PROJECT_ROOT}/packages/incus.list.chroot"
rg -q '^incus-client$' "${PROJECT_ROOT}/packages/incus.list.chroot"
rg -q '^incus-extra$' "${PROJECT_ROOT}/packages/incus.list.chroot"
rg -q '^ptyxis$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^gnome-terminal$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^starship$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^fonts-cascadia-code$' "${PROJECT_ROOT}/packages/terminal-fonts.list.chroot"
rg -q '^fonts-noto-color-emoji$' "${PROJECT_ROOT}/packages/terminal-fonts.list.chroot"
rg -q '^gir1.2-xapp-1.0$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^xapps-common$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^python3-bs4$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^python3-configobj$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^python3-pil$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^python3-setproctitle$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^python3-tldextract$' "${PROJECT_ROOT}/packages/webapps-support.list.chroot"
rg -q '^element-desktop$' \
    "${PROJECT_ROOT}/metapackages/distro-communication.depends"
rg -q '^chromium$' "${PROJECT_ROOT}/packages/build.list.chroot"
rg -q '^firefox-esr$' "${PROJECT_ROOT}/packages/build.list.chroot"
rg -q '^user-setup$' "${PROJECT_ROOT}/packages/base.list.chroot"
! rg -q '^(snapd|casper|ubuntu-drivers-common)$' \
    "${PROJECT_ROOT}/packages" --glob '*.list.chroot'
rg -q '^gnome-core$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
rg -q '^papirus-icon-theme$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
rg -q '^qt6-wayland$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^squashfs-tools$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^rsync$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^dosfstools$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^efibootmgr$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^grub2-common$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^grub-pc-bin$' "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -q '^grub-efi-amd64-bin$' "${PROJECT_ROOT}/packages/installer.list.chroot"
! rg -q '^(grub-pc|grub-efi-amd64|shim-signed)$' \
    "${PROJECT_ROOT}/packages/installer.list.chroot"
rg -Fq 'build_uefi_boot_image' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'grub-mkstandalone' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'BOOTX64.EFI' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq -- '-eltorito-alt-boot' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq -- '-isohybrid-gpt-basdat' "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq '    - grubcfg' "${PROJECT_ROOT}/installer/settings.conf"
rg -Fq '    - starlight-bootloader' "${PROJECT_ROOT}/installer/settings.conf"
rg -Fq '    - starlight-user-avatar' "${PROJECT_ROOT}/installer/settings.conf"
rg -Fq -- '--no-nvram' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
rg -Fq -- '--no-uefi-secure-boot' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
rg -Fq 'grub-mkstandalone' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
rg -Fq 'BOOTX64.EFI' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
rg -Fq 'root=UUID=' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
! rg -Fq 'could not find /boot/grub/grub.cfg' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"
rg -Fq 'always_use_defaults: true' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"
rg -Fq 'GRUB_DISABLE_OS_PROBER: false' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"
rg -Fq 'Exec=/usr/local/bin/starlight-launch-installer' \
    "${PROJECT_ROOT}/sosd/usr/share/applications/starlight-install.desktop"
rg -Fq 'NoDisplay=true' \
    "${PROJECT_ROOT}/sosd/usr/share/applications/calamares.desktop"
rg -Fq 'com.starlight.install.pkexec.run' \
    "${PROJECT_ROOT}/sosd/etc/polkit-1/rules.d/49-starlight-live-installer.rules"
rg -q '^epiphany-browser$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
rg -q '^libavcodec-extra$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^NERD_FONT_SHA256=[0-9a-f]{64}$' "${PROJECT_ROOT}/config/assets.env"
rg -q '/run/live/medium/live/filesystem.squashfs' \
    "${PROJECT_ROOT}/installer/modules/unpackfs.conf"
rg -Fq 'destination: "/"' \
    "${PROJECT_ROOT}/installer/modules/unpackfs.conf"
rg -Fq 'requiredStorage: 30' \
    "${PROJECT_ROOT}/installer/modules/welcome.conf"
rg -Fq 'requiredRam: 2.0' \
    "${PROJECT_ROOT}/installer/modules/welcome.conf"
rg -Fq '    - welcome' "${PROJECT_ROOT}/installer/settings.conf"
rg -Fq 'mountPoint: /boot/efi' \
    "${PROJECT_ROOT}/installer/modules/partition.conf"
rg -Fq 'efiSystemPartition: /boot/efi' \
    "${PROJECT_ROOT}/installer/modules/partition.conf"
! rg -Fq 'requiredPartitionTableType:' \
    "${PROJECT_ROOT}/installer/modules/partition.conf"
rg -Fq 'GRUB_TIMEOUT: 5' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"
rg -Fq 'grubProbe: grub-probe' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"
rg -Fq 'efiBootMgr: efibootmgr' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"
rg -Fq 'installEFIFallback: true' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"
rg -Fq 'productIcon: starlight-calamares.png' \
    "${PROJECT_ROOT}/installer/branding.desc"
rg -Fq 'productLogo: starlight-calamares.png' \
    "${PROJECT_ROOT}/installer/branding.desc"
rg -Fq 'productWelcome: starlight-calamares-dark.png' \
    "${PROJECT_ROOT}/installer/branding.desc"
rg -Fq 'sync_calamares_config chroot' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'usr/lib/x86_64-linux-gnu/calamares/modules' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'installer/modules/${local_module}/' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'starlight-user-avatar' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'branding/starlight-calamares.png' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'AccountsService/icons' \
    "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py"
rg -Fq '.sosd-package-lists.sha256' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'SidebarBackgroundCurrent: "#c89b3c"' \
    "${PROJECT_ROOT}/installer/branding.desc"
rg -q '^setRootPassword: false$' \
    "${PROJECT_ROOT}/installer/modules/users.conf"
rg -q 'name: sudo' "${PROJECT_ROOT}/installer/modules/users.conf"
rg -q '^allowWeakPasswords: true$' \
    "${PROJECT_ROOT}/installer/modules/users.conf"
rg -q '^allowWeakPasswordsDefault: true$' \
    "${PROJECT_ROOT}/installer/modules/users.conf"
rg -q '^  minLength: 1$' "${PROJECT_ROOT}/installer/modules/users.conf"

echo "Static tests passed."
