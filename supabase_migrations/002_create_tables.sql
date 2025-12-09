-- Migration 002: Create All Tables
-- This migration creates all required tables

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

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (2, 'Create all tables')
ON CONFLICT (version) DO NOTHING;

