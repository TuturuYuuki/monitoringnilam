-- ============================================================
-- UPDATE DEVICE NAMING FORMAT TO NEW STANDARD
-- ============================================================
-- Access Point: AP-CY1-01 → AP 01
-- CCTV: Cam-CY1-01 → CAM 01
-- MMT: MMT-CY1-01 → MMT 01
-- ============================================================

USE monitoring_api;

-- ============================================================
-- CEK DATA EXISTING DULU (JALANKAN INI PERTAMA)
-- ============================================================

-- Cek Access Points dengan format lama:
SELECT tower_id, location, container_yard FROM towers WHERE tower_id LIKE '%-%' ORDER BY tower_id;

-- Cek CCTVs dengan format lama:
SELECT camera_id, location, container_yard FROM cameras WHERE camera_id LIKE '%-%' ORDER BY camera_id;

-- Cek MMTs dengan format lama:
SELECT mmt_id, location, container_yard FROM mmts WHERE mmt_id LIKE '%-%' ORDER BY mmt_id;

-- ============================================================
-- UPDATE TOWERS (ACCESS POINTS)
-- ============================================================
-- Contoh update manual (sesuaikan dengan data yang ada):

UPDATE towers SET tower_id = 'AP 01' WHERE tower_id = 'AP-CY1-01';
UPDATE towers SET tower_id = 'AP 02' WHERE tower_id = 'AP-CY2-01';
UPDATE towers SET tower_id = 'AP 03' WHERE tower_id = 'AP-CY1-02';
UPDATE towers SET tower_id = 'AP 04' WHERE tower_id = 'AP-CY2-02';
UPDATE towers SET tower_id = 'AP 05' WHERE tower_id = 'AP-CY3-01';

-- ============================================================
-- UPDATE CAMERAS (CCTV)
-- ============================================================
-- Contoh update manual (sesuaikan dengan data yang ada):

UPDATE cameras SET camera_id = 'CAM 01' WHERE camera_id = 'Cam-CY1-01';
UPDATE cameras SET camera_id = 'CAM 02' WHERE camera_id = 'Cam-CY2-01';
UPDATE cameras SET camera_id = 'CAM 03' WHERE camera_id = 'Cam-CY3-01';
UPDATE cameras SET camera_id = 'CAM 04' WHERE camera_id = 'CCTV-Gate-01';
UPDATE cameras SET camera_id = 'CAM 05' WHERE camera_id = 'CCTV-Parking-01';

-- ============================================================
-- UPDATE MMTS
-- ============================================================
-- Contoh update manual (sesuaikan dengan data yang ada):

UPDATE mmts SET mmt_id = 'MMT 01' WHERE mmt_id = 'MMT-CY1-01';
UPDATE mmts SET mmt_id = 'MMT 02' WHERE mmt_id = 'MMT-CY2-01';
UPDATE mmts SET mmt_id = 'MMT 03' WHERE mmt_id = 'MMT-CY3-01';
UPDATE mmts SET mmt_id = 'MMT 04' WHERE mmt_id = 'MMT-CY1-02';
UPDATE mmts SET mmt_id = 'MMT 05' WHERE mmt_id = 'MMT-CY2-02';

-- ============================================================
-- VERIFIKASI HASIL UPDATE
-- ============================================================
-- Jalankan query ini setelah update untuk memastikan berhasil:

SELECT tower_id, location, container_yard FROM towers ORDER BY tower_id;
SELECT camera_id, location, container_yard FROM cameras ORDER BY camera_id;
SELECT mmt_id, location, container_yard FROM mmts ORDER BY mmt_id;

-- ============================================================
-- CARA PENGGUNAAN DI phpMyAdmin
-- ============================================================
-- 1. Buka phpMyAdmin: http://localhost/phpmyadmin
-- 2. Pilih database "monitoring_api"
-- 3. Klik tab "SQL"
-- 4. Copy paste query SELECT pertama untuk CEK data
-- 5. Sesuaikan query UPDATE dengan data yang muncul
-- 6. Copy paste dan jalankan query UPDATE
-- 7. Jalankan query VERIFIKASI untuk cek hasil
-- ============================================================
