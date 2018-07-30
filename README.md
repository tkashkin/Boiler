# Boiler
Simple app to control Redmond Skykettle RK-G200S (and probably similar devices)

## Supported devices:
* Redmond Skykettle RK-G200S

## Installation
Prebuilt releases can be found on [releases page](https://github.com/tkashkin/Boiler/releases).

## Building

### Debian/Ubuntu-based distros

#### Build dependencies
* meson
* valac
* libgranite-dev
* libgtk-3-dev
* libglib2.0-dev
* libgee-0.8-dev

#### Building
```bash
git clone https://github.com/tkashkin/Boiler.git
cd Boiler
debuild
```

### Any distro, without package manager
```bash
git clone https://github.com/tkashkin/Boiler.git
cd Boiler
meson build --prefix=/usr
cd build
ninja
sudo ninja install
```
