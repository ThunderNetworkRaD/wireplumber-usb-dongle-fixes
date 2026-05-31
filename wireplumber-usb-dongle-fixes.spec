Name:           wireplumber-usb-dongle-fixes
Version:        1.0
Release:        0
Summary:        Fixes and optimizations for USB dongles in WirePlumber
License:        MIT
Group:          System/Management
URL:            https://thundernetwork.org
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       wireplumber
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description

This package installs a configuration rule for WirePlumber that disables idle suspension for USB dongles and enables software volume/mixer.

%prep
%setup -q

%build
# Nulla da compilare

%install
# Crea la cartella di destinazione nella buildroot di openSUSE
mkdir -p %{buildroot}%{_sysconfdir}/wireplumber/wireplumber.conf.d/
cp -a etc/wireplumber/wireplumber.conf.d/50-usb-dongle-fixes.conf %{buildroot}%{_sysconfdir}/wireplumber/wireplumber.conf.d/

%post
echo "WirePlumber rule installed. Restart the service now with:"
echo "systemctl --user restart wireplumber"

%files
%defattr(-,root,root)
%dir %{_sysconfdir}/wireplumber
%dir %{_sysconfdir}/wireplumber/wireplumber.conf.d
%config(noreplace) %{_sysconfdir}/wireplumber/wireplumber.conf.d/50-usb-dongle-fixes.conf

%changelog
* Sun May 31 2026 KillerBossOriginal <KillerBossOriginal@outlook.it> - 1.0-0
- First Release.
