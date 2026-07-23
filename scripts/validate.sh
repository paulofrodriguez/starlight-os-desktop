#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_build_env

errors=0

require_package() {
    local package_name="$1"
    local package_list="$2"
    local message="$3"

    if ! rg -qx "${package_name}" "${PROJECT_ROOT}/packages/${package_list}"; then
        echo "${message}" >&2
        ((errors += 1))
    fi
}

verify_third_party_asset() {
    local file_name="$1"
    local expected_sha256="$2"

    if [[ ! "${expected_sha256}" =~ ^[0-9a-f]{64}$ ]]; then
        echo "Invalid SHA-256 for bundled asset: ${file_name}" >&2
        ((errors += 1))
    elif [[ ! -s "${PROJECT_ROOT}/assets/third-party/${file_name}" ]]; then
        echo "Missing bundled asset: ${file_name}" >&2
        ((errors += 1))
    elif ! printf '%s  %s\n' "${expected_sha256}" \
        "${PROJECT_ROOT}/assets/third-party/${file_name}" | sha256sum -c -
    then
        echo "Bundled asset checksum mismatch: ${file_name}" >&2
        ((errors += 1))
    fi
}

required_directories=(
    sosd build branding packages hooks scripts config docs tests installer assets
)

for directory in "${required_directories[@]}"; do
    if [[ ! -d "${PROJECT_ROOT}/${directory}" ]]; then
        echo "Missing directory: ${directory}" >&2
        ((errors += 1))
    fi
done

while IFS= read -r script; do
    first_non_comment="$(awk 'NR == 1 { next } /^[[:space:]]*#/ { next } NF { print; exit }' "${script}")"
    if [[ "${first_non_comment}" != "set -Eeuo pipefail" ]]; then
        echo "${script}: must use set -Eeuo pipefail" >&2
        ((errors += 1))
    fi
    bash -n "${script}" || ((errors += 1))
done < <(find "${PROJECT_ROOT}/scripts" "${PROJECT_ROOT}/hooks" \
    "${PROJECT_ROOT}/sosd/usr/local" -type f -print | sort)

if command -v shellcheck >/dev/null 2>&1; then
    mapfile -t shell_files < <(find "${PROJECT_ROOT}/scripts" \
        "${PROJECT_ROOT}/hooks" "${PROJECT_ROOT}/sosd/usr/local" \
        -type f -print | sort)
    shellcheck "${shell_files[@]}" || ((errors += 1))
else
    echo "Warning: shellcheck is not installed." >&2
fi

for forbidden in ubuntu-desktop ubuntu-session gnome-shell-extension-ubuntu-dock \
    yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon snapd casper \
    ubuntu-drivers-common task-gnome-desktop libreoffice libreoffice-gtk3 \
    epiphany-browser; do
    if rg -n "^[[:space:]]*${forbidden}[[:space:]]*$" \
        "${PROJECT_ROOT}/packages" --glob '*.list.chroot'; then
        echo "Forbidden package requested: ${forbidden}" >&2
        ((errors += 1))
    fi
done

for excluded_desktop_package in task-gnome-desktop libreoffice libreoffice-gtk3; do
    if rg -n "^[[:space:]]*${excluded_desktop_package}[[:space:]]*$" \
        "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"; then
        echo "Excluded desktop package requested by metapackage: ${excluded_desktop_package}" >&2
        ((errors += 1))
    fi
done

required_build_packages=(isolinux syslinux-common)
for package_name in "${required_build_packages[@]}"; do
    if ! rg -qx "${package_name}" "${PROJECT_ROOT}/packages/build.list.chroot"; then
        echo "Missing ISO boot dependency: ${package_name}" >&2
        ((errors += 1))
    fi
done

if ! rg -Fxq 'deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot" || \
    ! rg -Fxq 'deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware' \
        "${PROJECT_ROOT}/config/apt/sources.list.chroot" || \
    ! rg -Fxq 'deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware' \
        "${PROJECT_ROOT}/config/apt/sources.list.chroot"; then
    echo "The final Debian APT sources must point at active online Debian repositories." >&2
    ((errors += 1))
fi
if rg -q '^[[:space:]]*deb[[:space:]]+cdrom:' \
    "${PROJECT_ROOT}/config/apt/sources.list.chroot"; then
    echo "The final Debian APT sources must not contain active cdrom repositories." >&2
    ((errors += 1))
fi
if ! rg -Fq 'config/includes.chroot/etc/apt/sources.list' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not copy online Debian APT sources into the final image." >&2
    ((errors += 1))
fi
if ! rg -Fq '/usr/local/sbin/starlight-configure-debian-apt-sources' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"; then
    echo "The chroot hook does not normalize final Debian APT sources." >&2
    ((errors += 1))
fi

if ! rg -qx 'gnome-shell-extension-blur-my-shell' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "Blur my Shell is not requested by the GNOME package list." >&2
    ((errors += 1))
fi
if ! rg -qx 'gnome-shell-extension-dashtodock' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "Dash to Dock is not requested by the GNOME package list." >&2
    ((errors += 1))
fi
if ! rg -qx 'gnome-shell-extension-prefs' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "GNOME Extensions is not requested by the GNOME package list." >&2
    ((errors += 1))
fi
for gnome_extension_package in \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-tiling-assistant; do
    if ! rg -qx "${gnome_extension_package}" \
        "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
        echo "GNOME extension package is not requested: ${gnome_extension_package}" >&2
        ((errors += 1))
    fi
    if ! rg -qx "${gnome_extension_package}" \
        "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"; then
        echo "GNOME extension package is missing from distro-desktop-gnome: ${gnome_extension_package}" >&2
        ((errors += 1))
    fi
done
if rg -qx 'gnome-shell-extension-desktop-icons-ng' \
    "${PROJECT_ROOT}/packages/gnome.list.chroot" \
    "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"; then
    echo "Desktop Icons NG must not be requested because it hides the wallpaper on this image." >&2
    ((errors += 1))
fi
if ! rg -qx 'gnome-tweaks' "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "GNOME Tweaks is not requested by the GNOME package list." >&2
    ((errors += 1))
fi
if ! rg -qx 'binutils' "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "binutils is required to patch GNOME Shell JS resources." >&2
    ((errors += 1))
fi
if ! rg -Fq "'blur-my-shell@aunetx'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Blur my Shell is not enabled in the Starlight GNOME defaults." >&2
    ((errors += 1))
fi
if ! rg -Fq "pipeline_starlight_app_grid" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight" || \
    ! rg -Fq "'color': <(0.054901960784313725, 0.12156862745098039, 0.29411764705882354, 0.05)>" \
        "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Blur my Shell must define the Starlight app-grid-only blue tint pipeline." >&2
    ((errors += 1))
fi
if ! rg -Fxq "pipeline='pipeline_starlight_app_grid'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Blur my Shell overview must use the Starlight app-grid tint pipeline." >&2
    ((errors += 1))
fi
if ! rg -Fxq "pipeline='pipeline_default'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight" || \
    ! rg -Fxq "pipeline='pipeline_default_rounded'" \
        "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Blur my Shell panel and dock must stay on untinted pipelines." >&2
    ((errors += 1))
fi
if ! rg -Fq "'dash-to-dock@micxgx.gmail.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Dash to Dock is not enabled in the Starlight GNOME defaults." >&2
    ((errors += 1))
fi
for enabled_extension in \
    "'ubuntu-appindicators@ubuntu.com'" \
    "'caffeine@patapon.info'" \
    "'tiling-assistant@leleat-on-github'"; do
    if ! rg -Fq "${enabled_extension}" \
        "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
        echo "Requested GNOME extension is not enabled by default: ${enabled_extension}" >&2
        ((errors += 1))
    fi
done
if rg -Fq "'ding@rastersoft.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Desktop Icons NG must not be enabled because it hides the wallpaper on this image." >&2
    ((errors += 1))
fi
if ! rg -Fq "favorite-apps=['chromium.desktop'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Chromium is not pinned as the first GNOME dock favourite." >&2
    ((errors += 1))
fi
if rg -q "favorite-apps=.*firefox" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Firefox must not be pinned to the GNOME dock by default." >&2
    ((errors += 1))
fi
if ! rg -Fxq "show-weekdate=true" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "GNOME calendar week numbers are not enabled by default." >&2
    ((errors += 1))
fi
if ! rg -Fxq 'text/html=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list" || \
    ! rg -Fxq 'x-scheme-handler/http=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list" || \
    ! rg -Fxq 'x-scheme-handler/https=chromium.desktop' "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"; then
    echo "Chromium is not configured as the default browser." >&2
    ((errors += 1))
fi
if ! rg -Fxq 'application/vnd.debian.binary-package=gdebi.desktop' \
    "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list" || \
    ! rg -Fxq 'application/x-deb=gdebi.desktop' \
        "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list" || \
    ! rg -Fxq 'application/x-debian-package=gdebi.desktop' \
        "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"; then
    echo "Debian packages are not configured to open with GDebi by default." >&2
    ((errors += 1))
fi
if rg -q '^application/(vnd\.debian\.binary-package|x-deb|x-debian-package)=.*(file-roller|FileRoller)' \
    "${PROJECT_ROOT}/sosd/etc/xdg/mimeapps.list"; then
    echo "Debian packages must not open with File Roller by default." >&2
    ((errors += 1))
fi
firefox_policies="${PROJECT_ROOT}/sosd/usr/share/firefox-esr/distribution/policies.json"
if [[ ! -f "${firefox_policies}" ]]; then
    echo "Firefox ESR policies are missing." >&2
    ((errors += 1))
elif ! python3 -c 'import json, pathlib, sys; policies = json.loads(pathlib.Path(sys.argv[1]).read_text())["policies"]; assert policies["NoDefaultBookmarks"] is True; assert "Debian packages" in policies["SearchEngines"]["Remove"]' \
    "${firefox_policies}"; then
    echo "Firefox ESR policies must disable default bookmarks and the Debian package search engine." >&2
    ((errors += 1))
fi
if [[ -e "${PROJECT_ROOT}/sosd/usr/share/applications/starlight-browser.desktop" ]]; then
    echo "The redundant generic Web Browser desktop launcher must not be installed." >&2
    ((errors += 1))
fi
if rg -q 'epiphany' "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-browser"; then
    echo "starlight-browser must not retain an Epiphany fallback after GNOME Web removal." >&2
    ((errors += 1))
fi
if ! rg -Fq "'starlight-clock-right@starlightbrasil.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Starlight Clock Right is not enabled in the Starlight GNOME defaults." >&2
    ((errors += 1))
fi
clock_right_root="${PROJECT_ROOT}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com"
if [[ ! -s "${clock_right_root}/metadata.json" ]] || \
    [[ ! -s "${clock_right_root}/extension.js" ]]; then
    echo "Missing Starlight Clock Right GNOME Shell extension." >&2
    ((errors += 1))
elif ! python3 -c 'import json, pathlib, sys; data = json.loads(pathlib.Path(sys.argv[1]).read_text()); assert data["uuid"] == "starlight-clock-right@starlightbrasil.com"; assert "48" in data["shell-version"]' \
    "${clock_right_root}/metadata.json"; then
    echo "Starlight Clock Right metadata is invalid." >&2
    ((errors += 1))
fi
if ! rg -Fq 'Main.panel.statusArea.dateMenu' "${clock_right_root}/extension.js" || \
    ! rg -Fq 'Main.panel._rightBox' "${clock_right_root}/extension.js" || \
    ! rg -Fq 'insert_child_at_index' "${clock_right_root}/extension.js"; then
    echo "Starlight Clock Right must move the native date menu into the right panel box." >&2
    ((errors += 1))
fi
if ! rg -Fq "background-color='#07182b'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The Starlight Dash to Dock colour is not configured." >&2
    ((errors += 1))
fi
if ! rg -Fxq "background-opacity=0.74" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The Starlight Dash to Dock translucency is not configured." >&2
    ((errors += 1))
fi
if ! rg -Fq '#dashtodockContainer .dash-background' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css" || \
    ! rg -Fq 'background-gradient-start: rgba(19, 46, 74, 0.82);' \
        "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css" || \
    ! rg -Fq 'border: 1px solid rgba(147, 190, 235, 0.28);' \
        "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"; then
    echo "The Starlight dock shell CSS is not configured for the translucent navy dock." >&2
    ((errors += 1))
fi
if ! rg -Fxq "icon-theme='Starlight-Colloid-Yellow-Dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The Starlight Colloid icon theme is not the default." >&2
    ((errors += 1))
fi
if ! rg -Fxq "accent-color='yellow'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The GNOME accent colour is not Starlight yellow." >&2
    ((errors += 1))
fi
if ! rg -Fxq "color-scheme='prefer-dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The GNOME colour scheme is not configured for dark surfaces." >&2
    ((errors += 1))
fi
if ! rg -Fxq "gtk-theme='Adwaita-dark'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The GTK theme is not configured for dark titlebars." >&2
    ((errors += 1))
fi
if ! rg -Fq 'background-gradient-start: #f3c653;' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"; then
    echo "The GNOME Shell yellow gradient accent override is missing." >&2
    ((errors += 1))
fi
if ! rg -Fq '.calendar .calendar-day.calendar-today' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"; then
    echo "The GNOME Shell calendar accent override is missing." >&2
    ((errors += 1))
fi
if ! rg -Fq '.calendar-day-base' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"; then
    echo "The GNOME Shell broad calendar selector override is missing." >&2
    ((errors += 1))
fi
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
    if ! rg -Fq "${shell_selector}" \
        "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css"; then
        echo "The GNOME Shell Starlight surface override is missing: ${shell_selector}" >&2
        ((errors += 1))
    fi
done
for gtk_css in \
    sosd/etc/gtk-3.0/gtk.css \
    sosd/etc/gtk-4.0/gtk.css \
    sosd/etc/skel/.config/gtk-3.0/gtk.css \
    sosd/etc/skel/.config/gtk-4.0/gtk.css; do
    if [[ ! -s "${PROJECT_ROOT}/${gtk_css}" ]]; then
        echo "Missing Starlight GTK CSS: ${gtk_css}" >&2
        ((errors += 1))
    fi
done
if ! rg -Fq 'headerbar.titlebar' "${PROJECT_ROOT}/sosd/etc/gtk-4.0/gtk.css"; then
    echo "The GTK titlebar override is missing." >&2
    ((errors += 1))
fi
if ! rg -Fq '@define-color headerbar_bg_color #08111e;' \
    "${PROJECT_ROOT}/sosd/etc/gtk-4.0/gtk.css"; then
    echo "The libadwaita headerbar colour override is missing." >&2
    ((errors += 1))
fi
if ! rg -Fq '/home/starlight/.config/gtk-${gtk_version}/gtk.css' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-live-session"; then
    echo "The live session does not copy the Starlight GTK CSS to the live user." >&2
    ((errors += 1))
fi
for bundled_asset in \
    starlight-colloid-icon-theme.tar.gz \
    tela-circle-icon-theme.tar.gz \
    wps-office_12.1.2.26885_amd64.deb; do
    if [[ ! -s "${PROJECT_ROOT}/assets/third-party/${bundled_asset}" ]]; then
        echo "Missing bundled asset: ${bundled_asset}" >&2
        ((errors += 1))
    fi
done
if ! [[ "${WPS_PACKAGE_SHA256}" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid SHA-256 for WPS Office asset: ${WPS_PACKAGE}" >&2
    ((errors += 1))
elif [[ -s "${PROJECT_ROOT}/assets/third-party/${WPS_PACKAGE}" ]]; then
    if ! printf '%s  %s\n' "${WPS_PACKAGE_SHA256}" \
        "${PROJECT_ROOT}/assets/third-party/${WPS_PACKAGE}" | sha256sum -c -
    then
        echo "WPS Office asset checksum mismatch: ${WPS_PACKAGE}" >&2
        ((errors += 1))
    fi
    wps_package_version="$(
        dpkg-deb -f "${PROJECT_ROOT}/assets/third-party/${WPS_PACKAGE}" Version \
            2>/dev/null || true
    )"
    if [[ "${wps_package_version}" != "${WPS_PACKAGE_VERSION}" ]]; then
        echo "WPS Office asset must contain package version ${WPS_PACKAGE_VERSION}." >&2
        ((errors += 1))
    fi
fi
verify_third_party_asset "${LINUXTOYS_PACKAGE}" "${LINUXTOYS_PACKAGE_SHA256}"
verify_third_party_asset "${LINUXTOYS_SOURCE_ORIG}" "${LINUXTOYS_SOURCE_ORIG_SHA256}"
verify_third_party_asset "${LINUXTOYS_SOURCE_DEBIAN}" "${LINUXTOYS_SOURCE_DEBIAN_SHA256}"
verify_third_party_asset "${LINUXTOYS_SOURCE_DSC}" "${LINUXTOYS_SOURCE_DSC_SHA256}"
verify_third_party_asset "${WEBAPP_MANAGER_PACKAGE}" "${WEBAPP_MANAGER_PACKAGE_SHA256}"
verify_third_party_asset "${WEBAPP_MANAGER_SOURCE}" "${WEBAPP_MANAGER_SOURCE_SHA256}"
verify_third_party_asset "${WEBAPP_MANAGER_SOURCE_DSC}" "${WEBAPP_MANAGER_SOURCE_DSC_SHA256}"
verify_third_party_asset "${OH_MY_BASH_ARCHIVE}" "${OH_MY_BASH_SHA256}"
if ! rg -Fxq 'papirus-icon-theme' "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "Papirus icon theme is not requested." >&2
    ((errors += 1))
fi

require_package 'thunderbird' 'communication.list.chroot' \
    'Thunderbird is not requested by the communication package list.'
require_package 'element-desktop' 'communication.list.chroot' \
    'Element Desktop is not requested by the communication package list.'
require_package 'steam-installer' 'gaming.list.chroot' \
    'Steam installer is not requested by the gaming package list.'
require_package 'steam-devices' 'gaming.list.chroot' \
    'Steam device rules are not requested by the gaming package list.'
require_package 'gamemode' 'gaming.list.chroot' \
    'GameMode is not requested by the gaming package list.'
require_package 'mangohud' 'gaming.list.chroot' \
    'MangoHud is not requested by the gaming package list.'
require_package 'incus' 'incus.list.chroot' \
    'Incus is not requested by the Incus package list.'
require_package 'incus-client' 'incus.list.chroot' \
    'Incus client is not requested by the Incus package list.'
require_package 'incus-extra' 'incus.list.chroot' \
    'Incus extras are not requested by the Incus package list.'
require_package 'ffmpeg' 'audio-codecs.list.chroot' \
    'FFmpeg is not requested by the audio/video codec package list.'
require_package 'libavcodec-extra' 'audio-codecs.list.chroot' \
    'libavcodec-extra is not requested by the audio/video codec package list.'
require_package 'gstreamer1.0-plugins-base' 'audio-codecs.list.chroot' \
    'GStreamer base plugins are not requested by the codec package list.'
require_package 'gstreamer1.0-plugins-good' 'audio-codecs.list.chroot' \
    'GStreamer good plugins are not requested by the codec package list.'
require_package 'gstreamer1.0-plugins-bad' 'audio-codecs.list.chroot' \
    'GStreamer bad plugins are not requested by the codec package list.'
require_package 'gstreamer1.0-plugins-ugly' 'audio-codecs.list.chroot' \
    'GStreamer ugly plugins are not requested by the codec package list.'
require_package 'gstreamer1.0-libav' 'audio-codecs.list.chroot' \
    'GStreamer libav plugin is not requested by the codec package list.'
require_package 'gstreamer1.0-vaapi' 'audio-codecs.list.chroot' \
    'GStreamer VA-API plugin is not requested by the codec package list.'
require_package 'va-driver-all' 'audio-codecs.list.chroot' \
    'VA-API driver metapackage is not requested by the codec package list.'
require_package 'vdpau-driver-all' 'audio-codecs.list.chroot' \
    'VDPAU driver metapackage is not requested by the codec package list.'
require_package 'vainfo' 'audio-codecs.list.chroot' \
    'VA-API inspection tool is not requested by the codec package list.'
require_package 'easyeffects' 'audio-codecs.list.chroot' \
    'EasyEffects is not requested by the codec/audio package list.'
require_package 'lame' 'audio-codecs.list.chroot' \
    'LAME MP3 encoder is not requested by the codec package list.'
require_package 'libdvdnav4' 'audio-codecs.list.chroot' \
    'DVD navigation support is not requested by the codec package list.'
require_package 'libdvdread8t64' 'audio-codecs.list.chroot' \
    'DVD read support is not requested by the codec package list.'
require_package 'unrar' 'audio-codecs.list.chroot' \
    'RAR support from the restricted-extras set is not requested.'
require_package 'vlc' 'audio-codecs.list.chroot' \
    'VLC is not requested by the audio/video codec package list.'
require_package 'ptyxis' 'development.list.chroot' \
    'Ptyxis is not requested by the development package list.'
require_package 'gnome-terminal' 'development.list.chroot' \
    'GNOME Terminal fallback is not requested by the development package list.'
require_package 'starship' 'development.list.chroot' \
    'Starship fallback prompt is not requested by the development package list.'
require_package 'build-essential' 'development.list.chroot' \
    'Build toolchain is not requested by the development package list.'
require_package 'dkms' 'development.list.chroot' \
    'DKMS is not requested for VirtualBox Guest Additions module builds.'
require_package 'linux-headers-amd64' 'development.list.chroot' \
    'Kernel headers are not requested for VirtualBox Guest Additions module builds.'
require_package 'perl' 'development.list.chroot' \
    'Perl is not requested for VirtualBox Guest Additions installer scripts.'
require_package 'bzip2' 'development.list.chroot' \
    'bzip2 is not requested for VirtualBox Guest Additions installer assets.'
require_package 'fonts-cascadia-code' 'terminal-fonts.list.chroot' \
    'Cascadia Code terminal font is not requested.'
require_package 'fonts-noto-color-emoji' 'terminal-fonts.list.chroot' \
    'Noto Color Emoji terminal font is not requested.'
require_package 'firmware-misc-nonfree' 'base.list.chroot' \
    'NVIDIA-capable firmware package is not requested by the base package list.'
require_package 'xdg-desktop-portal' 'gnome.list.chroot' \
    'Wayland desktop portal is not requested by the GNOME package list.'
require_package 'xdg-desktop-portal-gtk' 'gnome.list.chroot' \
    'GTK Wayland desktop portal is not requested by the GNOME package list.'
for gnome_software_deb_package in \
    gnome-software-plugin-deb \
    gnome-software-plugin-fwupd \
    packagekit \
    packagekit-tools \
    appstream \
    apt-config-icons; do
    require_package "${gnome_software_deb_package}" 'gnome.list.chroot' \
        "GNOME Software APT backend package is not requested: ${gnome_software_deb_package}"
    if ! rg -qx "${gnome_software_deb_package}" \
        "${PROJECT_ROOT}/metapackages/distro-desktop-gnome.depends"; then
        echo "GNOME Software APT backend package is missing from distro-desktop-gnome: ${gnome_software_deb_package}" >&2
        ((errors += 1))
    fi
done
if ! rg -Fq 'libgs_plugin_packagekit.so' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"; then
    echo "The image verification hook must check GNOME Software PackageKit plugin files." >&2
    ((errors += 1))
fi
if ! rg -Fq 'org.freedesktop.PackageKit.service' \
    "${PROJECT_ROOT}/hooks/1000-verify-image.hook.chroot"; then
    echo "The image verification hook must check PackageKit D-Bus activation." >&2
    ((errors += 1))
fi
require_package 'gnome-tweaks' 'gnome.list.chroot' \
    'GNOME Tweaks is not requested by the GNOME package list.'
require_package 'seahorse' 'gnome.list.chroot' \
    'Seahorse is not requested by the GNOME package list.'
require_package 'gnome-firmware' 'system-polish.list.chroot' \
    'GNOME Firmware is not requested by the system polish package list.'
require_package 'flatseal' 'system-polish.list.chroot' \
    'Flatseal is not requested by the system polish package list.'
require_package 'switcheroo-control' 'system-polish.list.chroot' \
    'switcheroo-control is not requested for GNOME discrete GPU integration.'
if ! rg -Fq 'systemctl enable switcheroo-control.service' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"; then
    echo "switcheroo-control.service is not enabled during image configuration." >&2
    ((errors += 1))
fi
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
    require_package "${files_device_package}" 'files-devices.list.chroot' \
        "File/device integration package is not requested: ${files_device_package}"
    if ! rg -qx "${files_device_package}" \
        "${PROJECT_ROOT}/metapackages/distro-files-devices.depends"; then
        echo "File/device package is missing from distro-files-devices: ${files_device_package}" >&2
        ((errors += 1))
    fi
done
for metapackage_media_entry in easyeffects va-driver-all vdpau-driver-all vainfo; do
    if ! rg -qx "${metapackage_media_entry}" \
        "${PROJECT_ROOT}/metapackages/distro-codecs-media.depends"; then
        echo "Media package is missing from distro-codecs-media: ${metapackage_media_entry}" >&2
        ((errors += 1))
    fi
done
for metapackage_polish_entry in gnome-firmware flatseal switcheroo-control; do
    if ! rg -qx "${metapackage_polish_entry}" \
        "${PROJECT_ROOT}/metapackages/distro-system-polish.depends"; then
        echo "System polish package is missing from distro-system-polish: ${metapackage_polish_entry}" >&2
        ((errors += 1))
    fi
done
easyeffects_presets="${PROJECT_ROOT}/sosd/usr/share/starlight/easyeffects/presets"
if [[ ! -f "${easyeffects_presets}/README.md" ]]; then
    echo "EasyEffects preset directory must contain a README placeholder." >&2
    ((errors += 1))
elif find "${easyeffects_presets}" -maxdepth 1 -type f -name '*.json' | grep -q .; then
    echo "EasyEffects preset JSON files must not ship before technical validation." >&2
    ((errors += 1))
fi
require_package 'gir1.2-xapp-1.0' 'webapps-support.list.chroot' \
    'XApp introspection data is not requested for WebApp Manager.'
require_package 'xapps-common' 'webapps-support.list.chroot' \
    'XApps common files are not requested for WebApp Manager.'
require_package 'python3-bs4' 'webapps-support.list.chroot' \
    'BeautifulSoup is not requested for WebApp Manager.'
require_package 'python3-configobj' 'webapps-support.list.chroot' \
    'ConfigObj is not requested for WebApp Manager.'
require_package 'python3-pil' 'webapps-support.list.chroot' \
    'Pillow is not requested for WebApp Manager.'
require_package 'python3-setproctitle' 'webapps-support.list.chroot' \
    'setproctitle is not requested for WebApp Manager.'
require_package 'python3-tldextract' 'webapps-support.list.chroot' \
    'tldextract is not requested for WebApp Manager.'

if ! rg -q -- '--cache-stages "bootstrap chroot"' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The reusable chroot cache is not enabled." >&2
    ((errors += 1))
fi

if [[ "${SOSD_ENABLE_I386}" != true && "${SOSD_ENABLE_I386}" != false ]]; then
    echo "SOSD_ENABLE_I386 must be true or false." >&2
    ((errors += 1))
fi
if [[ "${SOSD_ENABLE_I386}" != true ]]; then
    echo "The release image must enable i386 for Steam on amd64." >&2
    ((errors += 1))
fi
if ! rg -Fq 'dpkg --add-architecture i386' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not enable i386 before resolving Steam packages." >&2
    ((errors += 1))
fi
if ! rg -Fq 'apt-get update' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not refresh APT indices after enabling i386." >&2
    ((errors += 1))
fi
if ! rg -Fq 'build_uefi_boot_image' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not create a GRUB UEFI live boot image." >&2
    ((errors += 1))
fi
if ! rg -Fq 'grub-mkstandalone' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not generate BOOTX64.EFI with GRUB." >&2
    ((errors += 1))
fi
if ! rg -Fq 'BOOTX64.EFI' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The build does not stage the removable-media UEFI boot path." >&2
    ((errors += 1))
fi
if ! rg -Fq -- '-eltorito-alt-boot' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The ISO build does not add an EFI El Torito boot image." >&2
    ((errors += 1))
fi
if ! rg -Fq -- '-isohybrid-gpt-basdat' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The ISO build does not expose the EFI image to hybrid USB firmware." >&2
    ((errors += 1))
fi
if ! rg -Fq 'https://packages.element.io/debian/ default main' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The Element APT repository is not configured during image builds." >&2
    ((errors += 1))
fi
if ! rg -Fq "${ELEMENT_KEY_SHA256}" "${PROJECT_ROOT}/config/assets.env"; then
    echo "The Element repository key checksum is not pinned." >&2
    ((errors += 1))
fi
if ! rg -Fq 'flatpak install --system --noninteractive --or-update flathub' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "System Flatpak applications are not installed during image creation." >&2
    ((errors += 1))
fi
if ! rg -Fq 'install_wps_office' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets" || \
    ! rg -Fq 'postinst.starlight-original' \
        "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets" || \
    ! rg -Fq 'dpkg --configure wps-office' \
        "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "The bundled asset installer does not handle WPS postinst failures in chroot." >&2
    ((errors += 1))
fi
if ! rg -Fq '/usr/local/sbin/starlight-install-bundled-assets' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"; then
    echo "The chroot hook does not run the bundled asset installer." >&2
    ((errors += 1))
fi
if ! rg -Fq 'com.rtosta.zapzap' "${PROJECT_ROOT}/flatpaks/system-apps.txt"; then
    echo "ZapZap is not requested as a system Flatpak." >&2
    ((errors += 1))
fi
if ! rg -Fq 'LINUXTOYS_PACKAGE' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "LinuxToys is not installed from the bundled upstream package." >&2
    ((errors += 1))
fi
if ! rg -Fq 'WEBAPP_MANAGER_PACKAGE' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "WebApp Manager is not installed from the bundled Linux Mint package." >&2
    ((errors += 1))
fi
if ! rg -Fq 'apt-mark manual' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"; then
    echo "Bootloader support packages must be marked manual in the installed target." >&2
    ((errors += 1))
fi
if ! rg -Fq 'grub-efi-amd64-bin' \
    "${PROJECT_ROOT}/hooks/010-configure-system.hook.chroot"; then
    echo "UEFI GRUB modules must be protected from apt autoremove." >&2
    ((errors += 1))
fi
if ! rg -Fq 'rm -rf "${ASSET_ROOT}"' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "Bundled installer assets are not removed after installation." >&2
    ((errors += 1))
fi
if ! rg -Fq '/usr/share/oh-my-bash' \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-bundled-assets"; then
    echo "Oh My Bash is not installed as a shared bundled shell framework." >&2
    ((errors += 1))
fi
if ! rg -Fq 'OSH_THEME=${STARLIGHT_OMB_THEME:-agnoster}' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc"; then
    echo "The default Bash prompt is not configured with the Starlight Oh My Bash theme." >&2
    ((errors += 1))
fi
if ! rg -Fq 'plugins=(git sudo bashmarks colored-man-pages)' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc" || \
    ! rg -Fq 'plugins=(git sudo bashmarks colored-man-pages)' \
        "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-oh-my-bash"; then
    echo "Oh My Bash must use only bundled plugin names." >&2
    ((errors += 1))
fi
if rg -Fq 'plugins=(git sudo history bashmarks)' \
    "${PROJECT_ROOT}/sosd/etc/skel/.bashrc" \
    "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-install-oh-my-bash"; then
    echo "Oh My Bash must not enable the missing history plugin." >&2
    ((errors += 1))
fi
if ! rg -Fq 'JetBrainsMono Nerd Font 11' \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The GNOME monospace font is not set to JetBrainsMono Nerd Font." >&2
    ((errors += 1))
fi
if ! rg -Fxq "exec='ptyxis'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Ptyxis is not configured as the default terminal command." >&2
    ((errors += 1))
fi
if ! rg -Fq 'WaylandEnable=true' "${PROJECT_ROOT}/sosd/etc/gdm3/custom.conf"; then
    echo "GDM Wayland mode is not explicitly enabled." >&2
    ((errors += 1))
fi

if [[ "${SOSD_LIVE_AUTOLOGIN}" != true && "${SOSD_LIVE_AUTOLOGIN}" != false ]]; then
    echo "SOSD_LIVE_AUTOLOGIN must be true or false." >&2
    ((errors += 1))
fi
if [[ "${SOSD_LIVE_AUTOLOGIN}" != true ]]; then
    echo "The release live image must log in automatically." >&2
    ((errors += 1))
fi
if [[ "${SOSD_LIVE_AUTOLOGIN}" == false ]] && ! rg -Fq 'live-config.noautologin' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The diagnostic no-autologin path is missing." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/sosd/etc/polkit-1/rules.d/49-starlight-live-installer.rules" ]]; then
    echo "Missing live Calamares Polkit rule." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/branding/starlight-calamares-dark.png" ]]; then
    echo "Missing dark Calamares welcome logo." >&2
    ((errors += 1))
fi
if ! rg -Fq 'productIcon: starlight-calamares.png' \
    "${PROJECT_ROOT}/installer/branding.desc"; then
    echo "Calamares sidebar icon must use the light Starlight logo." >&2
    ((errors += 1))
fi
if ! rg -Fq 'productLogo: starlight-calamares.png' \
    "${PROJECT_ROOT}/installer/branding.desc"; then
    echo "Calamares sidebar logo must use the light Starlight logo." >&2
    ((errors += 1))
fi
if ! rg -Fq 'productWelcome: starlight-calamares-dark.png' \
    "${PROJECT_ROOT}/installer/branding.desc"; then
    echo "Calamares welcome page must use the dark Starlight logo." >&2
    ((errors += 1))
fi
if ! rg -q '^allowWeakPasswords: true$' \
    "${PROJECT_ROOT}/installer/modules/users.conf"; then
    echo "Calamares must allow simple local user passwords." >&2
    ((errors += 1))
fi
if ! rg -q '^allowWeakPasswordsDefault: true$' \
    "${PROJECT_ROOT}/installer/modules/users.conf"; then
    echo "Calamares must default to accepting simple local user passwords." >&2
    ((errors += 1))
fi
if ! rg -q '^  minLength: 1$' "${PROJECT_ROOT}/installer/modules/users.conf"; then
    echo "Calamares password minimum length must allow short numeric passwords." >&2
    ((errors += 1))
fi
if ! rg -Fq 'sync_calamares_config chroot' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "Calamares config must be synced after lb chroot to avoid stale fast-build branding." >&2
    ((errors += 1))
fi
if ! rg -Fq 'usr/lib/x86_64-linux-gnu/calamares/modules' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "Custom Calamares modules must be copied to the Calamares runtime module path." >&2
    ((errors += 1))
fi
if ! rg -Fq 'installer/modules/${local_module}/' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The Starlight Calamares modules are not staged as runtime modules." >&2
    ((errors += 1))
fi
if ! rg -Fq 'starlight-clean-installed-system' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The installed-system cleanup module is not synced into the Calamares runtime path." >&2
    ((errors += 1))
fi
if ! rg -Fq '.sosd-package-lists.sha256' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "Fast builds must invalidate the chroot cache when package lists change." >&2
    ((errors += 1))
fi
if ! rg -Fq 'destination: "/"' "${PROJECT_ROOT}/installer/modules/unpackfs.conf"; then
    echo "Calamares unpackfs destination must be explicit." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/installer/modules/grubcfg.conf" ]]; then
    echo "Missing Calamares GRUB defaults module configuration." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-bootloader/module.desc" ]] || \
    [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py" ]]; then
    echo "Missing Starlight Calamares bootloader module." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/module.desc" ]] || \
    [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py" ]]; then
    echo "Missing Starlight Calamares user avatar module." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/module.desc" ]] || \
    [[ ! -s "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py" ]]; then
    echo "Missing Starlight installed-system cleanup Calamares module." >&2
    ((errors += 1))
fi
if ! python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight Calamares bootloader module has invalid Python syntax." >&2
    ((errors += 1))
fi
if ! python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
    "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py"; then
    echo "Starlight Calamares user avatar module has invalid Python syntax." >&2
    ((errors += 1))
fi
if ! python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"; then
    echo "Starlight installed-system cleanup module has invalid Python syntax." >&2
    ((errors += 1))
fi
if ! rg -Fq '    - grubcfg' "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares must run grubcfg before the Starlight bootloader module." >&2
    ((errors += 1))
fi
if ! rg -Fq '    - starlight-bootloader' \
    "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares must run the Starlight bootloader module." >&2
    ((errors += 1))
fi
if ! rg -Fq '    - starlight-clean-installed-system' \
    "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares must clean live-only artifacts from the installed system." >&2
    ((errors += 1))
fi
if ! rg -Fq '    - starlight-user-avatar' \
    "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares must run the Starlight user avatar module." >&2
    ((errors += 1))
fi
if ! awk '
    $0 ~ /^[[:space:]]*-[[:space:]]*grubcfg$/ { seen_grubcfg = NR }
    $0 ~ /^[[:space:]]*-[[:space:]]*starlight-bootloader$/ { seen_bootloader = NR }
    $0 ~ /^[[:space:]]*-[[:space:]]*starlight-clean-installed-system$/ { seen_cleanup = NR }
    $0 ~ /^[[:space:]]*-[[:space:]]*umount$/ { seen_umount = NR }
    END {
        exit !(seen_grubcfg && seen_bootloader && seen_cleanup && seen_umount &&
            seen_grubcfg < seen_bootloader &&
            seen_bootloader < seen_cleanup &&
            seen_cleanup < seen_umount)
    }
' "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares must run cleanup after bootloader and before umount." >&2
    ((errors += 1))
fi
if ! rg -Fq 'PACKAGES_TO_PURGE' \
    "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py" || \
    ! rg -Fq 'starlight-install.desktop' \
        "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py" || \
    ! rg -Fq 'epiphany-browser' \
        "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py" || \
    ! rg -Fq 'apt-get", "--purge", "-q", "-y", "remove' \
        "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py" || \
    ! rg -Fq 'dconf", "update"' \
        "${PROJECT_ROOT}/installer/modules/starlight-clean-installed-system/main.py"; then
    echo "The installed-system cleanup module does not remove installer/browser leftovers." >&2
    ((errors += 1))
fi
if ! rg -Fq -- '--no-nvram' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader fallback must avoid NVRAM writes." >&2
    ((errors += 1))
fi
if ! rg -Fq -- '--no-uefi-secure-boot' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader install must avoid implicit Secure Boot assets." >&2
    ((errors += 1))
fi
if ! rg -Fq 'grub-mkstandalone' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader fallback must generate a standalone EFI loader." >&2
    ((errors += 1))
fi
if ! rg -Fq 'BOOTX64.EFI' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader fallback must install the removable EFI path." >&2
    ((errors += 1))
fi
if ! rg -Fq 'root=UUID=' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader fallback must contain a direct kernel boot entry." >&2
    ((errors += 1))
fi
if rg -Fq 'could not find /boot/grub/grub.cfg' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight UEFI bootloader fallback must not depend only on /boot/grub/grub.cfg." >&2
    ((errors += 1))
fi
if ! rg -Fq 'always_use_defaults: true' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"; then
    echo "Calamares grubcfg must always apply Starlight GRUB defaults." >&2
    ((errors += 1))
fi
if ! rg -Fq 'GRUB_DEFAULT: "0"' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"; then
    echo "Calamares grubcfg must set a deterministic default boot entry." >&2
    ((errors += 1))
fi
if ! rg -Fq 'GRUB_DISABLE_OS_PROBER: false' \
    "${PROJECT_ROOT}/installer/modules/grubcfg.conf"; then
    echo "Calamares grubcfg must allow os-prober for desktop dual-boot installs." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/installer/modules/welcome.conf" ]]; then
    echo "Missing Calamares welcome requirements." >&2
    ((errors += 1))
fi
if ! rg -Fq 'requiredStorage: 30' "${PROJECT_ROOT}/installer/modules/welcome.conf"; then
    echo "Calamares must require at least 30 GiB before unpackfs." >&2
    ((errors += 1))
fi
if ! rg -Fq 'requiredRam: 2.0' "${PROJECT_ROOT}/installer/modules/welcome.conf"; then
    echo "Calamares must require at least 2 GiB RAM before installation." >&2
    ((errors += 1))
fi
if ! rg -Fq 'welcome.conf' "${PROJECT_ROOT}/scripts/build.sh" && \
    ! rg -Fq 'installer/modules/' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "Calamares module configuration is not synced by the build." >&2
    ((errors += 1))
fi
if ! rg -Fq 'starlight-user-avatar' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The Starlight user avatar module is not synced into the Calamares runtime path." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/sosd/usr/share/polkit-1/actions/com.starlight.install.policy" ]]; then
    echo "Missing Starlight installer Polkit policy." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/sosd/usr/local/bin/starlight-launch-installer" ]] || \
    [[ ! -s "${PROJECT_ROOT}/sosd/usr/local/sbin/starlight-run-installer" ]]; then
    echo "Missing Starlight installer launcher scripts." >&2
    ((errors += 1))
fi
if ! rg -qx 'qt6-wayland' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "qt6-wayland is required for the Calamares Qt6 installer." >&2
    ((errors += 1))
fi
if ! rg -qx 'squashfs-tools' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "squashfs-tools is required for Calamares unpackfs." >&2
    ((errors += 1))
fi
if ! rg -qx 'rsync' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "rsync is required for Calamares unpackfs." >&2
    ((errors += 1))
fi
if ! rg -qx 'dosfstools' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "dosfstools is required to format the EFI system partition." >&2
    ((errors += 1))
fi
if ! rg -qx 'efibootmgr' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "efibootmgr is required for UEFI GRUB boot entries." >&2
    ((errors += 1))
fi
if ! rg -qx 'grub2-common' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "grub2-common is required for grub-install and grub-mkconfig." >&2
    ((errors += 1))
fi
if ! rg -qx 'grub-pc-bin' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "grub-pc-bin is required for BIOS GRUB installation." >&2
    ((errors += 1))
fi
if ! rg -qx 'grub-efi-amd64-bin' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "grub-efi-amd64-bin is required for UEFI GRUB installation." >&2
    ((errors += 1))
fi
if rg -qx 'grub-pc|grub-efi-amd64|shim-signed' "${PROJECT_ROOT}/packages/installer.list.chroot"; then
    echo "Installer must keep the live image on non-conflicting GRUB bin packages; Calamares installs the selected firmware target." >&2
    ((errors += 1))
fi
if ! rg -Fq 'mountPoint: /boot/efi' \
    "${PROJECT_ROOT}/installer/modules/partition.conf"; then
    echo "Calamares must create/use /boot/efi for UEFI installs." >&2
    ((errors += 1))
fi
if ! rg -Fq 'efiSystemPartition: /boot/efi' \
    "${PROJECT_ROOT}/installer/modules/partition.conf"; then
    echo "Calamares EFI partition legacy alias must be kept for compatibility." >&2
    ((errors += 1))
fi
if rg -Fq 'requiredPartitionTableType:' "${PROJECT_ROOT}/installer/modules/partition.conf"; then
    echo "Calamares installer must allow GPT for UEFI and msdos for BIOS." >&2
    ((errors += 1))
fi
if ! rg -Fq 'grubProbe: grub-probe' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"; then
    echo "Calamares bootloader config must declare grub-probe." >&2
    ((errors += 1))
fi
if ! rg -Fq 'efiBootMgr: efibootmgr' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"; then
    echo "Calamares bootloader config must declare efibootmgr." >&2
    ((errors += 1))
fi
if ! rg -Fq 'installEFIFallback: true' \
    "${PROJECT_ROOT}/installer/modules/bootloader.conf"; then
    echo "Calamares must install the EFI fallback bootloader path." >&2
    ((errors += 1))
fi
if ! rg -Fq 'Exec=/usr/local/bin/starlight-launch-installer' \
    "${PROJECT_ROOT}/sosd/usr/share/applications/starlight-install.desktop"; then
    echo "The Starlight installer desktop entry does not use the launcher." >&2
    ((errors += 1))
fi
if ! rg -Fq 'NoDisplay=true' \
    "${PROJECT_ROOT}/sosd/usr/share/applications/calamares.desktop"; then
    echo "The generic Calamares desktop entry is not hidden." >&2
    ((errors += 1))
fi

if [[ -d "${PROJECT_ROOT}/config/bootloaders/isolinux" ]]; then
    for boot_file in isolinux.cfg menu.cfg stdmenu.cfg live.cfg.in; do
        if [[ ! -f "${PROJECT_ROOT}/config/bootloaders/isolinux/${boot_file}" ]]; then
            echo "Missing Syslinux source file: ${boot_file}" >&2
            ((errors += 1))
        fi
    done
else
    echo "Missing versioned Syslinux configuration." >&2
    ((errors += 1))
fi

if find "${PROJECT_ROOT}/hooks" -mindepth 2 -type f | grep -q .; then
    echo "Hooks must be directly below hooks/ for live-build 3." >&2
    ((errors += 1))
fi

vega_root="${PROJECT_ROOT}/assets/gdm/starlight-os-vega"
for vega_file in \
    assets/starlight-os-vega-4k.png \
    assets/starlight-os-vega-gdm.css \
    scripts/install-gdm-theme.sh \
    scripts/validate-gdm-theme.sh; do
    if [[ ! -s "${vega_root}/${vega_file}" ]]; then
        echo "Missing Vega GDM asset: ${vega_file}" >&2
        ((errors += 1))
    fi
done
if ! rg -q -- "--exclude 'login-reference.png'" "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The GDM reference mockup is not excluded from the ISO." >&2
    ((errors += 1))
fi
if ! rg -q 'STARLIGHT_OS_VEGA_GDM_BEGIN' \
    "${vega_root}/assets/starlight-os-vega-gdm.css"; then
    echo "The idempotency marker is absent from the Vega CSS." >&2
    ((errors += 1))
fi
if rg -q 'padding-left: 42%;' "${vega_root}/assets/starlight-os-vega-gdm.css"; then
    echo "The old CSS-only GDM displacement is still present." >&2
    ((errors += 1))
fi
if ! rg -q '//RIGHT' "${vega_root}/scripts/install-gdm-theme.sh"; then
    echo "The GNOME Shell login dialog right-side patch is absent." >&2
    ((errors += 1))
fi

if [[ ! -s "${PROJECT_ROOT}/branding/starlight-live-user.png" ]]; then
    echo "Missing Starlight live-user avatar." >&2
    ((errors += 1))
fi
if ! rg -Fq 'branding/starlight-calamares.png' "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The live-user avatar must be staged from the Calamares white empress asset." >&2
    ((errors += 1))
fi
if ! rg -Fq 'AccountsService/icons' \
    "${PROJECT_ROOT}/installer/modules/starlight-user-avatar/main.py"; then
    echo "The installed user avatar module does not configure AccountsService." >&2
    ((errors += 1))
fi
if ! rg -Fq "logo=''" "${PROJECT_ROOT}/sosd/usr/share/gdm/dconf/99-starlight-login" || \
    ! rg -Fq "fallback-logo=''" "${PROJECT_ROOT}/sosd/usr/share/gdm/dconf/99-starlight-login"; then
    echo "The redundant GDM logo is not disabled." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/sosd/usr/share/gnome-background-properties/starlight.xml" ]]; then
    echo "Missing GNOME wallpaper registration for Starlight." >&2
    ((errors += 1))
fi
if [[ ! -s "${PROJECT_ROOT}/sosd/usr/share/gdm/dconf/99-starlight-login" ]]; then
    echo "Missing Starlight GDM logo defaults." >&2
    ((errors += 1))
fi

package_index_dir="${PROJECT_ROOT}/build/live-build/chroot/var/lib/apt/lists"
cache_key_file="${PROJECT_ROOT}/build/live-build/.sosd-cache-key"
expected_cache_key="${SOSD_DISTRIBUTION}-${SOSD_ARCHITECTURE}"
cached_key="$(cat "${cache_key_file}" 2>/dev/null || true)"
if [[ "${cached_key}" == "${expected_cache_key}" ]] && \
    compgen -G "${package_index_dir}/*_binary-amd64_Packages" >/dev/null; then
    available_packages="$(mktemp)"
    requested_packages="$(mktemp)"
    trap 'rm -f "${available_packages}" "${requested_packages}"' EXIT
    awk '/^Package: / {print $2}' \
        "${package_index_dir}"/*_binary-amd64_Packages | sort -u \
        >"${available_packages}"
    awk 'NF && $1 !~ /^#/ && $1 != "element-desktop"' \
        "${PROJECT_ROOT}"/packages/*.list.chroot | \
        sort -u >"${requested_packages}"
    if missing_packages="$(comm -23 "${requested_packages}" "${available_packages}")" \
        && [[ -n "${missing_packages}" ]]; then
        echo "Packages absent from the cached ${SOSD_DISTRIBUTION} indices:" >&2
        echo "${missing_packages}" >&2
        ((errors += 1))
    fi
elif [[ -n "${cached_key}" && "${cached_key}" != "${expected_cache_key}" ]]; then
    echo "Skipping stale package indices (${cached_key}); expected ${expected_cache_key}."
fi

if [[ -s "${PROJECT_ROOT}/.git/index" ]]; then
    if git -C "${PROJECT_ROOT}" ls-files | rg \
        '(^|/)(machine-id|ssh_host_.*|.*\\.log|\\.bash_history)$'; then
        echo "Potentially unique or private files are tracked." >&2
        ((errors += 1))
    fi
else
    echo "Warning: Git metadata is unavailable in this workspace." >&2
fi

if ((errors > 0)); then
    echo "Validation failed with ${errors} error(s)." >&2
    exit 1
fi

echo "Validation completed successfully."
