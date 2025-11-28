-- Fix RLS policies for passenger table to allow inserts with uid field

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can insert" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can select" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can update" ON public.passenger;

-- Create new policies that check the uid field matches auth.uid()
CREATE POLICY "Users can insert their own profile"
ON public.passenger
FOR INSERT
TO authenticated
WITH CHECK (uid = auth.uid());

CREATE POLICY "Users can select their own profile"
ON public.passenger
FOR SELECT
TO authenticated
USING (uid = auth.uid());

CREATE POLICY "Users can update their own profile"
ON public.passenger
FOR UPDATE
TO authenticated
USING (uid = auth.uid())
WITH CHECK (uid = auth.uid());

-- Also ensure storage policies are correct
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
CREATE POLICY "Authenticated users can upload images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-images');

DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;
CREATE POLICY "Authenticated users can view images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'profile-images');
