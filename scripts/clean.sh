#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_build_env
readonly CACHE_ROOT="${CACHE_BASE}/${SOSD_DISTRIBUTION}-${SOSD_ARCHITECTURE}"

if mountpoint -q "${BUILD_ROOT}/chroot/dev" 2>/dev/null; then
    echo "A build chroot is mounted; run this command as root." >&2
    [[ "${EUID}" -eq 0 ]] || exit 1
fi

if [[ -d "${BUILD_ROOT}" && -x "$(command -v lb || true)" && "${EUID}" -eq 0 ]]; then
    (cd "${BUILD_ROOT}" && lb clean --purge) || true
fi

rm -rf "${BUILD_ROOT}" "${ARTIFACT_DIR}"

if [[ "${1:-}" == "--purge-cache" ]]; then
    rm -rf "${CACHE_BASE}" "${DOWNLOAD_CACHE}"
    echo "All persistent package caches removed."
fi

install -d -m 0755 "${PROJECT_ROOT}/build"
touch "${PROJECT_ROOT}/build/.gitkeep"
