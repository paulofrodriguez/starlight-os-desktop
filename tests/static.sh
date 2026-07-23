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
test -f "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/module.desc"
test -f "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
test -f "${PROJECT_ROOT}/installer/modules/users.conf"
test -s "${PROJECT_ROOT}/branding/starlight-calamares.png"
test -s "${PROJECT_ROOT}/branding/starlight-calamares-light.png"
test -s "${PROJECT_ROOT}/branding/starlight-calamares-dark.png"
test -f "${PROJECT_ROOT}/sosd/etc/systemd/system/starlight-live-session.service"
test -f "${PROJECT_ROOT}/sosd/lib/live/config/0035-starlight-user"
test -f "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-launch-installer"
test -f "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-run-installer"
test -f "${PROJECT_ROOT}/sosd/usr/share/firefox-esr/distribution/policies.json"
test -f "${PROJECT_ROOT}/sosd/usr/share/starlight/easyeffects/presets/README.md"
test -f "${PROJECT_ROOT}/docs/metapackages.md"
test -f "${PROJECT_ROOT}/packages/files-devices.list.chroot"
test -f "${PROJECT_ROOT}/metapackages/distro-files-devices.depends"
test -f "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
test -f "${PROJECT_ROOT}/flatpaks/system-apps.txt"
test -f "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
test -f "${PROJECT_ROOT}/sosd/etc/skel/.profile"
test -f "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/metadata.json"
test -f "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js"
for helper_script in \
    starlight-configure-debian-apt-sources \
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
rg -Fxq 'deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot"
rg -Fxq 'deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot"
rg -Fxq 'deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot"
! rg -q '^[[:space:]]*deb[[:space:]]+cdrom:' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot"
rg -Fq 'config/includes.chroot/etc/apt/sources.list' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq '/usr/local/sbin/starlight-configure-debian-apt-sources' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"
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
rg -Fq "'starlight-clock-right@starlightbrasil.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fq "pipeline_starlight_app_grid" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fq "'color': <(0.054901960784313725, 0.12156862745098039, 0.29411764705882354, 0.05)>" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "pipeline='pipeline_starlight_app_grid'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "pipeline='pipeline_default'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "pipeline='pipeline_default_rounded'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
for enabled_extension in \
    "'ubuntu-appindicators@ubuntu.com'" \
    "'caffeine@patapon.info'" \
    "'tiling-assistant@leleat-on-github'"; do
    rg -Fq "${enabled_extension}" \
        "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
done
! rg -Fq "'ding@rastersoft.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fq "favorite-apps=['chromium.desktop'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
! rg -q "favorite-apps=.*firefox" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "show-weekdate=true" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq 'text/html=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
rg -Fxq 'x-scheme-handler/http=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
rg -Fxq 'x-scheme-handler/https=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
rg -Fxq 'application/vnd.debian.binary-package=gdebi.desktop' \
    "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
rg -Fxq 'application/x-deb=gdebi.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
rg -Fxq 'application/x-debian-package=gdebi.desktop' \
    "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
! rg -q '^application/(vnd\.debian\.binary-package|x-deb|x-debian-package)=.*(file-roller|FileRoller)' \
    "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"
python3 -c 'import json, pathlib, sys; policies = json.loads(pathlib.Path(sys.argv[1]).read_text())["policies"]; assert policies["NoDefaultBookmarks"] is True; assert "Debian packages" in policies["SearchEngines"]["Remove"]' \
    "${PROJECT_ROOT}/sosd/usr/share/firefox-esr/distribution/policies.json"
test ! -e "${PROJECT_ROOT}/sosd/usr/share/applications/starlight-browser.desktop"
! rg -q 'epiphany' "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-browser"
rg -Fxq "background-color='#07182b'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fxq "background-opacity=0.74" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"
rg -Fq '#dashtodockContainer .dash-background' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq 'background-gradient-start: rgba(19, 46, 74, 0.82);' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq 'border: 1px solid rgba(147, 190, 235, 0.28);' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
rg -Fq 'Main.panel.statusArea.dateMenu' \
    "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js"
rg -Fq 'Main.panel._rightBox' \
    "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js"
rg -Fq 'insert_child_at_index' \
    "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js"
python3 -c 'import json, pathlib, sys; data = json.loads(pathlib.Path(sys.argv[1]).read_text()); assert data["uuid"] == "starlight-clock-right@starlightbrasil.com"; assert "48" in data["shell-version"]' \
    "${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/metadata.json"
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
for shell_selector in \
    '.unlock-dialog' \
    '.modal-dialog' \
    '.end-session-dialog' \
    '.message-dialog-content' \
    '.prompt-dialog' \
    '.run-dialog' \
    '.polkit-dialog-user-layout' \
    '.access-dialog' \
    '.audio-device-selection-dialog' \
    '.screenshot-ui-panel' \
    '.switcher-list' \
    '.osd-window' \
    '#LookingGlassDialog'; do
    rg -Fq "${shell_selector}" \
        "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"
done
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
rg -Fq 'wps-office-wps.desktop' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -Fq 'wps-office2023-wpsmain.svg' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -q 'com.mitchellh.ghostty' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'nvidia-open-kernel-dkms' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q 'libnvidia-egl-wayland1' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-firstboot"
rg -q '^com.rtosta.zapzap$' "${PROJECT_ROOT}/flatpaks/system-apps.txt"
rg -Fq 'flatpak install --system --noninteractive --or-update flathub' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'install_wps_office' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'postinst.starlight-original' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"
rg -Fq 'dpkg --configure wps-office' \
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
rg -Fq 'plugins=(git sudo bashmarks colored-man-pages)' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"
rg -Fq 'plugins=(git sudo bashmarks colored-man-pages)' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-oh-my-bash"
! rg -Fq 'plugins=(git sudo history bashmarks)' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc" \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-oh-my-bash"
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
rg -q '^gnome-tweaks$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
for gnome_extension_package in \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-tiling-assistant; do
    rg -qx "${gnome_extension_package}" "${PROJECT_ROOT}/packages/gnome.list.chroot"
    rg -qx "${gnome_extension_package}" \
        "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
done
! rg -qx 'gnome-shell-extension-desktop-icons-ng' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot"
! rg -qx 'gnome-shell-extension-desktop-icons-ng' \
    "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
rg -Fq 'Desktop Icons NG must not be installed' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -Fq 'test ! -e /usr/share/gnome-shell/extensions/ding@rastersoft.com' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
! rg -q '^(task-gnome-desktop|libreoffice|libreoffice-gtk3)$' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot"
! rg -q '^(task-gnome-desktop|libreoffice|libreoffice-gtk3)$' \
    "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
rg -q '^ptyxis$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^gnome-terminal$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^starship$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^build-essential$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^dkms$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^linux-headers-amd64$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^perl$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^bzip2$' "${PROJECT_ROOT}/packages/development.list.chroot"
rg -q '^dkms$' "${PROJECT_ROOT}/metapackages/distro-devtools.depends"
rg -q '^linux-headers-amd64$' "${PROJECT_ROOT}/metapackages/distro-devtools.depends"
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
rg -q '^gnome-tweaks$' \
    "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
rg -Fq 'org.gnome.tweaks.desktop' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -Fq 'Icon=org.gnome.tweaks' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -q '^chromium$' "${PROJECT_ROOT}/packages/build.list.chroot"
rg -q '^firefox-esr$' "${PROJECT_ROOT}/packages/build.list.chroot"
rg -q '^user-setup$' "${PROJECT_ROOT}/packages/base.list.chroot"
! rg -q '^(snapd|casper|ubuntu-drivers-common)$' \
    "${PROJECT_ROOT}/packages" --glob '*.list.chroot'
rg -q '^gnome-core$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
! rg -q '^epiphany-browser$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
for gnome_software_deb_package in \
    gnome-software-plugin-deb \
    gnome-software-plugin-fwupd \
    packagekit \
    packagekit-tools \
    appstream \
    apt-config-icons; do
    rg -qx "${gnome_software_deb_package}" \
        "${PROJECT_ROOT}/packages/gnome.list.chroot"
    rg -qx "${gnome_software_deb_package}" \
        "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
done
rg -Fq 'libgs_plugin_packagekit.so' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -Fq 'org.freedesktop.PackageKit.service' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
rg -q '^seahorse$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
rg -q '^seahorse$' "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"
rg -q '^papirus-icon-theme$' "${PROJECT_ROOT}/packages/gnome.list.chroot"
rg -q '^gnome-firmware$' "${PROJECT_ROOT}/packages/system-polish.list.chroot"
rg -q '^flatseal$' "${PROJECT_ROOT}/packages/system-polish.list.chroot"
rg -q '^switcheroo-control$' "${PROJECT_ROOT}/packages/system-polish.list.chroot"
rg -q '^gnome-firmware$' "${PROJECT_ROOT}/metapackages/distro-system-polish.depends"
rg -q '^flatseal$' "${PROJECT_ROOT}/metapackages/distro-system-polish.depends"
rg -q '^switcheroo-control$' "${PROJECT_ROOT}/metapackages/distro-system-polish.depends"
rg -Fq 'systemctl enable switcheroo-control.service' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"
rg -Fq 'com.github.tchx84.Flatseal' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"
for files_device_package in \
    avahi-daemon \
    libnss-mdns \
    cifs-utils \
    smbclient \
    exfatprogs \
    ntfs-3g \
    libmtp-runtime \
    mtp-tools \
    7zip; do
    rg -qx "${files_device_package}" "${PROJECT_ROOT}/packages/files-devices.list.chroot"
    rg -qx "${files_device_package}" \
        "${PROJECT_ROOT}/metapackages/distro-files-devices.depends"
done
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
rg -Fq '    - starlight-clean-installed-system' \
    "${PROJECT_ROOT}/installer/settings.conf"
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
rg -q '^libavcodec-extra$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^ffmpeg$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-plugins-base$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-plugins-good$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-plugins-bad$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-plugins-ugly$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-libav$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^gstreamer1.0-vaapi$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^va-driver-all$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^vdpau-driver-all$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^vainfo$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^easyeffects$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^va-driver-all$' "${PROJECT_ROOT}/metapackages/distro-codecs-media.depends"
rg -q '^vdpau-driver-all$' "${PROJECT_ROOT}/metapackages/distro-codecs-media.depends"
rg -q '^vainfo$' "${PROJECT_ROOT}/metapackages/distro-codecs-media.depends"
rg -q '^easyeffects$' "${PROJECT_ROOT}/metapackages/distro-codecs-media.depends"
rg -q '^lame$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^libdvdnav4$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^libdvdread8t64$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^unrar$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
rg -q '^vlc$' "${PROJECT_ROOT}/packages/audio-codecs.list.chroot"
! find "${PROJECT_ROOT}/sosd/usr/share/starlight/easyeffects/presets" \
    -maxdepth 1 -type f -name '*.json' | grep -q .
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
rg -Fq 'starlight-clean-installed-system' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'starlight-user-avatar' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'branding/starlight-calamares.png' \
    "${PROJECT_ROOT}/scripts/build.sh"
rg -Fq 'AccountsService/icons' \
    "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py"
test -f "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/module.desc"
test -f "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
rg -Fq 'PACKAGES_TO_PURGE' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
rg -Fq 'starlight-install.desktop' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
rg -Fq 'epiphany-browser' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
rg -Fq 'dconf", "update"' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"
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
