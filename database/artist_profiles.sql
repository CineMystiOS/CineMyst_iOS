-- Create the artist_profiles table if it doesn't already exist
CREATE TABLE IF NOT EXISTS public.artist_profiles (
  id uuid NOT NULL,
  primary_roles text[] NULL,
  career_stage text NULL,
  skills text[] NULL,
  media_urls text[] NULL,
  travel_willing boolean NULL,
  specific_role text NULL,
  secondary_roles text[] NULL,
  years_of_experience integer NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  headshot_url text NULL,
  CONSTRAINT artist_profiles_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;

-- Migration: Ensure all columns exist in case the table was created with an older schema
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS primary_roles text[] NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS career_stage text NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS skills text[] NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS media_urls text[] NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS travel_willing boolean NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS specific_role text NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS secondary_roles text[] NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS years_of_experience integer NULL;
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS created_at timestamp with time zone NULL DEFAULT now();
ALTER TABLE public.artist_profiles ADD COLUMN IF NOT EXISTS headshot_url text NULL;
