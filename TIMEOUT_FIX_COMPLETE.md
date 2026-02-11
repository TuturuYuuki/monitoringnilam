# 🔧 Fix Timeout Issue - Change Password

## ✅ Perubahan yang Sudah Dilakukan

### 1. **Timeout Diperbesar: 8 detik → 30 detik**
   - **File**: `lib/services/api_service.dart` (line 228)
   - **Alasan**: Backend terbukti cepat (94ms), tapi timeout 8 detik mungkin terlalu pendek untuk koneksi Flutter → PHP
   - **Hasil**: Lebih banyak waktu untuk koneksi berhasil

### 2. **Logging Ultra-Detail**
   - **File**: `lib/services/api_service.dart` (method changePassword)
   - **Ditambahkan**:
     - ✅ Timestamp request start
     - ✅ Full URL yang dipanggil
     - ✅ Response time dalam milliseconds
     - ✅ Detail setiap status code (200, 401, 404, 408)
     - ✅ Exception dengan stack trace
     - ✅ Visual indicators (✓, ✗, ⚠️)

### 3. **Test Connection Feature**
   - **Files**: `lib/services/api_service.dart` + `lib/change_password.dart`
   - **Fitur Baru**: Button **"Test Koneksi Backend"** di halaman Change Password
   - **Fungsi**: Cek apakah Flutter bisa koneksi ke backend sebelum ganti password

---

## 🚀 Cara Menggunakan

### **Langkah 1: Hot Restart Flutter (PENTING!)**

Aplikasi harus di-restart untuk load kode baru:

```bash
# Di terminal Flutter, tekan:
R  (huruf R besar - full restart)

# ATAU restart lengkap:
# Ctrl+C untuk stop
flutter run
```

⚠️ **BUKAN** `r` (huruf kecil) - itu hanya hot reload yang tidak cukup!

### **Langkah 2: Test Koneksi Dulu**

1. Buka halaman **Change Password**
2. Klik button **"Test Koneksi Backend"** (berwarna biru)
3. Lihat hasil:
   - ✅ **Koneksi Berhasil** → Backend bisa diakses, lanjut ganti password
   - ❌ **Koneksi Gagal** → Ada masalah koneksi, baca solusinya

### **Langkah 3: Ganti Password dengan Log**

1. Isi form change password
2. Klik **"Ubah Password"**
3. **Lihat console log** (sangat penting untuk debugging!)

---

## 📊 Contoh Log Sukses

```
=== Change Password Request START ===
Timestamp: 2026-02-11T10:15:30.123Z
User ID: 6
Base URL: http://localhost/monitoring_api/index.php
Full URL: http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password
About to send HTTP POST request...
✓ HTTP Request completed in 95ms
Change Password Response Status: 200
✓ SUCCESS - Parsed result: {success: true, message: Password berhasil diubah}
=== Change Password Request END (SUCCESS) ===
```

---

## ❌ Diagnosa Masalah Timeout

### **Jika Masih Timeout (30 detik):**

#### **1. Backend Tidak Running**
```
❌❌❌ Connection test FAILED ❌❌❌
Error: SocketException: Connection refused
```

**Solusi**: Cek XAMPP:
```powershell
# Cek Apache running
netstat -an | findstr ":80"

# Harusnya muncul:
# TCP    0.0.0.0:80    LISTENING
```

#### **2. Firewall Memblokir**
```
❌ TIMEOUT after 30 seconds
Cannot reach backend - timeout
```

**Solusi**:
- Matikan sementara Windows Firewall
- Atau tambahkan exception untuk Flutter/Chrome

#### **3. URL Salah**
```
Error: Failed host lookup: 'localhost'
```

**Solusi**: Ganti `localhost` → `127.0.0.1` di `api_service.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1/monitoring_api/index.php';
```

#### **4. Flutter Web Cache**
Jika running di browser:
```bash
# Hard refresh browser
Ctrl + Shift + R  # Chrome/Edge
Ctrl + F5         # Alternative

# ATAU hapus build cache:
flutter clean
flutter run
```

---

## 🧪 Test Backend Terpisah

Pastikan backend bekerja dengan script PHP:

```powershell
# Test dari PowerShell
powershell -ExecutionPolicy Bypass -File "test_backend_timeout.ps1"

# Expected output:
# Status Code: 200 ✓
# Response Time: 94.47 ms ✓ FAST
# Response Body: {"success":true,"message":"Password berhasil diubah"}
```

---

## 📈 Statistik Performance

### Backend (sudah teruji):
- ✅ Response time: **94ms** (sangat cepat)
- ✅ Timeout threshold: **30,000ms** (30 detik)
- ✅ Margin: **99.7%** (backend 318x lebih cepat dari timeout)

### Kesimpulan:
**Backend BUKAN masalah**. Jika masih timeout, masalahnya ada di:
1. Flutter tidak bisa koneksi ke localhost (network issue)
2. Flutter masih pakai kode lama (butuh hot restart)
3. Browser cache (perlu hard refresh)

---

## 🔍 Debug Checklist

Cek satu per satu:

- [ ] XAMPP Apache running (`netstat -an | findstr ":80"`)
- [ ] Backend test berhasil (`test_backend_timeout.ps1`)
- [ ] Flutter di-**hot restart** (R besar, bukan r kecil)
- [ ] Browser di-**hard refresh** (Ctrl+Shift+R jika web)
- [ ] **Test Koneksi Backend** button berhasil (✅ hijau)
- [ ] Console log muncul saat ganti password
- [ ] Tidak ada firewall yang memblokir

---

## 📝 Error Message Baru

### **Timeout Message (30 detik)**
```
Request timeout setelah 30 detik. Backend mungkin tidak dapat diakses dari Flutter.
```

**Artinya**: 
- Flutter sudah tunggu 30 detik tapi tidak dapat response
- Backend kemungkinan tidak bisa dihubungi
- **BUKAN** masalah backend lambat (backend cuma 94ms)

### **Solusi Step-by-step:**

1. **Klik "Test Koneksi Backend"** → Jika gagal, backend unreachable
2. **Cek XAMPP** → Pastikan Apache hijau
3. **Hot Restart Flutter** → Tekan R (besar)
4. **Coba lagi** → Seharusnya <1 detik (bukan 30 detik)

---

## ✨ Fitur Baru: Test Koneksi

### **Kapan Menggunakan:**
- Sebelum ganti password pertama kali
- Setelah restart XAMPP
- Jika timeout terus terjadi
- Untuk verifikasi setup

### **Informasi yang Didapat:**
```
✅ Koneksi Berhasil
Backend reachable
Waktu respons: 125ms
```

**ATAU**

```
❌ Koneksi Gagal
Cannot connect: SocketException: Connection refused

Kemungkinan masalah:
• Backend tidak running (cek XAMPP Apache)
• Firewall memblokir koneksi
• URL salah (localhost vs 127.0.0.1)
```

---

## 🎯 Expected Behavior Setelah Fix

### **Normal Flow (Sukses):**
1. Klik "Ubah Password"
2. Loading ~100-200ms (sangat cepat!)
3. Dialog sukses hijau: "Password berhasil diubah"

### **Console Log:**
```
=== Change Password Request START ===
About to send HTTP POST request...
✓ HTTP Request completed in 94ms
✓ SUCCESS - Parsed result: {success: true, ...}
=== Change Password Request END (SUCCESS) ===
```

### **Jika Masih Lambat/Timeout:**
→ **Masalahnya bukan backend**
→ **Gunakan "Test Koneksi Backend" untuk diagnosa**

---

## 📞 Troubleshooting Quick Reference

| Error | Solusi |
|-------|--------|
| Timeout 30 detik | Test Koneksi Backend → Cek XAMPP → Hot Restart |
| Connection refused | XAMPP Apache tidak running |
| Failed host lookup | Ganti localhost → 127.0.0.1 |
| No console log | Hot restart Flutter dengan R (besar) |
| Button "Test Koneksi" tidak ada | Hot restart atau hard refresh browser |

---

## ✅ Verification

Jika fix berhasil, harusnya:
1. ✅ Console log sangat detail muncul
2. ✅ Response time <500ms (bukan 30 detik)
3. ✅ Button "Test Koneksi Backend" tersedia
4. ✅ Test koneksi berhasil dengan hijau
5. ✅ Ganti password cepat (<1 detik)

**Jika masih timeout setelah semua ini → Share screenshot console log lengkap!**
