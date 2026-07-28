Name:           starlight-fedora
Version:        1.0.0
Release:        13%{?dist}
Summary:        Starlight OS Vega visual profile and Fedora application helper
License:        GPL-3.0-or-later
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  gtk3
BuildRequires:  python3
BuildRequires:  unzip
BuildRequires:  glib2
BuildRequires:  plymouth-theme-spinner
Requires:       accountsservice
Requires:       bash
Requires:       binutils
Requires:       coreutils
Requires:       curl
Requires:       dconf
Requires:       flatpak
Requires:       firefox
Requires:       gdm
Requires:       glib2
Requires:       glib2-devel
Requires:       gnome-shell
Requires:       gnome-shell >= 50
Requires:       gnome-shell < 51
Requires:       hicolor-icon-theme
Requires:       gtk3
Requires:       polkit
Requires:       plymouth-plugin-two-step
Requires:       plymouth-scripts
Requires:       plymouth-theme-spinner
Requires:       gnome-shell-extension-appindicator
Requires:       gnome-shell-extension-blur-my-shell
Requires:       gnome-shell-extension-caffeine
Requires:       gnome-shell-extension-dash-to-dock
Requires:       gnome-shell-extension-user-theme
# Starlight's declared container/virtualization baseline. These are Fedora
# packages, not an optional post-install best effort.
Requires:       incus
Requires:       incus-client
Requires:       incus-tools
Requires:       lxcfs
Requires:       dnsmasq
Requires:       btrfs-progs
Requires:       lvm2
Requires:       python3-gobject
Requires:       python3-requests
Requires:       vte291

%description
Starlight OS Vega visual profile for Fedora GNOME.  It installs the Starlight
wallpaper, icon theme, dconf defaults, local Shell extensions, and a graphical
manager for applying or removing the optional application set.

%prep
%autosetup

%build

%install
rm -rf %{buildroot}
install -d %{buildroot}%{_datadir}/backgrounds/starlight
install -m 0644 branding/starlight-wallpaper.png \
  %{buildroot}%{_datadir}/backgrounds/starlight/starlight-wallpaper.png
install -d %{buildroot}%{_datadir}/starlight-gdm
install -m 0644 assets/gdm/starlight-os-vega/assets/starlight-os-vega-4k.png \
  %{buildroot}%{_datadir}/starlight-gdm/starlight-os-vega-4k.png
install -m 0644 assets/gdm/starlight-os-vega/assets/starlight-os-vega-gdm.css \
  %{buildroot}%{_datadir}/starlight-gdm/starlight-os-vega-gdm.css
install -d %{buildroot}%{_datadir}/starlight
install -m 0644 branding/starlight-calamares-light.png \
  %{buildroot}%{_datadir}/starlight/starlight-user-avatar.png
install -d %{buildroot}%{_datadir}/gnome-background-properties
install -m 0644 packaging/fedora/files/starlight.xml \
  %{buildroot}%{_datadir}/gnome-background-properties/starlight.xml
install -d %{buildroot}%{_sysconfdir}/dconf/db/local.d
install -m 0644 packaging/fedora/files/00-starlight \
  %{buildroot}%{_sysconfdir}/dconf/db/local.d/00-starlight
install -m 0644 packaging/fedora/files/30-starlight-blur-my-shell \
  %{buildroot}%{_sysconfdir}/dconf/db/local.d/30-starlight-blur-my-shell
install -d %{buildroot}%{_sysconfdir}/dconf/db/gdm.d
install -m 0644 packaging/fedora/files/01-starlight-gdm \
  %{buildroot}%{_sysconfdir}/dconf/db/gdm.d/01-starlight-gdm
install -d %{buildroot}%{_sysconfdir}/dnf/libdnf5.conf.d
install -m 0644 packaging/fedora/files/90-starlight.conf \
  %{buildroot}%{_sysconfdir}/dnf/libdnf5.conf.d/90-starlight.conf
install -d %{buildroot}%{_datadir}/themes/Starlight/gtk-3.0 %{buildroot}%{_datadir}/themes/Starlight/gtk-4.0
install -m 0644 packaging/fedora/files/index.theme %{buildroot}%{_datadir}/themes/Starlight/index.theme
install -m 0644 sosd/etc/gtk-3.0/gtk.css %{buildroot}%{_datadir}/themes/Starlight/gtk-3.0/gtk.css
install -m 0644 sosd/etc/gtk-4.0/gtk.css %{buildroot}%{_datadir}/themes/Starlight/gtk-4.0/gtk.css
install -d %{buildroot}%{_sysconfdir}/gtk-3.0 %{buildroot}%{_sysconfdir}/gtk-4.0
install -m 0644 sosd/etc/gtk-3.0/gtk.css %{buildroot}%{_sysconfdir}/gtk-3.0/gtk.css
install -m 0644 sosd/etc/gtk-4.0/gtk.css %{buildroot}%{_sysconfdir}/gtk-4.0/gtk.css
install -d %{buildroot}%{_sysconfdir}/skel/.config/gtk-3.0 %{buildroot}%{_sysconfdir}/skel/.config/gtk-4.0
install -m 0644 sosd/etc/skel/.config/gtk-3.0/gtk.css %{buildroot}%{_sysconfdir}/skel/.config/gtk-3.0/gtk.css
install -m 0644 sosd/etc/skel/.config/gtk-3.0/settings.ini %{buildroot}%{_sysconfdir}/skel/.config/gtk-3.0/settings.ini
install -m 0644 sosd/etc/skel/.config/gtk-4.0/gtk.css %{buildroot}%{_sysconfdir}/skel/.config/gtk-4.0/gtk.css
install -m 0644 sosd/etc/skel/.config/gtk-4.0/settings.ini %{buildroot}%{_sysconfdir}/skel/.config/gtk-4.0/settings.ini
# Fedora's x86_64 Firefox lives under lib64, while BuildArch: noarch makes
# %{_libdir} expand to /usr/lib during rpmbuild.
install -d %{buildroot}%{_prefix}/lib64/firefox/distribution
install -m 0644 sosd/usr/share/firefox-esr/distribution/policies.json \
  %{buildroot}%{_prefix}/lib64/firefox/distribution/policies.json
install -d %{buildroot}%{_datadir}/themes/Starlight/gnome-shell
install -m 0644 packaging/fedora/files/gnome-shell.css \
  %{buildroot}%{_datadir}/themes/Starlight/gnome-shell/gnome-shell.css
install -d %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com
install -m 0644 sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js
install -m 0644 packaging/fedora/files/metadata.json \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/metadata.json
install -d %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-brighter@starlightbrasil.com
install -m 0644 sosd/usr/share/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/extension.js \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/extension.js
install -m 0644 sosd/usr/share/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/metadata.json \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/metadata.json
install -m 0644 sosd/usr/share/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/stylesheet.css \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-brighter@starlightbrasil.com/stylesheet.css
install -d %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
unzip -q packaging/fedora/sources/kiwi-menu-32.zip \
  -d %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
find %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma -type d -exec chmod 0755 {} +
find %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma -type f -exec chmod 0644 {} +
glib-compile-schemas %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma/schemas
install -m 0644 branding/starlight-calamares-light.png \
  %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma/src/starlight-menu.png
sed -i '0,/"path": "\/icons\/gnome-icon-symbolic.svg"/s|"path": "/icons/gnome-icon-symbolic.svg"|"path": "/src/starlight-menu.png"|' \
  %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma/src/icons.json
grep -Fq '"path": "/src/starlight-menu.png"' \
  %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma/src/icons.json
install -d %{buildroot}%{_prefix}
linuxtoys_stage="$(mktemp -d)"
tar -xJf assets/third-party/linuxtoys_6.4.8.orig.tar.xz -C "${linuxtoys_stage}"
cp -a "${linuxtoys_stage}/linuxtoys_6.4.8.orig/usr/." %{buildroot}%{_prefix}/
rm -rf "${linuxtoys_stage}"
install -d %{buildroot}%{_datadir}/starlight-fedora
install -m 0644 packaging/fedora/files/fedora-package-map.txt \
  %{buildroot}%{_datadir}/starlight-fedora/fedora-package-map.txt
tar -xzf assets/third-party/starlight-colloid-icon-theme.tar.gz \
  -C %{buildroot}%{_datadir}/starlight-fedora
bash %{buildroot}%{_datadir}/starlight-fedora/starlight-colloid-yellow-dark/install-starlight.sh \
  --dest %{buildroot}%{_datadir}/icons --force
rm -rf %{buildroot}%{_datadir}/starlight-fedora/starlight-colloid-yellow-dark
install -d %{buildroot}%{_sbindir}
install -m 0755 packaging/fedora/files/starlight-fedora-apply \
  %{buildroot}%{_sbindir}/starlight-fedora-apply
install -m 0755 packaging/fedora/files/starlight-fedora-rollback \
  %{buildroot}%{_sbindir}/starlight-fedora-rollback
install -m 0755 packaging/fedora/files/starlight-fedora-reset-gnome \
  %{buildroot}%{_sbindir}/starlight-fedora-reset-gnome
install -m 0755 packaging/fedora/files/starlight-fedora-enable-rpmfusion \
  %{buildroot}%{_sbindir}/starlight-fedora-enable-rpmfusion
install -m 0755 packaging/fedora/files/starlight-fedora-set-user-avatar \
  %{buildroot}%{_sbindir}/starlight-fedora-set-user-avatar
install -d %{buildroot}%{_bindir}
install -m 0755 packaging/fedora/files/starlight-fedora-manager \
  %{buildroot}%{_bindir}/starlight-fedora-manager
install -d %{buildroot}%{_datadir}/plymouth/themes/starlight
install -m 0644 packaging/fedora/files/starlight.plymouth \
  %{buildroot}%{_datadir}/plymouth/themes/starlight/starlight.plymouth
for image in %{_datadir}/plymouth/themes/spinner/*.png; do
  image_name="${image##*/}"
  [ "${image_name}" = watermark.png ] && continue
  ln -s "../spinner/${image_name}" \
    "%{buildroot}%{_datadir}/plymouth/themes/starlight/${image_name}"
done
install -m 0644 branding/starlight-gdm-logo.png \
  %{buildroot}%{_datadir}/plymouth/themes/starlight/watermark.png
install -d %{buildroot}%{_libexecdir}/starlight-fedora
install -m 0755 assets/gdm/starlight-os-vega/scripts/install-gdm-theme.sh \
  %{buildroot}%{_libexecdir}/starlight-fedora/apply-gdm-theme
install -m 0755 packaging/fedora/files/starlight-wps-language-wrapper \
  %{buildroot}%{_libexecdir}/starlight-fedora/wps-language-wrapper
install -m 0755 packaging/fedora/files/starlight-fedora-apply-plymouth \
  %{buildroot}%{_libexecdir}/starlight-fedora/apply-plymouth-theme
install -m 0755 packaging/fedora/files/starlight-fedora-restore-plymouth \
  %{buildroot}%{_libexecdir}/starlight-fedora/restore-plymouth-theme
install -d %{buildroot}%{_prefix}/local/share/applications
install -m 0644 packaging/fedora/files/wps-office-*.desktop \
  %{buildroot}%{_prefix}/local/share/applications/
install -d %{buildroot}%{_datadir}/applications
install -m 0644 packaging/fedora/files/com.starlight.FedoraManager.desktop \
  %{buildroot}%{_datadir}/applications/com.starlight.FedoraManager.desktop
install -d %{buildroot}%{_datadir}/polkit-1/actions
install -m 0644 packaging/fedora/files/com.starlight.FedoraManager.policy \
  %{buildroot}%{_datadir}/polkit-1/actions/com.starlight.FedoraManager.policy
install -d %{buildroot}%{_datadir}/pixmaps
install -m 0644 branding/starlight-calamares-light.png \
  %{buildroot}%{_datadir}/pixmaps/starlight-fedora-manager.png
install -d %{buildroot}%{_docdir}/%{name}
install -m 0644 packaging/fedora/README.md %{buildroot}%{_docdir}/%{name}/README.md

%posttrans
if [ -x /usr/bin/dconf ]; then
  /usr/bin/dconf update || :
fi
if [ -x /usr/bin/gtk-update-icon-cache ]; then
  /usr/bin/gtk-update-icon-cache -q -t -f %{_datadir}/icons/Starlight-Colloid-Yellow-Dark || :
fi
if [ -x /usr/bin/update-desktop-database ]; then
  /usr/bin/update-desktop-database %{_datadir}/applications || :
  /usr/bin/update-desktop-database %{_prefix}/local/share/applications || :
fi
# Apply the resource-based GDM integration last, after the assets and dconf
# database are in place.  The helper is idempotent and preserves originals.
%{_libexecdir}/starlight-fedora/apply-gdm-theme || :
%{_libexecdir}/starlight-fedora/apply-plymouth-theme || :

%preun
if [ "$1" -eq 0 ]; then
  %{_libexecdir}/starlight-fedora/restore-plymouth-theme || :
fi

%postun
if [ "$1" -eq 0 ] && [ -x /usr/bin/dconf ]; then
  /usr/bin/dconf update || :
fi
if [ "$1" -eq 0 ] && [ -x /usr/bin/update-desktop-database ]; then
  /usr/bin/update-desktop-database %{_datadir}/applications || :
  /usr/bin/update-desktop-database %{_prefix}/local/share/applications || :
fi

%files
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%{_datadir}/backgrounds/starlight
%{_datadir}/starlight-gdm
%{_datadir}/starlight/starlight-user-avatar.png
%{_datadir}/gnome-background-properties/starlight.xml
%{_datadir}/themes/Starlight
%config(noreplace) %{_sysconfdir}/gtk-3.0/gtk.css
%config(noreplace) %{_sysconfdir}/gtk-4.0/gtk.css
%{_sysconfdir}/skel/.config/gtk-3.0/gtk.css
%{_sysconfdir}/skel/.config/gtk-3.0/settings.ini
%{_sysconfdir}/skel/.config/gtk-4.0/gtk.css
%{_sysconfdir}/skel/.config/gtk-4.0/settings.ini
%{_prefix}/lib64/firefox/distribution/policies.json
%config(noreplace) %{_sysconfdir}/dconf/db/local.d/00-starlight
%config(noreplace) %{_sysconfdir}/dconf/db/local.d/30-starlight-blur-my-shell
%config(noreplace) %{_sysconfdir}/dconf/db/gdm.d/01-starlight-gdm
%config(noreplace) %{_sysconfdir}/dnf/libdnf5.conf.d/90-starlight.conf
%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com
%{_datadir}/gnome-shell/extensions/starlight-brighter@starlightbrasil.com
%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
%{_bindir}/linuxtoys
%{_datadir}/applications/LinuxToys.desktop
%{_datadir}/linuxtoys
%{_datadir}/icons/hicolor/scalable/apps/linuxtoys.svg
%{_datadir}/icons/Starlight-Colloid-Yellow-Dark
%{_datadir}/starlight-fedora/fedora-package-map.txt
%{_sbindir}/starlight-fedora-apply
%{_sbindir}/starlight-fedora-rollback
%{_sbindir}/starlight-fedora-reset-gnome
%{_sbindir}/starlight-fedora-enable-rpmfusion
%{_sbindir}/starlight-fedora-set-user-avatar
%{_bindir}/starlight-fedora-manager
%{_datadir}/plymouth/themes/starlight
%{_libexecdir}/starlight-fedora/apply-gdm-theme
%{_libexecdir}/starlight-fedora/apply-plymouth-theme
%{_libexecdir}/starlight-fedora/restore-plymouth-theme
%{_libexecdir}/starlight-fedora/wps-language-wrapper
%{_datadir}/applications/com.starlight.FedoraManager.desktop
%{_datadir}/polkit-1/actions/com.starlight.FedoraManager.policy
%{_datadir}/pixmaps/starlight-fedora-manager.png
%{_prefix}/local/share/applications/wps-office-*.desktop

%changelog
* Tue Jul 28 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-13
- Use Starlight amber selection colours in Firefox and native GTK text fields
- Start Firefox on a blank page without Fedora bookmarks or pinned shortcuts

* Tue Jul 28 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-12
- Hide the duplicate Quick Settings power button while retaining menu actions

* Tue Jul 28 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-11
- Show all graphical profile-manager controls when its window opens

* Tue Jul 28 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-10
- Brand Plymouth with Starlight, add Telegram and refresh AccountsService avatars

* Tue Jul 28 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-9
- Add a graphical install/rollback launcher and preserve the user's terminal font

* Mon Jul 27 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-8
- Install the official WPS Office 12 RPM and replace LibreOffice in the Fedora profile

* Mon Jul 27 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-7
- Add the optional Starlight Brighter extension for dim notebook displays

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-6
- Replace LibreOffice with the international WPS Office Flatpak in the Fedora profile

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-5
- Match GTK 3/4, Shell, Kiwi, wallpaper and avatar defaults to the live Starlight session

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-4
- Apply the complete GDM resource theme, DNF defaults, RPM Fusion/codec helper and Starlight avatars

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-3
- Add the GNOME Shell navy theme, GDM wallpaper defaults and Kiwi schemas

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-2
- Bundle Fedora-compatible LinuxToys source release

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-1
- Initial Fedora conversion of the Starlight OS Vega profile
