-- Add purpose column to otp_tokens table for forgot password feature
-- Purpose: 'signup' for user registration, 'reset_password' for password reset

USE monitoring_api;

-- Add purpose column if not exists
ALTER TABLE otp_tokens 
ADD COLUMN IF NOT EXISTS purpose VARCHAR(50) DEFAULT 'signup'
COMMENT 'Purpose of OTP: signup or reset_password';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_otp_purpose ON otp_tokens(purpose);

-- Update existing records to have 'signup' purpose
UPDATE otp_tokens SET purpose = 'signup' WHERE purpose IS NULL;

-- Show table structure
DESCRIBE otp_tokens;
