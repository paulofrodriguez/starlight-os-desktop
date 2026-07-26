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
mkdir -p "${stage}/sosd/usr/share/gnome-shell/extensions"
cp -a "${root}/sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com" \
  "${stage}/sosd/usr/share/gnome-shell/extensions/"
mkdir -p "${stage}/sosd/etc"
cp -a "${root}/sosd/etc/gtk-3.0" "${root}/sosd/etc/gtk-4.0" "${stage}/sosd/etc/"
cp -a "${root}/LICENSE" "${stage}/LICENSE" 2>/dev/null || \
  printf 'GPL-3.0-or-later\n' >"${stage}/LICENSE"
mkdir -p "${dist}/SOURCES" "${dist}/SPECS" "${dist}/BUILD" "${dist}/BUILDROOT" "${dist}/RPMS" "${dist}/SRPMS"
tar -C "${work}" -czf "${dist}/SOURCES/${name}-${version}.tar.gz" "${name}-${version}"
cp "${root}/packaging/fedora/${name}.spec" "${dist}/SPECS/"
rpmbuild -bb "${dist}/SPECS/${name}.spec" --define "_topdir ${dist}"
find "${dist}/RPMS" -name "${name}-*.rpm" -print
