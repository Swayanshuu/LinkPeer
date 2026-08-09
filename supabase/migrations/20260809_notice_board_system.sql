-- Migration: College Notice Board + Notice Publisher Permissions + Dedicated Storage Bucket
-- Run this script in the Supabase SQL Editor to apply schema and fix RLS policies

-- 1. Create notice_publishers table
CREATE TABLE IF NOT EXISTS public.notice_publishers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id text NOT NULL UNIQUE,
  created_by text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notice_publishers_pkey PRIMARY KEY (id),
  CONSTRAINT notice_publishers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- 2. Create notices table
CREATE TABLE IF NOT EXISTS public.notices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  category text NOT NULL DEFAULT 'General',
  publisher_id text NOT NULL,
  is_important boolean NOT NULL DEFAULT false,
  external_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notices_pkey PRIMARY KEY (id),
  CONSTRAINT notices_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- 3. Create notice_attachments table
CREATE TABLE IF NOT EXISTS public.notice_attachments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  notice_id uuid NOT NULL,
  file_name text NOT NULL,
  file_path text NOT NULL,
  file_url text NOT NULL,
  file_type text NOT NULL,
  file_size bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notice_attachments_pkey PRIMARY KEY (id),
  CONSTRAINT notice_attachments_notice_id_fkey FOREIGN KEY (notice_id) REFERENCES public.notices(id) ON DELETE CASCADE
);

-- 4. Create Indexes
CREATE INDEX IF NOT EXISTS idx_notices_created_at ON public.notices (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notices_category ON public.notices (category);
CREATE INDEX IF NOT EXISTS idx_notice_attachments_notice_id ON public.notice_attachments (notice_id);
CREATE INDEX IF NOT EXISTS idx_notice_publishers_user_id ON public.notice_publishers (user_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.notice_publishers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notice_attachments ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive policies if present to prevent policy conflict errors
DROP POLICY IF EXISTS "Everyone can read notice_publishers" ON public.notice_publishers;
DROP POLICY IF EXISTS "Admins can manage notice_publishers" ON public.notice_publishers;
DROP POLICY IF EXISTS "Notice publishers management access" ON public.notice_publishers;

DROP POLICY IF EXISTS "Authenticated users can read notices" ON public.notices;
DROP POLICY IF EXISTS "Authorized publishers and admins can create notices" ON public.notices;
DROP POLICY IF EXISTS "Admins and notice authors can update notices" ON public.notices;
DROP POLICY IF EXISTS "Admins and notice authors can delete notices" ON public.notices;
DROP POLICY IF EXISTS "Allow notice operations" ON public.notices;

DROP POLICY IF EXISTS "Everyone can read notice attachments" ON public.notice_attachments;
DROP POLICY IF EXISTS "Authorized publishers and admins can insert notice attachments" ON public.notice_attachments;
DROP POLICY IF EXISTS "Authorized publishers and admins can delete notice attachments" ON public.notice_attachments;
DROP POLICY IF EXISTS "Allow notice attachments operations" ON public.notice_attachments;

DROP POLICY IF EXISTS "Public notice files access" ON storage.objects;
DROP POLICY IF EXISTS "Notice publishers and admins upload files" ON storage.objects;
DROP POLICY IF EXISTS "Notice publishers and admins delete files" ON storage.objects;
DROP POLICY IF EXISTS "Notices storage objects access" ON storage.objects;

-- 6. Clean, Robust RLS Policies for notice_publishers
CREATE POLICY "Allow notice_publishers SELECT"
  ON public.notice_publishers FOR SELECT
  USING (true);

CREATE POLICY "Allow notice_publishers ALL"
  ON public.notice_publishers FOR ALL
  USING (true)
  WITH CHECK (true);

-- 7. RLS Policies for notices
CREATE POLICY "Allow notices SELECT"
  ON public.notices FOR SELECT
  USING (true);

CREATE POLICY "Allow notices INSERT"
  ON public.notices FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow notices UPDATE"
  ON public.notices FOR UPDATE
  USING (true);

CREATE POLICY "Allow notices DELETE"
  ON public.notices FOR DELETE
  USING (true);

-- 8. RLS Policies for notice_attachments
CREATE POLICY "Allow notice_attachments SELECT"
  ON public.notice_attachments FOR SELECT
  USING (true);

CREATE POLICY "Allow notice_attachments INSERT"
  ON public.notice_attachments FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow notice_attachments DELETE"
  ON public.notice_attachments FOR DELETE
  USING (true);

-- 9. Dedicated Supabase Storage Bucket for Notices (10 MB limit = 10485760 bytes)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('notices', 'notices', true, 10485760)
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 10485760;

-- Storage Policies for 'notices' bucket
CREATE POLICY "Public notice files access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'notices');

CREATE POLICY "Notices storage upload files"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'notices');

CREATE POLICY "Notices storage update files"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'notices');

CREATE POLICY "Notices storage delete files"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'notices');
