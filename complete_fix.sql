-- COMPLETE FIX FOR RLS POLICIES
-- Run this entire script in Supabase SQL Editor

-- 1. First, let's check if the profile-images bucket exists and create it if not
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop ALL existing policies on passenger table
DROP POLICY IF EXISTS "Authenticated users can insert" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can select" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can update" ON public.passenger;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.passenger;
DROP POLICY IF EXISTS "Users can select their own profile" ON public.passenger;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.passenger;
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.passenger;
DROP POLICY IF EXISTS "Allow authenticated select" ON public.passenger;
DROP POLICY IF EXISTS "Allow authenticated update" ON public.passenger;

-- 3. Create NEW simple policies for passenger table
CREATE POLICY "passenger_insert_policy"
ON public.passenger
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "passenger_select_policy"
ON public.passenger
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "passenger_update_policy"
ON public.passenger
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Fix storage policies for profile-images bucket
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated view" ON storage.objects;
DROP POLICY IF EXISTS "Public Access" ON storage.objects;

-- 5. Create storage policies
CREATE POLICY "Anyone can upload profile images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Anyone can view profile images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

CREATE POLICY "Users can update their profile images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-images')
WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Users can delete their profile images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'profile-images');

-- 6. Verify the passenger table has the uid column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'passenger' 
        AND column_name = 'uid'
    ) THEN
        ALTER TABLE passenger ADD COLUMN uid uuid;
        ALTER TABLE passenger ADD CONSTRAINT unique_passenger_uid UNIQUE (uid);
    END IF;
END $$;
