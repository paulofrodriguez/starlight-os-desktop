#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_build_env
readonly CACHE_ROOT="${CACHE_BASE}/${SOSD_DISTRIBUTION}-${SOSD_ARCHITECTURE}"
readonly CACHE_KEY="${SOSD_DISTRIBUTION}-${SOSD_ARCHITECTURE}"
readonly BUILD_MODE="${1:-full}"

if [[ "${BUILD_MODE}" != "full" && "${BUILD_MODE}" != "--fast" ]]; then
    echo "Usage: $0 [--fast]" >&2
    exit 2
fi

readonly PACKAGE_LIST_FINGERPRINT="$(
    find "${PROJECT_ROOT}/packages" -type f -name '*.list.*' -print0 |
        sort -z |
        xargs -0 sha256sum |
        sha256sum |
        awk '{print $1}'
)"

if [[ "${EUID}" -ne 0 ]]; then
    echo "The ISO build requires root for debootstrap and chroot mounts." >&2
    echo "Run: sudo make build" >&2
    exit 1
fi

for command_name in chroot cpio curl lb mount rsync sha256sum stat tar umount xorriso; do
    require_command "${command_name}"
done

export SOURCE_DATE_EPOCH="${SOSD_SOURCE_DATE_EPOCH}"
export TZ=UTC
export LC_ALL=C.UTF-8
export MKSQUASHFS_OPTIONS="-processors ${SOSD_BUILD_JOBS}"
iso_timestamp="$(date -u -d "@${SOSD_SOURCE_DATE_EPOCH}" +%Y%m%d%H%M%S00)"

case "${SOSD_LIVE_AUTOLOGIN}" in
    true)
        live_autologin_argument=""
        ;;
    false)
        live_autologin_argument="live-config.noautologin"
        ;;
    *)
        echo "SOSD_LIVE_AUTOLOGIN must be true or false." >&2
        exit 2
        ;;
esac

case "${SOSD_ENABLE_I386}" in
    true|false)
        ;;
    *)
        echo "SOSD_ENABLE_I386 must be true or false." >&2
        exit 2
        ;;
esac

install -d -m 0755 "${ARTIFACT_DIR}" "${CACHE_ROOT}" "${DOWNLOAD_CACHE}"
exec > >(tee "${ARTIFACT_DIR}/build.log") 2>&1
if [[ "${BUILD_MODE}" == "--fast" ]] && \
    [[ -d "${CACHE_ROOT}/chroot" ]] && \
    [[ "$(cat "${CACHE_ROOT}/.sosd-package-lists.sha256" 2>/dev/null || true)" != "${PACKAGE_LIST_FINGERPRINT}" ]]; then
    echo "Package lists changed; dropping the stale fast chroot cache..."
    rm -rf "${CACHE_ROOT}/chroot"
fi
if [[ "${BUILD_MODE}" == "--fast" ]] && \
    [[ ! -d "${CACHE_ROOT}/chroot" ]] && \
    [[ -d "${BUILD_ROOT}/chroot" ]]; then
    if [[ "$(cat "${BUILD_ROOT}/.sosd-package-lists.sha256" 2>/dev/null || true)" == "${PACKAGE_LIST_FINGERPRINT}" ]]; then
        echo "Seeding the fast chroot cache from the previous successful build..."
        cp -a --reflink=auto "${BUILD_ROOT}/chroot" "${CACHE_ROOT}/chroot"
    else
        echo "Skipping previous chroot seed because package lists changed."
    fi
fi
if [[ -d "${BUILD_ROOT}/cache" ]] &&
    [[ "$(cat "${BUILD_ROOT}/.sosd-cache-key" 2>/dev/null || true)" == "${CACHE_KEY}" ]]; then
    rsync -a "${BUILD_ROOT}/cache/" "${CACHE_ROOT}/"
fi
if [[ "${BUILD_MODE}" == "full" ]]; then
    rm -rf "${CACHE_ROOT}/chroot"
fi
rm -rf "${CACHE_ROOT}/contents.chroot" "${CACHE_ROOT}/contents.binary"
rm -rf "${CACHE_ROOT}/packages_binary" "${CACHE_ROOT}/packages_chroot"
rm -rf "${BUILD_ROOT}"
install -d -m 0755 "${BUILD_ROOT}"
printf '%s\n' "${CACHE_KEY}" >"${BUILD_ROOT}/.sosd-cache-key"
printf '%s\n' "${PACKAGE_LIST_FINGERPRINT}" \
    >"${BUILD_ROOT}/.sosd-package-lists.sha256"

persist_cache() {
    if [[ -d "${BUILD_ROOT}/cache" ]]; then
        rsync -a --delete "${BUILD_ROOT}/cache/" "${CACHE_ROOT}/"
    fi
    printf '%s\n' "${PACKAGE_LIST_FINGERPRINT}" \
        >"${CACHE_ROOT}/.sosd-package-lists.sha256"
}
trap persist_cache EXIT

cd "${BUILD_ROOT}"
lb config \
    --mode debian \
    --distribution "${SOSD_DISTRIBUTION}" \
    --architectures "${SOSD_ARCHITECTURE}" \
    --bootstrap-keyring debian-archive-keyring \
    --linux-packages linux-image \
    --linux-flavours amd64 \
    --firmware-chroot false \
    --firmware-binary false \
    --archive-areas "${SOSD_ARCHIVE_AREAS}" \
    --mirror-bootstrap "${SOSD_MIRROR_BOOTSTRAP}" \
    --mirror-binary "${SOSD_MIRROR_BINARY}" \
    --binary-images iso \
    --bootloader syslinux \
    --syslinux-theme live-build \
    --debian-installer false \
    --security false \
    --initsystem systemd \
    --apt-recommends false \
    --cache-stages "bootstrap chroot" \
    --zsync false \
    --memtest none \
    --iso-application "Starlight OS Vega" \
    --iso-publisher "Starlight Brasil" \
    --iso-volume "${SOSD_VOLUME_LABEL}" \
    --bootappend-live "boot=live components username=starlight hostname=starlight ${live_autologin_argument} quiet splash console=ttyS0,115200n8"

sed -i \
    -e 's|^GENISOIMAGE_OPTIONS_EXTRA=.*|GENISOIMAGE_OPTIONS_EXTRA="--iso-level 3"|' \
    -e 's|^LB_CACHE_STAGES=.*|LB_CACHE_STAGES="bootstrap chroot"|' \
    config/common

rsync -a "${CACHE_ROOT}/" cache/
install -m 0644 "${PROJECT_ROOT}/config/environment.chroot" \
    config/environment.chroot

install -d config/package-lists config/hooks config/includes.chroot \
    config/includes.binary config/archives
install -D -m 0644 /dev/null config/includes.chroot/etc/starlight/live.conf
printf 'STARLIGHT_LIVE_AUTOLOGIN=%s\n' "${SOSD_LIVE_AUTOLOGIN}" \
    >config/includes.chroot/etc/starlight/live.conf

printf '%s\n' \
    "deb ${SOSD_SECURITY_MIRROR} ${SOSD_DISTRIBUTION}-security ${SOSD_ARCHIVE_AREAS}" \
    >config/archives/starlight-security.list.chroot

element_keyring="${DOWNLOAD_CACHE}/${ELEMENT_KEYRING}"
if [[ ! -f "${element_keyring}" ]] ||
    ! printf '%s  %s\n' "${ELEMENT_KEY_SHA256}" "${element_keyring}" | sha256sum -c -
then
    rm -f "${element_keyring}"
    curl --fail --location --retry 3 --output "${element_keyring}" \
        "${ELEMENT_KEY_URL}"
fi
printf '%s  %s\n' "${ELEMENT_KEY_SHA256}" "${element_keyring}" | sha256sum -c -
install -m 0644 "${element_keyring}" config/archives/element-io.key.chroot
printf '%s\n' \
    "deb [arch=${SOSD_ARCHITECTURE}] https://packages.element.io/debian/ default main" \
    >config/archives/element-io.list.chroot

rsync -a "${PROJECT_ROOT}/packages/" config/package-lists/
# Hooks are an ordered pipeline. Remove old generated hooks first so a rename
# cannot leave a stale earlier verification hook in a cached build directory.
find config/hooks -mindepth 1 -maxdepth 1 -type f -name '*.hook.chroot' -delete
rsync -a "${PROJECT_ROOT}/hooks/" config/hooks/
rsync -a "${PROJECT_ROOT}/sosd/" config/includes.chroot/
install -D -m 0644 "${PROJECT_ROOT}/flatpaks/system-apps.txt" \
    config/includes.chroot/usr/share/starlight/flatpaks/system-apps.txt
install -d -m 0755 config/includes.chroot/opt/starlight-os/third-party
rsync -a "${PROJECT_ROOT}/assets/third-party/" \
    config/includes.chroot/opt/starlight-os/third-party/
install -d -m 0755 \
    config/includes.chroot/opt/starlight-os/gdm/starlight-os-vega
rsync -a --delete \
    --exclude 'login-reference.png' \
    --exclude 'CODEX-PROMPT.md' \
    "${PROJECT_ROOT}/assets/gdm/starlight-os-vega/" \
    config/includes.chroot/opt/starlight-os/gdm/starlight-os-vega/
chmod 0755 \
    config/includes.chroot/opt/starlight-os/gdm/starlight-os-vega/scripts/*.sh
install -D -m 0644 "${PROJECT_ROOT}/branding/starlight-logo.png" \
    config/includes.chroot/usr/share/plymouth/themes/starlight/starlight-logo.png
install -D -m 0644 "${PROJECT_ROOT}/branding/starlight-wallpaper.png" \
    config/includes.chroot/usr/share/backgrounds/starlight/starlight-wallpaper.png
install -D -m 0644 "${PROJECT_ROOT}/branding/starlight-calamares.png" \
    config/includes.chroot/usr/share/starlight/starlight-live-user.png
install -D -m 0644 "${PROJECT_ROOT}/branding/starlight-gdm-logo.png" \
    config/includes.chroot/usr/share/starlight/starlight-gdm-logo.png
install -D -m 0644 "${PROJECT_ROOT}/config/apt/sources.list.chroot" \
    config/includes.chroot/usr/share/starlight/sources.list

rsync -a "${PROJECT_ROOT}/config/bootloaders/" config/bootloaders/
install -m 0644 "${PROJECT_ROOT}/branding/starlight-boot-menu.png" \
    config/bootloaders/isolinux/splash.png

nerd_font_archive="${DOWNLOAD_CACHE}/${NERD_FONT_ARCHIVE}"
if [[ ! -f "${nerd_font_archive}" ]] ||
    ! printf '%s  %s\n' "${NERD_FONT_SHA256}" "${nerd_font_archive}" | sha256sum -c -
then
    rm -f "${nerd_font_archive}"
    curl --fail --location --retry 3 --output "${nerd_font_archive}" \
        "${NERD_FONT_URL}"
fi
printf '%s  %s\n' "${NERD_FONT_SHA256}" "${nerd_font_archive}" | sha256sum -c -
install -d -m 0755 \
    config/includes.chroot/usr/share/fonts/truetype/nerd-fonts
tar -xJf "${nerd_font_archive}" \
    -C config/includes.chroot/usr/share/fonts/truetype/nerd-fonts \
    --wildcards '*.ttf' 'README.md'

sync_calamares_config() {
    local target_root="$1"
    local branding_root
    local local_module
    local module_root

    install -D -m 0644 "${PROJECT_ROOT}/installer/settings.conf" \
        "${target_root}/etc/calamares/settings.conf"
    install -d -m 0755 "${target_root}/etc/calamares/modules"
    rsync -a --delete \
        --exclude '__pycache__/' \
        --exclude '*.pyc' \
        "${PROJECT_ROOT}/installer/modules/" \
        "${target_root}/etc/calamares/modules/"

    module_root="${target_root}/usr/lib/x86_64-linux-gnu/calamares/modules"
    for local_module in starlight-bootloader starlight-user-avatar; do
        install -d -m 0755 "${module_root}/${local_module}"
        rsync -a --delete \
            --exclude '__pycache__/' \
            --exclude '*.pyc' \
            "${PROJECT_ROOT}/installer/modules/${local_module}/" \
            "${module_root}/${local_module}/"
    done

    for branding_root in \
        "${target_root}/etc/calamares/branding/starlight" \
        "${target_root}/usr/share/calamares/branding/starlight"
    do
        install -d -m 0755 "${branding_root}"
        install -m 0644 \
            "${PROJECT_ROOT}/installer/branding.desc" \
            "${PROJECT_ROOT}/installer/slideshow.qml" \
            "${branding_root}/"
        install -m 0644 "${PROJECT_ROOT}/branding/starlight-calamares.png" \
            "${branding_root}/starlight-calamares.png"
        install -m 0644 "${PROJECT_ROOT}/branding/starlight-calamares-light.png" \
            "${branding_root}/starlight-calamares-light.png"
        install -m 0644 "${PROJECT_ROOT}/branding/starlight-calamares-dark.png" \
            "${branding_root}/starlight-calamares-dark.png"
    done
}

build_uefi_boot_image() {
    local grub_cfg="chroot/tmp/starlight-grub-live.cfg"
    local bootx64="chroot/tmp/starlight-BOOTX64.EFI"
    local efi_image="binary/boot/grub/efi.img"
    local efi_image_chroot="/tmp/starlight-efi.img"
    local bootx64_size_bytes
    local efi_image_size_mib
    local efi_mount
    local mounted=false

    for boot_file in \
        /usr/bin/grub-mkstandalone \
        /usr/sbin/mkfs.vfat \
        /usr/lib/grub/x86_64-efi/modinfo.sh \
        /usr/share/grub/unicode.pf2
    do
        if [[ ! -s "chroot${boot_file}" ]]; then
            echo "Required UEFI boot file is missing from the chroot: ${boot_file}" >&2
            exit 1
        fi
    done

    install -d -m 0755 binary/EFI/BOOT binary/boot/grub/fonts
    install -m 0644 chroot/usr/share/grub/unicode.pf2 \
        binary/boot/grub/fonts/unicode.pf2

    cat >"${grub_cfg}" <<EOF
search --no-floppy --set=root --label ${SOSD_VOLUME_LABEL}
set default=0
set timeout=5

if loadfont /boot/grub/fonts/unicode.pf2; then
    set gfxmode=auto
    insmod all_video
    insmod gfxterm
    terminal_output gfxterm
fi

menuentry 'Iniciar Starlight OS Vega' {
    linux /live/vmlinuz boot=live config components username=starlight hostname=starlight ${live_autologin_argument} quiet splash console=ttyS0,115200n8
    initrd /live/initrd.img
}

menuentry 'Starlight OS Vega (modo seguro)' {
    linux /live/vmlinuz boot=live config components username=starlight hostname=starlight ${live_autologin_argument} quiet splash console=ttyS0,115200n8 noapic noapm nodma nomce nolapic nomodeset nosmp nosplash
    initrd /live/initrd.img
}
EOF

    chroot chroot grub-mkstandalone \
        -O x86_64-efi \
        -o /tmp/starlight-BOOTX64.EFI \
        --modules="all_video boot configfile echo fat gfxterm iso9660 linux normal part_gpt part_msdos search search_fs_uuid search_label" \
        "boot/grub/grub.cfg=/tmp/starlight-grub-live.cfg"
    install -m 0644 "${bootx64}" binary/EFI/BOOT/BOOTX64.EFI

    bootx64_size_bytes="$(stat -c '%s' "${bootx64}")"
    efi_image_size_mib=$(( (bootx64_size_bytes + 1048575) / 1048576 + 16 ))
    if (( efi_image_size_mib < 32 )); then
        efi_image_size_mib=32
    fi

    chroot chroot truncate -s "${efi_image_size_mib}M" "${efi_image_chroot}"
    chroot chroot mkfs.vfat -n STAREFI "${efi_image_chroot}"
    efi_mount="$(mktemp -d)"
    trap 'if [[ "${mounted}" == true ]]; then umount "${efi_mount}"; fi; rmdir "${efi_mount}" 2>/dev/null || true' RETURN
    mount -o loop "chroot${efi_image_chroot}" "${efi_mount}"
    mounted=true
    install -D -m 0644 binary/EFI/BOOT/BOOTX64.EFI \
        "${efi_mount}/EFI/BOOT/BOOTX64.EFI"
    umount "${efi_mount}"
    mounted=false
    rmdir "${efi_mount}"
    trap - RETURN
    install -m 0644 "chroot${efi_image_chroot}" "${efi_image}"
    rm -f "${grub_cfg}" "${bootx64}" "chroot${efi_image_chroot}"
}

sync_calamares_config config/includes.chroot

lb bootstrap
if [[ "${SOSD_ENABLE_I386}" == true ]]; then
    if [[ "${SOSD_ARCHITECTURE}" != amd64 ]]; then
        echo "SOSD_ENABLE_I386 is only supported for amd64 images." >&2
        exit 2
    fi
    if ! chroot chroot dpkg --print-foreign-architectures | grep -qx i386; then
        chroot chroot dpkg --add-architecture i386
    fi
    chroot chroot apt-get update
fi
lb chroot

# Fast builds can reuse a cached chroot, so rewrite Calamares config after the
# chroot stage as well. This keeps branding and module fixes from going stale.
sync_calamares_config chroot

for boot_file in \
    /usr/lib/ISOLINUX/isolinux.bin \
    /usr/lib/ISOLINUX/isohdpfx.bin \
    /usr/lib/syslinux/modules/bios/vesamenu.c32 \
    /usr/lib/syslinux/modules/bios/ldlinux.c32 \
    /usr/lib/syslinux/modules/bios/libcom32.c32 \
    /usr/lib/syslinux/modules/bios/libutil.c32
do
    if [[ ! -s "chroot${boot_file}" ]]; then
        echo "Required bootloader file is missing from the chroot: ${boot_file}" >&2
        exit 1
    fi
    install -m 0644 "chroot${boot_file}" \
        "config/bootloaders/isolinux/$(basename "${boot_file}")"
done

cpio --quiet --create --format=newc \
    --file=config/bootloaders/isolinux/bootlogo </dev/null

lb binary

build_uefi_boot_image

xorriso -as mkisofs \
        -r -J -joliet-long -l -iso-level 3 \
        -V "${SOSD_VOLUME_LABEL}" \
        -A "Starlight OS Vega" \
        -publisher "Starlight Brasil" \
        --modification-date="${iso_timestamp}" \
        --set_all_file_dates "${iso_timestamp}" \
        -isohybrid-mbr config/bootloaders/isolinux/isohdpfx.bin \
        -partition_offset 16 \
        -c isolinux/boot.cat \
        -b isolinux/isolinux.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o binary.hybrid.iso binary

"${SCRIPT_DIR}/package.sh"
