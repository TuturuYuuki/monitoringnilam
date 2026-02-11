-- FIX CORRUPTED IP ADDRESSES
-- Restore unique IPs for each device

-- Fix Towers: Assign unique IPs based on tower number and container yard
UPDATE towers SET ip_address = CONCAT('10.', 
    CASE 
        WHEN container_yard = 'CY1' THEN '1'
        WHEN container_yard = 'CY2' THEN '2'
        WHEN container_yard = 'CY3' THEN '3'
        ELSE '2'
    END,
    '.71.',
    10 + (CAST(SUBSTRING(tower_id, 4) AS UNSIGNED) % 90)
)
WHERE ip_address = '10.2.71.60' OR ip_address = '' OR ip_address IS NULL;

-- Fix Cameras: Assign unique IPs based on camera number and location
UPDATE cameras SET ip_address = CONCAT('10.',
    CASE 
        WHEN location LIKE '%Yard 1%' THEN '1'
        WHEN location LIKE '%Yard 2%' THEN '2'
        WHEN location LIKE '%Yard 3%' THEN '3'
        WHEN location LIKE '%Gate%' THEN '1'
        WHEN location LIKE '%Parking%' THEN '1'
        ELSE '2'
    END,
    '.71.',
    20 + (CAST(SUBSTRING(camera_id, 5) AS UNSIGNED) % 80)
)
WHERE ip_address = '10.2.71.60' OR ip_address = '' OR ip_address IS NULL;

-- MMTs already have correct IPs (10.1.71.10-12, 10.2.71.10-12, 10.3.71.10-12)
-- No change needed for MMTs

-- Verify results
SELECT 'TOWERS' as type, COUNT(DISTINCT ip_address) as unique_ips, COUNT(*) as total_devices FROM towers
UNION
SELECT 'CAMERAS', COUNT(DISTINCT ip_address), COUNT(*) FROM cameras
UNION
SELECT 'MMTS', COUNT(DISTINCT ip_address), COUNT(*) FROM mmts;
