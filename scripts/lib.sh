#!/usr/bin/env bash
# shellcheck disable=SC2034
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_ROOT
readonly BUILD_ROOT="${PROJECT_ROOT}/build/live-build"
readonly ARTIFACT_DIR="${PROJECT_ROOT}/build/artifacts"
readonly CACHE_BASE="${PROJECT_ROOT}/build/cache"
readonly DOWNLOAD_CACHE="${PROJECT_ROOT}/build/downloads"

load_build_env() {
    # shellcheck source=../config/build.env
    source "${PROJECT_ROOT}/config/build.env"
    # shellcheck source=../config/assets.env
    source "${PROJECT_ROOT}/config/assets.env"
}

require_command() {
    local command_name="$1"
    command -v "${command_name}" >/dev/null 2>&1 || {
        echo "Missing required command: ${command_name}" >&2
        return 1
    }
}
