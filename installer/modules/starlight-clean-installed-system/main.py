#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Starlight Brasil
# SPDX-License-Identifier: GPL-3.0-or-later

import os
import shutil
import subprocess

import libcalamares


PACKAGES_TO_PURGE = (
    "calamares",
    "calamares-extensions",
    "epiphany-browser",
)

PATHS_TO_REMOVE = (
    "/etc/calamares",
    "/etc/polkit-1/rules.d/49-starlight-live-installer.rules",
    "/usr/lib/x86_64-linux-gnu/calamares/modules/starlight-bootloader",
    "/usr/lib/x86_64-linux-gnu/calamares/modules/starlight-clean-installed-system",
    "/usr/lib/x86_64-linux-gnu/calamares/modules/starlight-user-avatar",
    "/usr/local/bin/starlight-browser",
    "/usr/local/bin/starlight-launch-installer",
    "/usr/local/sbin/starlight-run-installer",
    "/usr/share/applications/calamares.desktop",
    "/usr/share/applications/org.gnome.Epiphany.desktop",
    "/usr/share/applications/starlight-browser.desktop",
    "/usr/share/applications/starlight-install.desktop",
    "/usr/share/calamares/branding/starlight",
    "/usr/share/polkit-1/actions/com.starlight.install.policy",
)

FAVORITES_TO_REMOVE = (
    "starlight-install.desktop",
    "starlight-browser.desktop",
    "org.gnome.Epiphany.desktop",
)


def pretty_name():
    return "Clean live-only Starlight installer artifacts."


def _gs(name, default=None):
    try:
        value = libcalamares.globalstorage.value(name)
    except Exception:
        return default
    return default if value is None else value


def _target_path(root_mount_point, absolute_path):
    return os.path.join(root_mount_point, absolute_path.lstrip("/"))


def _decode_output(output):
    if output is None:
        return ""
    if isinstance(output, bytes):
        return output.decode("utf-8", "replace")
    if isinstance(output, (list, tuple)):
        return "\n".join(_decode_output(item) for item in output if item is not None)
    return str(output)


def _target_process(command):
    command_text = " ".join(str(item) for item in command)
    libcalamares.utils.debug("Starlight cleanup: running " + command_text)
    try:
        output = libcalamares.utils.target_env_process_output(command)
    except subprocess.CalledProcessError as error:
        stdout = _decode_output(
            getattr(error, "stdout", None) or getattr(error, "output", None)
        ).strip()
        stderr = _decode_output(getattr(error, "stderr", None)).strip()
        return error.returncode or 1, stderr or stdout or str(error)
    except Exception as error:
        return 1, str(error)
    return 0, _decode_output(output).strip()


def _installed_packages(package_names):
    installed = []
    for package_name in package_names:
        exit_code, status = _target_process(
            ["dpkg-query", "-W", "-f=${db:Status-Status}", package_name]
        )
        if exit_code == 0 and status == "installed":
            installed.append(package_name)
    return installed


def _purge_packages(package_names):
    if not package_names:
        return None

    exit_code, detail = _target_process(
        ["apt-get", "--purge", "-q", "-y", "remove"] + list(package_names)
    )
    if exit_code != 0:
        return (
            "Falha ao limpar pacotes live",
            "Nao foi possivel remover pacotes live do sistema instalado: " + detail,
        )
    return None


def _remove_target_path(root_mount_point, absolute_path):
    target_path = _target_path(root_mount_point, absolute_path)
    try:
        if os.path.isdir(target_path) and not os.path.islink(target_path):
            shutil.rmtree(target_path)
        else:
            os.remove(target_path)
    except FileNotFoundError:
        return None
    except OSError as error:
        return absolute_path + ": " + str(error)
    return None


def _remove_live_only_favorites(root_mount_point):
    defaults_path = _target_path(
        root_mount_point, "/etc/dconf/db/starlight.d/00-starlight"
    )
    try:
        with open(defaults_path, "r", encoding="utf-8") as handle:
            content = handle.read()
    except FileNotFoundError:
        return False
    except OSError as error:
        raise RuntimeError(str(error)) from error

    cleaned = content
    for favorite in FAVORITES_TO_REMOVE:
        quoted = "'" + favorite + "'"
        cleaned = cleaned.replace(", " + quoted, "")
        cleaned = cleaned.replace(quoted + ", ", "")
        cleaned = cleaned.replace(quoted, "")

    if cleaned == content:
        return False

    with open(defaults_path, "w", encoding="utf-8") as handle:
        handle.write(cleaned)
    return True


def run():
    root_mount_point = _gs("rootMountPoint")
    if not root_mount_point or not os.path.isdir(root_mount_point):
        return (
            "Destino nao montado",
            "O sistema instalado nao esta montado para limpar artefatos live.",
        )

    installed_packages = _installed_packages(PACKAGES_TO_PURGE)
    if installed_packages:
        libcalamares.utils.debug(
            "Starlight cleanup: purging " + ", ".join(installed_packages)
        )
    package_error = _purge_packages(installed_packages)
    if package_error:
        return package_error

    remove_errors = []
    for absolute_path in PATHS_TO_REMOVE:
        error = _remove_target_path(root_mount_point, absolute_path)
        if error:
            remove_errors.append(error)
    if remove_errors:
        return (
            "Falha ao limpar artefatos live",
            "Nao foi possivel remover: " + "; ".join(remove_errors),
        )

    try:
        dconf_changed = _remove_live_only_favorites(root_mount_point)
    except RuntimeError as error:
        return (
            "Falha ao limpar favoritos do GNOME",
            "Nao foi possivel atualizar os favoritos padrao: " + str(error),
        )

    if dconf_changed:
        exit_code, detail = _target_process(["dconf", "update"])
        if exit_code != 0:
            return (
                "Falha ao atualizar dconf",
                "Nao foi possivel recompilar os defaults do GNOME: " + detail,
            )

    return None
