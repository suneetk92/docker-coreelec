#!/bin/bash

DOCKER_TAG="27.5.1"
DOCKER_VERSION="v22.06.0-beta.0-167-gec89e7cde1.m"
DOCKER_DATE="20250125225049"

# Default architecture
ARCH_TAR="arm64"

# Determine architecture from command-line argument, defaulting to arm64
if [ -n "$1" ]; then
  ARCH_TAR=$1
fi

echo "ARCH_TAR: $ARCH_TAR"

DOCKER_FILE="docker_v${DOCKER_TAG}_coreelec_${ARCH_TAR}_${DOCKER_DATE}.tar.xz"
DOCKER_URL="https://github.com/suneetk92/docker-coreelec/releases/download/${DOCKER_TAG}/${DOCKER_FILE}"

# Check for existing Docker installation
if [ -f "/storage/.kodi/addons/service.system.docker/bin/dockerd" ]; then
  echo -e "\nFound a Docker package installed via Kodi addon."
  read -p "Do you want to remove it and install corelec-docker 22.06 [y/N]? " choice
  if [[ "$choice" =~ ^[yY]$ ]]; then
    echo -e "\nUninstalling Docker addon\n"

    # Stop and remove files
    systemctl stop service.system.docker.service
    systemctl disable service.system.docker.service
    rm -rf /storage/.kodi/addons/service.system.docker
    rm -rf /storage/.kodi/userdata/addon_data/service.system.docker
    rm -rf /storage/.kodi/addons/packages/service.system.docker-*.zip

    # Remove from SQLite databases
    sqlite3 /storage/.kodi/userdata/Database/Addons33.db \
      "DELETE FROM installed WHERE addonID LIKE '%docker%'; VACUUM;"
    sqlite3 /storage/.kodi/userdata/Database/Textures13.db \
      "DELETE FROM texture WHERE url LIKE '%docker%'; VACUUM;"
  else
    echo -e "\nInstallation aborted.\n"
    exit 1
  fi
fi

# Install Docker
echo -e "\nDOCKER_URL: ${DOCKER_URL}"
echo "Downloading Docker. This may take a while."
curl -L --fail ${DOCKER_URL} -o ${DOCKER_FILE}
mv ${DOCKER_FILE} /storage/

cd /
echo -e "\nInstalling Docker\n"
tar xvf /storage/${DOCKER_FILE}

# Configure Docker service
echo -e "\nConfiguring dockerd service. This may take a while.\n"
systemctl daemon-reload
systemctl enable service.system.docker.service
systemctl restart service.system.docker
rm /storage/${DOCKER_FILE}

# Update PATH in /storage/.profile
echo -e "\nConfiguring PATH\n"
if ! grep -q "PATH=/storage/.docker/bin" /storage/.profile 2>/dev/null; then
  echo "export PATH=/storage/.docker/bin:\$PATH" >> /storage/.profile
  echo "Docker PATH added to /storage/.profile"
fi

echo -e "\nInstallation is almost finished. Please reboot the system to complete the setup."
echo "For more information, visit: https://github.com/suneetk92/docker-coreelec"

# Reboot prompt
if [ "$1" != "noshutdown" ]; then
  read -p "Do you want to reboot the system now [y/N]? " choice
  if [[ "$choice" =~ ^[yY]$ ]]; then
    shutdown -r now
  fi
fi
