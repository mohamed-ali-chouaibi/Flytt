-- 1. Create driver table (without primary_vehicle_id for now)
create table driver (
  id uuid primary key default uuid_generate_v4(),
  uid uuid unique, -- Link to auth.uid, same as passenger
  name text not null,
  surname text not null,
  email text not null unique,
  profile_image_url text,
  phone text not null unique,
  rating numeric default 5.0,
  number_of_rides integer default 0,
  -- Add location and ride type for ETA calculation
  lat double precision,
  lng double precision,
  ride_type text,
  is_available boolean default false,
  is_verified boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Table: vehicles
create table vehicles (
  id uuid primary key default uuid_generate_v4(),
  driver_uid uuid references driver(uid) on delete cascade,
  name text not null,
  model text,
  plate text,
  color text,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table driver enable row level security;

-- Policy: Authenticated users can insert
drop policy if exists "Authenticated users can insert" on public.driver;
create policy "Authenticated users can insert"
on public.driver
for insert
to authenticated
with check (true);

-- Policy: Authenticated users can select
drop policy if exists "Authenticated users can select" on public.driver;
create policy "Authenticated users can select"
on public.driver
for select
to authenticated
using (true);

-- Policy: Authenticated users can update
drop policy if exists "Authenticated users can update" on public.driver;
create policy "Authenticated users can update"
on public.driver
for update
to authenticated
using (auth.uid() = uid)
with check (auth.uid() = uid);

-- Policy: Authenticated users can delete their own driver record
drop policy if exists "Authenticated users can delete" on public.driver;
create policy "Authenticated users can delete"
on public.driver
for delete
to authenticated
using (auth.uid() = uid);

-- Indexes for performance
create index if not exists idx_driver_uid on driver(uid);
create index if not exists idx_driver_phone on driver(phone);

-- 2. Driver documents table (for storing driver docs)
create table driver_documents (
  id uuid primary key default uuid_generate_v4(),
  driver_uid uuid references driver(uid) on delete cascade,
  document_type text not null, -- e.g. 'license', 'insurance', 'registration'
  document_url text not null,
  uploaded_at timestamp with time zone default timezone('utc'::text, now()),
  expires_at date,
  license_number text,
  license_expiry date
);

alter table driver_documents enable row level security;

create policy "Users can insert their driver documents" on driver_documents
  for insert to authenticated
  with check (auth.uid() = driver_uid);

create policy "Users can select their driver documents" on driver_documents
  for select to authenticated
  using (auth.uid() = driver_uid);

create policy "Users can update their driver documents" on driver_documents
  for update to authenticated
  using (auth.uid() = driver_uid)
  with check (auth.uid() = driver_uid);

create policy "Users can delete their driver documents" on driver_documents
  for delete to authenticated
  using (auth.uid() = driver_uid);

create index if not exists idx_driver_documents_driver_uid on driver_documents(driver_uid);

-- Table: driver_earnings
create table driver_earnings (
  id uuid primary key default uuid_generate_v4(),
  driver_uid uuid references driver(uid) on delete cascade,
  date date not null, -- The day this earning record is for
  total_earnings double precision not null default 0.0,
  week_earnings double precision not null default 0.0,
  month_earnings double precision not null default 0.0,
  trip_earnings double precision not null default 0.0,
  tip double precision not null default 0.0,
  trip_count integer not null default 0,
  time_online interval,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  -- Add unique constraint to ensure one record per driver per day
  unique(driver_uid, date)
);

-- Index for fast lookup
create index if not exists idx_driver_earnings_driver_uid on driver_earnings(driver_uid);
create index if not exists idx_driver_earnings_date on driver_earnings(date);

-- Enable RLS
alter table driver_earnings enable row level security;

-- Policy: Authenticated drivers can insert their own earnings
create policy "Drivers can insert their earnings" on driver_earnings
  for insert to authenticated
  with check (auth.uid() = driver_uid);

-- Policy: Authenticated drivers can select their own earnings
create policy "Drivers can select their earnings" on driver_earnings
  for select to authenticated
  using (auth.uid() = driver_uid);

-- Policy: Authenticated drivers can update their own earnings
create policy "Drivers can update their earnings" on driver_earnings
  for update to authenticated
  using (auth.uid() = driver_uid)
  with check (auth.uid() = driver_uid);

-- Table: driver_withdrawals
create table driver_withdrawals (
  id uuid primary key default uuid_generate_v4(),
  driver_uid uuid references driver(uid) on delete cascade,
  wallet_id uuid references driver_wallets(id) on delete cascade,
  card_id uuid references payment_cards(id) on delete set null,
  amount double precision not null,
  status text not null default 'completed',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create index if not exists idx_driver_withdrawals_driver_uid on driver_withdrawals(driver_uid);
create index if not exists idx_driver_withdrawals_wallet_id on driver_withdrawals(wallet_id);

alter table driver_withdrawals enable row level security;

create policy "Drivers can insert their withdrawals" on driver_withdrawals
  for insert to authenticated
  with check (auth.uid() = driver_uid);

create policy "Drivers can select their withdrawals" on driver_withdrawals
  for select to authenticated
  using (auth.uid() = driver_uid);

-- Add primary_vehicle_id to driver after both tables exist
alter table driver
  add column primary_vehicle_id uuid,
  add constraint fk_primary_vehicle
    foreign key (primary_vehicle_id) references vehicles(id);

create index if not exists idx_vehicles_driver_uid on vehicles(driver_uid);

alter table vehicles enable row level security;

create policy "Drivers can insert their vehicles" on vehicles
  for insert to authenticated
  with check (auth.uid() = driver_uid);

create policy "Drivers can select their vehicles" on vehicles
  for select to authenticated
  using (auth.uid() = driver_uid);

create policy "Drivers can update their vehicles" on vehicles
  for update to authenticated
  using (auth.uid() = driver_uid)
  with check (auth.uid() = driver_uid);

create policy "Drivers can delete their vehicles" on vehicles
  for delete to authenticated
  using (auth.uid() = driver_uid);

-- Table: driver_requests
create table driver_requests (
  id uuid primary key default uuid_generate_v4(),
  ride_id uuid references rides(id) on delete cascade,
  driver_uid uuid references driver(uid) on delete cascade,
  status text not null default 'pending', -- 'pending', 'accepted', 'rejected', 'expired'
  requested_at timestamp with time zone default timezone('utc'::text, now()),
  responded_at timestamp with time zone,
  response_time_ms integer, -- How long it took driver to respond
  distance_km double precision, -- Distance from driver to pickup
  eta_minutes integer -- Estimated time of arrival
);

alter table driver_requests enable row level security;

create policy "Users can view driver requests" on driver_requests
  for select to authenticated
  using (true);

create policy "Drivers can update their requests" on driver_requests
  for update to authenticated
  using (auth.uid() = driver_uid)
  with check (auth.uid() = driver_uid);

create policy "System can insert driver requests" on driver_requests
  for insert to authenticated
  with check (true);

create index if not exists idx_driver_requests_ride_id on driver_requests(ride_id);
create index if not exists idx_driver_requests_driver_uid on driver_requests(driver_uid);
create index if not exists idx_driver_requests_status on driver_requests(status);

-- You may add more driver-specific tables (e.g., earnings, schedules) as needed.

-- Function: get_closest_drivers
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
    d.uid as driver_uid,
    (point(d.lat, d.lng) <@> point(p_lat, p_lng)) * 1.60934 as distance_km,
    ceil((point(d.lat, d.lng) <@> point(p_lat, p_lng)) * 1.60934 * 60 / 40)::integer as eta_minutes,
    d.rating as driver_rating
  from driver d
  where d.is_available = true 
    and d.ride_type = p_ride_type
    and is_online = 
    and d.lat is not null
    and d.lng is not null
  order by (point(d.lat, d.lng) <@> point(p_lat, p_lng))
  limit p_limit;
end;
$$;
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

-- Table: driver_wallets
create table driver_wallets (
  id uuid primary key default uuid_generate_v4(),
  driver_uid uuid references driver(uid) on delete cascade unique,
  balance double precision not null default 0.0,
  currency text not null default 'TND',
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

alter table driver_wallets enable row level security;

create policy "Drivers can insert their driver wallet" on driver_wallets
  for insert to authenticated
  with check (auth.uid() = driver_uid);

create policy "Drivers can select their driver wallet" on driver_wallets
  for select to authenticated
  using (auth.uid() = driver_uid);

create policy "Drivers can update their driver wallet" on driver_wallets
  for update to authenticated
  using (auth.uid() = driver_uid)
  with check (auth.uid() = driver_uid);

create index if not exists idx_driver_wallets_driver_uid on driver_wallets(driver_uid);

-- Table: driver_wallet_transactions
create table driver_wallet_transactions (
  id uuid primary key default uuid_generate_v4(),
  wallet_id uuid references driver_wallets(id) on delete cascade,
  driver_uid uuid references driver(uid) on delete cascade,
  amount double precision not null,
  transaction_type text not null, -- 'ride_earning', 'withdrawal', 'bonus', etc.
  description text,
  reference_id uuid, -- ride_id, withdrawal_id, etc.
  reference_type text, -- 'ride', 'withdrawal', etc.
  balance_before double precision not null,
  balance_after double precision not null,
  status text not null default 'completed', -- 'pending', 'completed', 'failed'
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table driver_wallet_transactions enable row level security;

create policy "Drivers can insert their driver wallet transactions" on driver_wallet_transactions
  for insert to authenticated
  with check (auth.uid() = driver_uid);

create policy "Drivers can select their driver wallet transactions" on driver_wallet_transactions
  for select to authenticated
  using (auth.uid() = driver_uid);

create index if not exists idx_driver_wallet_transactions_driver_uid on driver_wallet_transactions(driver_uid);

-- Function to automatically create driver wallet for new driver
CREATE OR REPLACE FUNCTION create_driver_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO driver_wallets (driver_uid, balance, currency)
  VALUES (NEW.uid, 0.0, 'TND');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create driver wallet when driver is created
CREATE TRIGGER create_driver_wallet_on_driver_insert
  AFTER INSERT ON driver
  FOR EACH ROW
  EXECUTE FUNCTION create_driver_wallet();