-- Migration 003: Setup Row Level Security and Policies

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_article_progress ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
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

-- RLS Policies for user_profiles
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for cycle_entries
CREATE POLICY "Users can view their own cycle entries" ON cycle_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cycle entries" ON cycle_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cycle entries" ON cycle_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cycle entries" ON cycle_entries
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for wellness_articles (public read)
CREATE POLICY "Anyone can view wellness articles" ON wellness_articles
  FOR SELECT USING (true);

-- RLS Policies for chat_messages
CREATE POLICY "Users can view their own chat messages" ON chat_messages
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own chat messages" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for article_ratings
CREATE POLICY "Users can view their own article ratings" ON article_ratings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own article ratings" ON article_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own article ratings" ON article_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for user_article_progress
CREATE POLICY "Users can view their own article progress" ON user_article_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own article progress" ON user_article_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own article progress" ON user_article_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (3, 'Setup RLS and policies')
ON CONFLICT (version) DO NOTHING;

