-- ====================================================================
-- LinkPeer Premium Monetization & Analytics Schema Updates
-- Run this in your Supabase SQL Editor
-- ====================================================================

-- 1. Updates to existing `users` table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS subscription_plan text DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_status text DEFAULT 'active',
ADD COLUMN IF NOT EXISTS subscription_expiry timestamp without time zone,
ADD COLUMN IF NOT EXISTS ranking_score integer DEFAULT 0;
-- Note: You already have `is_verified boolean DEFAULT false` which we will use for the Verified Badge.

-- 2. Updates to existing `posts` table for multiple image uploads
ALTER TABLE public.posts 
ADD COLUMN IF NOT EXISTS image_urls text[];

-- 3. Create `subscriptions` table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id text REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    plan_type text NOT NULL, -- 'premium_lite' or 'premium_pro'
    amount numeric NOT NULL,
    status text NOT NULL DEFAULT 'active', -- 'active', 'expired', 'cancelled'
    transaction_id text,
    start_date timestamp without time zone DEFAULT now(),
    end_date timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);

-- Enable RLS for subscriptions
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "Allow Public Select" ON public.subscriptions;
DROP POLICY IF EXISTS "Allow Public Insert" ON public.subscriptions;
DROP POLICY IF EXISTS "Allow Public Update" ON public.subscriptions;
CREATE POLICY "Allow Public Select" ON public.subscriptions FOR SELECT TO public USING (true);
CREATE POLICY "Allow Public Insert" ON public.subscriptions FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow Public Update" ON public.subscriptions FOR UPDATE TO public USING (true);

-- 4. Create `payments` table
CREATE TABLE IF NOT EXISTS public.payments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id text REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    plan_type text NOT NULL,
    amount numeric NOT NULL,
    payment_provider text DEFAULT 'phonepe',
    transaction_id text NOT NULL UNIQUE,
    status text NOT NULL DEFAULT 'pending', -- 'pending', 'success', 'failed'
    created_at timestamp without time zone DEFAULT now()
);

-- Enable RLS for payments
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can insert their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can update their own payments" ON public.payments;
DROP POLICY IF EXISTS "Allow Public Select" ON public.payments;
DROP POLICY IF EXISTS "Allow Public Insert" ON public.payments;
DROP POLICY IF EXISTS "Allow Public Update" ON public.payments;
CREATE POLICY "Allow Public Select" ON public.payments FOR SELECT TO public USING (true);
CREATE POLICY "Allow Public Insert" ON public.payments FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow Public Update" ON public.payments FOR UPDATE TO public USING (true);

-- 5. Create `analytics_events` table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    viewer_id text REFERENCES public.users(id) ON DELETE SET NULL, -- Can be null for anonymous
    target_id text REFERENCES public.users(id) ON DELETE CASCADE NOT NULL, -- The user whose profile/post was viewed
    event_type text NOT NULL, -- 'profile_view', 'search_appearance', 'post_impression'
    created_at timestamp without time zone DEFAULT now()
);

-- Enable RLS for analytics
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own analytics" ON public.analytics_events;
DROP POLICY IF EXISTS "Anyone can insert analytics events" ON public.analytics_events;
DROP POLICY IF EXISTS "Allow Public Select" ON public.analytics_events;
DROP POLICY IF EXISTS "Allow Public Insert" ON public.analytics_events;
CREATE POLICY "Allow Public Select" ON public.analytics_events FOR SELECT TO public USING (true);
CREATE POLICY "Allow Public Insert" ON public.analytics_events FOR INSERT TO public WITH CHECK (true);

-- 6. Storage Bucket for Post Images
-- Make sure the bucket 'post_images' exists. You may need to create it manually in the dashboard or using the following:
INSERT INTO storage.buckets (id, name, public) VALUES ('post_images', 'post_images', true) ON CONFLICT (id) DO NOTHING;

-- Storage Policies for 'post_images'
DROP POLICY IF EXISTS "Public Access for post_images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload post_images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own post_images" ON storage.objects;
CREATE POLICY "Public Access for post_images" ON storage.objects FOR SELECT USING ( bucket_id = 'post_images' );
CREATE POLICY "Authenticated users can upload post_images" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'post_images' AND auth.role() = 'authenticated' );
CREATE POLICY "Users can delete their own post_images" ON storage.objects FOR DELETE USING ( bucket_id = 'post_images' AND auth.uid() = owner );

-- 7. Automated verified_badge removal function & trigger
-- Removes verified badge if subscription expires.
CREATE OR REPLACE FUNCTION check_subscription_expiry()
RETURNS trigger AS $$
BEGIN
  IF NEW.subscription_expiry < now() AND NEW.is_verified = true THEN
    NEW.is_verified = false;
    NEW.subscription_plan = 'free';
    NEW.subscription_status = 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_subscription_status
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION check_subscription_expiry();

-- 8. Create `user_activities` table for immutable action tracking & ranking
CREATE TABLE IF NOT EXISTS public.user_activities (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id text REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    activity_type text NOT NULL, -- e.g., 'text_post', 'image_post'
    created_at timestamp without time zone DEFAULT now()
);

-- Enable RLS for user_activities
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own activities" ON public.user_activities;
DROP POLICY IF EXISTS "Allow Public Select" ON public.user_activities;
DROP POLICY IF EXISTS "Allow Public Inserts" ON public.user_activities;
CREATE POLICY "Allow Public Select" ON public.user_activities FOR SELECT TO public USING (true);
-- Allow public insert because app uses Firebase Auth and requests look like anon to Supabase
CREATE POLICY "Allow Public Inserts" ON public.user_activities FOR INSERT TO public WITH CHECK (true);

-- ====================================================================
-- Comments System Schema
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.post_comments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id TEXT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),

    CONSTRAINT post_comments_post_id_fkey
        FOREIGN KEY (post_id)
        REFERENCES public.posts(id)
        ON DELETE CASCADE,

    CONSTRAINT post_comments_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES public.users(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON public.post_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_created_at ON public.post_comments(created_at DESC);

-- Enable RLS for post_comments (assuming public access based on other tables)
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow Public Select" ON public.post_comments;
DROP POLICY IF EXISTS "Allow Public Insert" ON public.post_comments;
DROP POLICY IF EXISTS "Allow Public Delete" ON public.post_comments;
CREATE POLICY "Allow Public Select" ON public.post_comments FOR SELECT TO public USING (true);
CREATE POLICY "Allow Public Insert" ON public.post_comments FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow Public Delete" ON public.post_comments FOR DELETE TO public USING (true);

-- ====================================================================
-- Comment Likes
-- ====================================================================
ALTER TABLE public.post_comments 
ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS liked_by TEXT[] DEFAULT '{}';

CREATE OR REPLACE FUNCTION toggle_comment_like(p_comment_id BIGINT, p_user_id TEXT)
RETURNS void AS $$
DECLARE
    v_liked_by TEXT[];
BEGIN
    -- Get current liked_by array
    SELECT liked_by INTO v_liked_by FROM public.post_comments WHERE id = p_comment_id;
    
    IF p_user_id = ANY(v_liked_by) THEN
        -- User has already liked it, so unlike (remove from array and decrement)
        UPDATE public.post_comments
        SET liked_by = array_remove(liked_by, p_user_id),
            likes_count = likes_count - 1
        WHERE id = p_comment_id;
    ELSE
        -- User hasn't liked it, so like (append to array and increment)
        UPDATE public.post_comments
        SET liked_by = array_append(liked_by, p_user_id),
            likes_count = likes_count + 1
        WHERE id = p_comment_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================
-- End of Migrations
-- ====================================================================
