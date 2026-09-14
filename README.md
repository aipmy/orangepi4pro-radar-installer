# Orange Pi 4 Pro - Radar Traffic Counting Provisioning Installer

Repository ini berisi script otomasi installer dan konfigurasi standar untuk **Orange Pi 4 Pro** (Allwinner A733) yang menjalankan firmware **Radar Engine v1.12** (Dual Stream Pipeline MQTT & WebSocket).

Engineered By: **by.aipmy**

---

## Fitur Utama Installer:
1. **Clock UART7 Fix (100 MHz):**
   - Mengaktifkan device tree overlay `sun60i-a733-uart7-clock-fix.dtbo`.
   - Mengatasi framing error (18.6%) pada baudrate tinggi 921.600 bps uRAD sensor.
2. **Branding & MOTD Header by.aipmy:**
   - Menampilkan banner ASCII "Radar Traffic Counting System" saat login SSH.
   - Deteksi real-time CPU temp, RAM, Disk, Status PM2, dan DEVID dari `/etc/urad-config.yml`.
3. **User Management Standar:**
   - User `aipmy` (sudo NOPASSWD)
   - User `pim` (sudo NOPASSWD, owner proses PM2 radar)
4. **Automasi Database:**
   - Konfigurasi MariaDB `TF` dengan hak akses penuh ke `pim@localhost` dan `pim@127.0.0.1`.
5. **PM2 Process Guard:**
   - Service ID 0: `pm2-logrotate` (10M r7)
   - Service ID 1: `radar-sensor` (Sensor Doppler)
   - Service ID 2: `radar-uploader` (MQTT/WS Pipeline)
   - Service ID 3: `radar-cleaner` (Log rotation & retention)
   - Service ID 4: `radar-monitor` (Thermal Guard & Watchdog)

---

## Cara Instalasi di Orange Pi 4 Pro Bersih (Fresh Image):

Jalankan perintah satu baris berikut di terminal Orange Pi:

```bash
git clone https://github.com/aipmy/orangepi4pro-radar-installer.git /tmp/installer
cd /tmp/installer
sudo bash install.sh
sudo reboot
```
