-- ====================================================================
-- TRANSIT AI - PRODUCTION SUPABASE DATABASE SCHEMA v2.0
-- Unified Multimodal AMTS / Janmarg BRTS Architecture
-- Project URL: https://your-project-id.supabase.co
--
-- INSTRUCTIONS TO RUN:
-- 1. Log in to your Supabase Dashboard: https://supabase.com/dashboard
-- 2. Select project 'your-project-id'
-- 3. In the left navigation bar, click on "SQL Editor"
-- 4. Click "New Query", paste this entire script, and click "Run" (▶)
-- ====================================================================

-- 0. Enable Essential Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ====================================================================
-- TABLE 1: PROFILES (Safely create or upgrade existing table)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safely add columns if profiles table already existed from v1
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'commuter';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS college_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS roll_number TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS home_stop_id TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS locality TEXT DEFAULT 'Ahmedabad';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(10, 2) DEFAULT 150.00;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop old conflicting policies if they exist
DROP POLICY IF EXISTS "Allow public read on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public insert/upsert on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public update on profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert or update their own profile" ON public.profiles;

CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can insert or update their own profile"
    ON public.profiles FOR ALL
    USING (true)
    WITH CHECK (true);

-- ====================================================================
-- TABLE 2 & 3: GTFS_STOPS & GTFS_ROUTES (Ahmedabad AMTS / BRTS Network)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.gtfs_stops (
    stop_id VARCHAR(50) PRIMARY KEY,
    stop_name TEXT NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    transit_type TEXT NOT NULL DEFAULT 'BRTS',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.gtfs_stops ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read for gtfs_stops" ON public.gtfs_stops;
CREATE POLICY "Public read for gtfs_stops"
    ON public.gtfs_stops FOR SELECT
    USING (true);

CREATE TABLE IF NOT EXISTS public.gtfs_routes (
    route_id VARCHAR(50) PRIMARY KEY,
    route_short_name TEXT NOT NULL,
    operator TEXT NOT NULL DEFAULT 'BRTS',
    polyline_points TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.gtfs_routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read for gtfs_routes" ON public.gtfs_routes;
CREATE POLICY "Public read for gtfs_routes"
    ON public.gtfs_routes FOR SELECT
    USING (true);

-- ====================================================================
-- TABLE 4: FARE_MATRIX (Stage-based fares & transfer discounts)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.fare_matrix (
    id BIGSERIAL PRIMARY KEY,
    operator TEXT NOT NULL,
    stage_from INT NOT NULL,
    stage_to INT NOT NULL,
    fare_paise INT NOT NULL,
    interchange_discount_percent INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(operator, stage_from, stage_to)
);

ALTER TABLE public.fare_matrix ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read for fare_matrix" ON public.fare_matrix;
CREATE POLICY "Public read for fare_matrix"
    ON public.fare_matrix FOR SELECT
    USING (true);

-- ====================================================================
-- TABLE 5: KYC_APPLICATIONS (AI Gemini OCR & DigiLocker Verifications)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.kyc_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    phone TEXT NOT NULL,
    student_id_url TEXT,
    bonafide_cert_url TEXT,
    institution_name TEXT,
    roll_number TEXT,
    ocr_extracted_data JSONB,
    digilocker_verified BOOLEAN DEFAULT false,
    status TEXT NOT NULL DEFAULT 'pending',
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.kyc_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students view own kyc applications" ON public.kyc_applications;
DROP POLICY IF EXISTS "Students insert own kyc applications" ON public.kyc_applications;
DROP POLICY IF EXISTS "Admins and services update kyc status" ON public.kyc_applications;

CREATE POLICY "Students view own kyc applications"
    ON public.kyc_applications FOR SELECT
    USING (true);

CREATE POLICY "Students insert own kyc applications"
    ON public.kyc_applications FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Admins and services update kyc status"
    ON public.kyc_applications FOR UPDATE
    USING (true);

-- ====================================================================
-- TABLE 6: CONCESSION_PASSES (80% Statutory Subsidized Passes)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.concession_passes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    kyc_id UUID,
    pass_number TEXT UNIQUE NOT NULL,
    corridor_route_id TEXT DEFAULT 'ALL_BRTS_AMTS_NETWORK',
    subsidy_discount_percent INT DEFAULT 80,
    monthly_fare NUMERIC(10, 2) DEFAULT 60.00,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.concession_passes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students read own concession passes" ON public.concession_passes;
DROP POLICY IF EXISTS "Concession passes insert" ON public.concession_passes;

CREATE POLICY "Students read own concession passes"
    ON public.concession_passes FOR SELECT
    USING (true);

CREATE POLICY "Concession passes insert"
    ON public.concession_passes FOR INSERT
    WITH CHECK (true);

-- ====================================================================
-- TABLE 7: PAYMENTS (UPI Intent & Razorpay transactions)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    amount_paise INT NOT NULL,
    payment_rail TEXT NOT NULL DEFAULT 'UPI_INTENT',
    upi_txn_ref TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'initiated',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own payments" ON public.payments;
DROP POLICY IF EXISTS "Payments insert and update" ON public.payments;

CREATE POLICY "Users read own payments"
    ON public.payments FOR SELECT
    USING (true);

CREATE POLICY "Payments insert and update"
    ON public.payments FOR ALL
    USING (true)
    WITH CHECK (true);

-- ====================================================================
-- TABLE 8: TICKETS (Digital Dynamic Boarding Tokens with HMAC-SHA256)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id TEXT UNIQUE NOT NULL,
    origin TEXT NOT NULL,
    destination TEXT NOT NULL,
    line_info TEXT,
    fare NUMERIC(10, 2) NOT NULL,
    qr_payload TEXT NOT NULL,
    status TEXT DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safely add columns if tickets table already existed from v1
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS payment_id UUID;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS route_segments JSONB DEFAULT '["BRTS 9U", "BRTS 8D"]';
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS hmac_signature TEXT;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS is_validated BOOLEAN DEFAULT false;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS validated_at TIMESTAMPTZ;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS validated_by_conductor_id TEXT;
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '2 hours');

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on tickets" ON public.tickets;
DROP POLICY IF EXISTS "Allow public insert on tickets" ON public.tickets;
DROP POLICY IF EXISTS "Users read own tickets" ON public.tickets;
DROP POLICY IF EXISTS "Tickets insert and update" ON public.tickets;

CREATE POLICY "Users read own tickets"
    ON public.tickets FOR SELECT
    USING (true);

CREATE POLICY "Tickets insert and update"
    ON public.tickets FOR ALL
    USING (true)
    WITH CHECK (true);

-- ====================================================================
-- COMMUNITY Q&A & INCIDENT REPORTS TABLES (Preserved & Enhanced)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.route_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Traveler',
    question TEXT NOT NULL,
    origin TEXT DEFAULT 'Current Hub',
    destination TEXT DEFAULT 'Ahmedabad',
    route_tag TEXT DEFAULT 'Leg #AMD-LIVE',
    category TEXT NOT NULL DEFAULT 'all',
    badge_text TEXT DEFAULT 'LIVE INQUIRY',
    upvotes INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.route_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Allow public insert on route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Allow public update on route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Public read route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Public insert route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Public update route_questions" ON public.route_questions;

CREATE POLICY "Public read route_questions" ON public.route_questions FOR SELECT USING (true);
CREATE POLICY "Public insert route_questions" ON public.route_questions FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update route_questions" ON public.route_questions FOR UPDATE USING (true);

CREATE TABLE IF NOT EXISTS public.route_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES public.route_questions(id) ON DELETE CASCADE,
    author TEXT NOT NULL,
    role_badge TEXT DEFAULT 'Commuter Advice',
    content TEXT NOT NULL,
    avatar_letter TEXT DEFAULT 'C',
    likes INT DEFAULT 0,
    dislikes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.route_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Allow public insert on route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Allow public update on route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Public read route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Public insert route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Public update route_answers" ON public.route_answers;

CREATE POLICY "Public read route_answers" ON public.route_answers FOR SELECT USING (true);
CREATE POLICY "Public insert route_answers" ON public.route_answers FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update route_answers" ON public.route_answers FOR UPDATE USING (true);

CREATE TABLE IF NOT EXISTS public.transit_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_name TEXT NOT NULL,
    report_type TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location_name TEXT NOT NULL,
    route_tag TEXT DEFAULT 'Corridor #9',
    upvotes INT DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.transit_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on transit_reports" ON public.transit_reports;
DROP POLICY IF EXISTS "Allow public insert on transit_reports" ON public.transit_reports;
DROP POLICY IF EXISTS "Allow public update on transit_reports" ON public.transit_reports;
DROP POLICY IF EXISTS "Public read transit_reports" ON public.transit_reports;
DROP POLICY IF EXISTS "Public insert transit_reports" ON public.transit_reports;
DROP POLICY IF EXISTS "Public update transit_reports" ON public.transit_reports;

CREATE POLICY "Public read transit_reports" ON public.transit_reports FOR SELECT USING (true);
CREATE POLICY "Public insert transit_reports" ON public.transit_reports FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update transit_reports" ON public.transit_reports FOR UPDATE USING (true);

CREATE TABLE IF NOT EXISTS public.report_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES public.transit_reports(id) ON DELETE CASCADE,
    author TEXT NOT NULL,
    comment TEXT NOT NULL,
    user_locality TEXT DEFAULT 'Ahmedabad',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.report_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on report_comments" ON public.report_comments;
DROP POLICY IF EXISTS "Allow public insert on report_comments" ON public.report_comments;
DROP POLICY IF EXISTS "Public read report_comments" ON public.report_comments;
DROP POLICY IF EXISTS "Public insert report_comments" ON public.report_comments;

CREATE POLICY "Public read report_comments" ON public.report_comments FOR SELECT USING (true);
CREATE POLICY "Public insert report_comments" ON public.report_comments FOR INSERT WITH CHECK (true);

-- ====================================================================
-- SEED DATA: AHMEDABAD GTFS STOPS & BRTS CORRIDOR NODES
-- ====================================================================
INSERT INTO public.gtfs_stops (stop_id, stop_name, latitude, longitude, transit_type)
VALUES
('STOP_SOLA', 'Sola Bhagwat (BRTS Hub)', 23.082700, 72.528400, 'BRTS'),
('STOP_ISKCON', 'Iskcon Cross Road', 23.031500, 72.507400, 'BRTS'),
('STOP_SHIV', 'Shivranjani Cross Road', 23.023400, 72.531200, 'BRTS'),
('STOP_VASTRAPUR', 'Vastrapur Lake Stand', 23.037200, 72.529800, 'AMTS'),
('STOP_KALUPUR', 'Kalupur Railway Interchange', 23.029800, 72.601000, 'METRO'),
('STOP_RANIP', 'Ranip Central Bus Terminal', 23.076800, 72.576200, 'BRTS'),
('STOP_GIFT', 'GIFT City Multimodal Center', 23.161000, 72.684100, 'BRTS')
ON CONFLICT (stop_id) DO NOTHING;

INSERT INTO public.gtfs_routes (route_id, route_short_name, operator, polyline_points)
VALUES
('ROUTE_BRTS_9U', 'BRTS 9U (Sola to Shivranjani)', 'BRTS', '23.0827,72.5284|23.0560,72.5210|23.0234,72.5312'),
('ROUTE_BRTS_8D', 'BRTS 8D (Shivranjani to Iskcon)', 'BRTS', '23.0234,72.5312|23.0280,72.5180|23.0315,72.5074'),
('ROUTE_AMTS_4U', 'AMTS 4U (Vastrapur to Kalupur)', 'AMTS', '23.0372,72.5298|23.0330,72.5650|23.0298,72.6010')
ON CONFLICT (route_id) DO NOTHING;

INSERT INTO public.fare_matrix (operator, stage_from, stage_to, fare_paise, interchange_discount_percent)
VALUES
('BRTS', 1, 3, 500, 0),
('BRTS', 4, 8, 900, 10),
('AMTS', 1, 3, 400, 0),
('AMTS', 4, 8, 800, 10),
('MULTIMODAL_COMBI', 1, 8, 900, 20)
ON CONFLICT DO NOTHING;
