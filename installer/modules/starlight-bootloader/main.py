#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Starlight Brasil
# SPDX-License-Identifier: GPL-3.0-or-later

import os
import platform
import shutil
import subprocess

import libcalamares


BOOTLOADER_ID = "starlight"
EFI_SYSTEM_PARTITION = "/boot/efi"
GRUB_INSTALL = "grub-install"
GRUB_MKCONFIG = "grub-mkconfig"
GRUB_MKSTANDALONE = "grub-mkstandalone"
GRUB_CFG = "/boot/grub/grub.cfg"
STANDALONE_CONFIG = "/tmp/starlight-grub-efi-fallback.cfg"
STANDALONE_MODULES = (
    "all_video boot btrfs configfile echo ext2 f2fs fat gfxterm gzio linux "
    "normal part_gpt part_msdos reboot search search_fs_file search_fs_uuid "
    "sleep test xfs"
)


def pretty_name():
    return "Install Starlight bootloader."


def _gs(name, default=None):
    try:
        value = libcalamares.globalstorage.value(name)
    except Exception:
        return default
    return default if value is None else value


def _target_call(command):
    libcalamares.utils.debug(
        "Starlight bootloader: running " + " ".join(str(item) for item in command)
    )
    return libcalamares.utils.target_env_call(command)


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
    libcalamares.utils.debug("Starlight bootloader: running " + command_text)
    try:
        output = libcalamares.utils.target_env_process_output(command)
    except subprocess.CalledProcessError as error:
        stdout = _decode_output(
            getattr(error, "stdout", None) or getattr(error, "output", None)
        ).strip()
        stderr = _decode_output(getattr(error, "stderr", None)).strip()
        detail = stderr or stdout or str(error)
        libcalamares.utils.warning(
            "Starlight bootloader: command failed with exit code "
            + str(error.returncode)
            + ": "
            + command_text
        )
        if stdout:
            libcalamares.utils.debug("Starlight bootloader stdout:\n" + stdout)
        if stderr:
            libcalamares.utils.warning("Starlight bootloader stderr:\n" + stderr)
        return error.returncode or 1, detail
    except Exception as error:
        libcalamares.utils.warning(
            "Starlight bootloader: command failed: "
            + command_text
            + ": "
            + str(error)
        )
        return 1, str(error)

    output_text = _decode_output(output).strip()
    if output_text:
        libcalamares.utils.debug("Starlight bootloader output:\n" + output_text)
    return 0, ""


def _case_exists(root, relative_path):
    current = root
    for part in relative_path.split("/"):
        if not part:
            continue
        try:
            entries = os.listdir(current)
        except OSError:
            return False
        match = next((entry for entry in entries if entry.lower() == part.lower()), None)
        if match is None:
            return False
        current = os.path.join(current, match)
    return os.path.exists(current)


def _efi_target():
    try:
        with open("/sys/firmware/efi/fw_platform_size", "r", encoding="utf-8") as handle:
            efi_bits = handle.read(2)
    except OSError:
        efi_bits = "64"

    machine = platform.machine()
    if efi_bits == "32":
        return "i386-efi", "grubia32.efi", "BOOTIA32.EFI"
    if machine == "aarch64":
        return "arm64-efi", "grubaa64.efi", "BOOTAA64.EFI"
    if machine == "loongarch64":
        return "loongarch64-efi", "grubloongarch64.efi", "BOOTLOONGARCH64.EFI"
    return "x86_64-efi", "grubx64.efi", "BOOTX64.EFI"


def _run_mkconfig():
    exit_code, detail = _target_process(["mkdir", "-p", "/boot/grub"])
    if exit_code != 0:
        return (
            "Erro ao preparar configuracao do GRUB",
            "Nao foi possivel criar /boot/grub no sistema instalado. " + detail,
        )

    exit_code, detail = _target_process([GRUB_MKCONFIG, "-o", GRUB_CFG])
    if exit_code != 0:
        return (
            "Erro ao gerar configuracao do GRUB",
            "O comando grub-mkconfig falhou dentro do sistema instalado. " + detail,
        )
    return None


def _partition_with_mount(partitions, mount_point):
    return next(
        (
            partition
            for partition in partitions
            if partition.get("mountPoint") == mount_point
        ),
        None,
    )


def _vfat_child(parent, name):
    try:
        entries = os.listdir(parent)
    except OSError:
        return os.path.join(parent, name)

    match = next((entry for entry in entries if entry.lower() == name.lower()), None)
    return os.path.join(parent, match or name)


def _ensure_efi_layout(install_efi_dir):
    firmware_dir = _vfat_child(install_efi_dir, "EFI")
    boot_dir = _vfat_child(firmware_dir, "BOOT")
    vendor_dir = _vfat_child(firmware_dir, BOOTLOADER_ID)

    os.makedirs(boot_dir, exist_ok=True)
    os.makedirs(vendor_dir, exist_ok=True)
    return vendor_dir, boot_dir


def _copy_vendor_loader_to_fallback(vendor_dir, boot_dir, grub_file, fallback_file):
    source = _vfat_child(vendor_dir, grub_file)
    if not os.path.exists(source):
        return False

    shutil.copy2(source, os.path.join(boot_dir, fallback_file))
    return True


def _newest_boot_pair(root_mount_point):
    boot_dir = os.path.join(root_mount_point, "boot")
    try:
        kernels = sorted(
            filename for filename in os.listdir(boot_dir) if filename.startswith("vmlinuz-")
        )
    except OSError:
        return None

    for kernel in reversed(kernels):
        version = kernel.removeprefix("vmlinuz-")
        initrd = "initrd.img-" + version
        if os.path.exists(os.path.join(boot_dir, initrd)):
            return kernel, initrd

    return None


def _boot_context(root_mount_point, partitions):
    root_partition = _partition_with_mount(partitions, "/")
    if root_partition is None or not root_partition.get("uuid"):
        return None

    boot_pair = _newest_boot_pair(root_mount_point)
    if boot_pair is None:
        return None

    boot_partition = _partition_with_mount(partitions, "/boot")
    search_uuid = (
        boot_partition.get("uuid")
        if boot_partition is not None and boot_partition.get("uuid")
        else root_partition.get("uuid")
    )
    if not search_uuid:
        return None

    if boot_partition is not None:
        kernel_path = "/" + boot_pair[0]
        initrd_path = "/" + boot_pair[1]
        grub_cfg_path = "/grub/grub.cfg"
    else:
        kernel_path = "/boot/" + boot_pair[0]
        initrd_path = "/boot/" + boot_pair[1]
        grub_cfg_path = "/boot/grub/grub.cfg"

    return {
        "root_uuid": root_partition["uuid"],
        "search_uuid": search_uuid,
        "kernel_path": kernel_path,
        "initrd_path": initrd_path,
        "grub_cfg_path": grub_cfg_path,
    }


def _direct_boot_config(context, include_configfile_entry):
    lines = [
        "set default=0",
        "set timeout=5",
        "insmod part_gpt",
        "insmod part_msdos",
        "insmod ext2",
        "insmod btrfs",
        "insmod xfs",
        "insmod f2fs",
        "insmod search",
        "insmod search_fs_uuid",
        "search --no-floppy --fs-uuid --set=root " + context["search_uuid"],
        "menuentry 'Starlight OS Vega' {",
        "    search --no-floppy --fs-uuid --set=root " + context["search_uuid"],
        "    linux "
        + context["kernel_path"]
        + " root=UUID="
        + context["root_uuid"]
        + " ro quiet splash",
        "    initrd " + context["initrd_path"],
        "}",
    ]

    if include_configfile_entry:
        lines.extend(
            [
                "if [ -e ($root)" + context["grub_cfg_path"] + " ]; then",
                "    menuentry 'Starlight OS Vega (GRUB config)' {",
                "        search --no-floppy --fs-uuid --set=root "
                + context["search_uuid"],
                "        configfile ($root)" + context["grub_cfg_path"],
                "    }",
                "fi",
            ]
        )

    return "\n".join(lines) + "\n"


def _write_standalone_config(root_mount_point, partitions):
    context = _boot_context(root_mount_point, partitions)
    config_path = os.path.join(root_mount_point, STANDALONE_CONFIG.lstrip("/"))
    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    with open(config_path, "w", encoding="utf-8") as handle:
        if context is None:
            handle.write(
                "insmod part_gpt\n"
                "insmod part_msdos\n"
                "insmod ext2\n"
                "insmod search\n"
                "insmod search_fs_file\n"
                "search --no-floppy --file --set=root /boot/grub/grub.cfg\n"
                "if [ -e ($root)/boot/grub/grub.cfg ]; then\n"
                "    configfile ($root)/boot/grub/grub.cfg\n"
                "fi\n"
                "echo \"Starlight bootloader could not find a bootable kernel\"\n"
                "sleep --interruptible 10\n"
                "reboot\n"
            )
        else:
            handle.write(_direct_boot_config(context, True))
    return STANDALONE_CONFIG


def _install_standalone_efi(
    root_mount_point,
    partitions,
    efi_dir,
    target,
    grub_file,
    fallback_file,
    vendor_dir,
    boot_dir,
):
    config_path = _write_standalone_config(root_mount_point, partitions)
    fallback_target = efi_dir + "/EFI/BOOT/" + fallback_file
    exit_code, detail = _target_process(
        [
            GRUB_MKSTANDALONE,
            "-O",
            target,
            "-o",
            fallback_target,
            "--modules=" + STANDALONE_MODULES,
            "boot/grub/grub.cfg=" + config_path,
        ]
    )
    if exit_code != 0:
        return False, detail

    fallback_host_path = os.path.join(boot_dir, fallback_file)
    if os.path.exists(fallback_host_path):
        shutil.copy2(fallback_host_path, os.path.join(vendor_dir, grub_file))

    return True, ""


def _write_minimal_grub_cfg(root_mount_point, partitions):
    context = _boot_context(root_mount_point, partitions)
    if context is None:
        return False

    cfg_path = os.path.join(root_mount_point, GRUB_CFG.lstrip("/"))
    os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
    with open(cfg_path, "w", encoding="utf-8") as handle:
        handle.write(_direct_boot_config(context, False))
    libcalamares.utils.warning(
        "Starlight bootloader: wrote a minimal grub.cfg after grub-mkconfig failed."
    )
    return True


def _ensure_grub_cfg(root_mount_point, partitions):
    result = _run_mkconfig()
    if result is None:
        return None

    if _write_minimal_grub_cfg(root_mount_point, partitions):
        return None

    return result


def _install_efi(root_mount_point, partitions):
    efi_dir = _gs("efiSystemPartition", EFI_SYSTEM_PARTITION)
    install_efi_dir = root_mount_point + efi_dir
    partition = _partition_with_mount(partitions, efi_dir)

    os.makedirs(install_efi_dir, exist_ok=True)
    if not os.path.ismount(install_efi_dir):
        return (
            "Particao EFI nao montada",
            "A instalacao UEFI precisa de uma particao FAT32 montada em /boot/efi.",
        )

    if partition is not None:
        filesystem = (partition.get("fs") or partition.get("fsName") or "").lower()
        if filesystem and filesystem not in ("fat32", "vfat"):
            return (
                "Particao EFI invalida",
                "A particao EFI precisa ser FAT32 e estar montada em /boot/efi.",
            )

    target, grub_file, fallback_file = _efi_target()
    vendor_dir, boot_dir = _ensure_efi_layout(install_efi_dir)
    grub_cfg_result = _ensure_grub_cfg(root_mount_point, partitions)
    if grub_cfg_result is not None:
        return grub_cfg_result

    install_command = [
        GRUB_INSTALL,
        "--target=" + target,
        "--efi-directory=" + efi_dir,
        "--bootloader-id=" + BOOTLOADER_ID,
        "--force",
        "--no-nvram",
        "--no-uefi-secure-boot",
    ]

    exit_code, detail = _target_process(install_command)
    if exit_code != 0:
        libcalamares.utils.warning(
            "Starlight bootloader: offline EFI GRUB install failed; "
            "trying standalone removable EFI fallback."
        )
    else:
        _copy_vendor_loader_to_fallback(vendor_dir, boot_dir, grub_file, fallback_file)

    fallback_ok, fallback_detail = _install_standalone_efi(
        root_mount_point,
        partitions,
        efi_dir,
        target,
        grub_file,
        fallback_file,
        vendor_dir,
        boot_dir,
    )
    if not fallback_ok and exit_code != 0:
        return (
            "Erro ao instalar o GRUB UEFI",
            "O grub-install falhou e o fallback standalone tambem falhou. "
            + (fallback_detail or detail),
        )
    if not fallback_ok and not _case_exists(install_efi_dir, "EFI/BOOT/" + fallback_file):
        return (
            "Erro ao criar fallback UEFI",
            "O GRUB instalou sem NVRAM, mas o carregador removivel nao foi criado. "
            + fallback_detail,
        )
    if not fallback_ok:
        libcalamares.utils.warning(
            "Starlight bootloader: standalone fallback failed, keeping copied "
            "GRUB EFI fallback: "
            + fallback_detail
        )

    if not _case_exists(install_efi_dir, "EFI/BOOT/" + fallback_file):
        return (
            "Fallback UEFI ausente",
            "O GRUB terminou sem criar o carregador EFI removivel em EFI/BOOT.",
        )

    return None


def _install_bios():
    boot_loader = _gs("bootLoader")
    install_path = boot_loader.get("installPath") if isinstance(boot_loader, dict) else None
    if not install_path:
        return (
            "Destino BIOS ausente",
            "Nenhum disco foi selecionado para instalar o GRUB BIOS.",
        )

    exit_code = _target_call(
        [GRUB_INSTALL, "--target=i386-pc", "--recheck", "--force", install_path]
    )
    if exit_code != 0:
        return (
            "Erro ao instalar o GRUB BIOS",
            "Em BIOS com GPT, crie uma particao bios_grub de 8 MiB ou use tabela MBR.",
        )

    return _run_mkconfig()


def run():
    fw_type = _gs("firmwareType")
    partitions = _gs("partitions", [])
    root_mount_point = _gs("rootMountPoint")

    if not root_mount_point or not os.path.isdir(root_mount_point):
        return (
            "Destino nao montado",
            "O sistema instalado nao esta montado para configurar o bootloader.",
        )

    if fw_type == "efi":
        return _install_efi(root_mount_point, partitions)

    return _install_bios()
