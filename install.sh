#!/usr/bin/env bash
# ==============================================================================
# ORANGE PI 4 PRO - RADAR TRAFFIC COUNTING AUTO-PROVISIONING INSTALLER
# Engineered By: by.aipmy
# Spec: Radar Engine v1.12 on Allwinner A733 (64-bit OS with 32-bit armhf compat)
# ==============================================================================

set -e

C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_CYAN="\e[1;36m"

echo -e "${C_CYAN}"
cat << 'ASCII'
  ____            _               _____            __  __ _       
 |  _ \  __ _  __| | __ _  _ __  |_   _| __ __ _  / _|/ _(_) ___  
 | |_) |/ _` |/ _` |/ _` || '__|   | || '__/ _` || |_| |_| |/ __| 
 |  _ <| (_| | (_| | (_| || |      | || | | (_| ||  _|  _| | (__  
 |_| \_\\__,_|\__,_|\__,_||_|      |_||_|  \__,_||_| |_| |_|\___| 
                                                                  
                 RADAR TRAFFIC COUNTING SYSTEM
                     AUTO-INSTALLER PROVISIONING
                             by.aipmy
ASCII
echo -e "${C_RESET}"

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${C_RED}[ERROR] Script installer ini wajib dijalankan sebagai root (sudo bash install.sh)!${C_RESET}"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${C_BLUE}[1/8] Membuat user sistem 'aipmy' dan 'pim'...${C_RESET}"
if ! id -u aipmy >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo,dialout,plugdev aipmy
  echo "aipmy:adminaip0020" | chpasswd
  echo "aipmy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aipmy
  chmod 440 /etc/sudoers.d/aipmy
  echo -e "${C_GREEN}[✓] User 'aipmy' berhasil dibuat.${C_RESET}"
fi

if ! id -u pim >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo,dialout,plugdev pim
  echo "pim:K@t4kunci" | chpasswd
  echo "pim ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pim
  chmod 440 /etc/sudoers.d/pim
  echo -e "${C_GREEN}[✓] User 'pim' berhasil dibuat.${C_RESET}"
fi

echo -e "${C_BLUE}[2/8] Menginstal paket dependensi inti OS...${C_RESET}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl wget git htop build-essential mariadb-server mariadb-client \
  python3 python3-pip python3-dev python3-setuptools python3-venv \
  pkg-config libmariadb-dev libmariadb-dev-compat \
  libglib2.0-0 libncurses5 libncursesw5 \
  libc6:armhf libstdc++6:armhf libgcc-s1:armhf >/dev/null 2>&1 || true

echo -e "${C_BLUE}[3/8] Menginstal Node.js & PM2 Ecosystem...${C_RESET}"
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
  apt-get install -y nodejs >/dev/null 2>&1
fi
npm install -g pm2 >/dev/null 2>&1 || true
pm2 install pm2-logrotate >/dev/null 2>&1 || true
pm2 set pm2-logrotate:max_size 10M >/dev/null 2>&1 || true
pm2 set pm2-logrotate:retain 7 >/dev/null 2>&1 || true

echo -e "${C_BLUE}[4/8] Memasang Fix Clock UART7 (24MHz -> 100MHz)...${C_RESET}"
DTB_DIR="/boot/dtb/allwinner/overlay"
mkdir -p "$DTB_DIR"
if [ -f "$BASE_DIR/overlays/sun60i-a733-uart7-clock-fix.dtbo" ]; then
  cp "$BASE_DIR/overlays/sun60i-a733-uart7-clock-fix.dtbo" "$DTB_DIR/"
  chmod 644 "$DTB_DIR/sun60i-a733-uart7-clock-fix.dtbo"
fi

if [ -f /boot/orangepiEnv.txt ]; then
  if ! grep -q "uart7-clock-fix" /boot/orangepiEnv.txt; then
    sed -i '/^overlays=/ s/$/ uart7 uart7-clock-fix/' /boot/orangepiEnv.txt
    sed -i 's/uart7 uart7/uart7/g' /boot/orangepiEnv.txt
  fi
fi

echo -e "${C_BLUE}[5/8] Memasang Tampilan Header / MOTD Kustom by.aipmy...${C_RESET}"
mkdir -p /etc/update-motd.d
cp "$BASE_DIR/motd/10-orangepi-header" /etc/update-motd.d/10-orangepi-header
chmod 755 /etc/update-motd.d/10-orangepi-header
chmod -x /etc/update-motd.d/10-header 2>/dev/null || true

echo -e "${C_BLUE}[6/8] Menyiapkan Direktori & Konfigurasi Radar...${C_RESET}"
mkdir -p /home/pim/radar /etc
cp -r "$BASE_DIR/radar/"* /home/pim/radar/
cp "$BASE_DIR/config/urad-config.yaml" /etc/urad-config.yml
ln -sf /etc/urad-config.yml /home/pim/radar/config/urad-config.yaml

mkdir -p /usr/local/bin
cp "$BASE_DIR/bin/"* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/* /home/pim/radar/python3_armhf /home/pim/radar/radar-debug 2>/dev/null || true

chown -R pim:pim /home/pim

echo -e "${C_BLUE}[7/8] Mengonfigurasi MariaDB Database...${C_RESET}"
systemctl enable --now mariadb >/dev/null 2>&1 || true
mysql -e "CREATE DATABASE IF NOT EXISTS TF;"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'pim'@'localhost' IDENTIFIED BY 'K@t4kunci' WITH GRANT OPTION;"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'pim'@'127.0.0.1' IDENTIFIED BY 'K@t4kunci' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo -e "${C_BLUE}[8/8] Mengaktifkan PM2 Daemon Under User 'pim'...${C_RESET}"
su - pim -c "cd /home/pim/radar && pm2 start ecosystem.config.js && pm2 save" || true
env PATH=$PATH:/usr/bin pm2 startup systemd -u pim --hp /home/pim >/dev/null 2>&1 || true

echo -e "${C_GREEN}=================================================================================${C_RESET}"
echo -e "${C_GREEN}[✓] INSTALASI & PROVISI ORANGE PI 4 PRO BERHASIL 100%!${C_RESET}"
echo -e "Silakan reboot perangkat untuk mengaktifkan Overlay Clock 100MHz: ${C_YELLOW}sudo reboot${C_RESET}"
echo -e "${C_GREEN}=================================================================================${C_RESET}"
