-- Query untuk melihat semua kamera Parking dan Gate
-- Jalankan di phpMyAdmin untuk memastikan data ada

-- 1. Cek semua kamera dengan area_type atau location yang berisi 'parking' atau 'lot'
SELECT 
    camera_id, 
    location, 
    area_type, 
    container_yard,
    status,
    ip_address
FROM cameras 
WHERE 
    LOWER(area_type) LIKE '%lot%' 
    OR LOWER(area_type) LIKE '%parking%'
    OR LOWER(location) LIKE '%parking%'
ORDER BY camera_id;

-- 2. Cek semua kamera dengan area_type atau location yang berisi 'gate' atau 'entrance'
SELECT 
    camera_id, 
    location, 
    area_type, 
    container_yard,
    status,
    ip_address
FROM cameras 
WHERE 
    LOWER(area_type) LIKE '%entrance%' 
    OR LOWER(area_type) LIKE '%gate%'
    OR LOWER(location) LIKE '%gate%'
ORDER BY camera_id;

-- 3. Jika data masih kosong, update beberapa kamera untuk testing:
-- UPDATE cameras SET area_type = 'Lot', location = 'Parking Area' WHERE camera_id LIKE 'CAM 52%';
-- UPDATE cameras SET area_type = 'Lot', location = 'Parking Area' WHERE camera_id LIKE 'CAM 53%';
-- UPDATE cameras SET area_type = 'Lot', location = 'Parking Area' WHERE camera_id LIKE 'CAM 54%';

-- UPDATE cameras SET area_type = 'Entrance', location = 'Gate Area' WHERE camera_id LIKE 'CAM 55%';
-- UPDATE cameras SET area_type = 'Entrance', location = 'Gate Area' WHERE camera_id LIKE 'CAM 56%';

-- 4. Cek semua kamera untuk melihat struktur data lengkap
SELECT * FROM cameras ORDER BY camera_id;
