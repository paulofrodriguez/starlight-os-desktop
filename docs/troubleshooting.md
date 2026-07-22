# Troubleshooting

## Build fails during bootstrap

Check DNS, mirror reachability, system time, and that the configured Debian base
is still supported. Run `sudo make clean` before retrying after an interrupted
build.

## Browser installation fails

Chromium and Firefox ESR are installed from the Debian archive. Check mirror
reachability, the package indices in `build/live-build/chroot/var/lib/apt/lists`,
and whether `main contrib non-free non-free-firmware` are still enabled in
`config/build.env`.

## Installer fails with rsync error 11

`rsync` exit code 11 means file I/O failed during the Calamares `unpackfs`
copy. For this image, the usual cause is an undersized target disk: the ISO is
compressed, but the installed live filesystem currently expands to more than
12 GiB before user data, package upgrades, and filesystem overhead.

Use a target disk of at least 30 GiB. The Calamares welcome module is configured
to require 30 GiB so small VMs or disks fail before the destructive install
stage instead of during `rsync`.

## QEMU test has no success marker

Open `build/artifacts/qemu-boot.log`. Confirm the boot menu passes the serial
console argument and check for kernel panic, missing squashfs, live-boot, or GDM
errors. Increase the timeout only after ruling out a real failure.

## NVIDIA first boot fails

Read `/var/log/starlight/firstboot.log`. The failure is non-fatal by design.
Verify internet connectivity, Secure Boot enrollment requirements, enabled
Debian archive areas, and the Debian NVIDIA package branch.
