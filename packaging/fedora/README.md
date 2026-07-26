# Starlight Fedora RPM

This is a Fedora GNOME conversion of the Starlight OS Vega customizations. It
does not attempt to transform Fedora into Debian or replace Fedora boot, GDM,
or package-management components.

Dash to Dock, AppIndicator, Caffeine, Blur My Shell, Kiwi Menu, and the local
Starlight Clock Right extension are installed with the RPM. Tiling Assistant is not
currently available in the enabled Fedora repositories, so the package reports
it as intentionally unavailable rather than downloading it from an unpinned
source.

Build it on Fedora:

```bash
sudo dnf install rpm-build rpmdevtools gtk3 python3
./packaging/fedora/build-rpm.sh
sudo dnf install ./dist/RPMS/noarch/starlight-fedora-1.0.0-1.noarch.rpm
sudo starlight-fedora-apply
```

Use `--remove-conflicts` only if you explicitly want Epiphany and Chromium
removed. Both the application installation set and those removals are recorded
under `/var/lib/starlight-fedora` and can be reversed:

```bash
sudo starlight-fedora-rollback
sudo starlight-fedora-rollback --purge-assets
```

The package map installed at `/usr/share/starlight-fedora/fedora-package-map.txt`
lists all Debian-specific components intentionally left out.
