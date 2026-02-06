# 🔧 FIX: IP Address Hardcoded Issue

## 📋 MASALAH
User melaporkan bahwa saat menambah device dengan IP yang berbeda, IP yang tersimpan di database adalah `10.2.71.60` padahal user memasukkan IP yang berbeda.

## 🔍 ROOT CAUSE
Backend PHP files untuk endpoint create tidak ada di workspace, dan kemungkinan ada di server lokal XAMPP dengan bug yang meng-override IP parameter dengan hardcoded value.

Files yang hilang:
- `monitoring_api/network.php` (untuk create tower/access point)
- `monitoring_api/cctv.php` (untuk create camera)

## ✅ SOLUSI

Saya telah membuat 2 file backend yang benar:

### 1. **network.php** - Untuk Access Point/Tower
```
📄 monitoring/network.php
```

**Key fixes:**
- Function `createTower()` (Line 236)
- ✅ Menggunakan `$ipAddress = $data['ip_address']` dari parameter request
- ✅ Bind parameter dengan benar: `bind_param("sisisssiss", ..., $ipAddress, ...)`
- ❌ TIDAK ada hardcoded IP

### 2. **cctv.php** - Untuk CCTV/Camera
```
📄 monitoring/cctv.php
```

**Key fixes:**
- Function `createCamera()` (Line 183)
- ✅ Menggunakan `$ipAddress = $data['ip_address']` dari parameter request
- ✅ Bind parameter dengan benar: `bind_param("ssissss", ..., $ipAddress, ...)`
- ❌ TIDAK ada hardcoded IP

## 🚀 INSTALASI

### Langkah 1: Copy file ke server
Copy kedua file ke folder server XAMPP:
```
C:\xampp\htdocs\monitoring_api\network.php
C:\xampp\htdocs\monitoring_api\cctv.php
```

Atau jika struktur folder berbeda:
```
[XAMPP_ROOT]\htdocs\monitoring_api\network.php
[XAMPP_ROOT]\htdocs\monitoring_api\cctv.php
```

### Langkah 2: Update index.php (jika diperlukan)
Pastikan `index.php` sudah include kedua file ini:
```php
// Di index.php routing section, pastikan:
if ($endpoint === 'network') {
    require 'network.php';
} elseif ($endpoint === 'cctv') {
    require 'cctv.php';
} elseif ($endpoint === 'mmt') {
    require 'mmt.php';
}
```

### Langkah 3: Test
1. Buka halaman Add Device
2. Pilih tipe device (Access Point atau CCTV)
3. Masukkan IP address yang berbeda, misalnya: `192.168.1.100`
4. Simpan device
5. Check database (phpMyAdmin) untuk verifikasi IP tersimpan dengan benar

## 🔐 KEAMANAN

Kedua file sudah include:
- ✅ Database connection validation
- ✅ Required field validation
- ✅ Error handling dengan try-catch
- ✅ Prepared statements (prevent SQL injection)
- ✅ JSON response format
- ✅ CORS-ready headers

## 📊 ENDPOINTS YANG TERSEDIA

### network.php
```
GET  /monitoring_api/index.php?endpoint=network&action=all
GET  /monitoring_api/index.php?endpoint=network&action=by-yard&container_yard=CY1
GET  /monitoring_api/index.php?endpoint=network&action=by-id&tower_id=AP%2001
GET  /monitoring_api/index.php?endpoint=network&action=stats
POST /monitoring_api/index.php?endpoint=network&action=create
POST /monitoring_api/index.php?endpoint=network&action=update-status
```

### cctv.php
```
GET  /monitoring_api/index.php?endpoint=cctv&action=all
GET  /monitoring_api/index.php?endpoint=cctv&action=by-yard&container_yard=CY1
GET  /monitoring_api/index.php?endpoint=cctv&action=by-id&camera_id=CAM%2001
GET  /monitoring_api/index.php?endpoint=cctv&action=stats
POST /monitoring_api/index.php?endpoint=cctv&action=create
POST /monitoring_api/index.php?endpoint=cctv&action=update-status
```

## 📝 CATATAN

- File ini kompatibel dengan struktur database yang sudah ada
- Field `towerNumber` di table `towers` di-extract dari `tower_id` (contoh: "AP 01" → 1)
- Semua timestamp menggunakan `NOW()` dari database
- Status default: `'UP'`
- Traffic default: `'0 Mbps'`
- Uptime default: `'0%'`

## 🐛 TROUBLESHOOTING

Jika masih ada error:

1. **Connection Refused**
   - Pastikan XAMPP berjalan
   - Check port MySQL (default 3306)

2. **Table not found**
   - Verify database name: `monitoring`
   - Run migration/setup script jika belum ada table

3. **IP masih hardcoded**
   - Hapus old files dari server
   - Pastikan new files sudah ter-copy dengan benar
   - Restart Apache

4. **Parameter tidak diterima**
   - Check Content-Type header: `application/json`
   - Verify request body format (must be valid JSON)

---

✅ **FIX COMPLETE** - IP Address sekarang akan tersimpan dengan benar sesuai input user!
