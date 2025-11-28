
CREATE TABLE IF NOT EXISTS surge_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    city VARCHAR(100) NOT NULL,
    center_lat DOUBLE PRECISION NOT NULL,
    center_lng DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 2000, -- 2km default radius
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Surge Events Table - Tracks when surge pricing is active
CREATE TABLE IF NOT EXISTS surge_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    surge_zone_id UUID REFERENCES surge_zones(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- 'demand_high', 'weather', 'event', 'traffic'
    event_name VARCHAR(255), -- e.g., 'Concert at Arena', 'Heavy Rain'
    base_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.0, -- Base surge multiplier
    driver_bonus_per_ride DECIMAL(5,2) NOT NULL DEFAULT 0.0, -- Bonus for subscribed drivers
    max_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.5, -- Maximum allowed multiplier
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Surge Pricing Rules Table - Defines pricing rules for different scenarios
CREATE TABLE IF NOT EXISTS surge_pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(2) NOT NULL,
    rule_type VARCHAR(50) NOT NULL, -- 'demand_high', 'weather', 'event', 'traffic', 'night'
    min_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    max_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.5,
    driver_bonus_base DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    driver_bonus_per_km DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    subscription_discount_percent DECIMAL(3,1) DEFAULT 0.0, -- Discount for subscribed riders (saver/premium)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. SurgePass Subscriptions Table - REMOVED (using existing subscription system)
-- The app uses the existing passenger.subscription_plan field for discounts

-- 5. Surge Pricing History Table - Tracks all surge pricing applications
CREATE TABLE IF NOT EXISTS surge_pricing_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID, -- References the ride when it's created
    passenger_uid UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    driver_uid UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    surge_event_id UUID REFERENCES surge_events(id) ON DELETE SET NULL,
    base_price DECIMAL(8,2) NOT NULL,
    surge_multiplier DECIMAL(3,2) NOT NULL,
    final_price DECIMAL(8,2) NOT NULL,
    driver_bonus DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    subscription_discount DECIMAL(8,2) NOT NULL DEFAULT 0.0,
    location_lat DOUBLE PRECISION NOT NULL,
    location_lng DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Driver Surge Bonuses Table - Tracks bonuses paid to drivers
CREATE TABLE IF NOT EXISTS driver_surge_bonuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_uid UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ride_id UUID, -- References the ride when it's created
    surge_event_id UUID REFERENCES surge_events(id) ON DELETE SET NULL,
    bonus_amount DECIMAL(5,2) NOT NULL,
    bonus_type VARCHAR(50) NOT NULL, -- 'hot_zone', 'demand_bonus', 'weather_bonus'
    is_paid BOOLEAN DEFAULT false,
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Surge Analytics Table - For tracking surge pricing effectiveness
CREATE TABLE IF NOT EXISTS surge_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    surge_zone_id UUID REFERENCES surge_zones(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    hour INTEGER NOT NULL, -- 0-23
    total_rides INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0.0,
    total_driver_bonuses DECIMAL(10,2) DEFAULT 0.0,
    avg_multiplier DECIMAL(3,2) DEFAULT 1.0,
    driver_satisfaction_score DECIMAL(3,2), -- 1.0-5.0
    rider_satisfaction_score DECIMAL(3,2), -- 1.0-5.0
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_surge_zones_country_city ON surge_zones(country_code, city);
CREATE INDEX IF NOT EXISTS idx_surge_zones_location ON surge_zones USING GIST (
    ll_to_earth(center_lat, center_lng)
);
CREATE INDEX IF NOT EXISTS idx_surge_events_active ON surge_events(is_active, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_surge_events_zone ON surge_events(surge_zone_id);
CREATE INDEX IF NOT EXISTS idx_surge_pricing_rules_country ON surge_pricing_rules(country_code, rule_type);
-- SurgePass index removed - using existing subscription system
CREATE INDEX IF NOT EXISTS idx_surge_history_passenger ON surge_pricing_history(passenger_uid, created_at);
CREATE INDEX IF NOT EXISTS idx_surge_history_driver ON surge_pricing_history(driver_uid, created_at);
CREATE INDEX IF NOT EXISTS idx_driver_bonuses_driver ON driver_surge_bonuses(driver_uid, is_paid);
CREATE INDEX IF NOT EXISTS idx_surge_analytics_zone_date ON surge_analytics(surge_zone_id, date, hour);

-- Enable Row Level Security
ALTER TABLE surge_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE surge_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE surge_pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE surge_pass_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE surge_pricing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_surge_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE surge_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Surge zones: Read-only for all authenticated users
CREATE POLICY "Users can view surge zones" ON surge_zones
    FOR SELECT USING (auth.role() = 'authenticated');

-- Surge events: Read-only for all authenticated users
CREATE POLICY "Users can view surge events" ON surge_events
    FOR SELECT USING (auth.role() = 'authenticated');

-- Surge pricing rules: Read-only for all authenticated users
CREATE POLICY "Users can view surge pricing rules" ON surge_pricing_rules
    FOR SELECT USING (auth.role() = 'authenticated');

-- SurgePass subscriptions: Users can manage their own subscriptions
CREATE POLICY "Users can manage their surge pass subscriptions" ON surge_pass_subscriptions
    FOR ALL USING (auth.uid() = passenger_uid);

-- Surge pricing history: Users can view their own history
CREATE POLICY "Users can view their surge pricing history" ON surge_pricing_history
    FOR SELECT USING (auth.uid() = passenger_uid OR auth.uid() = driver_uid);

-- Driver bonuses: Drivers can view their own bonuses
CREATE POLICY "Drivers can view their bonuses" ON driver_surge_bonuses
    FOR SELECT USING (auth.uid() = driver_uid);

-- Surge analytics: Read-only for authenticated users
CREATE POLICY "Users can view surge analytics" ON surge_analytics
    FOR SELECT USING (auth.role() = 'authenticated');

-- Insert default surge pricing rules
INSERT INTO surge_pricing_rules (country_code, rule_type, min_multiplier, max_multiplier, driver_bonus_base, driver_bonus_per_km, subscription_discount_percent, surge_pass_discount_percent) VALUES
('FR', 'demand_high', 1.1, 1.4, 2.0, 0.1, 5.0, 100.0),
('FR', 'weather', 1.05, 1.3, 1.5, 0.05, 3.0, 100.0),
('FR', 'event', 1.2, 1.5, 3.0, 0.15, 10.0, 100.0),
('FR', 'traffic', 1.05, 1.25, 1.0, 0.05, 2.0, 100.0),
('FR', 'night', 1.1, 1.3, 1.5, 0.08, 5.0, 100.0),

('EE', 'demand_high', 1.1, 1.4, 1.5, 0.08, 5.0, 100.0),
('EE', 'weather', 1.05, 1.3, 1.0, 0.05, 3.0, 100.0),
('EE', 'event', 1.2, 1.5, 2.5, 0.12, 10.0, 100.0),
('EE', 'traffic', 1.05, 1.25, 0.8, 0.05, 2.0, 100.0),
('EE', 'night', 1.1, 1.3, 1.2, 0.06, 5.0, 100.0),

('LV', 'demand_high', 1.1, 1.4, 1.2, 0.06, 5.0, 100.0),
('LV', 'weather', 1.05, 1.3, 0.8, 0.04, 3.0, 100.0),
('LV', 'event', 1.2, 1.5, 2.0, 0.10, 10.0, 100.0),
('LV', 'traffic', 1.05, 1.25, 0.6, 0.04, 2.0, 100.0),
('LV', 'night', 1.1, 1.3, 1.0, 0.05, 5.0, 100.0),

('LT', 'demand_high', 1.1, 1.4, 1.3, 0.07, 5.0, 100.0),
('LT', 'weather', 1.05, 1.3, 0.9, 0.05, 3.0, 100.0),
('LT', 'event', 1.2, 1.5, 2.2, 0.11, 10.0, 100.0),
('LT', 'traffic', 1.05, 1.25, 0.7, 0.04, 2.0, 100.0),
('LT', 'night', 1.1, 1.3, 1.1, 0.06, 5.0, 100.0),

('TN', 'demand_high', 1.1, 1.4, 1.0, 0.05, 5.0, 100.0),
('TN', 'weather', 1.05, 1.3, 0.7, 0.04, 3.0, 100.0),
('TN', 'event', 1.2, 1.5, 1.8, 0.09, 10.0, 100.0),
('TN', 'traffic', 1.05, 1.25, 0.5, 0.03, 2.0, 100.0),
('TN', 'night', 1.1, 1.3, 0.9, 0.05, 5.0, 100.0)
ON CONFLICT DO NOTHING;

-- Functions for surge pricing calculations

-- Function to check if a location is within a surge zone
CREATE OR REPLACE FUNCTION is_in_surge_zone(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_country_code VARCHAR(2)
) RETURNS TABLE(
    zone_id UUID,
    zone_name VARCHAR(255),
    event_id UUID,
    event_type VARCHAR(50),
    event_name VARCHAR(255),
    base_multiplier DECIMAL(3,2),
    driver_bonus_per_ride DECIMAL(5,2),
    max_multiplier DECIMAL(3,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sz.id as zone_id,
        sz.name as zone_name,
        se.id as event_id,
        se.event_type,
        se.event_name,
        se.base_multiplier,
        se.driver_bonus_per_ride,
        se.max_multiplier
    FROM surge_zones sz
    JOIN surge_events se ON sz.id = se.surge_zone_id
    WHERE sz.country_code = p_country_code
        AND sz.is_active = true
        AND se.is_active = true
        AND NOW() BETWEEN se.start_time AND se.end_time
        AND earth_distance(
            ll_to_earth(sz.center_lat, sz.center_lng),
            ll_to_earth(p_lat, p_lng)
        ) <= sz.radius_meters;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate surge pricing for a ride
CREATE OR REPLACE FUNCTION calculate_surge_pricing(
    p_passenger_uid UUID,
    p_driver_uid UUID,
    p_base_price DECIMAL(8,2),
    p_distance_km DECIMAL(5,2),
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_country_code VARCHAR(2)
) RETURNS TABLE(
    final_price DECIMAL(8,2),
    surge_multiplier DECIMAL(3,2),
    driver_bonus DECIMAL(5,2),
    subscription_discount DECIMAL(8,2),
    surge_event_id UUID,
    pricing_breakdown JSONB
) AS $$
DECLARE
    v_surge_multiplier DECIMAL(3,2) := 1.0;
    v_driver_bonus DECIMAL(5,2) := 0.0;
    v_subscription_discount DECIMAL(8,2) := 0.0;
    v_surge_event_id UUID := NULL;
    v_has_subscription BOOLEAN := false;
    v_subscription_type VARCHAR(20);
    v_surge_zone RECORD;
    v_pricing_rule RECORD;
    v_final_price DECIMAL(8,2);
    v_breakdown JSONB;
BEGIN
    -- Check for active surge zone
    SELECT * INTO v_surge_zone
    FROM is_in_surge_zone(p_lat, p_lng, p_country_code)
    LIMIT 1;
    
    IF v_surge_zone IS NOT NULL THEN
        v_surge_multiplier := v_surge_zone.base_multiplier;
        v_driver_bonus := v_surge_zone.driver_bonus_per_ride;
        v_surge_event_id := v_surge_zone.event_id;
        
        -- Get pricing rule for this event type
        SELECT * INTO v_pricing_rule
        FROM surge_pricing_rules
        WHERE country_code = p_country_code 
            AND rule_type = v_surge_zone.event_type
            AND is_active = true;
            
        IF v_pricing_rule IS NOT NULL THEN
            -- Apply distance-based driver bonus
            v_driver_bonus := v_driver_bonus + (p_distance_km * v_pricing_rule.driver_bonus_per_km);
            
            -- Ensure multiplier is within bounds
            v_surge_multiplier := GREATEST(v_pricing_rule.min_multiplier, 
                                         LEAST(v_surge_multiplier, v_pricing_rule.max_multiplier));
        END IF;
    END IF;
    
    -- Check for rider subscription
    SELECT subscription_plan INTO v_subscription_type
    FROM passenger
    WHERE id = p_passenger_uid;
    
    v_has_subscription := v_subscription_type IS NOT NULL AND v_subscription_type != 'free';
    
    -- SurgePass check removed - using existing subscription system
    
    -- Calculate final price
    v_final_price := p_base_price * v_surge_multiplier;
    
    -- Apply subscription discount
    IF v_has_subscription AND v_surge_zone IS NOT NULL THEN
        v_subscription_discount := v_final_price * (v_pricing_rule.subscription_discount_percent / 100.0);
        v_final_price := v_final_price - v_subscription_discount;
    END IF;
    
    -- SurgePass discount removed - using existing subscription system
    
    -- Create pricing breakdown
    v_breakdown := jsonb_build_object(
        'base_price', p_base_price,
        'surge_multiplier', v_surge_multiplier,
        'surge_amount', p_base_price * (v_surge_multiplier - 1.0),
        'driver_bonus', v_driver_bonus,
        'subscription_discount', v_subscription_discount,
        'has_subscription', v_has_subscription,
        'surge_zone_name', COALESCE(v_surge_zone.zone_name, ''),
        'event_type', COALESCE(v_surge_zone.event_type, ''),
        'event_name', COALESCE(v_surge_zone.event_name, '')
    );
    
    RETURN QUERY SELECT 
        v_final_price,
        v_surge_multiplier,
        v_driver_bonus,
        v_subscription_discount,
        v_surge_event_id,
        v_breakdown;
END;
$$ LANGUAGE plpgsql;

-- Function to record surge pricing for a ride
CREATE OR REPLACE FUNCTION record_surge_pricing(
    p_ride_id UUID,
    p_passenger_uid UUID,
    p_driver_uid UUID,
    p_surge_event_id UUID,
    p_base_price DECIMAL(8,2),
    p_surge_multiplier DECIMAL(3,2),
    p_final_price DECIMAL(8,2),
    p_driver_bonus DECIMAL(5,2),
    p_subscription_discount DECIMAL(8,2),
    p_location_lat DOUBLE PRECISION,
    p_location_lng DOUBLE PRECISION
) RETURNS UUID AS $$
DECLARE
    v_history_id UUID;
BEGIN
    INSERT INTO surge_pricing_history (
        ride_id, passenger_uid, driver_uid, surge_event_id,
        base_price, surge_multiplier, final_price, driver_bonus,
        subscription_discount,
        location_lat, location_lng
    ) VALUES (
        p_ride_id, p_passenger_uid, p_driver_uid, p_surge_event_id,
        p_base_price, p_surge_multiplier, p_final_price, p_driver_bonus,
        p_subscription_discount,
        p_location_lat, p_location_lng
    ) RETURNING id INTO v_history_id;
    
    -- Record driver bonus if applicable
    IF p_driver_bonus > 0 THEN
        INSERT INTO driver_surge_bonuses (
            driver_uid, ride_id, surge_event_id, bonus_amount, bonus_type
        ) VALUES (
            p_driver_uid, p_ride_id, p_surge_event_id, p_driver_bonus, 'surge_bonus'
        );
    END IF;
    
    RETURN v_history_id;
END;
$$ LANGUAGE plpgsql; 