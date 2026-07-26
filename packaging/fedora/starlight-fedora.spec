Name:           starlight-fedora
Version:        1.0.0
Release:        2%{?dist}
Summary:        Starlight OS Vega visual profile and Fedora application helper
License:        GPL-3.0-or-later
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  gtk3
BuildRequires:  python3
BuildRequires:  unzip
Requires:       bash
Requires:       dconf
Requires:       glib2
Requires:       hicolor-icon-theme
Requires:       gnome-shell-extension-appindicator
Requires:       gnome-shell-extension-blur-my-shell
Requires:       gnome-shell-extension-caffeine
Requires:       gnome-shell-extension-dash-to-dock
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
wallpaper, icon theme, dconf defaults, local Shell extension, and provides
explicit apply and rollback commands for the optional application set.

%prep
%autosetup

%build

%install
rm -rf %{buildroot}
install -d %{buildroot}%{_datadir}/backgrounds/starlight
install -m 0644 branding/starlight-wallpaper.png \
  %{buildroot}%{_datadir}/backgrounds/starlight/starlight-wallpaper.png
install -d %{buildroot}%{_datadir}/gnome-background-properties
install -m 0644 packaging/fedora/files/starlight.xml \
  %{buildroot}%{_datadir}/gnome-background-properties/starlight.xml
install -d %{buildroot}%{_sysconfdir}/dconf/db/local.d
install -m 0644 packaging/fedora/files/00-starlight \
  %{buildroot}%{_sysconfdir}/dconf/db/local.d/00-starlight
install -m 0644 packaging/fedora/files/30-starlight-blur-my-shell \
  %{buildroot}%{_sysconfdir}/dconf/db/local.d/30-starlight-blur-my-shell
install -d %{buildroot}%{_datadir}/themes/Starlight/gtk-3.0 %{buildroot}%{_datadir}/themes/Starlight/gtk-4.0
install -m 0644 packaging/fedora/files/index.theme %{buildroot}%{_datadir}/themes/Starlight/index.theme
install -m 0644 sosd/etc/gtk-3.0/gtk.css %{buildroot}%{_datadir}/themes/Starlight/gtk-3.0/gtk.css
install -m 0644 sosd/etc/gtk-4.0/gtk.css %{buildroot}%{_datadir}/themes/Starlight/gtk-4.0/gtk.css
install -d %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com
install -m 0644 sosd/usr/share/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/extension.js
install -m 0644 packaging/fedora/files/metadata.json \
  %{buildroot}%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com/metadata.json
install -d %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
unzip -q packaging/fedora/sources/kiwi-menu-32.zip \
  -d %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
find %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma -type d -exec chmod 0755 {} +
find %{buildroot}%{_datadir}/gnome-shell/extensions/kiwimenu@kemma -type f -exec chmod 0644 {} +
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
install -d %{buildroot}%{_docdir}/%{name}
install -m 0644 packaging/fedora/README.md %{buildroot}%{_docdir}/%{name}/README.md

%posttrans
if [ -x /usr/bin/dconf ]; then
  /usr/bin/dconf update || :
fi
if [ -x /usr/bin/gtk-update-icon-cache ]; then
  /usr/bin/gtk-update-icon-cache -q -t -f %{_datadir}/icons/Starlight-Colloid-Yellow-Dark || :
fi

%postun
if [ "$1" -eq 0 ] && [ -x /usr/bin/dconf ]; then
  /usr/bin/dconf update || :
fi

%files
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%{_datadir}/backgrounds/starlight
%{_datadir}/gnome-background-properties/starlight.xml
%{_datadir}/themes/Starlight
%config(noreplace) %{_sysconfdir}/dconf/db/local.d/00-starlight
%config(noreplace) %{_sysconfdir}/dconf/db/local.d/30-starlight-blur-my-shell
%{_datadir}/gnome-shell/extensions/starlight-clock-right@starlightbrasil.com
%{_datadir}/gnome-shell/extensions/kiwimenu@kemma
%{_bindir}/linuxtoys
%{_datadir}/applications/LinuxToys.desktop
%{_datadir}/linuxtoys
%{_datadir}/icons/Starlight-Colloid-Yellow-Dark
%{_datadir}/starlight-fedora/fedora-package-map.txt
%{_sbindir}/starlight-fedora-apply
%{_sbindir}/starlight-fedora-rollback
%{_sbindir}/starlight-fedora-reset-gnome

%changelog
* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-2
- Bundle Fedora-compatible LinuxToys source release

* Sun Jul 26 2026 Paulo Rodriguez <paulofrodriguez@users.noreply.github.com> - 1.0.0-1
- Initial Fedora conversion of the Starlight OS Vega profile
