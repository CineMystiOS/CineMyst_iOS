-- ============================================
-- FLICKS/REELS SUPABASE SCHEMA
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- ============================================

-- 1. Create flicks table
CREATE TABLE IF NOT EXISTS flicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    audio_title TEXT DEFAULT 'Original Audio',
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key to profiles table (profiles.id, not user_id)
    CONSTRAINT flicks_user_id_fkey FOREIGN KEY (user_id) 
        REFERENCES profiles(id) ON DELETE CASCADE
);

-- 2. Create flick_likes table
CREATE TABLE IF NOT EXISTS flick_likes (
    flick_id UUID NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (flick_id, user_id),
    
    CONSTRAINT flick_likes_flick_id_fkey FOREIGN KEY (flick_id) 
        REFERENCES flicks(id) ON DELETE CASCADE,
    CONSTRAINT flick_likes_user_id_fkey FOREIGN KEY (user_id) 
        REFERENCES profiles(id) ON DELETE CASCADE
);

-- 3. Create flick_comments table
CREATE TABLE IF NOT EXISTS flick_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flick_id UUID NOT NULL,
    user_id UUID NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT flick_comments_flick_id_fkey FOREIGN KEY (flick_id) 
        REFERENCES flicks(id) ON DELETE CASCADE,
    CONSTRAINT flick_comments_user_id_fkey FOREIGN KEY (user_id) 
        REFERENCES profiles(id) ON DELETE CASCADE
);

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_flicks_user_id ON flicks(user_id);
CREATE INDEX IF NOT EXISTS idx_flicks_created_at ON flicks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_flick_likes_flick_id ON flick_likes(flick_id);
CREATE INDEX IF NOT EXISTS idx_flick_likes_user_id ON flick_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_flick_comments_flick_id ON flick_comments(flick_id);
CREATE INDEX IF NOT EXISTS idx_flick_comments_user_id ON flick_comments(user_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE flicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE flick_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE flick_comments ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for flicks
-- Anyone can view flicks
CREATE POLICY "Flicks are viewable by everyone"
    ON flicks FOR SELECT
    USING (true);

-- Users can create their own flicks
CREATE POLICY "Users can create their own flicks"
    ON flicks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own flicks
CREATE POLICY "Users can update their own flicks"
    ON flicks FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own flicks
CREATE POLICY "Users can delete their own flicks"
    ON flicks FOR DELETE
    USING (auth.uid() = user_id);

-- 7. RLS Policies for flick_likes
-- Anyone can view likes
CREATE POLICY "Flick likes are viewable by everyone"
    ON flick_likes FOR SELECT
    USING (true);

-- Users can create their own likes
CREATE POLICY "Users can like flicks"
    ON flick_likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own likes
CREATE POLICY "Users can unlike flicks"
    ON flick_likes FOR DELETE
    USING (auth.uid() = user_id);

-- 8. RLS Policies for flick_comments
-- Anyone can view comments
CREATE POLICY "Flick comments are viewable by everyone"
    ON flick_comments FOR SELECT
    USING (true);

-- Users can create comments
CREATE POLICY "Users can comment on flicks"
    ON flick_comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments"
    ON flick_comments FOR DELETE
    USING (auth.uid() = user_id);

-- 9. Database functions for incrementing/decrementing counts
CREATE OR REPLACE FUNCTION increment_flick_likes(flick_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE flicks
    SET likes_count = likes_count + 1
    WHERE id = flick_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_flick_likes(flick_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE flicks
    SET likes_count = GREATEST(likes_count - 1, 0)
    WHERE id = flick_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_flick_comments(flick_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE flicks
    SET comments_count = comments_count + 1
    WHERE id = flick_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_flick_shares(flick_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE flicks
    SET shares_count = shares_count + 1
    WHERE id = flick_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_flicks_updated_at
    BEFORE UPDATE ON flicks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STORAGE BUCKET SETUP
-- ============================================
-- Run these commands in Supabase Storage section:
-- 1. Create a bucket called "videos" (if not exists)
-- 2. Make it public
-- 3. Set up the following policies:

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Videos are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own videos" ON storage.objects;

-- Storage policies for videos bucket
-- INSERT policy: Users can upload their own videos
CREATE POLICY "Users can upload videos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'videos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- SELECT policy: Anyone can view videos
CREATE POLICY "Videos are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'videos');

-- DELETE policy: Users can delete their own videos
CREATE POLICY "Users can delete their own videos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'videos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================
-- Uncomment to insert sample data
/*
INSERT INTO flicks (user_id, video_url, caption, audio_title, likes_count, comments_count, shares_count)
VALUES 
    (auth.uid(), 'https://your-supabase-url.supabase.co/storage/v1/object/public/videos/sample1.mov', 
     'My first flick! 🎬', 'Original Audio', 150, 23, 5),
    (auth.uid(), 'https://your-supabase-url.supabase.co/storage/v1/object/public/videos/sample2.mov', 
     'Behind the scenes', 'Trending Sound', 320, 45, 12);
*/

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify setup:

-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('flicks', 'flick_likes', 'flick_comments');

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('flicks', 'flick_likes', 'flick_comments');

-- Check policies
SELECT tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('flicks', 'flick_likes', 'flick_comments');

-- ============================================
-- IMPORTANT: Refresh Schema Cache
-- ============================================
-- After running this SQL, you MUST refresh the schema cache:
-- Go to: Supabase Dashboard → API → Click "Reload Schema" button
-- OR run this command:
NOTIFY pgrst, 'reload schema';
