#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
name=starlight-fedora
version=1.0.0
dist="${root}/dist"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

command -v rpmbuild >/dev/null || {
  echo 'Missing rpmbuild. Install rpm-build: sudo dnf install rpm-build' >&2
  exit 1
}

stage="${work}/${name}-${version}"
mkdir -p "${stage}/packaging"
cp -a "${root}/packaging/fedora" "${stage}/packaging/"
cp -a "${root}/branding" "${stage}/"
mkdir -p "${stage}/assets/third-party"
cp -a "${root}/assets/third-party/starlight-colloid-icon-theme.tar.gz" "${stage}/assets/third-party/"
cp -a "${root}/assets/third-party/linuxtoys_6.4.8.orig.tar.xz" "${stage}/assets/third-party/"
mkdir -p "${stage}/assets/gdm"
cp -a "${root}/assets/gdm/starlight-os-vega" "${stage}/assets/gdm/"
mkdir -p "${stage}/sosd/usr/share/gnome-shell/extensions"
cp -a "${root}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com" \
  "${stage}/sosd/usr/share/gnome-shell/extensions/"
cp -a "${root}/sosd/usr/share/gnome-shell/extensions/starlight-brighter@starlightbrasil.com" \
  "${stage}/sosd/usr/share/gnome-shell/extensions/"
mkdir -p "${stage}/sosd/usr/share"
cp -a "${root}/sosd/usr/share/firefox-esr" "${stage}/sosd/usr/share/"
mkdir -p "${stage}/sosd/etc"
cp -a "${root}/sosd/etc/gtk-3.0" "${root}/sosd/etc/gtk-4.0" "${stage}/sosd/etc/"
mkdir -p "${stage}/sosd/etc/skel/.config"
cp -a "${root}/sosd/etc/skel/.config/gtk-3.0" \
  "${root}/sosd/etc/skel/.config/gtk-4.0" \
  "${stage}/sosd/etc/skel/.config/"
cp -a "${root}/LICENSE" "${stage}/LICENSE" 2>/dev/null || \
  printf 'GPL-3.0-or-later\n' >"${stage}/LICENSE"
mkdir -p "${dist}/SOURCES" "${dist}/SPECS" "${dist}/BUILD" "${dist}/BUILDROOT" "${dist}/RPMS" "${dist}/SRPMS"
tar -C "${work}" -czf "${dist}/SOURCES/${name}-${version}.tar.gz" "${name}-${version}"
cp "${root}/packaging/fedora/${name}.spec" "${dist}/SPECS/"
rpmbuild -bb "${dist}/SPECS/${name}.spec" --define "_topdir ${dist}"

rpm_path="$(
  find "${dist}/RPMS" -type f -name "${name}-${version}-*.noarch.rpm" \
    -printf '%T@ %p\n' |
    sort -nr |
    head -n 1 |
    cut -d' ' -f2-
)"
[[ -n "${rpm_path}" ]] || {
  echo 'rpmbuild completed without producing the expected noarch RPM.' >&2
  exit 1
}

rpm_basename="${rpm_path##*/}"
installer="${rpm_path%/*}/install-and-apply-${rpm_basename%.rpm}.sh"
sed "s|@RPM_BASENAME@|${rpm_basename}|g" \
  "${root}/packaging/fedora/install-and-apply.sh.in" >"${installer}"
chmod 0755 "${installer}"

checksum="${rpm_path%/*}/${rpm_basename%.rpm}.sha256"
(
  cd -- "${rpm_path%/*}"
  sha256sum "${rpm_basename}" "${installer##*/}" >"${checksum##*/}"
)

printf '%s\n' "${rpm_path}" "${installer}" "${checksum}"
