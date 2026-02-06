# Quick Reference - Database MMT

## ✅ Status Setup

**Database Table:** `mmts` ✓ Sudah dibuat
**Sample Data:** 9 MMT devices ✓ Sudah dimasukkan

## 📊 Data Summary

| Container Yard | Total MMT | Status UP | Status DOWN |
|----------------|-----------|-----------|-------------|
| CY1            | 3         | 3         | 0           |
| CY2            | 3         | 3         | 0           |
| CY3            | 3         | 3         | 0           |
| **TOTAL**      | **9**     | **9**     | **0**       |

## 📁 File-file Penting

1. **mmt_schema.sql** - Schema tabel (sudah dijalankan)
2. **mmt_data_template.sql** - Template untuk insert data (EDIT FILE INI!)
3. **MMT_DATABASE_SETUP.md** - Panduan lengkap

## 🚀 Cara Menambah/Edit Data MMT

### 1. Edit File Template
Buka file: `mmt_data_template.sql`

### 2. Tambah Data Baru
```sql
INSERT INTO mmts (mmt_id, mmt_number, location, ip_address, status, type, container_yard, device_count, traffic, uptime) VALUES
('MMT-CY1-04', 4, 'Container Yard 1 - Area D', '10.1.71.13', 'UP', 'Mine Monitor', 'CY1', 2, '155 Mbps', '99.0%');
```

### 3. Jalankan via Terminal
```powershell
Get-Content "c:\Tuturu\File alvan\PENS\KP\monitoring\mmt_data_template.sql" | & "C:\xampp\mysql\bin\mysql.exe" -u root monitoring_api
```

## 🔍 Query Berguna

### Lihat Semua Data MMT
```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT * FROM monitoring_api.mmts"
```

### Lihat Data per Container Yard
```powershell
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT * FROM monitoring_api.mmts WHERE container_yard = 'CY1'"
```

### Update Status MMT
```sql
UPDATE mmts SET status = 'DOWN' WHERE mmt_id = 'MMT-CY1-01';
```

### Hapus Data MMT
```sql
DELETE FROM mmts WHERE mmt_id = 'MMT-CY1-01';
```

### Hapus Semua Data (Reset)
```sql
DELETE FROM mmts;
```

## 📝 Format Data

| Field          | Contoh              | Keterangan                    |
|----------------|---------------------|-------------------------------|
| mmt_id         | MMT-CY1-01          | Harus UNIQUE                  |
| mmt_number     | 1                   | Untuk sorting                 |
| location       | Container Yard 1    | Lokasi fisik                  |
| ip_address     | 10.1.71.10          | Format IP                     |
| status         | UP                  | UP/DOWN/Warning/Unknown       |
| type           | Mine Monitor        | Tipe perangkat                |
| container_yard | CY1                 | CY1/CY2/CY3/GATE              |
| device_count   | 2                   | Jumlah device terhubung       |
| traffic        | 150 Mbps            | Network traffic               |
| uptime         | 99.5%               | Persentase uptime             |

## ⚠️ Catatan Penting

1. **mmt_id** harus UNIQUE (tidak boleh sama)
2. **mmt_number** digunakan untuk sorting di aplikasi
3. **container_yard** harus sesuai: CY1, CY2, CY3
4. Data akan langsung muncul di aplikasi Flutter setelah dimasukkan
5. Tidak perlu restart Apache setelah insert data

## 🎯 Next Steps

Setelah data dimasukkan, data akan otomatis muncul di aplikasi pada halaman MMT monitoring.

---
File ini berisi contoh 9 MMT devices (3 per container yard).
Silakan edit sesuai kebutuhan Anda!
