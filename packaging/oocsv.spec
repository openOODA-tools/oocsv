Name:           oocsv
Version:        0.2.0
Release:        1%{?dist}
Summary:        High-speed RFC 4180 CSV parser with SQL-like query filtering and header renaming.
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oocsv
Source0:        oocsv-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oocsv is a sovereign, capability-bounded CSV FILTER written
in pure openOODA, featuring zero ambient authority, oote color themes,
and an MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oocsv
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oocsv-uninstall

%files
/usr/bin/oocsv
/usr/bin/oocsv-uninstall

%changelog
* Wed Oct 08 2026 openOODA-tools <ops@openooda.org> - 0.2.0-1
- Elevation to pure native openOODA v0.2.0 with MCP and tri-distro packaging
