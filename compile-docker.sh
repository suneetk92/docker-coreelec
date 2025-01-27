#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

echo "Docker compiler (client and server) for CoreELEC systems"

BUILDX_VERSION="0.20.1"
CTOP_VERSION="0.7.7"
COMPOSE_VERSION="2.32.4"
MOBY_VERSION="27.5.1"
CLI_VERSION="27.4.0"

# Prefix definitions
BUILDX_PREFIX="buildx-v${BUILDX_VERSION}."
CTOP_PREFIX="ctop-${CTOP_VERSION}-"
COMPOSE_PREFIX="docker-compose-"

# Function to display usage
print_usage() {
  echo "Usage:"
  echo "    $0 -h         Display this help message."
  echo "    $0 -a <arch>  Build docker using buildx for specified architecture. Default arm64."
  echo "    <arch> must be ${bold}arm64${normal}, ${bold}armv7${normal}, or ${bold}armv6${normal}"
}

# Default architecture
ARCH="linux/arm64"
ARCH_TAR="arm64"
BUILDX_SUFFIX="linux-arm64"
CTOP_SUFFIX="linux-arm64"
COMPOSE_SUFFIX="linux-aarch64"

# Parse subcommands and options
if [[ "$1" == "-a" ]]; then
  case "$2" in
    "arm64" )
      ARCH="linux/arm64"
      ARCH_TAR="arm64"
      BUILDX_SUFFIX="linux-arm64"
      CTOP_SUFFIX="linux-arm64"
      COMPOSE_SUFFIX="linux-aarch64"
      ;;
    "armv7" )
      ARCH="linux/arm/v7"
      ARCH_TAR="armv7"
      BUILDX_SUFFIX="linux-arm-v7"
      CTOP_SUFFIX="linux-arm"
      COMPOSE_SUFFIX="linux-armv7"
      ;;
    "armv6" )
      ARCH="linux/arm/v6"
      ARCH_TAR="armv6"
      BUILDX_SUFFIX="linux-arm-v6"
      CTOP_SUFFIX="linux-arm"
      COMPOSE_SUFFIX="linux-armv6"
      ;;
    * )
      echo -e "\nInvalid architecture: $2" 1>&2
      print_usage
      exit 1
      ;;
  esac
else
  echo -e "\nNo architecture defined, defaulting to arm64" 1>&2
fi

# Output selected build method and architecture
echo -e "\nARCH: $ARCH"

# Check Docker and buildx support
if ! command -v docker >/dev/null 2>&1; then
  echo -e "\nDocker is not installed. Please install Docker."
  exit 1
fi

# Prepare environment
set -e  # Enable error handling
echo -e "\nCleaning up old build files..."
rm -rf ./build_tmp && rm -f ./storage/.docker/bin/* ./storage/.docker/cli-plugins/*
mkdir -p storage/.docker/bin storage/.docker/cli-plugins storage/.docker/data-root build_tmp

# Download dependencies
download_file() {
  echo -e "\nDownloading $2..."
  curl -L -s --fail "$1" -o "$2" || { echo "Failed to download $1"; exit 1; }
  chmod +x "$2"
}

# Parallelize downloads
download_file "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/$BUILDX_PREFIX$BUILDX_SUFFIX" ./storage/.docker/cli-plugins/docker-buildx
download_file "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/$CTOP_PREFIX$CTOP_SUFFIX" ./storage/.docker/bin/ctop
download_file "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/${COMPOSE_PREFIX}${COMPOSE_SUFFIX}" ./storage/.docker/bin/docker-compose
wait # Ensure all downloads complete before proceeding

# Clone and build repositories
cd build_tmp

echo -e "\nDownloading Moby repository..."
wget -q https://github.com/moby/moby/archive/refs/tags/v${MOBY_VERSION}.zip -O moby.zip || { echo "Failed to download moby repository"; exit 1; }
echo -e "\nUnzipping Moby repository..."
unzip -q moby.zip || { echo "Failed to unzip moby repository"; exit 1; }
mv moby-${MOBY_VERSION} moby
echo -e "\nApplying patch to Moby..."
sed -i 's|/etc/docker|/storage/.config/docker/etc|' moby/cmd/dockerd/daemon_unix.go || { echo "Failed to apply patch"; exit 1; }

echo -e "\nDownloading Docker CLI repository..."
wget -q https://github.com/docker/cli/archive/refs/tags/v${CLI_VERSION}.zip -O cli.zip || { echo "Failed to download cli repository"; exit 1; }
echo -e "\nUnzipping Docker CLI repository..."
unzip -q cli.zip || { echo "Failed to unzip cli repository"; exit 1; }
mv cli-${CLI_VERSION} cli

# Build Moby and CLI
cd moby
echo -e "\nBuilding Moby with buildx..."
docker buildx bake --progress=plain --set binary.platform=$ARCH || { echo "Buildx build failed for moby"; exit 1; }
cd ../cli
echo -e "\nBuilding Docker CLI with buildx..."
docker buildx bake --progress=plain --set binary.platform=$ARCH || { echo "Buildx build failed for cli"; exit 1; }
cd ../..

# Copy binaries
echo -e "\nCopying Moby binaries..."
cp -p build_tmp/moby/bundles/binary/* ./storage/.docker/bin || { echo "Failed to copy moby binaries"; exit 1; }
echo -e "\nCopying CLI binaries..."
cp -p build_tmp/cli/build/docker* ./storage/.docker/bin || { echo "Failed to copy cli binaries"; exit 1; }

# Create tarball
FILE_NAME="docker_v${MOBY_VERSION}_coreelec_${ARCH_TAR}.tar.xz"
echo -e "\nCreating tarball $FILE_NAME..."
tar -caf $FILE_NAME storage || { echo "Failed to create tarball"; exit 1; }

echo -e "\nBuild completed successfully!"
