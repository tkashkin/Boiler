# Boiler
Simple app to control Redmond Skykettle RK-G200S/RK-G210S/RK-G211S (and probably similar devices)

## Supported devices:
* Redmond Skykettle
  - RK-G200S, RK-G210S, RK-G211S (tested)
  - other 2nd-gen devices (RK-G2xx) (not tested)

## Runtime dependencies
* bluez

Note: Bluetooth 4.0 adapter with BLE support required.

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

## Screenshots
<p align="center"><img src="data/screenshots/connect.png?raw=true" /><img src="data/screenshots/kettle_not_paired.png?raw=true" width="49%" /><img src="data/screenshots/kettle_64.png?raw=true" width="49%" /> <img src="data/screenshots/kettle_80.png?raw=true" width="49%" /><img src="data/screenshots/kettle_100.png?raw=true" width="49%" /></p>
