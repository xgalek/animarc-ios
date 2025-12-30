-- Fix the last_attempt_reset column type
-- DATE type causes decoding issues with Swift - change to TIMESTAMPTZ

-- First, drop the existing columns if they exist (safe approach)
ALTER TABLE user_progress 
  DROP COLUMN IF EXISTS portal_attempts,
  DROP COLUMN IF EXISTS last_attempt_reset;

-- Re-add with correct types
ALTER TABLE user_progress 
  ADD COLUMN portal_attempts INT DEFAULT 50,
  ADD COLUMN last_attempt_reset TIMESTAMPTZ DEFAULT NOW();

-- Update any existing rows to have default values
UPDATE user_progress 
SET 
  portal_attempts = 50,
  last_attempt_reset = NOW()
WHERE portal_attempts IS NULL;




