-- ============================================
-- MMT DATA TEMPLATE
-- Database: monitoring_api
-- Silakan edit data di bawah sesuai kebutuhan
-- ============================================

USE monitoring_api;

-- Hapus data lama (optional - uncomment jika ingin reset data)
-- DELETE FROM mmts;

-- ============================================
-- INSERT DATA MMT
-- Format: (mmt_id, mmt_number, location, ip_address, status, type, container_yard, device_count, traffic, uptime)
-- ============================================

INSERT INTO mmts (mmt_id, mmt_number, location, ip_address, status, type, container_yard, device_count, traffic, uptime) VALUES

-- ============================================
-- Container Yard 1 (CY1) - MMT Devices
-- ============================================
('MMT-CY1-01', 1, 'Container Yard 1 - Area A', '10.1.71.10', 'UP', 'Mine Monitor', 'CY1', 2, '150 Mbps', '99.5%'),
('MMT-CY1-02', 2, 'Container Yard 1 - Area B', '10.1.71.11', 'UP', 'Mine Monitor', 'CY1', 3, '175 Mbps', '98.8%'),
('MMT-CY1-03', 3, 'Container Yard 1 - Area C', '10.1.71.12', 'UP', 'Mine Monitor', 'CY1', 2, '160 Mbps', '99.2%'),

-- ============================================
-- Container Yard 2 (CY2) - MMT Devices
-- ============================================
('MMT-CY2-01', 1, 'Container Yard 2 - Area A', '10.2.71.10', 'UP', 'Mine Monitor', 'CY2', 2, '180 Mbps', '99.0%'),
('MMT-CY2-02', 2, 'Container Yard 2 - Area B', '10.2.71.11', 'UP', 'Mine Monitor', 'CY2', 3, '165 Mbps', '98.5%'),
('MMT-CY2-03', 3, 'Container Yard 2 - Area C', '10.2.71.12', 'UP', 'Mine Monitor', 'CY2', 2, '170 Mbps', '99.3%'),

-- ============================================
-- Container Yard 3 (CY3) - MMT Devices
-- ============================================
('MMT-CY3-01', 1, 'Container Yard 3 - Area A', '10.3.71.10', 'UP', 'Mine Monitor', 'CY3', 2, '155 Mbps', '99.1%'),
('MMT-CY3-02', 2, 'Container Yard 3 - Area B', '10.3.71.11', 'UP', 'Mine Monitor', 'CY3', 3, '185 Mbps', '98.9%'),
('MMT-CY3-03', 3, 'Container Yard 3 - Area C', '10.3.71.12', 'UP', 'Mine Monitor', 'CY3', 2, '162 Mbps', '99.4%');

-- ============================================
-- CATATAN PENGGUNAAN:
-- ============================================
-- 1. mmt_id: Format MMT-[CY]-[NOMOR] (contoh: MMT-CY1-01)
-- 2. mmt_number: Nomor urut untuk sorting (1, 2, 3, dst)
-- 3. location: Lokasi fisik perangkat MMT
-- 4. ip_address: Alamat IP perangkat (format: xxx.xxx.xxx.xxx)
-- 5. status: UP, DOWN, Warning, atau Unknown
-- 6. type: Tipe perangkat (default: Mine Monitor)
-- 7. container_yard: CY1, CY2, CY3, dst
-- 8. device_count: Jumlah perangkat yang terhubung
-- 9. traffic: Traffic jaringan (contoh: 150 Mbps)
-- 10. uptime: Persentase uptime (contoh: 99.5%)

-- ============================================
-- VERIFIKASI DATA
-- ============================================
-- SELECT * FROM mmts ORDER BY container_yard, mmt_number;
-- SELECT container_yard, COUNT(*) as total, 
--        SUM(CASE WHEN status = 'UP' THEN 1 ELSE 0 END) as up_count,
--        SUM(CASE WHEN status = 'DOWN' THEN 1 ELSE 0 END) as down_count
-- FROM mmts GROUP BY container_yard;
