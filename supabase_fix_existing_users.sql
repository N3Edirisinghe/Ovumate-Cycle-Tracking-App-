-- Fix for existing users: Create user_profiles for users who signed up before the trigger was added
-- Run this in Supabase SQL Editor if you have existing users without profiles

-- Create user profiles for all existing auth.users who don't have a profile yet
INSERT INTO public.user_profiles (id, email, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  au.created_at,
  NOW()
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Verify: Check how many users now have profiles
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM public.user_profiles) as users_with_profiles;

