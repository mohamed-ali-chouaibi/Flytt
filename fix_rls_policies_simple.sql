-- Simple RLS policies - allow all authenticated users

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can insert" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can select" ON public.passenger;
DROP POLICY IF EXISTS "Authenticated users can update" ON public.passenger;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.passenger;
DROP POLICY IF EXISTS "Users can select their own profile" ON public.passenger;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.passenger;

-- Create simple policies
CREATE POLICY "Allow authenticated insert"
ON public.passenger
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated select"
ON public.passenger
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated update"
ON public.passenger
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
