-- ============================================================
-- CLEANUP SCRIPT: Remove Anomali Devices (IP 10.2.71.60)
-- ============================================================
-- 
-- HATI-HATI: Jalankan di phpMyAdmin atau MySQL client
-- BACKUP DATABASE TERLEBIH DAHULU SEBELUM JALANKAN!
--

-- ==================== STEP 1: Lihat anomali devices ====================

-- Cari di towers
SELECT 'TOWERS' as source, id, tower_id, location, ip_address, created_at FROM towers 
WHERE ip_address = '10.2.71.60' 
ORDER BY created_at DESC;

-- Cari di cameras  
SELECT 'CAMERAS' as source, id, camera_id, location, ip_address, created_at FROM cameras 
WHERE ip_address = '10.2.71.60'
ORDER BY created_at DESC;

-- Cari di mmt
SELECT 'MMT' as source, id, mmt_id, location, ip_address, created_at FROM mmts 
WHERE ip_address = '10.2.71.60'
ORDER BY created_at DESC;

-- ==================== STEP 2: Backup sebelum delete ====================

-- Cek berapa banyak yang akan didelete
SELECT COUNT(*) as total_anomali_towers FROM towers WHERE ip_address = '10.2.71.60';
SELECT COUNT(*) as total_anomali_cameras FROM cameras WHERE ip_address = '10.2.71.60';
SELECT COUNT(*) as total_anomali_mmts FROM mmts WHERE ip_address = '10.2.71.60';

-- ==================== STEP 3: DELETE ANOMALI (RUN JIKA SUDAH YAKIN) ====================

-- DELETE dari towers
DELETE FROM towers WHERE ip_address = '10.2.71.60';

-- DELETE dari cameras
DELETE FROM cameras WHERE ip_address = '10.2.71.60';

-- DELETE dari mmts
DELETE FROM mmts WHERE ip_address = '10.2.71.60';

-- ==================== STEP 4: Verify deletion ====================

-- Pastikan anomali sudah hilang
SELECT COUNT(*) as remaining_anomali_towers FROM towers WHERE ip_address = '10.2.71.60';
SELECT COUNT(*) as remaining_anomali_cameras FROM cameras WHERE ip_address = '10.2.71.60';
SELECT COUNT(*) as remaining_anomali_mmts FROM mmts WHERE ip_address = '10.2.71.60';

-- Lihat devices yang tersisa
SELECT * FROM towers ORDER BY created_at DESC LIMIT 10;
SELECT * FROM cameras ORDER BY created_at DESC LIMIT 10;
SELECT * FROM mmts ORDER BY created_at DESC LIMIT 10;

-- ==================== ALTERNATIVE: Delete spesifik Tower 1 anomali ====================

-- Jika anomali hanya di Tower 1:
DELETE FROM towers 
WHERE location LIKE '%Tower 1%' 
  AND ip_address = '10.2.71.60'
  AND tower_id NOT LIKE 'AP%';  -- Jangan hapus yang sudah di-format benar

DELETE FROM cameras 
WHERE location LIKE '%Tower 1%' 
  AND ip_address = '10.2.71.60';

-- ==================== STEP 5: Verify Tower 1 tetap ada ====================

-- Pastikan Tower 1 yang benar masih ada
SELECT * FROM towers WHERE location LIKE '%Tower 1%' OR tower_id = 'Tower 1';
