-- AUTO-CONFIRM ALL NEW USER EMAILS
-- This trigger automatically sets email_confirmed_at when a new user signs up
-- So users don't need to confirm their email

-- Create a function to auto-confirm emails
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Automatically set email_confirmed_at to now (confirmed_at is auto-generated)
  NEW.email_confirmed_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS auto_confirm_user_trigger ON auth.users;

-- Create trigger that runs BEFORE INSERT on auth.users
CREATE TRIGGER auto_confirm_user_trigger
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_user();

-- Also fix any existing unconfirmed users (only set email_confirmed_at)
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
