-- ============================================
-- ADD IP ADDRESS COLUMN TO MMT TABLE (If not exists)
-- Database: monitoring_api
-- ============================================

USE monitoring_api;

-- Check if column exists first
-- If the column already exists, this will show an error, you can ignore it
-- Or run this query first to check:
-- SHOW COLUMNS FROM mmts LIKE 'ip_address';

-- Add ip_address column if it doesn't exist
ALTER TABLE mmts 
ADD COLUMN IF NOT EXISTS ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' 
COMMENT 'IP address of MMT device'
AFTER location;

-- Add index for ip_address if it doesn't exist
ALTER TABLE mmts 
ADD INDEX IF NOT EXISTS idx_ip_address (ip_address);

-- Update existing rows with a default IP if needed
-- UPDATE mmts SET ip_address = '192.168.1.1' WHERE ip_address = '0.0.0.0';

-- Verify the changes
SELECT * FROM mmts LIMIT 5;

-- Show table structure
DESCRIBE mmts;

-- ============================================
-- NOTES:
-- 1. Kolom ip_address sudah ada di schema asli (mmt_schema.sql)
-- 2. File ini hanya untuk memastikan kolom ada jika database di-setup manual
-- 3. Jika error "Duplicate column name", berarti kolom sudah ada (OK)
-- ============================================
