-- Fix for currency field error in passenger and driver wallet creation triggers
-- This script fixes the PostgrestException: record "new" has no field "currency"

-- Fix passenger wallet creation trigger
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO passenger_wallets (passenger_uid, balance, currency)
  VALUES (NEW.uid, 0.0, 'TND');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fix driver wallet creation trigger (if you have one)
-- Uncomment and modify the function name if needed
/*
CREATE OR REPLACE FUNCTION create_driver_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO driver_wallets (driver_uid, balance, currency)
  VALUES (NEW.uid, 0.0, 'TND');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Verify the fix by checking if the function was updated
SELECT 
  proname as function_name,
  prosrc as function_source
FROM pg_proc 
WHERE proname IN ('create_user_wallet', 'create_driver_wallet'); 