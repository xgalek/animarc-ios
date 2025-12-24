-- Update existing users with default portal attempts
-- Run this SQL script to set default values for existing users who don't have portal_attempts set

UPDATE user_progress 
SET 
    portal_attempts = COALESCE(portal_attempts, 50),
    last_attempt_reset = COALESCE(last_attempt_reset, CURRENT_DATE)
WHERE 
    portal_attempts IS NULL 
    OR last_attempt_reset IS NULL;

