# 🔍 DEBUG GUIDE - IP Hardcoded & Icon Tap Issue

## 📋 MASALAH YANG DILAPORKAN

1. **IP masih hardcoded ke 10.2.71.60** - Meski sudah dibuat file backend baru
2. **Icon added device tidak bisa di-tap** - Tidak responsif terhadap klik

---

## 🔧 STEP-BY-STEP DEBUG

### MASALAH 1: IP HARDCODED

#### A. Check Console Log di Flutter
Saat menambah device:

1. Buka DevTools (press `F5` atau `flutter run` di terminal)
2. Buka Console tab
3. Cari output seperti ini:
```
=== DEBUG: Saving Device ===
Device Type: Access Point
Device ID: AP 01
IP Address from input: 192.168.1.100
Location: Tower 1 - CY2
Container Yard: CY2
DEBUG: Calling createTower with IP: 192.168.1.100
DEBUG: createTower response: {...}
```

**Jika IP di Console benar (192.168.1.100) tapi database salah (10.2.71.60):**
→ Masalah ada di BACKEND (network.php/cctv.php)

#### B. Check Network.php di Server

Mari saya verifikasi file:

```bash
# Di server lokal, check file:
C:\xampp\htdocs\monitoring_api\network.php

# Cari baris yang create tower (line ~236)
# Harus ada:
$ipAddress = $data['ip_address'];  // ✅ BENAR
$stmt->bind_param("sisisssiss", $towerId, $towerNumber, $location, $ipAddress, ...);
```

❌ JANGAN ada:
```php
$ipAddress = '10.2.71.60';  // ❌ SALAH - Hardcoded
```

#### C. Jika File Backend Sudah Benar

Kemungkinan adalah old file masih di cache atau tidak ter-update. Lakukan:

```bash
1. Stop XAMPP Apache
2. Delete old network.php dan cctv.php dari C:\xampp\htdocs\monitoring_api\
3. Copy file baru dari workspace:
   - monitoring/network.php → C:\xampp\htdocs\monitoring_api\network.php
   - monitoring/cctv.php → C:\xampp\htdocs\monitoring_api\cctv.php
4. Restart XAMPP Apache
5. Clear browser cache (Ctrl+Shift+Delete)
6. Test ulang
```

#### D. Check index.php Routing

Pastikan `index.php` di monitoring_api folder include files baru:

```php
// Di index.php, harus ada:
if ($endpoint === 'network') {
    require 'network.php';
    exit;
} elseif ($endpoint === 'cctv') {
    require 'cctv.php';
    exit;
} elseif ($endpoint === 'mmt') {
    require 'mmt.php';
    exit;
}
```

Jika tidak ada → TAMBAHKAN ke index.php

#### E. Direct API Test

Buka Postman atau curl dan test langsung:

```bash
# Test CREATE TOWER dengan IP custom
curl -X POST http://localhost/monitoring_api/index.php?endpoint=network&action=create \
  -H "Content-Type: application/json" \
  -d '{
    "tower_id": "AP TEST",
    "location": "Test Location",
    "ip_address": "192.168.99.99",
    "container_yard": "CY1"
  }'

# Lihat response - jika ip_address di response adalah 192.168.99.99 → API benar
# Jika response masih 10.2.71.60 → ada hardcoded di backend
```

---

### MASALAH 2: ICON TIDAK BISA DI-TAP

#### A. Check Console Log saat Tap Icon

Saat tap icon:
1. Buka Flutter DevTools Console
2. Tap icon added device di map
3. Cari log:
```
DEBUG: Tapped added device at -7.209459, 112.724717
```

**Jika log muncul:**
✅ Icon responsif - Masalah di dialog yang tidak muncul

**Jika log TIDAK muncul:**
❌ Icon tidak bisa di-tap - Masalah di GestureDetector

#### B. Jika Icon Tidak Responsif

Ini bisa terjadi karena flutter_map tidak pass through events. Solusi:

```dart
// Sudah ditambahkan: behavior: HitTestBehavior.opaque
// Ini membuat GestureDetector lebih "greedily" menangkap tap events
```

Jika masih tidak work, coba wrap dengan Material:

```dart
child: Material(
  color: Colors.transparent,
  child: GestureDetector(
    onTap: () => print('Tapped!'),
    behavior: HitTestBehavior.opaque,
    child: ... icon ...
  ),
)
```

#### C. Check Dialog Muncul

Jika tap responsif tapi dialog tidak muncul:

1. Check Console untuk error
2. Verifikasi data dalam addedDevices list tidak kosong
3. Test dengan print statement:

```dart
void _showDevicesAtLocation(BuildContext context, double latitude, double longitude) {
  final devicesAtLocation = addedDevices
      .where((d) => d.latitude == latitude && d.longitude == longitude)
      .toList();
  
  print('DEBUG: Devices at location: ${devicesAtLocation.length}');
  for (var d in devicesAtLocation) {
    print('  - ${d.name} (${d.ipAddress})');
  }
  
  if (devicesAtLocation.isEmpty) {
    print('WARNING: No devices found at this location!');
    return;
  }
  // ... rest of code
}
```

---

## 🚀 QUICK FIX CHECKLIST

- [ ] Verify network.php line ~225: `$ipAddress = $data['ip_address'];`
- [ ] Verify cctv.php line ~225: `$ipAddress = $data['ip_address'];`
- [ ] Check index.php includes network.php dan cctv.php dengan `require`
- [ ] Restart XAMPP Apache setelah update files
- [ ] Clear browser cache
- [ ] Rebuild Flutter app: `flutter clean && flutter pub get && flutter run`
- [ ] Check Flutter Console for "DEBUG:" logs
- [ ] Test with direct API call (Postman/curl)

---

## 📊 EXPECTED BEHAVIOR

**Sebelum fix:**
- Console log: IP = 192.168.1.100 ✅
- Database: IP = 10.2.71.60 ❌
- Tap icon: tidak responsif ❌

**Setelah fix:**
- Console log: IP = 192.168.1.100 ✅
- Database: IP = 192.168.1.100 ✅
- Tap icon: dialog muncul ✅

---

## 📞 JIKA MASIH ERROR

Jika sudah follow semua step tapi masih error, berikan info:

1. **Console log output** saat add device
2. **Response dari direct API test** (lihat di Postman)
3. **Database value** (check phpMyAdmin)
4. **network.php content** (line 225)
5. **Flutter error message** (jika ada)

---

✅ **READY FOR TESTING**
