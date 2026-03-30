-- Check if user_profiles exist for auth users
-- Run this in Supabase SQL Editor to see which users are missing profiles

SELECT 
    au.id,
    au.email,
    up.full_name,
    up.username,
    CASE 
        WHEN up.id IS NULL THEN 'Missing Profile ❌'
        WHEN up.full_name IS NULL AND up.username IS NULL THEN 'Profile exists but no name ⚠️'
        ELSE 'Has Profile ✅'
    END as status
FROM 
    auth.users au
LEFT JOIN 
    user_profiles up ON up.id = au.id
ORDER BY 
    au.created_at DESC;

-- If profiles are missing, create them automatically:
-- This will create profiles for any auth users that don't have one

INSERT INTO user_profiles (id, username, full_name, created_at, updated_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'username', SPLIT_PART(au.email, '@', 1)) as username,
    au.raw_user_meta_data->>'full_name' as full_name,
    NOW(),
    NOW()
FROM 
    auth.users au
LEFT JOIN 
    user_profiles up ON up.id = au.id
WHERE 
    up.id IS NULL;

-- Verify the profiles were created
SELECT COUNT(*) as profile_count FROM user_profiles;
