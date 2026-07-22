#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Starlight Brasil
# SPDX-License-Identifier: GPL-3.0-or-later

import os
import shutil

import libcalamares


ACCOUNTS_ICON_ROOT = "/var/lib/AccountsService/icons"
ACCOUNTS_USER_ROOT = "/var/lib/AccountsService/users"
AVATAR_SOURCE = "/usr/share/starlight/starlight-live-user.png"
USER_MIN_UID = 1000
USER_MAX_UID = 59999
IGNORED_USERS = {"nobody", "starlight"}


def pretty_name():
    return "Configure Starlight user avatar."


def _gs(name, default=None):
    try:
        value = libcalamares.globalstorage.value(name)
    except Exception:
        return default
    return default if value is None else value


def _target_path(root_mount_point, absolute_path):
    return os.path.join(root_mount_point, absolute_path.lstrip("/"))


def _valid_username(username):
    return isinstance(username, str) and username and "/" not in username


def _username_from_globalstorage():
    candidates = (
        _gs("username"),
        _gs("userName"),
        _gs("autologinUser"),
        _gs("user"),
    )
    for candidate in candidates:
        if _valid_username(candidate):
            return candidate
        if isinstance(candidate, dict):
            for key in ("username", "userName", "name"):
                value = candidate.get(key)
                if _valid_username(value):
                    return value
    return None


def _username_from_passwd(root_mount_point):
    passwd_path = _target_path(root_mount_point, "/etc/passwd")
    try:
        with open(passwd_path, "r", encoding="utf-8") as handle:
            passwd_lines = handle.readlines()
    except OSError:
        return None

    for line in passwd_lines:
        fields = line.rstrip("\n").split(":")
        if len(fields) < 3:
            continue
        username = fields[0]
        try:
            uid = int(fields[2])
        except ValueError:
            continue
        if USER_MIN_UID <= uid <= USER_MAX_UID and username not in IGNORED_USERS:
            return username
    return None


def _installed_username(root_mount_point):
    username = _username_from_globalstorage()
    if username:
        return username
    return _username_from_passwd(root_mount_point)


def _set_user_field(lines, user_start, user_end, key, value):
    field = key + "="
    for index in range(user_start + 1, user_end):
        line = lines[index]
        if line.startswith(field):
            lines[index] = field + value + "\n"
            return user_end
    lines.insert(user_end, field + value + "\n")
    return user_end + 1


def _accounts_service_content(existing_content, icon_path):
    lines = existing_content.splitlines(keepends=True)
    user_start = next(
        (index for index, line in enumerate(lines) if line.strip() == "[User]"),
        None,
    )
    if user_start is None:
        lines = ["[User]\n"] + lines
        user_start = 0

    user_end = len(lines)
    for index in range(user_start + 1, len(lines)):
        line = lines[index].strip()
        if line.startswith("[") and line.endswith("]"):
            user_end = index
            break

    user_end = _set_user_field(lines, user_start, user_end, "Icon", icon_path)
    _set_user_field(lines, user_start, user_end, "SystemAccount", "false")
    return "".join(lines)


def _write_user_avatar(root_mount_point, username):
    source_path = _target_path(root_mount_point, AVATAR_SOURCE)
    if not os.path.exists(source_path):
        return (
            "Avatar Starlight ausente",
            "O icone " + AVATAR_SOURCE + " nao existe no sistema instalado.",
        )

    icon_path = ACCOUNTS_ICON_ROOT + "/" + username
    target_icon = _target_path(root_mount_point, icon_path)
    target_user = _target_path(root_mount_point, ACCOUNTS_USER_ROOT + "/" + username)

    os.makedirs(os.path.dirname(target_icon), mode=0o755, exist_ok=True)
    os.makedirs(os.path.dirname(target_user), mode=0o755, exist_ok=True)
    shutil.copy2(source_path, target_icon)
    os.chmod(target_icon, 0o644)

    try:
        with open(target_user, "r", encoding="utf-8") as handle:
            existing_content = handle.read()
    except OSError:
        existing_content = ""

    with open(target_user, "w", encoding="utf-8") as handle:
        handle.write(_accounts_service_content(existing_content, icon_path))
    os.chmod(target_user, 0o644)
    return None


def run():
    root_mount_point = _gs("rootMountPoint")
    if not root_mount_point or not os.path.isdir(root_mount_point):
        return (
            "Destino nao montado",
            "O sistema instalado nao esta montado para configurar o avatar.",
        )

    username = _installed_username(root_mount_point)
    if not username:
        return (
            "Usuario instalado nao encontrado",
            "Nao foi possivel encontrar o usuario criado para configurar o avatar.",
        )

    libcalamares.utils.debug(
        "Starlight user avatar: configuring AccountsService for " + username
    )
    return _write_user_avatar(root_mount_point, username)
