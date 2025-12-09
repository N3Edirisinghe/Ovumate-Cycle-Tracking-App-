-- OvuMate Database Schema
-- Run this in your Supabase SQL Editor
-- This schema is idempotent - safe to run multiple times

-- Create custom types for enums (idempotent)
DO $$ BEGIN
  CREATE TYPE cycle_phase AS ENUM ('menstrual', 'follicular', 'ovulation', 'luteal', 'unknown');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE symptom_severity AS ENUM ('none', 'mild', 'moderate', 'severe');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE article_category AS ENUM ('menstrualHealth', 'fertility', 'nutrition', 'exercise', 'mentalHealth', 'lifestyle', 'medical', 'general', 'relationships', 'medicalConditions');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE article_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

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
  
  -- Cycle tracking preferences
  average_cycle_length INTEGER DEFAULT 28,
  average_period_length INTEGER DEFAULT 5,
  average_luteal_phase INTEGER DEFAULT 14,
  last_period_start DATE,
  notifications_enabled BOOLEAN DEFAULT true,
  partner_sharing_enabled BOOLEAN DEFAULT false,
  partner_id UUID REFERENCES user_profiles(id),
  
  -- Privacy settings
  data_sharing_enabled BOOLEAN DEFAULT false,
  analytics_enabled BOOLEAN DEFAULT true,
  marketing_emails_enabled BOOLEAN DEFAULT false,
  
  -- Wellness preferences
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
  
  -- Lifestyle tracking
  sleep_hours INTEGER CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
  water_intake INTEGER CHECK (water_intake >= 0),
  stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
  mood TEXT,
  activities TEXT[] DEFAULT '{}',
  took_medication BOOLEAN DEFAULT false,
  medication_notes TEXT,
  
  -- Ensure one entry per user per date
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
  read_time INTEGER NOT NULL, -- in minutes
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
  message_type TEXT DEFAULT 'text', -- 'text', 'image', 'file'
  metadata JSONB DEFAULT '{}'
);

-- Article Ratings table
CREATE TABLE IF NOT EXISTS article_ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  article_id UUID REFERENCES wellness_articles(id) ON DELETE CASCADE NOT NULL,
  rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Ensure one rating per user per article
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
  
  -- Ensure one progress record per user per article
  UNIQUE(user_id, article_id)
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_article_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for cycle_entries
DROP POLICY IF EXISTS "Users can view their own cycle entries" ON cycle_entries;
CREATE POLICY "Users can view their own cycle entries" ON cycle_entries
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own cycle entries" ON cycle_entries;
CREATE POLICY "Users can insert their own cycle entries" ON cycle_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own cycle entries" ON cycle_entries;
CREATE POLICY "Users can update their own cycle entries" ON cycle_entries
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own cycle entries" ON cycle_entries;
CREATE POLICY "Users can delete their own cycle entries" ON cycle_entries
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for wellness_articles (public read)
DROP POLICY IF EXISTS "Anyone can view wellness articles" ON wellness_articles;
CREATE POLICY "Anyone can view wellness articles" ON wellness_articles
  FOR SELECT USING (true);

-- RLS Policies for chat_messages
DROP POLICY IF EXISTS "Users can view their own chat messages" ON chat_messages;
CREATE POLICY "Users can view their own chat messages" ON chat_messages
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own chat messages" ON chat_messages;
CREATE POLICY "Users can insert their own chat messages" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for article_ratings
DROP POLICY IF EXISTS "Users can view their own article ratings" ON article_ratings;
CREATE POLICY "Users can view their own article ratings" ON article_ratings
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own article ratings" ON article_ratings;
CREATE POLICY "Users can insert their own article ratings" ON article_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own article ratings" ON article_ratings;
CREATE POLICY "Users can update their own article ratings" ON article_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for user_article_progress
DROP POLICY IF EXISTS "Users can view their own article progress" ON user_article_progress;
CREATE POLICY "Users can view their own article progress" ON user_article_progress
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own article progress" ON user_article_progress;
CREATE POLICY "Users can insert their own article progress" ON user_article_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own article progress" ON user_article_progress;
CREATE POLICY "Users can update their own article progress" ON user_article_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_cycle_entries_updated_at ON cycle_entries;
CREATE TRIGGER update_cycle_entries_updated_at BEFORE UPDATE ON cycle_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_wellness_articles_updated_at ON wellness_articles;
CREATE TRIGGER update_wellness_articles_updated_at BEFORE UPDATE ON wellness_articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_article_progress_updated_at ON user_article_progress;
CREATE TRIGGER update_user_article_progress_updated_at BEFORE UPDATE ON user_article_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample wellness articles (idempotent)
INSERT INTO wellness_articles (title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags) 
SELECT * FROM (VALUES
('Understanding Your Menstrual Cycle', 'A comprehensive guide to understanding the phases of your menstrual cycle', 'Your menstrual cycle is more than just your period...', 'Dr. Sarah Johnson', 'menstrualHealth', 'beginner', 5, true, true, 4.8, ARRAY['cycle', 'education', 'health']),
('Nutrition for Cycle Health', 'How proper nutrition can support your menstrual health', 'What you eat can significantly impact your cycle...', 'Nutritionist Emma Smith', 'nutrition', 'intermediate', 7, true, false, 4.6, ARRAY['nutrition', 'health', 'food']),
('Exercise During Your Period', 'Safe and effective workouts for different cycle phases', 'Exercise can help alleviate period symptoms...', 'Fitness Coach Lisa Brown', 'exercise', 'beginner', 4, false, true, 4.5, ARRAY['exercise', 'period', 'fitness']),
('Managing Period Pain Naturally', 'Natural remedies for menstrual cramps and discomfort', 'Many women experience pain during their periods...', 'Dr. Michelle Taylor', 'menstrualHealth', 'intermediate', 6, true, false, 4.7, ARRAY['pain relief', 'natural remedies', 'cramps'])
) AS v(title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags)
WHERE NOT EXISTS (SELECT 1 FROM wellness_articles WHERE wellness_articles.title = v.title);

-- Create indexes for better performance (idempotent)
CREATE INDEX IF NOT EXISTS idx_cycle_entries_user_date ON cycle_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_cycle_entries_date ON cycle_entries(date);
CREATE INDEX IF NOT EXISTS idx_wellness_articles_category ON wellness_articles(category);
CREATE INDEX IF NOT EXISTS idx_wellness_articles_featured ON wellness_articles(is_featured);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_timestamp ON chat_messages(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_article_ratings_article ON article_ratings(article_id);

-- Function to automatically create user profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id, 
    email, 
    first_name,
    last_name,
    created_at, 
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    -- Extract first_name from raw_user_meta_data or user_metadata
    COALESCE(
      NEW.raw_user_meta_data->>'first_name',
      NEW.raw_app_meta_data->>'first_name',
      NULL
    ),
    -- Extract last_name from raw_user_meta_data or user_metadata
    COALESCE(
      NEW.raw_user_meta_data->>'last_name',
      NEW.raw_app_meta_data->>'last_name',
      NULL
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    -- Update name fields if they're not already set
    first_name = COALESCE(
      user_profiles.first_name,
      EXCLUDED.first_name
    ),
    last_name = COALESCE(
      user_profiles.last_name,
      EXCLUDED.last_name
    ),
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create indexes for better performance
CREATE INDEX idx_cycle_entries_user_date ON cycle_entries(user_id, date);
CREATE INDEX idx_cycle_entries_date ON cycle_entries(date);
CREATE INDEX idx_wellness_articles_category ON wellness_articles(category);
CREATE INDEX idx_wellness_articles_featured ON wellness_articles(is_featured);
CREATE INDEX idx_chat_messages_user_timestamp ON chat_messages(user_id, timestamp);
CREATE INDEX idx_article_ratings_article ON article_ratings(article_id);
