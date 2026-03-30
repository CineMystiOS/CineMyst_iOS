-- ============================================
-- CineMyst - Update Profiles Table Schema
-- ============================================
-- This script updates the profiles table to match the new Instagram-style architecture
-- with 19 fields (18 + email for username login support)
--
-- Run this in your Supabase SQL Editor
-- ============================================

-- Add email column if it doesn't exist (needed for username → email login resolution)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;

-- Add all new columns if they don't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS website_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS connection_count INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing constraints
ALTER TABLE profiles ADD CONSTRAINT check_role CHECK (role IN ('artist', 'casting_professional')) ON CONFLICT DO NOTHING;
ALTER TABLE profiles ADD CONSTRAINT check_postal_code CHECK (postal_code ~ '^\d{6}$') ON CONFLICT DO NOTHING;

-- Create or update indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(LOWER(username));
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding_completed ON profiles(onboarding_completed);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active_at ON profiles(last_active_at DESC);

-- ============================================
-- Final Schema Verification
-- ============================================
-- Run this query to verify the new schema:
/*
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
*/

-- Expected columns (19 total):
-- 1. id - UUID PRIMARY KEY
-- 2. username - TEXT UNIQUE NOT NULL
-- 3. email - TEXT UNIQUE (NEW - for login)
-- 4. full_name - TEXT
-- 5. date_of_birth - DATE
-- 6. profile_picture_url - TEXT
-- 7. avatar_url - TEXT (NEW)
-- 8. role - VARCHAR(50) - artist or casting_professional
-- 9. employment_status - TEXT
-- 10. location_state - TEXT
-- 11. postal_code - VARCHAR(6)
-- 12. location_city - TEXT
-- 13. bio - TEXT (NEW)
-- 14. phone_number - TEXT (NEW)
-- 15. website_url - TEXT (NEW)
-- 16. is_verified - BOOLEAN DEFAULT FALSE (NEW)
-- 17. connection_count - INTEGER DEFAULT 0 (NEW)
-- 18. onboarding_completed - BOOLEAN DEFAULT FALSE (NEW)
-- 19. last_active_at - TIMESTAMPTZ (NEW)
-- 20. created_at - TIMESTAMPTZ
-- 21. updated_at - TIMESTAMPTZ

-- ============================================
-- Verification Query
-- ============================================
SELECT COUNT(*) as total_columns FROM information_schema.columns 
WHERE table_name = 'profiles';

-- Should return: 21 (including created_at and updated_at)
