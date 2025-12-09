-- Fix User Delete Error - Quick Fix Script
-- Run this in Supabase SQL Editor to fix the user delete issue

-- Step 1: Drop existing foreign key constraint if it doesn't have CASCADE
DO $$ 
BEGIN
    -- Check and drop the constraint if it exists without CASCADE
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'user_profiles_id_fkey'
        AND conrelid = 'user_profiles'::regclass
    ) THEN
        -- Check if it has CASCADE
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t ON c.conrelid = t.oid
            JOIN pg_namespace n ON t.relnamespace = n.oid
            WHERE c.conname = 'user_profiles_id_fkey'
            AND n.nspname = 'public'
            AND t.relname = 'user_profiles'
            AND EXISTS (
                SELECT 1
                FROM pg_constraint conf
                WHERE conf.conname = c.conname
                AND conf.confdeltype = 'c'  -- 'c' means CASCADE
            )
        ) THEN
            ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_id_fkey;
            RAISE NOTICE 'Dropped old constraint without CASCADE';
        ELSE
            RAISE NOTICE 'Constraint already has CASCADE, no change needed';
        END IF;
    END IF;
END $$;

-- Step 2: Recreate the foreign key with ON DELETE CASCADE
DO $$
BEGIN
    -- Only create if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'user_profiles_id_fkey'
        AND conrelid = 'user_profiles'::regclass
    ) THEN
        ALTER TABLE user_profiles 
        ADD CONSTRAINT user_profiles_id_fkey 
        FOREIGN KEY (id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE;
        
        RAISE NOTICE 'Created foreign key constraint with CASCADE';
    END IF;
END $$;

-- Step 3: Verify the constraint
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    rc.delete_rule,
    CASE 
        WHEN rc.delete_rule = 'CASCADE' THEN '✅ CASCADE is enabled'
        ELSE '❌ CASCADE is NOT enabled'
    END as status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'user_profiles'
  AND ccu.table_name = 'users';

-- Step 4: Test deletion (Optional - comment out if you don't want to test)
-- Uncomment the lines below to test with a specific user
/*
DO $$
DECLARE
    test_email TEXT := 'test@example.com';  -- Change this to a test user email
    test_user_id UUID;
BEGIN
    SELECT id INTO test_user_id FROM auth.users WHERE email = test_email;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing deletion of user: %', test_email;
        DELETE FROM auth.users WHERE id = test_user_id;
        RAISE NOTICE '✅ User deleted successfully!';
    ELSE
        RAISE NOTICE 'Test user not found: %', test_email;
    END IF;
END $$;
*/

