# Image hygiene and security

The final hook removes machine IDs, SSH host keys, journals, logs, histories,
caches, temporary files, and build-time APT state. systemd and OpenSSH generate
host-specific identity on the installed machine.

Build and CI rules:

- never copy a home directory into the image;
- never put credentials in hooks, package sources, or CI YAML;
- never publish build logs before scanning them;
- never embed release signing keys in the repository or ISO;
- treat optional telemetry as disabled until the user explicitly opts in;
- store only the minimum hardware information necessary for local diagnostics.

The first-boot hardware inventory remains local in `/var/lib/starlight`. It is
not transmitted.

