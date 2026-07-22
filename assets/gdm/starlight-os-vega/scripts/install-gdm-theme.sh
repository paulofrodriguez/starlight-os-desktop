#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT="${STARLIGHT_ROOT:-}"
readonly KIT_ROOT="${ROOT}/opt/starlight-os/gdm/starlight-os-vega"
readonly ASSET="${KIT_ROOT}/assets/starlight-os-vega-4k.png"
readonly OVERRIDE="${KIT_ROOT}/assets/starlight-os-vega-gdm.css"
readonly RESOURCE="${ROOT}/usr/share/gnome-shell/gnome-shell-theme.gresource"
readonly SHELL_RESOURCE="${ROOT}/usr/lib/gnome-shell/libshell-16.so"
readonly BACKUP_DIR="${ROOT}/usr/lib/starlight-os/backups"
readonly BACKUP="${BACKUP_DIR}/gnome-shell-theme.gresource.original"
readonly SHELL_BACKUP="${BACKUP_DIR}/libshell-16.so.original"
readonly RESOURCE_PREFIX=/org/gnome/shell/theme
readonly SHELL_RESOURCE_PREFIX=/org/gnome/shell
readonly SHELL_JS_SECTION=.gresource.shell_js_resources
readonly EXPECTED_GNOME_MAJOR=48

fail() {
    echo "Starlight Vega GDM installation failed: $*" >&2
    exit 1
}

for command_name in dpkg-query gresource glib-compile-resources objcopy python3; do
    command -v "${command_name}" >/dev/null 2>&1 || fail "missing command: ${command_name}"
done

dpkg_query() {
    if [[ -n "${ROOT}" ]]; then
        dpkg-query --admindir="${ROOT}/var/lib/dpkg" "$@"
    else
        dpkg-query "$@"
    fi
}

for package_name in binutils gdm3 gnome-shell libglib2.0-bin libglib2.0-dev-bin python3; do
    status="$(dpkg_query -W -f='${db:Status-Status}' "${package_name}" 2>/dev/null || true)"
    [[ "${status}" == "installed" ]] || fail "required package is not installed: ${package_name}"
done

gnome_version="$(dpkg_query -W -f='${Version}' gnome-shell)"
gnome_major="${gnome_version%%.*}"
[[ "${gnome_major}" == "${EXPECTED_GNOME_MAJOR}" ]] || \
    fail "unsupported GNOME Shell ${gnome_version}; this integration is validated only for major ${EXPECTED_GNOME_MAJOR}"

[[ -s "${RESOURCE}" ]] || fail "GNOME Shell resource not found: ${RESOURCE}"
[[ -s "${SHELL_RESOURCE}" ]] || fail "GNOME Shell library resource not found: ${SHELL_RESOURCE}"
[[ -s "${OVERRIDE}" ]] || fail "override CSS not found: ${OVERRIDE}"
[[ ! "$(cat "${OVERRIDE}")" =~ login-reference\.png ]] || fail "reference mockup must never be used"

python3 - "${ASSET}" <<'PY'
import struct
import sys

path = sys.argv[1]
with open(path, "rb") as stream:
    header = stream.read(24)
if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
    raise SystemExit(f"invalid PNG: {path}")
width, height = struct.unpack(">II", header[16:24])
if (width, height) != (3840, 2160):
    raise SystemExit(f"expected 3840x2160, found {width}x{height}: {path}")
PY

workdir="$(mktemp -d /tmp/starlight-vega-gdm.XXXXXX)"
trap 'rm -rf "${workdir}"' EXIT
resource_root="${workdir}/resources"
mkdir -p "${resource_root}${RESOURCE_PREFIX}"

mapfile -t resource_paths < <(gresource list "${RESOURCE}")
((${#resource_paths[@]} > 0)) || fail "the GNOME Shell resource is empty"
for resource_path in "${resource_paths[@]}"; do
    destination="${resource_root}${resource_path}"
    mkdir -p "$(dirname "${destination}")"
    gresource extract "${RESOURCE}" "${resource_path}" >"${destination}"
done

stylesheets=(
    "${resource_root}${RESOURCE_PREFIX}/gnome-shell-dark.css"
    "${resource_root}${RESOURCE_PREFIX}/gnome-shell-light.css"
    "${resource_root}${RESOURCE_PREFIX}/gnome-shell-high-contrast.css"
)
patched=0
for stylesheet in "${stylesheets[@]}"; do
    [[ -s "${stylesheet}" ]] || continue
    grep -Eq '(^|[[:space:],])\.login-dialog([[:space:],.{]|$)' "${stylesheet}" || \
        fail "selector .login-dialog is absent from $(basename "${stylesheet}")"
    grep -Fq '#lockDialogGroup' "${stylesheet}" || \
        fail "selector #lockDialogGroup is absent from $(basename "${stylesheet}")"
    python3 - "${stylesheet}" "${OVERRIDE}" <<'PY'
import re
import sys

stylesheet, override = sys.argv[1:]
begin = "/* STARLIGHT_OS_VEGA_GDM_BEGIN */"
end = "/* STARLIGHT_OS_VEGA_GDM_END */"
text = open(stylesheet, encoding="utf-8").read()
text = re.sub(re.escape(begin) + r".*?" + re.escape(end) + r"\s*", "", text,
              flags=re.DOTALL)
addition = open(override, encoding="utf-8").read().strip()
open(stylesheet, "w", encoding="utf-8").write(text.rstrip() + "\n\n" + addition + "\n")
PY
    ((patched += 1))
done
((patched >= 2)) || fail "fewer than two compatible GNOME Shell stylesheets were found"

install -m 0644 "${ASSET}" \
    "${resource_root}${RESOURCE_PREFIX}/starlight-os-vega-4k.png"

manifest="${workdir}/gnome-shell-theme.gresource.xml"
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<gresources>'
    echo "  <gresource prefix=\"${RESOURCE_PREFIX}\">"
    find "${resource_root}${RESOURCE_PREFIX}" -type f -printf '%f\n' | sort | \
        while IFS= read -r filename; do
            printf '    <file>%s</file>\n' "${filename}"
        done
    echo '  </gresource>'
    echo '</gresources>'
} >"${manifest}"

compiled="${workdir}/gnome-shell-theme.gresource"
glib-compile-resources "${manifest}" \
    --sourcedir="${resource_root}${RESOURCE_PREFIX}" \
    --target="${compiled}"
[[ -s "${compiled}" ]] || fail "the rebuilt resource is empty"
gresource list "${compiled}" | grep -Fqx \
    "${RESOURCE_PREFIX}/starlight-os-vega-4k.png" || fail "wallpaper missing from rebuilt resource"

shell_resource_root="${workdir}/shell-js-resources"
mkdir -p "${shell_resource_root}${SHELL_RESOURCE_PREFIX}"

mapfile -t shell_resource_paths < <(gresource list "${SHELL_RESOURCE}")
((${#shell_resource_paths[@]} > 0)) || fail "the GNOME Shell JS resource is empty"
printf '%s\n' "${shell_resource_paths[@]}" | grep -Fqx \
    "${SHELL_RESOURCE_PREFIX}/gdm/loginDialog.js" || fail "loginDialog.js is absent from GNOME Shell resources"
for resource_path in "${shell_resource_paths[@]}"; do
    destination="${shell_resource_root}${resource_path}"
    mkdir -p "$(dirname "${destination}")"
    gresource extract "${SHELL_RESOURCE}" "${resource_path}" >"${destination}"
done

login_dialog_js="${shell_resource_root}${SHELL_RESOURCE_PREFIX}/gdm/loginDialog.js"
python3 - "${login_dialog_js}" <<'PY'
import sys

path = sys.argv[1]
marker = "        //RIGHT\n"
old = """        let [, , natWidth, natHeight] = actor.get_preferred_size();
        let centerX = dialogBox.x1 + (dialogBox.x2 - dialogBox.x1) / 2;
        let centerY = dialogBox.y1 + (dialogBox.y2 - dialogBox.y1) / 2;

        natWidth = Math.min(natWidth, dialogBox.x2 - dialogBox.x1);
        natHeight = Math.min(natHeight, dialogBox.y2 - dialogBox.y1);

        actorBox.x1 = Math.floor(centerX - natWidth / 2);
        actorBox.y1 = Math.floor(centerY - natHeight / 2);
"""
new = """        let [, , natWidth, natHeight] = actor.get_preferred_size();
        let centerY=(dialogBox.y1+dialogBox.y2)/2;
        natWidth=Math.min(natWidth,dialogBox.x2-dialogBox.x1);
        natHeight=Math.min(natHeight,dialogBox.y2-dialogBox.y1);
        //RIGHT
        let r=Math.max(Math.floor((dialogBox.x2-dialogBox.x1)*.055),48);
        actorBox.x1=Math.floor(Math.max(dialogBox.x1,dialogBox.x2-r-natWidth));
        actorBox.y1=Math.floor(centerY-natHeight/2);
"""
if len(old) != len(new):
    raise SystemExit(f"internal patch length changed: {len(old)} -> {len(new)}")

text = open(path, encoding="utf-8").read()
if marker not in text:
    if old not in text:
        raise SystemExit("GNOME Shell login dialog allocation block was not found")
    text = text.replace(old, new, 1)
open(path, "w", encoding="utf-8").write(text)
PY

shell_manifest="${workdir}/gnome-shell-js.gresource.xml"
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<gresources>'
    echo "  <gresource prefix=\"${SHELL_RESOURCE_PREFIX}\">"
    find "${shell_resource_root}${SHELL_RESOURCE_PREFIX}" -type f -printf '%P\n' | sort | \
        while IFS= read -r filename; do
            printf '    <file>%s</file>\n' "${filename}"
        done
    echo '  </gresource>'
    echo '</gresources>'
} >"${shell_manifest}"

compiled_shell="${workdir}/gnome-shell-js.gresource"
glib-compile-resources "${shell_manifest}" \
    --sourcedir="${shell_resource_root}${SHELL_RESOURCE_PREFIX}" \
    --target="${compiled_shell}"
[[ -s "${compiled_shell}" ]] || fail "the rebuilt GNOME Shell JS resource is empty"

original_shell_resource="${workdir}/gnome-shell-js.original.gresource"
objcopy --dump-section "${SHELL_JS_SECTION}=${original_shell_resource}" \
    "${SHELL_RESOURCE}" || fail "could not extract ${SHELL_JS_SECTION}"
original_shell_resource_size="$(stat -c '%s' "${original_shell_resource}")"
compiled_shell_size="$(stat -c '%s' "${compiled_shell}")"
if ((compiled_shell_size > original_shell_resource_size)); then
    fail "rebuilt GNOME Shell JS resource grew from ${original_shell_resource_size} to ${compiled_shell_size} bytes"
fi
if ((compiled_shell_size < original_shell_resource_size)); then
    truncate -s "${original_shell_resource_size}" "${compiled_shell}"
fi

staged_shell="${SHELL_RESOURCE}.starlight-vega-new"
install -m 0644 "${SHELL_RESOURCE}" "${staged_shell}"
objcopy --update-section "${SHELL_JS_SECTION}=${compiled_shell}" \
    "${staged_shell}" || fail "could not update ${SHELL_JS_SECTION}"
gresource extract "${staged_shell}" "${SHELL_RESOURCE_PREFIX}/gdm/loginDialog.js" | \
    grep -Fq 'actorBox.x1=Math.floor(Math.max(dialogBox.x1,dialogBox.x2-r-natWidth));' || \
    fail "right-side login allocation is absent from rebuilt GNOME Shell library"

install -d -m 0755 "${BACKUP_DIR}"
if [[ ! -s "${BACKUP}" ]]; then
    install -m 0644 "${RESOURCE}" "${BACKUP}"
fi
if [[ ! -s "${SHELL_BACKUP}" ]]; then
    install -m 0644 "${SHELL_RESOURCE}" "${SHELL_BACKUP}"
fi
staged="${RESOURCE}.starlight-vega-new"
install -m 0644 "${compiled}" "${staged}"
mv -f "${staged}" "${RESOURCE}"
mv -f "${staged_shell}" "${SHELL_RESOURCE}"

echo "Starlight OS Vega GDM resource installed for GNOME Shell ${gnome_version}."
