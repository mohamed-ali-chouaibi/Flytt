-- Disable email confirmation requirement
-- This allows users to sign up without confirming their email

-- Update Supabase auth config to disable email confirmation
-- Note: This should be done in the Supabase Dashboard under Authentication > Providers > Email
-- But if you want to auto-confirm existing users, run this:

-- Auto-confirm all existing unconfirmed users (optional)
UPDATE auth.users 
SET email_confirmed_at = NOW(), 
    confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
