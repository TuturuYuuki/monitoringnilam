# 🚨 CRITICAL FIX: IP HARDCODED & ANOMALI ICON

## 🔴 MASALAH UTAMA

### 1. IP masih tersimpan sebagai 10.2.71.60
Backend files yang baru belum di-update di server XAMPP

### 2. Icon anomali di Tower 1
Ada device yang tidak seharusnya ada atau duplikat

---

## ✅ SOLUSI LENGKAP

### STEP 1: Backup Database
```bash
# Di phpMyAdmin, export database 'monitoring' sebelum lanjut
```

### STEP 2: Update Backend Files di Server

**PENTING: Harus copy ke server lokal XAMPP!**

```bash
# Copy files ke:
C:\xampp\htdocs\monitoring_api\

Files yang harus di-copy:
✅ index.php (FILE BARU - PENTING!)
✅ network.php
✅ cctv.php
✅ mmt.php (sudah ada)
```

**Jika folder monitoring_api tidak ada, buat:**
```bash
C:\xampp\htdocs\monitoring_api\
```

### STEP 3: Verify File Content

**CRITICAL: Di network.php line ~225, HARUS TIDAK ada hardcoded IP:**

```php
// ✅ BENAR:
$ipAddress = $data['ip_address'];  // Ambil dari request

// ❌ SALAH:
$ipAddress = '10.2.71.60';  // HARDCODED
```

**Jika ada HARDCODED, berarti file di server adalah OLD version!**

### STEP 4: Update index.php Routing

Check `C:\xampp\htdocs\monitoring_api\index.php` harus include:

```php
case 'network':
    require 'network.php';
    break;
    
case 'cctv':
    require 'cctv.php';
    break;
```

**Jika tidak ada → DELETE index.php di server dan copy yang baru!**

### STEP 5: Clear Cache & Restart

```bash
1. Stop XAMPP Apache
2. Wait 5 seconds
3. Start XAMPP Apache
4. Clear browser cache (Ctrl+Shift+Delete)
5. Rebuild Flutter: flutter clean && flutter pub get
```

### STEP 6: Test IP dengan API Direct

Buka terminal dan test:

```bash
curl -X POST http://localhost/monitoring_api/index.php?endpoint=network&action=create \
  -H "Content-Type: application/json" \
  -d '{
    "tower_id": "AP TEST99",
    "location": "Test Location",
    "ip_address": "123.45.67.89",
    "container_yard": "CY1"
  }'
```

**Output harus menunjukkan:**
```json
{
  "success": true,
  "data": {
    "ip_address": "123.45.67.89"   ← HARUS SAMA!
  }
}
```

Jika masih 10.2.71.60 → FILE DI SERVER MASIH OLD!

---

## 🗑️ HAPUS ICON ANOMALI

### Option A: Via Flutter UI
1. Buka Dashboard
2. Tap icon anomali di Tower 1
3. Dialog muncul
4. Ada tombol "Delete" (jika sudah saya implement)

### Option B: Via Database (phpMyAdmin)

Jika tidak ada tombol delete, hapus manual:

1. Buka phpMyAdmin
2. Database: `monitoring`
3. Table: Carilah yang tepat (towers, cameras, atau mmts)
4. Cari record dengan:
   - Location atau tower_id yang aneh
   - IP: 10.2.71.60
   - Status: DOWN terus
5. Click "Delete"

---

## 📋 CHECKLIST

- [ ] Copy index.php ke `C:\xampp\htdocs\monitoring_api\`
- [ ] Copy network.php ke `C:\xampp\htdocs\monitoring_api\`
- [ ] Copy cctv.php ke `C:\xampp\htdocs\monitoring_api\`
- [ ] Verify file content (cek tidak ada hardcoded IP)
- [ ] Restart XAMPP Apache
- [ ] Test dengan curl command
- [ ] Clear browser cache
- [ ] Rebuild Flutter app
- [ ] Hapus icon anomali di Tower 1
- [ ] Test add device dengan IP baru

---

## 🔧 EMERGENCY FIX (Jika file di server sudah corrupted)

Jika file di server sudah terlalu banyak edit dan tidak bisa diperbaiki:

### Delete OLD files:
```bash
DEL C:\xampp\htdocs\monitoring_api\network.php
DEL C:\xampp\htdocs\monitoring_api\cctv.php
DEL C:\xampp\htdocs\monitoring_api\index.php
```

### Copy NEW files from workspace:
```bash
COPY monitoring\index.php C:\xampp\htdocs\monitoring_api\
COPY monitoring\network.php C:\xampp\htdocs\monitoring_api\
COPY monitoring\cctv.php C:\xampp\htdocs\monitoring_api\
```

### Restart Apache dan test

---

## 🎯 EXPECTED RESULT SETELAH FIX

✅ IP tersimpan dengan benar (bukan 10.2.71.60)
✅ Icon anomali hilang
✅ Add device berfungsi normal
✅ Tap icon bisa buka dialog

---

## 💾 DATABASE QUERIES

Jika perlu manual delete anomali (via SQL):

```sql
-- Cari anomali di towers
SELECT * FROM towers WHERE ip_address = '10.2.71.60' OR location LIKE '%Tower 1%' LIMIT 5;

-- Delete anomali (HATI-HATI!)
DELETE FROM towers WHERE id = [ID_DARI_SELECT_ATAS];

-- Sama untuk cameras:
SELECT * FROM cameras WHERE ip_address = '10.2.71.60';
DELETE FROM cameras WHERE id = [ID_DARI_SELECT_ATAS];
```

---

✅ **READY TO FIX**
