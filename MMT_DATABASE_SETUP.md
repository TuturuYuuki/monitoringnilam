# Panduan Setup Database MMT

## File-file yang Tersedia

1. **mmt_schema.sql** - Schema/struktur tabel MMT (sudah dijalankan ✓)
2. **mmt_data_template.sql** - Template data MMT yang bisa Anda customize
3. **insert_mmts.sql** - File lama dengan sample data

## Status Database

✅ **Tabel `mmts` sudah dibuat** dengan struktur:

| Field          | Type         | Keterangan                                    |
|----------------|--------------|-----------------------------------------------|
| id             | int(11)      | Primary key, auto increment                   |
| mmt_id         | varchar(50)  | ID unik MMT (contoh: MMT-CY1-01)             |
| mmt_number     | int(11)      | Nomor urut untuk sorting                      |
| location       | varchar(255) | Lokasi fisik perangkat                        |
| ip_address     | varchar(15)  | Alamat IP perangkat                           |
| status         | varchar(20)  | UP/DOWN/Warning/Unknown (default: UP)         |
| type           | varchar(50)  | Tipe perangkat (default: Mine Monitor)        |
| container_yard | varchar(20)  | CY1, CY2, CY3, dll                           |
| device_count   | int(11)      | Jumlah device terhubung (default: 0)          |
| traffic        | varchar(50)  | Network traffic (default: 0 Mbps)             |
| uptime         | varchar(10)  | Persentase uptime (default: 0%)               |
| created_at     | timestamp    | Waktu pembuatan record                        |
| updated_at     | timestamp    | Waktu update terakhir (auto update)           |

## Cara Memasukkan Data

### Opsi 1: Menggunakan File Template (RECOMMENDED)

1. Edit file **mmt_data_template.sql** sesuai data Anda
2. Jalankan command di terminal:

```powershell
# Masuk ke direktori project
cd "c:\Tuturu\File alvan\PENS\KP\monitoring"

# Import data ke database
& "C:\xampp\mysql\bin\mysql.exe" -u root monitoring_api < mmt_data_template.sql
```

### Opsi 2: Manual via phpMyAdmin

1. Buka http://localhost/phpmyadmin
2. Pilih database **monitoring_api**
3. Klik tabel **mmts**
4. Klik tab **Insert**
5. Isi data sesuai field yang tersedia

### Opsi 3: SQL Query Langsung

```sql
INSERT INTO mmts (mmt_id, mmt_number, location, ip_address, status, type, container_yard, device_count, traffic, uptime) VALUES
('MMT-CY1-01', 1, 'Container Yard 1 - Area A', '10.1.71.10', 'UP', 'Mine Monitor', 'CY1', 2, '150 Mbps', '99.5%'),
('MMT-CY1-02', 2, 'Container Yard 1 - Area B', '10.1.71.11', 'UP', 'Mine Monitor', 'CY1', 3, '175 Mbps', '98.8%');
-- dst...
```

## Format Data yang Benar

### mmt_id
- Format: `MMT-[CY]-[NOMOR]`
- Contoh: `MMT-CY1-01`, `MMT-CY2-05`, `MMT-CY3-10`
- Harus UNIQUE (tidak boleh duplikat)

### mmt_number
- Nomor urut untuk sorting (1, 2, 3, 4, dst)
- Digunakan untuk mengurutkan tampilan di aplikasi

### location
- Lokasi fisik perangkat
- Contoh: `Container Yard 1 - Area A`, `Gate Section - Tower 5`

### ip_address
- Format IP: `xxx.xxx.xxx.xxx`
- Contoh: `10.1.71.10`, `192.168.1.100`

### status
- Pilihan: `UP`, `DOWN`, `Warning`, `Unknown`
- Default: `UP`

### container_yard
- Format: `CY1`, `CY2`, `CY3`, `GATE`, dll
- Digunakan untuk filtering data per area

## Verifikasi Data

Setelah memasukkan data, cek dengan query:

```powershell
# Lihat semua data MMT
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT * FROM monitoring_api.mmts ORDER BY container_yard, mmt_number"

# Lihat jumlah MMT per container yard
& "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT container_yard, COUNT(*) as total, SUM(CASE WHEN status = 'UP' THEN 1 ELSE 0 END) as up_count FROM monitoring_api.mmts GROUP BY container_yard"
```

## Contoh Data Lengkap

File **mmt_data_template.sql** sudah berisi 9 contoh data:
- CY1: 3 MMT devices
- CY2: 3 MMT devices  
- CY3: 3 MMT devices

Anda bisa langsung menggunakan atau memodifikasinya sesuai kebutuhan.

## Troubleshooting

### Error: Duplicate entry
- Pastikan `mmt_id` unik (tidak ada yang sama)
- Jika ingin reset data, uncomment baris `DELETE FROM mmts;` di file SQL

### Error: Unknown column
- Pastikan schema sudah dibuat dengan menjalankan `mmt_schema.sql` terlebih dahulu

### Data tidak muncul di aplikasi
- Pastikan nama `container_yard` sesuai (CY1, CY2, CY3)
- Cek status harus diisi (UP/DOWN/Warning/Unknown)
- Restart Apache jika diperlukan

## Next Steps

Setelah data dimasukkan:
1. Data akan otomatis muncul di aplikasi Flutter
2. API endpoint untuk MMT sudah tersedia di `mmt.php`
3. Aplikasi akan auto-refresh setiap 10 detik

---
Dibuat: 4 Februari 2026
