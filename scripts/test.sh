#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_build_env

require_command qemu-system-x86_64
require_command timeout

iso="${1:-}"
if [[ -z "${iso}" ]]; then
    iso="$(find "${ARTIFACT_DIR}" -maxdepth 1 -type f \
        -name "${SOSD_IMAGE_NAME}-*.iso" | sort | tail -n1)"
fi

if [[ -z "${iso}" || ! -f "${iso}" ]]; then
    echo "No ISO found. Run make build first." >&2
    exit 1
fi

test_result_dir="${PROJECT_ROOT}/build/test-results"
install -d -m 0755 "${test_result_dir}"
log_file="${test_result_dir}/qemu-boot.log"
rm -f "${log_file}"

qemu_acceleration=(-machine accel=tcg -cpu max)
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    qemu_acceleration=(-enable-kvm -cpu host)
fi

set +e
timeout --signal=TERM --kill-after=10s 240s \
    qemu-system-x86_64 \
    "${qemu_acceleration[@]}" \
    -m 4096 \
    -smp 4 \
    -boot d \
    -cdrom "${iso}" \
    -display none \
    -monitor none \
    -no-reboot \
    -serial "file:${log_file}"
qemu_status=$?
set -e

if [[ "${qemu_status}" -ne 0 && "${qemu_status}" -ne 124 ]]; then
    echo "QEMU exited unexpectedly with status ${qemu_status}." >&2
    exit "${qemu_status}"
fi

if ! rg -q \
    'Reached target .*?(graphical|multi-user)\.target|Started .*?gdm\.service|Finished .*?starlight-firstboot\.service|Starlight OS' \
    "${log_file}"; then
    echo "The ISO did not reach a successful boot target." >&2
    tail -n 100 "${log_file}" >&2
    exit 1
fi

echo "QEMU boot test passed."
