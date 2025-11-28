-- Delete your test user so you can sign up again
DELETE FROM auth.users WHERE email = 'timmytn123@gmail.com';

-- Or delete ALL unconfirmed users (be careful!)
-- DELETE FROM auth.users WHERE email_confirmed_at IS NULL;
