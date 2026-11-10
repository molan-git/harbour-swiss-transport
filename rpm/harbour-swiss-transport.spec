Name: harbour-swiss-transport
Version: 0.2.0
Release: 1
Summary: Swiss public transport timetables
Group: Harbour/Rich UI
License: MIT
URL: https://github.com/molan-git/harbour-swiss-transport
Source0: %{name}-%{version}.tar.bz2
Requires: sailfishsilica-qt5 >= 0.10.49
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: qt5-qtdeclarative-devel

%description
Timetables, station boards and real-time delays for Swiss public
transport (SBB and partner operators), powered by transport.opendata.ch.

%prep
%setup -q -n %{name}-%{version}

%build
%qtc_qmake5
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qtc_makeinstall

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
