-- Migration 001: Initial Schema Setup
-- This migration creates the initial database schema
-- It's safe to run multiple times (idempotent)

-- Migration tracking table
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  description TEXT
);

-- Create custom types for enums (safe to run multiple times)
DO $$ BEGIN
    CREATE TYPE cycle_phase AS ENUM ('menstrual', 'follicular', 'ovulation', 'luteal', 'unknown');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE symptom_severity AS ENUM ('none', 'mild', 'moderate', 'severe');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE article_category AS ENUM ('menstrualHealth', 'fertility', 'nutrition', 'exercise', 'mentalHealth', 'lifestyle', 'medical', 'general', 'relationships', 'medicalConditions');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE article_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Record this migration
INSERT INTO public.schema_migrations (version, description)
VALUES (1, 'Initial schema setup')
ON CONFLICT (version) DO NOTHING;

