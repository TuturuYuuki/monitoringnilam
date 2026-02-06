-- Script untuk mengubah format tower_id dari T-CYx-xx ke AP-CYx-xx
-- Backup data terlebih dahulu sebelum menjalankan script ini!

-- Update Container Yard 1 (CY1)
UPDATE towers SET tower_id = 'AP-CY1-01' WHERE tower_id = 'T-CY1-07';
UPDATE towers SET tower_id = 'AP-CY1-02' WHERE tower_id = 'T-CY1-08';
UPDATE towers SET tower_id = 'AP-CY1-03' WHERE tower_id = 'T-CY1-09';
UPDATE towers SET tower_id = 'AP-CY1-04' WHERE tower_id = 'T-CY1-10';
UPDATE towers SET tower_id = 'AP-CY1-05' WHERE tower_id = 'T-CY1-11';
UPDATE towers SET tower_id = 'AP-CY1-06' WHERE tower_id = 'T-CY1-12A';
UPDATE towers SET tower_id = 'AP-CY1-07' WHERE tower_id = 'T-CY1-12';
UPDATE towers SET tower_id = 'AP-CY1-08' WHERE tower_id = 'T-CY1-13';
UPDATE towers SET tower_id = 'AP-CY1-09' WHERE tower_id = 'T-CY1-14';
UPDATE towers SET tower_id = 'AP-CY1-10' WHERE tower_id = 'T-CY1-15';

-- Update Container Yard 2 (CY2)
UPDATE towers SET tower_id = 'AP-CY2-01' WHERE tower_id = 'T-CY2-01';
UPDATE towers SET tower_id = 'AP-CY2-02' WHERE tower_id = 'T-CY2-02';
UPDATE towers SET tower_id = 'AP-CY2-03' WHERE tower_id = 'T-CY2-03';
UPDATE towers SET tower_id = 'AP-CY2-04' WHERE tower_id = 'T-CY2-04';
UPDATE towers SET tower_id = 'AP-CY2-05' WHERE tower_id = 'T-CY2-05';
UPDATE towers SET tower_id = 'AP-CY2-06' WHERE tower_id = 'T-CY2-06';

-- Update Container Yard 3 (CY3)
UPDATE towers SET tower_id = 'AP-CY3-01' WHERE tower_id = 'T-CY3-16';
UPDATE towers SET tower_id = 'AP-CY3-02' WHERE tower_id = 'T-CY3-17';
UPDATE towers SET tower_id = 'AP-CY3-03' WHERE tower_id = 'T-CY3-19';
UPDATE towers SET tower_id = 'AP-CY3-04' WHERE tower_id = 'T-CY3-20';
UPDATE towers SET tower_id = 'AP-CY3-05' WHERE tower_id = 'T-CY3-21';

-- Verifikasi hasil update
SELECT tower_id, location, container_yard, tower_number 
FROM towers 
ORDER BY container_yard, tower_number;
