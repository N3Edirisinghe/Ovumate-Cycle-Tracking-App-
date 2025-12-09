-- Migration 004: Auto-create user profiles and triggers

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
    -- Extract first_name from raw_user_app_meta_data or user_metadata
    COALESCE(
      NEW.raw_user_meta_data->>'first_name',
      NEW.raw_app_meta_data->>'first_name',
      NULL
    ),
    -- Extract last_name from raw_user_app_meta_data or user_metadata
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

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (4, 'Auto-create user profiles and triggers')
ON CONFLICT (version) DO NOTHING;

