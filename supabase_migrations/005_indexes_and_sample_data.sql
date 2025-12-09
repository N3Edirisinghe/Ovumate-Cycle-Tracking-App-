-- Migration 005: Create indexes and sample data

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cycle_entries_user_date ON cycle_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_cycle_entries_date ON cycle_entries(date);
CREATE INDEX IF NOT EXISTS idx_wellness_articles_category ON wellness_articles(category);
CREATE INDEX IF NOT EXISTS idx_wellness_articles_featured ON wellness_articles(is_featured);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_timestamp ON chat_messages(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_article_ratings_article ON article_ratings(article_id);

-- Insert some sample wellness articles (only if they don't exist)
INSERT INTO wellness_articles (title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags) 
SELECT * FROM (VALUES
  ('Understanding Your Menstrual Cycle', 'A comprehensive guide to understanding the phases of your menstrual cycle', 'Your menstrual cycle is more than just your period. It consists of four main phases: menstrual, follicular, ovulation, and luteal. Understanding these phases can help you better track your health and predict your cycle.', 'Dr. Sarah Johnson', 'menstrualHealth'::article_category, 'beginner'::article_difficulty, 5, true, true, 4.8, ARRAY['cycle', 'education', 'health']),
  ('Nutrition for Cycle Health', 'How proper nutrition can support your menstrual health', 'What you eat can significantly impact your cycle. Focus on iron-rich foods during menstruation, complex carbohydrates for energy, and omega-3 fatty acids to reduce inflammation.', 'Nutritionist Emma Smith', 'nutrition'::article_category, 'intermediate'::article_difficulty, 7, true, false, 4.6, ARRAY['nutrition', 'health', 'food']),
  ('Exercise During Your Period', 'Safe and effective workouts for different cycle phases', 'Exercise can help alleviate period symptoms. Light cardio, yoga, and stretching are great during menstruation, while strength training works well during the follicular phase.', 'Fitness Coach Lisa Brown', 'exercise'::article_category, 'beginner'::article_difficulty, 4, false, true, 4.5, ARRAY['exercise', 'period', 'fitness']),
  ('Managing Period Pain Naturally', 'Natural remedies for menstrual cramps and discomfort', 'Many women experience pain during their periods. Natural remedies like heat therapy, gentle massage, herbal teas, and breathing exercises can provide significant relief.', 'Dr. Michelle Taylor', 'menstrualHealth'::article_category, 'intermediate'::article_difficulty, 6, true, false, 4.7, ARRAY['pain relief', 'natural remedies', 'cramps'])
) AS t(title, summary, content, author, category, difficulty, read_time, is_featured, is_new, rating, tags)
WHERE NOT EXISTS (SELECT 1 FROM wellness_articles WHERE title = t.title LIMIT 1);

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (5, 'Create indexes and sample data')
ON CONFLICT (version) DO NOTHING;

