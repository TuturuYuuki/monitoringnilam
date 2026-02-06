-- ==========================================
-- Create Users Table for Authentication
-- Database: monitoring_api
-- ==========================================

USE monitoring_api;

-- Drop table if exists (uncomment for fresh install)
-- DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    fullname VARCHAR(100) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    location VARCHAR(100) DEFAULT NULL,
    division VARCHAR(100) DEFAULT NULL,
    role VARCHAR(20) DEFAULT 'user',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Table for storing user authentication and profile information';

-- ==========================================
-- Insert Sample Users (Optional)
-- Username: admin / Password: admin123
-- Username: user / Password: user123
-- ==========================================

-- Hash password for 'admin123': $2y$10$Y9IXYZG61d4EZY4Kx8FRwO0Zfv6e1PV9Z5MyZqN8KZx.1d8ZZG6xK
-- Hash password for 'user123': $2y$10$K8wZx1Y9dN5Vq2Ep3Cm4AOf7Pv8R9U2T4WvZq6N3Ls1K5V8Xy9Aa

-- INSERT INTO users (username, email, password, fullname, role) VALUES
-- ('admin', 'admin@example.com', '$2y$10$Y9IXYZG61d4EZY4Kx8FRwO0Zfv6e1PV9Z5MyZqN8KZx.1d8ZZG6xK', 'Administrator', 'admin'),
-- ('user', 'user@example.com', '$2y$10$K8wZx1Y9dN5Vq2Ep3Cm4AOf7Pv8R9U2T4WvZq6N3Ls1K5V8Xy9Aa', 'Regular User', 'user');

-- ==========================================
-- Verification Query
-- ==========================================
-- SELECT * FROM users;
-- SELECT COUNT(*) as total_users FROM users;
