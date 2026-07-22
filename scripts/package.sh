#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_build_env

readonly ISO_SOURCE="${BUILD_ROOT}/binary.hybrid.iso"
readonly ARTIFACT="${ARTIFACT_DIR}/${SOSD_IMAGE_NAME}-${SOSD_VERSION}-${SOSD_ARCHITECTURE}.iso"

if [[ ! -s "${ISO_SOURCE}" ]]; then
    echo "No completed ISO exists at ${ISO_SOURCE}." >&2
    exit 1
fi

install -d -m 0755 "${ARTIFACT_DIR}"
install -m 0644 "${ISO_SOURCE}" "${ARTIFACT}"
sha256sum "${ARTIFACT}" >"${ARTIFACT}.sha256"

echo "ISO created: ${ARTIFACT}"
