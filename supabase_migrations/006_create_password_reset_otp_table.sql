-- Migration 006: Create Password Reset OTP Table
-- This table stores OTP codes for password reset

CREATE TABLE IF NOT EXISTS password_reset_otp (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Index for faster lookups
  CONSTRAINT unique_active_otp UNIQUE(email, otp_code)
);

-- Create index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_email ON password_reset_otp(email);
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_expires ON password_reset_otp(expires_at);

-- Function to automatically clean up expired OTPs (runs daily)
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
  DELETE FROM password_reset_otp
  WHERE expires_at < NOW() OR used = true;
END;
$$ LANGUAGE plpgsql;

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (6, 'Create password reset OTP table')
ON CONFLICT (version) DO NOTHING;


