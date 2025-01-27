# docker-coreelec
Docker for CoreELEC distro

CoreELEC is a Linux system (JeOS - Just enough Operational System) that runs on devices with Amlogic processors. It has the minimum required to run the Kodi system and uses the original Amlogic Kernel for Android (4.9.113) having support for almost all embedded devices (Bluetooth, WiFi, Ethernet, Audio and Video Output, Hardware Video Decoding) using the original Android structure while other Linux distributions often do not support all installed devices.

Usually new software is installed through add-on using the GUI interface (Kodi),
where the software is usually aimed for multimedia activities.
One exception is the system-oriented software Docker.
However, it is limited to version 19.

Generally,
boxes sold with the Amlogic processors line have reasonably high memory for this type of system
(4/8 GB) and multicore processor with a very attractive price.
The possibility of using a docker, especially the latest versions with security fixes,
can make this type of equipment very efficient for a lot of domestic applications, such as servers for IoT.

This project provides structure to install the Docker version 22.06, latest (fetched directly from GitHub), on these devices.

## Download releases

[Download releases](https://github.com/suneetk92/docker-coreelec/releases)

## Installation (easy way)

- Enable ssh via Kodi / CoreELEC interface on the device
- Access the device via SSH

```bash
curl https://raw.githubusercontent.com/suneetk92/docker-coreelec/main/auto-install-docker-coreelec.bash > auto-install-docker-coreelec.sh
bash ./auto-install-docker-coreelec.sh
```

## Compilation instructions (using Linux x86_64/arm64 or macOS)
**Note: If you're compiling it on a platform with a different target architecture, you have to use cross-compiling (buildx).**

### First step: know the device architecture with CoreELEC
- Enable ssh via Kodi / CoreELEC interface on the device
- Access the device via SSH
- Look for the architecture with the uname command:

```bash
# uname -m
```

#### Output table

| Output contains | Architecture is |
|-----------------|-----------------|
| aarch64         | arm64           |
| armhf or armv7  | arm7            |
| armv6           | arm6            |

### Second step: compile it on a platform with docker installed and running

To compile on a platform (<arch> is the architecture: arm64 (default), arm7 or arm6)

```bash
git clone https://github.com/suneetk92/docker-coreelec.git
cd docker-coreelec
./compile-docker.sh -a <arch>
# example: ./compile-docker.sh -a arm64
```

**Depending on your system performance, the compilation can take up to 30 minutes.**

When finished,
a file (.tar.gz) starting with **docker_v27.5.1** identified by architecture and date will be available locally.
Use it to install Docker on CoreELEC.

## Installing or Updating Docker on CoreELEC 

**Important: docker-coreelec (this project) is NOT compatible with Kodi add-on Docker. If you're using Kodi add-on Docker please remove-it before installing docker-coreelec**

To install it, you have to use the download package from [releases](https://github.com/suneetk92/docker-coreelec/releases).

Considering you are using the package name `docker_v27.5.1_coreelec_arm64_20250127231935.tar.xz`

- Send the package `docker_v27.5.1_coreelec_arm64_20250127231935.tar.xz` to device.
- Access the device via SSH and type:

```bash
cd /
# considering that your package is on /storage
tar xvf /storage/docker_v27.5.1_coreelec_arm64_20250127231935.tar.xz
systemctl daemon-reload
systemctl enable service.system.docker.service
systemctl restart service.system.docker
# if you wanna have docker commands on PATH (recommended)
echo "export PATH=/storage/.docker/bin:\$PATH" >> /storage/.profile
```

All docker executable files are at "/storage/.docker/bin".

The daemon.config file is at "/storage/.config/docker/daemon.json"

The data-root directory is "/storage/.docker/data-root"

## Files (binaries) installed on /storage/.docker/bin

| File                          | Source (github)                                     |
|-------------------------------|-----------------------------------------------------|
| ctop                          | [ctop](https://github.com/bcicen/ctop)              |
| docker                        | [docker-cli](https://github.com/docker/cli)         |
| docker-compose                | [docker-compose](https://github.com/docker/compose) |
| docker-proxy                  | [moby](https://github.com/moby/moby)                |
| dockerd                       | [moby](https://github.com/moby/moby)                |

## Files (binaries) installed on /storage/.docker/cli-plugins

| File          | Source (github)                            |
|---------------|--------------------------------------------|
| docker-buildx | [buildx](https://github.com/docker/buildx) |
