# 🔍 INVESTIGASI SINGKAT: IP Hardcoded Issue

## 📍 TEMUAN UTAMA

### ✅ **FRONTEND - OK**
File: [lib/services/api_service.dart](lib/services/api_service.dart)

Semua 3 function mengirim IP dengan benar:
- `createTower()` (Line 835) → `ip_address: ipAddress` ✅
- `createCamera()` (Line 874) → `ip_address: ipAddress` ✅  
- `createMMT()` (Line 914) → `ip_address: ipAddress` ✅

---

### ✅ **BACKEND MMT - OK**
File: [mmt.php](mmt.php)

Function `createMMT()` (Lines 293-370):
```php
$ipAddress = $data['ip_address'];  // ✅ Benar
$stmt->bind_param("...", ..., $ipAddress, ...);  // ✅ Digunakan
```

---

### ⚠️ **BACKEND NETWORK & CCTV - MISSING**

**File yang tidak ditemukan di workspace**:
- `network.php` (untuk `endpoint=network&action=create`)
- `cctv.php` (untuk `endpoint=cctv&action=create`)

**Lokasi kemungkinan** (ada di server lokal, bukan di workspace):
```
C:\xampp\htdocs\monitoring_api\network.php
C:\xampp\htdocs\monitoring_api\cctv.php
```

---

### 🔴 **HARDCODED IP DITEMUKAN** 
File: [lib/services/api_service.dart](lib/services/api_service.dart)

Lines 954-982:
```dart
String targetIp = '10.2.71.60'  // ⚠️ HARDCODED
```

**TAPI**: Ini hanya untuk `testDeviceConnectivity()` dan `reportDeviceStatus()`, **BUKAN untuk create device**.

---

## 🎯 ROOT CAUSE

### **Skenario 1: PALING MUNGKIN** ⚠️

File `network.php` dan `cctv.php` **ada di server lokal** dengan bug:
- Tidak menggunakan `$data['ip_address']` dari request
- Menggunakan hardcoded IP atau default value
- Ada salah ketik di parameter

---

### **Skenario 2: Database**

Tabel `towers` atau `cameras` **tidak memiliki kolom `ip_address`**.

Verifikasi:
```sql
SHOW COLUMNS FROM towers;  -- Cek ada kolom ip_address?
SHOW COLUMNS FROM cameras;  -- Cek ada kolom ip_address?
```

---

## ✅ CHECKLIST FIX

### Untuk Backend Developer:

1. **Cari file** `network.php` dan `cctv.php`:
   - Di `C:\xampp\htdocs\monitoring_api\`
   - Atau lokasi server yang sedang digunakan

2. **Jika file ditemukan, verifikasi**:
   ```php
   // ✅ HARUS ada baris seperti ini:
   $ipAddress = $data['ip_address'];
   
   // ❌ JANGAN ada baris seperti ini:
   $ipAddress = '10.2.71.60';  // HARDCODED
   $ipAddress = $_GET['ip'] ?? '10.2.71.60';  // Default salah
   ```

3. **Jika file tidak ada, buat** menggunakan template di file `BUG_REPORT_HARDCODED_IP.md`

4. **Verifikasi database**:
   ```sql
   ALTER TABLE towers ADD COLUMN ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' AFTER location;
   ALTER TABLE cameras ADD COLUMN ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' AFTER location;
   ```

5. **Test**:
   ```bash
   curl -X POST http://localhost/monitoring_api/network.php?endpoint=network&action=create \
     -H "Content-Type: application/json" \
     -d '{"tower_id":"TEST","location":"Test","ip_address":"192.168.1.50","container_yard":"CY1"}'
   ```
   
   **Expected**: Response harus include `"ip_address":"192.168.1.50"` ✅

---

## 📊 RINGKASAN

| Komponen | Status | Detail |
|----------|--------|--------|
| Frontend send IP | ✅ OK | Semua 3 function kirim IP benar |
| Backend MMT | ✅ OK | Terima & simpan IP benar |
| Backend Network | ⚠️ UNKNOWN | File tidak ada di workspace |
| Backend CCTV | ⚠️ UNKNOWN | File tidak ada di workspace |
| Database Tower | ❓ UNKNOWN | Perlu verifikasi kolom ip_address |
| Database Camera | ❓ UNKNOWN | Perlu verifikasi kolom ip_address |

---

**Lihat file lengkap**: [BUG_REPORT_HARDCODED_IP.md](BUG_REPORT_HARDCODED_IP.md)
