-- Fix Storage RLS for post_images bucket (FIREBASE AUTH FIX)
-- Since your app uses Firebase for Authentication instead of Supabase Auth,
-- Supabase considers all your app's requests as "anon" (anonymous/public).
-- Therefore, we must allow public uploads to the bucket.

-- 1. Ensure the bucket exists and is public
INSERT INTO storage.buckets (id, name, public) 
VALUES ('post_images', 'post_images', true) 
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Drop any previous policies
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Auth Users Upload" ON storage.objects;
DROP POLICY IF EXISTS "Users Update Own Images" ON storage.objects;
DROP POLICY IF EXISTS "Users Delete Own Images" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Uploads" ON storage.objects;

-- 3. Create policies that allow anon/public access
-- View images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'post_images' );

-- Upload images (Allow public since Firebase Auth is used)
CREATE POLICY "Allow Public Uploads"
ON storage.objects FOR INSERT
TO public
WITH CHECK ( bucket_id = 'post_images' );

-- Update images (Allow public)
CREATE POLICY "Users Update Own Images"
ON storage.objects FOR UPDATE
TO public
USING ( bucket_id = 'post_images' );

-- Delete images (Allow public)
CREATE POLICY "Users Delete Own Images"
ON storage.objects FOR DELETE
TO public
USING ( bucket_id = 'post_images' );
