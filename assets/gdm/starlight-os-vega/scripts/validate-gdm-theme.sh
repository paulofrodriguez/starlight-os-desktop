#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT="${STARLIGHT_ROOT:-}"
readonly KIT_ROOT="${ROOT}/opt/starlight-os/gdm/starlight-os-vega"
readonly ASSET="${KIT_ROOT}/assets/starlight-os-vega-4k.png"
readonly RESOURCE="${ROOT}/usr/share/gnome-shell/gnome-shell-theme.gresource"
readonly SHELL_RESOURCE="${ROOT}/usr/lib/gnome-shell/libshell-16.so"
readonly BACKUP="${ROOT}/usr/lib/starlight-os/backups/gnome-shell-theme.gresource.original"
readonly SHELL_BACKUP="${ROOT}/usr/lib/starlight-os/backups/libshell-16.so.original"
readonly PREFIX=/org/gnome/shell/theme
readonly SHELL_PREFIX=/org/gnome/shell
readonly BEGIN_MARKER='/* STARLIGHT_OS_VEGA_GDM_BEGIN */'

fail() { echo "Starlight Vega GDM validation failed: $*" >&2; exit 1; }

dpkg_query() {
    if [[ -n "${ROOT}" ]]; then
        dpkg-query --admindir="${ROOT}/var/lib/dpkg" "$@"
    else
        dpkg-query "$@"
    fi
}

for package_name in gdm3 gnome-shell libglib2.0-bin libglib2.0-dev-bin python3; do
    [[ "$(dpkg_query -W -f='${db:Status-Status}' "${package_name}" 2>/dev/null || true)" == installed ]] || \
        fail "required package is not installed: ${package_name}"
done
[[ "$(dpkg_query -W -f='${Version}' gnome-shell)" == 48.* ]] || \
    fail "GNOME Shell major changed; adapt and revalidate the Vega integration"
[[ -s "${RESOURCE}" ]] || fail "resource is missing"
[[ -s "${BACKUP}" ]] || fail "original resource backup is missing"
[[ -s "${SHELL_RESOURCE}" ]] || fail "GNOME Shell library is missing"
[[ -s "${SHELL_BACKUP}" ]] || fail "original GNOME Shell library backup is missing"


python3 - "${ASSET}" <<'PY'
import struct, sys
p = sys.argv[1]
h = open(p, "rb").read(24)
if len(h) != 24 or h[:8] != b"\x89PNG\r\n\x1a\n" or h[12:16] != b"IHDR":
    raise SystemExit("wallpaper is not a valid PNG")
if struct.unpack(">II", h[16:24]) != (3840, 2160):
    raise SystemExit("wallpaper is not 3840x2160")
PY

resource_list="$(gresource list "${RESOURCE}")"
grep -Fqx "${PREFIX}/starlight-os-vega-4k.png" <<<"${resource_list}" || \
    fail "wallpaper is absent from the resource"
grep -Fq 'login-reference.png' <<<"${resource_list}" && fail "mockup leaked into the resource"

validated=0
for name in gnome-shell-dark.css gnome-shell-light.css gnome-shell-high-contrast.css; do
    path="${PREFIX}/${name}"
    grep -Fqx "${path}" <<<"${resource_list}" || continue
    css="$(gresource extract "${RESOURCE}" "${path}")"
    [[ "$(grep -Foc "${BEGIN_MARKER}" <<<"${css}")" -eq 1 ]] || fail "marker count is not one in ${name}"
    grep -Fq '.login-dialog' <<<"${css}" || fail ".login-dialog absent from ${name}"
    grep -Fq '#lockDialogGroup' <<<"${css}" || fail "#lockDialogGroup absent from ${name}"
    grep -Fq '.screen-shield-background' <<<"${css}" || \
        fail ".screen-shield-background absent from ${name}"
    grep -Eq '#lockDialogGroup[[:space:]]*\{' <<<"${css}" || fail "login background override absent from ${name}"
    grep -Fq 'width: 25em;' <<<"${css}" || fail "compact login selection width absent from ${name}"
    grep -Fq 'starlight-os-vega-4k.png' <<<"${css}" || fail "wallpaper rule absent from ${name}"
    grep -Eq 'background:[[:space:]]*#050b16[[:space:]]+url\(' <<<"${css}" || \
        fail "GNOME Shell background rule absent from ${name}"
    grep -Fq '#panel {' <<<"${css}" || fail "Starlight panel rule absent from ${name}"
    grep -Fq '#dash .dash-background' <<<"${css}" || fail "Starlight dash rule absent from ${name}"
    grep -Fq '.calendar .calendar-day.calendar-today' <<<"${css}" || \
        fail "Starlight calendar accent rule absent from ${name}"
    grep -Fq '.calendar-day-base' <<<"${css}" || \
        fail "Starlight broad calendar selector absent from ${name}"
    grep -Fq 'background-gradient-start: #f3c653;' <<<"${css}" || \
        fail "yellow gradient accent rule absent from ${name}"
    grep -Fq '.login-dialog-user-selection-box' <<<"${css}" || \
        fail "Starlight user selection rule absent from ${name}"
    grep -Fq '#c89b3c' <<<"${css}" || fail "gold focus rule absent from ${name}"
    grep -Fq 'login-reference.png' <<<"${css}" && fail "mockup referenced by ${name}"
    ((validated += 1))
done
((validated >= 2)) || fail "not enough stylesheets were validated"

shell_resource_list="$(gresource list "${SHELL_RESOURCE}")"
grep -Fqx "${SHELL_PREFIX}/gdm/loginDialog.js" <<<"${shell_resource_list}" || \
    fail "loginDialog.js is absent from the GNOME Shell library"
login_dialog_js="$(gresource extract "${SHELL_RESOURCE}" "${SHELL_PREFIX}/gdm/loginDialog.js")"
grep -Fq '        //RIGHT' <<<"${login_dialog_js}" || \
    fail "right-side login marker is absent from loginDialog.js"
grep -Fq 'actorBox.x1=Math.floor(Math.max(dialogBox.x1,dialogBox.x2-r-natWidth));' \
    <<<"${login_dialog_js}" || fail "right-side login allocation is absent from loginDialog.js"

echo "Starlight OS Vega GDM validation passed (${validated} stylesheets)."
