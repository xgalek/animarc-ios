-- Portal Raid System Migration
-- Run this SQL script in your Supabase SQL editor

-- Create portal_bosses table
CREATE TABLE IF NOT EXISTS portal_bosses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  rank TEXT NOT NULL,
  image_name TEXT NOT NULL,
  specialization TEXT NOT NULL,
  stat_health INT NOT NULL,
  stat_attack INT NOT NULL,
  stat_defense INT NOT NULL,
  stat_speed INT NOT NULL,
  max_hp INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_portal_bosses_rank ON portal_bosses(rank);

-- Create portal_progress table
CREATE TABLE IF NOT EXISTS portal_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  portal_boss_id UUID REFERENCES portal_bosses(id) ON DELETE CASCADE,
  current_damage INT DEFAULT 0,
  max_hp INT NOT NULL,
  progress_percent DECIMAL(5,2) DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, portal_boss_id)
);

CREATE INDEX IF NOT EXISTS idx_portal_progress_user_id ON portal_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_portal_progress_user_completed ON portal_progress(user_id, completed);

-- Add portal attempts columns to user_progress
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_progress' AND column_name = 'portal_attempts'
  ) THEN
    ALTER TABLE user_progress 
      ADD COLUMN portal_attempts INT DEFAULT 50,
      ADD COLUMN last_attempt_reset TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

