Name:       harbour-swiss-transport
Version:    0.1.0
Release:    1
Summary:    Swiss public transport for Sailfish OS
License:    BSD-3-Clause
Group:      Qt/Qt
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Gui)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt5Network)
BuildRequires: sailfishsilica-qt5
Requires:   sailfishsilica-qt5

%description
Swiss public transport application for Sailfish OS.

%prep
%setup -q

%build
%qmake5
%make_build

%install
%qmake5_install

%files
%{_bindir}/harbour-swiss-transport
%{_datadir}/applications/harbour-swiss-transport.desktop
%{_datadir}/harbour-swiss-transport/qml/
%{_datadir}/icons/hicolor/86x86/apps/harbour-swiss-transport.png
%{_datadir}/icons/hicolor/108x108/apps/harbour-swiss-transport.png
%{_datadir}/icons/hicolor/128x128/apps/harbour-swiss-transport.png
%{_datadir}/icons/hicolor/172x172/apps/harbour-swiss-transport.png
