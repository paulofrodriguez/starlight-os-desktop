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
    ubuntu-drivers-common; do
    if rg -n "^[[:space:]]*${forbidden}[[:space:]]*$" \
        "${PROJECT_ROOT}/packages" --glob '*.list.chroot'; then
        echo "Forbidden package requested: ${forbidden}" >&2
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
if ! rg -qx 'binutils' "${PROJECT_ROOT}/packages/gnome.list.chroot"; then
    echo "binutils is required to patch GNOME Shell JS resources." >&2
    ((errors += 1))
fi
if ! rg -Fq "'blur-my-shell@aunetx'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Blur my Shell is not enabled in the Starlight GNOME defaults." >&2
    ((errors += 1))
fi
if ! rg -Fq "'dash-to-dock@micxgx.gmail.com'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "Dash to Dock is not enabled in the Starlight GNOME defaults." >&2
    ((errors += 1))
fi
if ! rg -Fq "background-color='#08111e'" \
    "${PROJECT_ROOT}/sosd/etc/dconf/db/starlight.d/00-starlight"; then
    echo "The Starlight Dash to Dock colour is not configured." >&2
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
require_package 'ptyxis' 'development.list.chroot' \
    'Ptyxis is not requested by the development package list.'
require_package 'gnome-terminal' 'development.list.chroot' \
    'GNOME Terminal fallback is not requested by the development package list.'
require_package 'starship' 'development.list.chroot' \
    'Starship fallback prompt is not requested by the development package list.'
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
if ! rg -Fq 'installer/modules/starlight-bootloader/' \
    "${PROJECT_ROOT}/scripts/build.sh"; then
    echo "The Starlight Calamares bootloader module is not staged as a runtime module." >&2
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
if ! python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
    "${PROJECT_ROOT}/installer/modules/starlight-bootloader/main.py"; then
    echo "Starlight Calamares bootloader module has invalid Python syntax." >&2
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
if ! awk '
    $0 ~ /^[[:space:]]*-[[:space:]]*grubcfg$/ { seen_grubcfg = NR }
    $0 ~ /^[[:space:]]*-[[:space:]]*starlight-bootloader$/ { seen_bootloader = NR }
    END { exit !(seen_grubcfg && seen_bootloader && seen_grubcfg < seen_bootloader) }
' "${PROJECT_ROOT}/installer/settings.conf"; then
    echo "Calamares grubcfg must run before the Starlight bootloader module." >&2
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
