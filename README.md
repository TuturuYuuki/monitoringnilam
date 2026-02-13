# Monitoring System - Real-time Network Device & Camera Monitoring

> **Sistem Monitoring Perangkat Jaringan & CCTV Real-time**  
> Project KP - Dapat diakses melalui jaringan lokal

## 📋 Deskripsi

Aplikasi monitoring real-time untuk memantau status perangkat jaringan dan kamera CCTV. Sistem ini dibangun menggunakan Flutter untuk frontend mobile dan PHP untuk backend API, dirancang khusus untuk memantau infrastruktur jaringan dalam lingkungan lokal.

## ✨ Fitur Utama

### 🔐 Autentikasi & Keamanan
- **Login dengan Email Verification**: Sistem OTP (One-Time Password) dikirim melalui email
- **Change Password**: Fitur ubah password dengan verifikasi OTP
- **Session Management**: Pengelolaan sesi pengguna yang aman

### 📡 Monitoring Real-time
- **CCTV Monitoring**: Pemantauan status kamera CCTV secara real-time
- **MMT (Massive MIMO Tower) Monitoring**: Monitoring perangkat MMT dengan status dan lokasi
- **Network Device Monitoring**: Pemantauan perangkat jaringan lainnya
- **Auto Ping Check**: Pemeriksaan konektivitas otomatis dengan ping
- **Manual Ping Check**: Tombol ping manual untuk verifikasi konektivitas
- **Real-time Status Updates**: Update status perangkat secara otomatis

### 🔔 Notifikasi & Alert
- **Status Alerts**: Notifikasi ketika perangkat offline/bermasalah
- **Device Status Tracking**: Pelacakan perubahan status perangkat
- **Visual Indicators**: Indikator visual untuk status online/offline

### 📊 Manajemen Perangkat
- **Add/Delete Devices**: Tambah dan hapus perangkat monitoring
- **Device Grouping**: Pengelompokan berdasarkan tipe (CCTV, MMT, Network)
- **Device Information**: Informasi detail setiap perangkat (IP, lokasi, tipe)

## 🛠️ Teknologi

### Frontend
- **Flutter**: Framework UI cross-platform
- **Dart**: Bahasa pemrograman
- **HTTP Package**: Untuk komunikasi dengan backend

### Backend
- **PHP**: Server-side scripting
- **MySQL**: Database management
- **SMTP**: Email service untuk OTP

### Infrastructure
- **Local Network**: Sistem berjalan di jaringan lokal
- **Ping Protocol**: ICMP untuk cek konektivitas

## 📁 Struktur Database

### Tabel Utama:
- **users**: Data pengguna dan autentikasi
- **otp_tokens**: Token OTP untuk verifikasi
- **cctv**: Data kamera CCTV
- **mmt**: Data Massive MIMO Tower
- **devices**: Data perangkat jaringan lainnya
- **alerts**: Log notifikasi dan alert

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK
- PHP 7.4+
- MySQL/MariaDB
- SMTP Email Service (untuk OTP)
- Local Network Access

### Backend Setup
```bash
# 1. Import database schema
mysql -u root -p < mmt_schema.sql
mysql -u root -p < otp_tokens_schema.sql
mysql -u root -p < create_users_table.sql

# 2. Insert sample data (optional)
mysql -u root -p < insert_sample_users.sql
mysql -u root -p < insert_cameras.sql
mysql -u root -p < insert_mmts.sql

# 3. Configure email settings di auth.php dan check_otp.php
```

### Frontend Setup
```bash
# 1. Install dependencies
flutter pub get

# 2. Run aplikasi
flutter run

# 3. Build APK (optional)
flutter build apk --release
```

## 📖 Dokumentasi Lengkap

Lihat file dokumentasi berikut untuk detail lebih lanjut:
- [Quick Start Guide](QUICK_START_GUIDE.md) - Panduan cepat memulai
- [Backend Deployment](BACKEND_DEPLOYMENT_GUIDE.md) - Deploy backend
- [Email OTP Setup](GMAIL_SMTP_SETUP_COMPLETE.md) - Konfigurasi email
- [MMT Integration](MMT_INTEGRATION_COMPLETE.md) - Integrasi MMT
- [Monitoring Realtime](MONITORING_REALTIME_ACTIVE.md) - Fitur real-time

## 🔧 Fitur-fitur Teknis

### Real-time Monitoring
- Auto-refresh setiap 5 detik
- Hybrid monitoring (optimized polling)
- Status indicators dengan warna visual

### Device Status Management
- Tower Status Override untuk kontrol manual
- Automatic status detection
- Ping-based connectivity check

### Security Features
- OTP expiration (5 menit)
- Rate limiting untuk OTP request
- Resend OTP dengan cooldown timer
- Secure password hashing

## 🐛 Troubleshooting

Jika mengalami masalah, lihat:
- [Debug Guide](DEBUG_GUIDE.md)
- [OTP Troubleshooting](OTP_TROUBLESHOOTING.md)
- [Device Status Fix](DEVICE_STATUS_FIX.md)

## 👥 Use Cases

1. **Network Administrator**: Monitoring infrastruktur jaringan
2. **Security Team**: Pemantauan status CCTV
3. **IT Operations**: Real-time device availability tracking
4. **Facility Management**: Tower dan perangkat monitoring

## 📝 Catatan Penting

- ⚠️ Sistem ini **hanya dapat diakses melalui jaringan lokal**
- 🔒 Pastikan konfigurasi email SMTP sudah benar untuk fitur OTP
- 📡 Periksa konektivitas jaringan untuk ping functionality
- 💾 Backup database secara berkala

## 📄 License

Project ini dibuat untuk keperluan Kuliah Kerja Praktek (KP)

---
**Last Updated**: February 2026
