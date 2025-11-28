-- 1. Create passenger table first
create table passenger (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  surname text not null,
  email text not null unique,
  profile_image_url text,
  phone text not null unique,
  auto_rematch boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table passenger enable row level security;

-- Policy name: Authenticated can upload
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
CREATE POLICY "Authenticated users can upload images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy name: Authenticated can view images
DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;
CREATE POLICY "Authenticated users can view images"
ON storage.objects
FOR SELECT
TO authenticated
USING (true);

-- Policy name: Authenticated users can insert
DROP POLICY IF EXISTS "Authenticated users can insert" ON public.passenger;
CREATE POLICY "Authenticated users can insert"
ON public.passenger
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to select
DROP POLICY IF EXISTS "Authenticated users can select" ON public.passenger;
CREATE POLICY "Authenticated users can select"
ON public.passenger
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to update
DROP POLICY IF EXISTS "Authenticated users can update" ON public.passenger;
CREATE POLICY "Authenticated users can update"
ON public.passenger
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

ALTER TABLE passenger
ADD COLUMN uid uuid;
ALTER TABLE passenger
ADD CONSTRAINT unique_passenger_uid UNIQUE (uid);

ALTER TABLE passenger
ADD COLUMN rating numeric DEFAULT 5.0;

ALTER TABLE passenger
ADD COLUMN number_of_rides integer DEFAULT 0;

-- Add language column to passenger table
ALTER TABLE passenger
ADD COLUMN language text DEFAULT 'fr';

-- Add auto_rematch column to passenger table
ALTER TABLE passenger
ADD COLUMN auto_rematch boolean DEFAULT false;

-- Add safety preference columns to passenger table
alter table passenger add column safety_check_ins boolean default false;
alter table passenger add column pin_verification boolean default false;
alter table passenger add column share_trip_status boolean default false;
alter table passenger add column safety_schedule text default 'all_rides';

-- Create promotions table for storing promotion codes and discounts
create table promotions (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  title text not null,
  description text,
  percent integer not null check (percent > 0 and percent <= 100),
  start_date timestamp with time zone not null,
  end_date timestamp with time zone not null,
  is_active boolean default true,
  passenger_id uuid references passenger(uid) on delete set null,
  used_at timestamp with time zone,
  max_uses integer default 1,
  current_uses integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table promotions enable row level security;

create policy "Users can view promotions" on promotions
  for select to authenticated
  using (true);

create policy "Users can update their used promotions" on promotions
  for update to authenticated
  using (auth.uid() = passenger_id)
  with check (auth.uid() = passenger_id);

create index if not exists idx_promotions_code on promotions(code);
create index if not exists idx_promotions_passenger_id on promotions(passenger_id);
create index if not exists idx_promotions_active on promotions(is_active);

-- 2. Create payment_cards table next (references passenger)
create table payment_cards (
  id uuid primary key default uuid_generate_v4(),
  passenger_uid uuid references passenger(uid) on delete cascade,
  card_number text not null, -- Last 4 digits only for security
  expiry_month integer not null,
  expiry_year integer not null,
  card_type text, -- 'visa', 'mastercard', 'amex', etc.
  is_default boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table payment_cards enable row level security;

-- Policy name: Authenticated can insert payment cards
DROP POLICY IF EXISTS "Authenticated users can insert payment cards" ON public.payment_cards;
CREATE POLICY "Authenticated users can insert payment cards"
ON public.payment_cards
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy name: Authenticated can select payment cards
DROP POLICY IF EXISTS "Authenticated users can select payment cards" ON public.payment_cards;
CREATE POLICY "Authenticated users can select payment cards"
ON public.payment_cards
FOR SELECT
TO authenticated
USING (true);

-- Policy name: Authenticated can update payment cards
DROP POLICY IF EXISTS "Authenticated users can update payment cards" ON public.payment_cards;
CREATE POLICY "Authenticated users can update payment cards"
ON public.payment_cards
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy name: Authenticated can delete payment cards
DROP POLICY IF EXISTS "Authenticated users can delete payment cards" ON public.payment_cards;
CREATE POLICY "Authenticated users can delete payment cards"
ON public.payment_cards
FOR DELETE
TO authenticated
USING (true);

-- Table: passenger_wallets
create table passenger_wallets (
  id uuid primary key default uuid_generate_v4(),
  passenger_uid uuid references passenger(uid) on delete cascade unique,
  balance double precision not null default 0.0,
  currency text not null default 'TND',
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

alter table passenger_wallets enable row level security;

create policy "Users can insert their passenger wallet" on passenger_wallets
  for insert to authenticated
  with check (auth.uid() = passenger_uid);

create policy "Users can select their passenger wallet" on passenger_wallets
  for select to authenticated
  using (auth.uid() = passenger_uid);

create policy "Users can update their passenger wallet" on passenger_wallets
  for update to authenticated
  using (auth.uid() = passenger_uid)
  with check (auth.uid() = passenger_uid);

create index if not exists idx_passenger_wallets_passenger_uid on passenger_wallets(passenger_uid);

-- Update wallet_transactions to reference passenger_wallets
create table passenger_wallet_transactions (
  id uuid primary key default uuid_generate_v4(),
  wallet_id uuid references passenger_wallets(id) on delete cascade,
  passenger_uid uuid references passenger(uid) on delete cascade,
  amount double precision not null,
  transaction_type text not null, -- 'recharge', 'ride_payment', 'refund', 'bonus'
  description text,
  reference_id uuid, -- ride_id, recharge_id, etc.
  reference_type text, -- 'ride', 'recharge', etc.
  balance_before double precision not null,
  balance_after double precision not null,
  status text not null default 'completed', -- 'pending', 'completed', 'failed'
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table passenger_wallet_transactions enable row level security;

create policy "Users can insert their passenger wallet transactions" on passenger_wallet_transactions
  for insert to authenticated
  with check (auth.uid() = passenger_uid);

create policy "Users can select their passenger wallet transactions" on passenger_wallet_transactions
  for select to authenticated
  using (auth.uid() = passenger_uid);

create index if not exists idx_passenger_wallet_transactions_passenger_uid on passenger_wallet_transactions(passenger_uid);

-- 4. Now create rides, ride_history, transactions, wallet_transactions, wallet_recharges, etc.
create table rides (
  id uuid primary key default uuid_generate_v4(),
  passenger_uid uuid references passenger(uid) on delete set null,
  driver_uid uuid references passenger(uid) on delete set null,
  from_address text not null,
  to_address text not null,
  from_lat double precision not null,
  from_lng double precision not null,
  to_lat double precision not null,
  to_lng double precision not null,
  distance_km double precision not null,
  duration_minutes integer not null,
  price double precision not null,
  payment_method text not null,
  ride_type text not null default 'weego', -- 'weego', 'comfort', 'taxi', 'eco', 'woman', 'weegoxl'
  status text not null default 'requested',
  rating double precision,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  selected_card_id uuid references payment_cards(id) on delete set null,
  wallet_id uuid references passenger_wallets(id) on delete set null,
  promotion_id uuid references promotions(id) on delete set null,
  discount_percent integer,
  original_price double precision,
  driver_amount double precision,
  app_commission double precision,
  currency text NOT NULL DEFAULT 'TND'
);

-- Enable RLS
alter table rides enable row level security;

-- Allow users to insert/select their own rides
create policy "Users can insert rides" on rides
  for insert to authenticated
  with check (auth.uid() = passenger_uid);

create policy "Users can select their rides" on rides
  for select to authenticated
  using (auth.uid() = passenger_uid);

create index if not exists idx_rides_passenger_uid on rides(passenger_uid);
create index if not exists idx_rides_promotion_id on rides(promotion_id);
create index if not exists idx_rides_ride_type on rides(ride_type);

-- Create ride_history table for storing completed/cancelled rides
create table ride_history (
  id uuid primary key,
  passenger_uid uuid references passenger(uid) on delete set null,
  driver_uid uuid references passenger(uid) on delete set null,
  from_address text not null,
  to_address text not null,
  from_lat double precision not null,
  from_lng double precision not null,
  to_lat double precision not null,
  to_lng double precision not null,
  distance_km double precision not null,
  duration_minutes integer not null,
  price double precision not null,
  payment_method text not null,
  ride_type text not null default 'weego', -- 'weego', 'comfort', 'taxi', 'eco', 'woman', 'weegoxl'
  status text not null,
  rating double precision,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  selected_card_id uuid references payment_cards(id) on delete set null,
  wallet_id uuid references passenger_wallets(id) on delete set null,
  promotion_id uuid references promotions(id) on delete set null,
  discount_percent integer,
  original_price double precision,
  driver_amount double precision,
  app_commission double precision,
  currency text NOT NULL DEFAULT 'TND'
);

alter table ride_history enable row level security;

create policy "Users can insert ride history" on ride_history
  for insert to authenticated
  with check (auth.uid() = passenger_uid);

create policy "Users can select their ride history" on ride_history
  for select to authenticated
  using (auth.uid() = passenger_uid);

create index if not exists idx_ride_history_passenger_uid on ride_history(passenger_uid);
create index if not exists idx_ride_history_ride_type on ride_history(ride_type);

-- Add driver_uid column to ride_history table
-- ALTER TABLE ride_history
-- ADD COLUMN driver_uid uuid references passenger(uid) on delete set null;

-- Add subscription columns to passenger table
ALTER TABLE passenger
ADD COLUMN subscription_plan text DEFAULT 'free';

ALTER TABLE passenger
ADD COLUMN subscription_start_date timestamp with time zone;

ALTER TABLE passenger
ADD COLUMN subscription_end_date timestamp with time zone;

-- Create trusted_contacts table
CREATE TABLE trusted_contacts (
  id uuid primary key default uuid_generate_v4(),
  passenger_uid uuid references passenger(uid) on delete cascade,
  name text not null,
  phone text not null,
  email text,
  is_emergency_contact boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Enable RLS for trusted_contacts
ALTER TABLE trusted_contacts ENABLE ROW LEVEL SECURITY;

-- Policies for trusted_contacts
CREATE POLICY "Users can insert their trusted contacts" ON trusted_contacts
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = passenger_uid);

CREATE POLICY "Users can select their trusted contacts" ON trusted_contacts
  FOR SELECT TO authenticated
  USING (auth.uid() = passenger_uid);

CREATE POLICY "Users can update their trusted contacts" ON trusted_contacts
  FOR UPDATE TO authenticated
  USING (auth.uid() = passenger_uid)
  WITH CHECK (auth.uid() = passenger_uid);

CREATE POLICY "Users can delete their trusted contacts" ON trusted_contacts
  FOR DELETE TO authenticated
  USING (auth.uid() = passenger_uid);

-- Create index for trusted_contacts
CREATE INDEX IF NOT EXISTS idx_trusted_contacts_passenger_uid ON trusted_contacts(passenger_uid);

create table saved_locations (
  id uuid primary key default uuid_generate_v4(),
  passenger_uid uuid references passenger(uid) on delete cascade,
  label text not null, -- e.g. 'home', 'work', 'custom'
  address text not null,
  lat double precision not null,
  lng double precision not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table saved_locations enable row level security;

create policy "Users can insert their saved locations" on saved_locations
  for insert to authenticated
  with check (auth.uid() = passenger_uid);

create policy "Users can select their saved locations" on saved_locations
  for select to authenticated
  using (auth.uid() = passenger_uid);

create policy "Users can update their saved locations" on saved_locations
  for update to authenticated
  using (auth.uid() = passenger_uid)
  with check (auth.uid() = passenger_uid);

create policy "Users can delete their saved locations" on saved_locations
  for delete to authenticated
  using (auth.uid() = passenger_uid);

create index if not exists idx_saved_locations_passenger_uid on saved_locations(passenger_uid);

-- Create payment_cards table for storing user's payment cards
-- Only one payment_cards table should exist. Remove any duplicate definitions below this line.
-- (Keep the first correct definition and all its policies and indexes.)

-- Create transactions table for storing payment transactions
create table transactions (
  id uuid primary key default uuid_generate_v4(),
  ride_id uuid references rides(id) on delete cascade,
  card_id uuid references payment_cards(id) on delete cascade,
  wallet_id uuid references passenger_wallets(id) on delete cascade,
  passenger_uid uuid references passenger(uid) on delete cascade,
  driver_uid uuid references passenger(uid) on delete cascade,
  amount double precision not null,
  status text not null default 'pending', -- 'pending', 'completed', 'failed'
  transaction_type text not null, -- 'ride_payment', 'driver_payment', 'refund', etc.
  payment_method text not null, -- 'card', 'wallet', 'cash'
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  currency text NOT NULL DEFAULT 'TND'
);

alter table transactions enable row level security;

-- Policy name: Authenticated can insert transactions
DROP POLICY IF EXISTS "Authenticated users can insert transactions" ON public.transactions;
CREATE POLICY "Authenticated users can insert transactions"
ON public.transactions
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy name: Authenticated can select transactions
DROP POLICY IF EXISTS "Authenticated users can select transactions" ON public.transactions;
CREATE POLICY "Authenticated users can select transactions"
ON public.transactions
FOR SELECT
TO authenticated
USING (true);

-- Create wallet_recharges table for storing recharge history
create table passenger_wallet_recharges (
  id uuid primary key default uuid_generate_v4(),
  wallet_id uuid references passenger_wallets(id) on delete cascade,
  passenger_uid uuid references passenger(uid) on delete cascade,
  amount double precision not null,
  payment_method text not null, -- 'card', 'cash', etc.
  card_id uuid references payment_cards(id) on delete set null,
  status text not null default 'pending', -- 'pending', 'completed', 'failed'
  transaction_id text, -- external payment processor transaction ID
  created_at timestamp with time zone default timezone('utc'::text, now()),
  completed_at timestamp with time zone
);

alter table passenger_wallet_recharges enable row level security;

-- Policy name: Authenticated can insert wallet recharges
DROP POLICY IF EXISTS "Authenticated users can insert wallet recharges" ON public.passenger_wallet_recharges;
CREATE POLICY "Authenticated users can insert wallet recharges"
ON public.passenger_wallet_recharges
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy name: Authenticated can select wallet recharges
DROP POLICY IF EXISTS "Authenticated users can select wallet recharges" ON public.passenger_wallet_recharges;
CREATE POLICY "Authenticated users can select wallet recharges"
ON public.passenger_wallet_recharges
FOR SELECT
TO authenticated
USING (true);

-- Policy name: Authenticated can update wallet recharges
DROP POLICY IF EXISTS "Authenticated users can update wallet recharges" ON public.passenger_wallet_recharges;
CREATE POLICY "Authenticated users can update wallet recharges"
ON public.passenger_wallet_recharges
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Function to automatically create wallet for new passenger
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO passenger_wallets (passenger_uid, balance, currency)
  VALUES (NEW.uid, 0.0, 'TND');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create wallet when passenger is created
CREATE TRIGGER create_wallet_on_user_insert
  AFTER INSERT ON passenger
  FOR EACH ROW
  EXECUTE FUNCTION create_user_wallet();

-- Function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance(
  p_wallet_id uuid,
  p_amount double precision,
  p_transaction_type text,
  p_description text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_reference_type text DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
  current_balance double precision;
  new_balance double precision;
BEGIN
  -- Get current balance
  SELECT balance INTO current_balance
  FROM passenger_wallets
  WHERE id = p_wallet_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Calculate new balance
  new_balance := current_balance + p_amount;
  
  -- Update wallet balance
  UPDATE passenger_wallets
  SET balance = new_balance,
      updated_at = now()
  WHERE id = p_wallet_id;
  
  -- Insert transaction record
  INSERT INTO passenger_wallet_transactions (
    wallet_id,
    passenger_uid,
    amount,
    transaction_type,
    description,
    reference_id,
    reference_type,
    balance_before,
    balance_after,
    status
  )
  SELECT 
    p_wallet_id,
    passenger_uid,
    p_amount,
    p_transaction_type,
    p_description,
    p_reference_id,
    p_reference_type,
    current_balance,
    new_balance,
    'completed'
  FROM passenger_wallets
  WHERE id = p_wallet_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to get ETA of closest available driver for a ride type
create or replace function get_closest_driver_eta(
  p_lat double precision,
  p_lng double precision,
  p_ride_type text
)
returns integer
language plpgsql
as $$
declare
  closest_eta integer := 10; -- default fallback
begin
  select
    ceil(
      (point(lat, lng) <@> point(p_lat, p_lng)) * 1.60934 * 60 / 40
    )::integer
  into closest_eta
  from drivers
  where is_available = true and is_online = true and ride_type = p_ride_type
  order by (point(lat, lng) <@> point(p_lat, p_lng))
  limit 1;

  return coalesce(closest_eta, 10);
end;
$$;

-- Function to get closest available drivers for a ride type
create or replace function get_closest_drivers(
  p_lat double precision,
  p_lng double precision,
  p_ride_type text,
  p_limit integer default 5
)
returns table(
  driver_uid uuid,
  distance_km double precision,
  eta_minutes integer,
  driver_rating numeric
)
language plpgsql
as $$
begin
  return query
  select 
    d.passenger_uid,
    (point(d.lat, d.lng) <@> point(p_lat, p_lng)) * 1.60934 as distance_km,
    ceil((point(d.lat, d.lng) <@> point(p_lat, p_lng)) * 1.60934 * 60 / 40)::integer as eta_minutes,
    d.rating as driver_rating
  from drivers d
  where d.is_available = true 
    and d.is_online = true 
    and d.ride_type = p_ride_type
    and d.current_ride_id is null
  order by (point(d.lat, d.lng) <@> point(p_lat, p_lng))
  limit p_limit;
end;
$$;

-- Insert sample promotions
INSERT INTO promotions (code, title, description, percent, start_date, end_date, max_uses) VALUES
('FIRSTRIDE', 'First Ride Discount', 'Get 50% off on your first ride with Weego', 50, '2024-01-01 00:00:00+00', '2024-12-31 23:59:59+00', 1),
('WEEKEND20', 'Weekend Special', '20% off on all weekend rides', 20, '2024-01-01 00:00:00+00', '2025-01-31 23:59:59+00', 5),
('LOYALTY15', 'Loyalty Reward', '15% off for our loyal customers', 15, '2024-01-01 00:00:00+00', '2025-02-28 23:59:59+00', 3),
('SUMMER25', 'Summer Special', '25% off summer rides', 25, '2024-06-01 00:00:00+00', '2024-09-30 23:59:59+00', 10);

-- Insert sample drivers for testing
-- Note: These are test drivers. In production, drivers would register through the app
INSERT INTO drivers (passenger_uid, is_available, is_online, lat, lng, ride_type, vehicle_info, rating, total_rides) VALUES
-- Weego drivers
('550e8400-e29b-41d4-a716-446655440001', true, true, 36.8065, 10.1815, 'weego', '{"model": "Toyota Corolla", "color": "White", "plate": "123-TUN-456"}', 4.8, 150),
('550e8400-e29b-41d4-a716-446655440002', true, true, 36.8065, 10.1815, 'weego', '{"model": "Renault Clio", "color": "Blue", "plate": "789-TUN-012"}', 4.6, 89),
('550e8400-e29b-41d4-a716-446655440003', true, true, 36.8065, 10.1815, 'weego', '{"model": "Peugeot 208", "color": "Red", "plate": "345-TUN-678"}', 4.9, 234),

-- Comfort drivers
('550e8400-e29b-41d4-a716-446655440004', true, true, 36.8065, 10.1815, 'comfort', '{"model": "Mercedes C-Class", "color": "Black", "plate": "901-TUN-234"}', 4.7, 67),
('550e8400-e29b-41d4-a716-446655440005', true, true, 36.8065, 10.1815, 'comfort', '{"model": "BMW 3 Series", "color": "Silver", "plate": "567-TUN-890"}', 4.5, 123),

-- Taxi drivers
('550e8400-e29b-41d4-a716-446655440006', true, true, 36.8065, 10.1815, 'taxi', '{"model": "Traditional Taxi", "color": "Yellow", "plate": "TUN-123"}', 4.3, 456),
('550e8400-e29b-41d4-a716-446655440007', true, true, 36.8065, 10.1815, 'taxi', '{"model": "Traditional Taxi", "color": "Yellow", "plate": "TUN-456"}', 4.4, 234),

-- Eco drivers
('550e8400-e29b-41d4-a716-446655440008', true, true, 36.8065, 10.1815, 'eco', '{"model": "Tesla Model 3", "color": "White", "plate": "ECO-001"}', 4.9, 89),
('550e8400-e29b-41d4-a716-446655440009', true, true, 36.8065, 10.1815, 'eco', '{"model": "Nissan Leaf", "color": "Blue", "plate": "ECO-002"}', 4.7, 156),

-- Woman drivers
('550e8400-e29b-41d4-a716-446655440010', true, true, 36.8065, 10.1815, 'woman', '{"model": "Toyota Yaris", "color": "Pink", "plate": "WOM-001"}', 4.8, 78),
('550e8400-e29b-41d4-a716-446655440011', true, true, 36.8065, 10.1815, 'woman', '{"model": "Fiat 500", "color": "Purple", "plate": "WOM-002"}', 4.6, 92),

-- WeegoXL drivers
('550e8400-e29b-41d4-a716-446655440012', true, true, 36.8065, 10.1815, 'weegoxl', '{"model": "Mercedes Vito", "color": "Black", "plate": "XL-001"}', 4.5, 45),
('550e8400-e29b-41d4-a716-446655440013', true, true, 36.8065, 10.1815, 'weegoxl', '{"model": "Ford Transit", "color": "White", "plate": "XL-002"}', 4.4, 67);