# Starlight OS metapackage plan

These files are source-of-truth dependency lists for future Debian
metapackages. The live ISO uses `packages/*.list.chroot`; keep both sets aligned
when an application graduates into the default image.

Each `*.depends` file maps one package name to Debian package dependencies.
External APT repositories, Flatpak applications, and user-level installers stay
outside normal Debian dependencies and are handled by post-install scripts.

## Packaging split

- Debian archive packages: keep as normal metapackage `Depends`.
- External APT: enable the repository first, then install the package.
- Flatpak: install through Flathub during image creation when it is part of the
  default image, and keep first boot as a repair/update path.
- User-level tools: install through explicit idempotent post-install scripts.

## External APT

- `element-desktop`: official Element repository, enabled by
  `starlight-enable-element-repo`.

## Flatpak

- `com.rtosta.zapzap`: ZapZap, from Flathub.

## Bundled upstream packages

- `linuxtoys`: upstream Debian package plus matching source artifacts under
  `assets/third-party/`.
- `webapp-manager`: Linux Mint WebApp Manager package plus source artifacts
  under `assets/third-party/`.
- `oh-my-bash`: upstream archive installed into `/usr/share/oh-my-bash`.

## Post-install scripts

- `starlight-enable-debian-components`
- `starlight-enable-steam-i386`
- `starlight-configure-flathub`
- `starlight-enable-element-repo`
- `starlight-install-homebrew`
- `starlight-install-sdkman`
- `starlight-install-oh-my-bash`
- `starlight-install-jetbrainsmono-nerd-font`
- `starlight-configure-terminals`

These scripts do not modify the Starlight GNOME, GTK, GDM, icon, or wallpaper
themes.
