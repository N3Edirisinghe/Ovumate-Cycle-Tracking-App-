-- Auto-Run All Migrations Script
-- Run this script to automatically apply ALL pending migrations
-- It will check current version and run only missing migrations

DO $$
DECLARE
    current_version INTEGER;
    migration_count INTEGER;
    i INTEGER;
    migration_sql TEXT;
BEGIN
    -- Create migration tracking table if it doesn't exist
    CREATE TABLE IF NOT EXISTS public.schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
        description TEXT
    );

    -- Get current migration version
    SELECT COALESCE(MAX(version), 0) INTO current_version
    FROM public.schema_migrations;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Auto-Migration Runner';
    RAISE NOTICE 'Current version: %', current_version;
    RAISE NOTICE '========================================';

    -- Migration 001: Initial Schema
    IF current_version < 1 THEN
        RAISE NOTICE 'Applying Migration 001: Initial Schema...';
        
        -- Create custom types for enums (with exception handling)
        BEGIN
            CREATE TYPE cycle_phase AS ENUM ('menstrual', 'follicular', 'ovulation', 'luteal', 'unknown');
        EXCEPTION WHEN duplicate_object THEN NULL; END;

        BEGIN
            CREATE TYPE symptom_severity AS ENUM ('none', 'mild', 'moderate', 'severe');
        EXCEPTION WHEN duplicate_object THEN NULL; END;

        BEGIN
            CREATE TYPE article_category AS ENUM ('menstrualHealth', 'fertility', 'nutrition', 'exercise', 'mentalHealth', 'lifestyle', 'medical', 'general', 'relationships', 'medicalConditions');
        EXCEPTION WHEN duplicate_object THEN NULL; END;

        BEGIN
            CREATE TYPE article_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
        EXCEPTION WHEN duplicate_object THEN NULL; END;

        INSERT INTO public.schema_migrations (version, description)
        VALUES (1, 'Initial schema setup')
        ON CONFLICT (version) DO NOTHING;
        
        current_version := 1;
        RAISE NOTICE '✅ Migration 001 completed!';
    END IF;

    -- Migration 002: Create Tables
    IF current_version < 2 THEN
        RAISE NOTICE 'Applying Migration 002: Create Tables...';
        
        -- User Profiles table
        CREATE TABLE IF NOT EXISTS user_profiles (
            id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            first_name TEXT,
            last_name TEXT,
            date_of_birth DATE,
            phone_number TEXT,
            profile_image_url TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            average_cycle_length INTEGER DEFAULT 28,
            average_period_length INTEGER DEFAULT 5,
            average_luteal_phase INTEGER DEFAULT 14,
            last_period_start DATE,
            notifications_enabled BOOLEAN DEFAULT true,
            partner_sharing_enabled BOOLEAN DEFAULT false,
            partner_id UUID REFERENCES user_profiles(id),
            data_sharing_enabled BOOLEAN DEFAULT false,
            analytics_enabled BOOLEAN DEFAULT true,
            marketing_emails_enabled BOOLEAN DEFAULT false,
            wellness_goals TEXT[] DEFAULT '{}',
            health_conditions TEXT[] DEFAULT '{}',
            medications TEXT[] DEFAULT '{}',
            lifestyle_tracking_enabled BOOLEAN DEFAULT true
        );

        -- Cycle Entries table
        CREATE TABLE IF NOT EXISTS cycle_entries (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
            date DATE NOT NULL,
            phase cycle_phase DEFAULT 'unknown',
            is_period_day BOOLEAN DEFAULT false,
            period_flow INTEGER CHECK (period_flow >= 1 AND period_flow <= 5),
            symptoms TEXT[] DEFAULT '{}',
            symptom_severity JSONB DEFAULT '{}',
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            sleep_hours INTEGER CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
            water_intake INTEGER CHECK (water_intake >= 0),
            stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
            mood TEXT,
            activities TEXT[] DEFAULT '{}',
            took_medication BOOLEAN DEFAULT false,
            medication_notes TEXT,
            UNIQUE(user_id, date)
        );

        -- Wellness Articles table
        CREATE TABLE IF NOT EXISTS wellness_articles (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT NOT NULL,
            content TEXT NOT NULL,
            author TEXT NOT NULL,
            category article_category NOT NULL,
            difficulty article_difficulty DEFAULT 'beginner',
            read_time INTEGER NOT NULL,
            image_url TEXT,
            tags TEXT[] DEFAULT '{}',
            is_premium BOOLEAN DEFAULT false,
            is_featured BOOLEAN DEFAULT false,
            is_new BOOLEAN DEFAULT false,
            rating DECIMAL(2,1) DEFAULT 0.0 CHECK (rating >= 0.0 AND rating <= 5.0),
            views_count INTEGER DEFAULT 0,
            likes_count INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
        );

        -- Chat Messages table
        CREATE TABLE IF NOT EXISTS chat_messages (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
            content TEXT NOT NULL,
            is_user_message BOOLEAN NOT NULL,
            timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            message_type TEXT DEFAULT 'text',
            metadata JSONB DEFAULT '{}'
        );

        -- Article Ratings table
        CREATE TABLE IF NOT EXISTS article_ratings (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
            article_id UUID REFERENCES wellness_articles(id) ON DELETE CASCADE NOT NULL,
            rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            UNIQUE(user_id, article_id)
        );

        -- User Article Progress table
        CREATE TABLE IF NOT EXISTS user_article_progress (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
            article_id UUID REFERENCES wellness_articles(id) ON DELETE CASCADE NOT NULL,
            is_read BOOLEAN DEFAULT false,
            is_bookmarked BOOLEAN DEFAULT false,
            read_progress DECIMAL(3,2) DEFAULT 0.0 CHECK (read_progress >= 0.0 AND read_progress <= 1.0),
            last_read_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
            UNIQUE(user_id, article_id)
        );

        INSERT INTO public.schema_migrations (version, description)
        VALUES (2, 'Create all tables')
        ON CONFLICT (version) DO NOTHING;
        
        current_version := 2;
        RAISE NOTICE '✅ Migration 002 completed!';
    END IF;

    -- Migration 003: RLS Policies
    IF current_version < 3 THEN
        RAISE NOTICE 'Applying Migration 003: Setup RLS and Policies...';
        
        -- Enable RLS
        ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
        ALTER TABLE cycle_entries ENABLE ROW LEVEL SECURITY;
        ALTER TABLE wellness_articles ENABLE ROW LEVEL SECURITY;
        ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
        ALTER TABLE article_ratings ENABLE ROW LEVEL SECURITY;
        ALTER TABLE user_article_progress ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies
        DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
        DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
        DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
        DROP POLICY IF EXISTS "Users can view their own cycle entries" ON cycle_entries;
        DROP POLICY IF EXISTS "Users can insert their own cycle entries" ON cycle_entries;
        DROP POLICY IF EXISTS "Users can update their own cycle entries" ON cycle_entries;
        DROP POLICY IF EXISTS "Users can delete their own cycle entries" ON cycle_entries;
        DROP POLICY IF EXISTS "Anyone can view wellness articles" ON wellness_articles;
        DROP POLICY IF EXISTS "Users can view their own chat messages" ON chat_messages;
        DROP POLICY IF EXISTS "Users can insert their own chat messages" ON chat_messages;
        DROP POLICY IF EXISTS "Users can view their own article ratings" ON article_ratings;
        DROP POLICY IF EXISTS "Users can insert their own article ratings" ON article_ratings;
        DROP POLICY IF EXISTS "Users can update their own article ratings" ON article_ratings;
        DROP POLICY IF EXISTS "Users can view their own article progress" ON user_article_progress;
        DROP POLICY IF EXISTS "Users can insert their own article progress" ON user_article_progress;
        DROP POLICY IF EXISTS "Users can update their own article progress" ON user_article_progress;

        -- Create policies
        CREATE POLICY "Users can view their own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
        CREATE POLICY "Users can update their own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
        CREATE POLICY "Users can insert their own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
        CREATE POLICY "Users can view their own cycle entries" ON cycle_entries FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own cycle entries" ON cycle_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own cycle entries" ON cycle_entries FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete their own cycle entries" ON cycle_entries FOR DELETE USING (auth.uid() = user_id);
        CREATE POLICY "Anyone can view wellness articles" ON wellness_articles FOR SELECT USING (true);
        CREATE POLICY "Users can view their own chat messages" ON chat_messages FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own chat messages" ON chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can view their own article ratings" ON article_ratings FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own article ratings" ON article_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own article ratings" ON article_ratings FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can view their own article progress" ON user_article_progress FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own article progress" ON user_article_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own article progress" ON user_article_progress FOR UPDATE USING (auth.uid() = user_id);

        INSERT INTO public.schema_migrations (version, description)
        VALUES (3, 'Setup RLS and policies')
        ON CONFLICT (version) DO NOTHING;
        
        current_version := 3;
        RAISE NOTICE '✅ Migration 003 completed!';
    END IF;

    -- Migration 004: Auto Profile Trigger
    IF current_version < 4 THEN
        RAISE NOTICE 'Applying Migration 004: Auto Profile Trigger...';
        
        -- Function to auto-create user profile (using different delimiter)
        EXECUTE '
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER AS $func$
        BEGIN
            INSERT INTO public.user_profiles (id, email, first_name, last_name, created_at, updated_at)
            VALUES (
                NEW.id,
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>''first_name'', NEW.raw_app_meta_data->>''first_name'', NULL),
                COALESCE(NEW.raw_user_meta_data->>''last_name'', NEW.raw_app_meta_data->>''last_name'', NULL),
                NOW(),
                NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                first_name = COALESCE(user_profiles.first_name, EXCLUDED.first_name),
                last_name = COALESCE(user_profiles.last_name, EXCLUDED.last_name),
                updated_at = NOW();
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;';

        -- Trigger
        DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

        -- Updated_at triggers (using different delimiter)
        EXECUTE '
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $func$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $func$ language ''plpgsql'';';

        DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
        DROP TRIGGER IF EXISTS update_cycle_entries_updated_at ON cycle_entries;
        DROP TRIGGER IF EXISTS update_wellness_articles_updated_at ON wellness_articles;
        DROP TRIGGER IF EXISTS update_user_article_progress_updated_at ON user_article_progress;

        CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        CREATE TRIGGER update_cycle_entries_updated_at BEFORE UPDATE ON cycle_entries
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        CREATE TRIGGER update_wellness_articles_updated_at BEFORE UPDATE ON wellness_articles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        CREATE TRIGGER update_user_article_progress_updated_at BEFORE UPDATE ON user_article_progress
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        INSERT INTO public.schema_migrations (version, description)
        VALUES (4, 'Auto-create user profiles and triggers')
        ON CONFLICT (version) DO NOTHING;
        
        current_version := 4;
        RAISE NOTICE '✅ Migration 004 completed!';
    END IF;

    -- Migration 005: Indexes and Sample Data
    IF current_version < 5 THEN
        RAISE NOTICE 'Applying Migration 005: Indexes and Sample Data...';
        
        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_cycle_entries_user_date ON cycle_entries(user_id, date);
        CREATE INDEX IF NOT EXISTS idx_cycle_entries_date ON cycle_entries(date);
        CREATE INDEX IF NOT EXISTS idx_wellness_articles_category ON wellness_articles(category);
        CREATE INDEX IF NOT EXISTS idx_wellness_articles_featured ON wellness_articles(is_featured);
        CREATE INDEX IF NOT EXISTS idx_chat_messages_user_timestamp ON chat_messages(user_id, timestamp);
        CREATE INDEX IF NOT EXISTS idx_article_ratings_article ON article_ratings(article_id);

        -- Sample data
        INSERT INTO wellness_articles (title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags) 
        SELECT * FROM (VALUES
            ('Understanding Your Menstrual Cycle', 'A comprehensive guide to understanding the phases of your menstrual cycle', 'Your menstrual cycle is more than just your period. It consists of four main phases: menstrual, follicular, ovulation, and luteal. Understanding these phases can help you better track your health and predict your cycle.', 'Dr. Sarah Johnson', 'menstrualHealth'::article_category, 'beginner'::article_difficulty, 5, true, true, 4.8, ARRAY['cycle', 'education', 'health']),
            ('Nutrition for Cycle Health', 'How proper nutrition can support your menstrual health', 'What you eat can significantly impact your cycle. Focus on iron-rich foods during menstruation, complex carbohydrates for energy, and omega-3 fatty acids to reduce inflammation.', 'Nutritionist Emma Smith', 'nutrition'::article_category, 'intermediate'::article_difficulty, 7, true, false, 4.6, ARRAY['nutrition', 'health', 'food']),
            ('Exercise During Your Period', 'Safe and effective workouts for different cycle phases', 'Exercise can help alleviate period symptoms. Light cardio, yoga, and stretching are great during menstruation, while strength training works well during the follicular phase.', 'Fitness Coach Lisa Brown', 'exercise'::article_category, 'beginner'::article_difficulty, 4, false, true, 4.5, ARRAY['exercise', 'period', 'fitness']),
            ('Managing Period Pain Naturally', 'Natural remedies for menstrual cramps and discomfort', 'Many women experience pain during their periods. Natural remedies like heat therapy, gentle massage, herbal teas, and breathing exercises can provide significant relief.', 'Dr. Michelle Taylor', 'menstrualHealth'::article_category, 'intermediate'::article_difficulty, 6, true, false, 4.7, ARRAY['pain relief', 'natural remedies', 'cramps'])
        ) AS t(title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags)
        WHERE NOT EXISTS (SELECT 1 FROM wellness_articles WHERE title = t.title LIMIT 1);

        INSERT INTO public.schema_migrations (version, description)
        VALUES (5, 'Create indexes and sample data')
        ON CONFLICT (version) DO NOTHING;
        
        current_version := 5;
        RAISE NOTICE '✅ Migration 005 completed!';
    END IF;

    -- Final status
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ All migrations completed!';
    RAISE NOTICE 'Current database version: %', current_version;
    RAISE NOTICE '========================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error applying migrations: %', SQLERRM;
        RAISE;
END $$;

-- Show migration status
SELECT 
    version,
    description,
    applied_at
FROM public.schema_migrations 
ORDER BY version ASC;

