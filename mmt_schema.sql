-- ============================================
-- MMT (MINE MANAGEMENT TECHNOLOGY) SCHEMA
-- Database: monitoring_api
-- ============================================

USE monitoring_api;

-- Drop table if exists (uncomment for fresh install)
-- DROP TABLE IF EXISTS mmts;

-- Create MMT table
CREATE TABLE IF NOT EXISTS mmts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mmt_id VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique identifier for MMT device (e.g., MMT-CY1-01)',
    mmt_number INT DEFAULT NULL COMMENT 'Extracted number from mmt_id for sorting',
    location VARCHAR(255) NOT NULL COMMENT 'Physical location of MMT device',
    ip_address VARCHAR(15) NOT NULL COMMENT 'IP address of MMT device',
    status VARCHAR(20) DEFAULT 'UP' COMMENT 'Device status: UP, DOWN, Warning, Unknown',
    type VARCHAR(50) DEFAULT 'Mine Monitor' COMMENT 'Type of MMT device',
    container_yard VARCHAR(20) NOT NULL COMMENT 'Container yard: CY1, CY2, CY3, etc',
    device_count INT DEFAULT 0 COMMENT 'Number of connected devices',
    traffic VARCHAR(50) DEFAULT '0 Mbps' COMMENT 'Network traffic',
    uptime VARCHAR(10) DEFAULT '0%' COMMENT 'Uptime percentage',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_mmt_id (mmt_id),
    INDEX idx_mmt_number (mmt_number),
    INDEX idx_container_yard (container_yard),
    INDEX idx_status (status),
    INDEX idx_ip_address (ip_address),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Table for storing MMT (Mine Management Technology) device information';

-- ============================================
-- Verification Query
-- ============================================
-- SELECT * FROM mmts ORDER BY container_yard, mmt_number;
-- SELECT container_yard, COUNT(*) as total FROM mmts GROUP BY container_yard;
