-- ====================================================================
-- TRANSIT AI - SUPABASE DATABASE SCHEMA
-- Project URL: https://your-project-id.supabase.co
--
-- HOW TO RUN:
-- 1. Log in to your Supabase Dashboard: https://supabase.com/dashboard
-- 2. Select project 'your-project-id'
-- 3. Click "SQL Editor" in the left sidebar
-- 4. Click "New Query", paste this entire file, and click "Run" (▶)
-- ====================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================================
-- TABLE 1: PROFILES (User accounts with Locality / From origin)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    locality TEXT DEFAULT 'Ahmedabad',
    wallet_balance NUMERIC(10, 2) DEFAULT 150.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on profiles"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert/upsert on profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public update on profiles"
    ON public.profiles FOR UPDATE
    USING (true);

-- ====================================================================
-- TABLE 2: ROUTE_QUESTIONS (Community Q&A Feed)
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

-- Enable RLS for Route Questions
ALTER TABLE public.route_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on route_questions"
    ON public.route_questions FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert on route_questions"
    ON public.route_questions FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public update on route_questions"
    ON public.route_questions FOR UPDATE
    USING (true);

-- ====================================================================
-- TABLE 3: ROUTE_ANSWERS (Replies, Verified Guides, and Reactions)
-- ====================================================================
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

-- Enable RLS for Route Answers
ALTER TABLE public.route_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on route_answers"
    ON public.route_answers FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert on route_answers"
    ON public.route_answers FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public update on route_answers"
    ON public.route_answers FOR UPDATE
    USING (true);

-- ====================================================================
-- TABLE 4: TICKETS (Digital QR Metro & BRTS bookings)
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

-- Enable RLS for Tickets
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on tickets"
    ON public.tickets FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert on tickets"
    ON public.tickets FOR INSERT
    WITH CHECK (true);

-- ====================================================================
-- INITIAL SEED DATA (Populates default verified questions)
-- ====================================================================
INSERT INTO public.route_questions (id, author, role, origin, destination, question, route_tag, category, badge_text, upvotes)
VALUES 
(
    'a0000000-0000-0000-0000-000000000001',
    'Nehal M.',
    'Traveler',
    'Kalupur Stn',
    'SG Highway (Prahlad Nagar)',
    'Just reached Kalupur with two trolley bags. Need to reach SG Highway (Prahlad Nagar). Should I take Metro Line 1 or direct BRTS? Which interchange has escalators/lifts?',
    'Leg #KAL-PRA',
    'airport',
    'NEW TO CITY',
    15
),
(
    'a0000000-0000-0000-0000-000000000002',
    'Ananya K.',
    'Student',
    'Iskcon Crossroad',
    'PDPU Gandhinagar',
    'What is the best feeder bus connection from Iskcon Crossroad to PDPU Gandhinagar in morning peak hours?',
    'PDPU Feeder',
    'student',
    'CAMPUS',
    9
),
(
    'a0000000-0000-0000-0000-000000000003',
    'Rohan V.',
    'Commuter',
    'Ranip',
    'GIFT City',
    'Does the Gandhinagar Metro connect to GIFT City after 10 PM on weekends, or should I take the GSRTC AC EV Bus?',
    'GIFT Express',
    'night',
    'NIGHT ROUTE',
    21
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.route_answers (id, question_id, author, role_badge, content, avatar_letter, likes, dislikes)
VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Dev',
    'Top Contributor',
    'Take Metro Line 1 to Commerce Six Roads, then switch to BRTS corridor 9. Concourse is sheltered and has functioning lifts for luggage.',
    'D',
    24,
    1
),
(
    'b0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000001',
    'Farhan',
    'Local Commuter',
    'Avoid changing at Geeta Mandir during peak 9 AM rush. Take the direct electric express bus 4U.',
    'F',
    18,
    0
),
(
    'b0000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000002',
    'AMTS Marshall',
    'Verified Guide',
    'Catch Route 8D Feeder departing Bay 3 at 8:10 AM sharp. It bypasses SG highway jams directly to PDPU Bhaijipura point.',
    'M',
    31,
    0
),
(
    'b0000000-0000-0000-0000-000000000004',
    'a0000000-0000-0000-0000-000000000003',
    'Pooja S.',
    'GIFT City Commuter',
    'Metro closes service at 9:45 PM on Sundays. Best option is the GIFT City Shuttle EV bus from Ranip Bay 6 which runs till 11:30 PM.',
    'P',
    14,
    0
)
ON CONFLICT (id) DO NOTHING;

-- ====================================================================
-- TABLE 5: TRANSIT_REPORTS (Live Incidents, Waterlogging, Delays & Hazards)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.transit_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_name TEXT NOT NULL,
    report_type TEXT NOT NULL, -- 'Waterlogging', 'Metro Delay', 'BRTS Breakdown', 'Road Construction', 'Heavy Crowd'
    severity TEXT NOT NULL DEFAULT 'medium', -- 'critical', 'high', 'medium', 'low'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location_name TEXT NOT NULL, -- e.g. 'Iskcon Cross Road, SG Highway'
    route_tag TEXT DEFAULT 'Corridor #9',
    upvotes INT DEFAULT 1,
    status TEXT DEFAULT 'ACTIVE', -- 'ACTIVE', 'VERIFIED', 'RESOLVED'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for Transit Reports
ALTER TABLE public.transit_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on transit_reports"
    ON public.transit_reports FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert on transit_reports"
    ON public.transit_reports FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow public update on transit_reports"
    ON public.transit_reports FOR UPDATE
    USING (true);

-- ====================================================================
-- TABLE 6: REPORT_COMMENTS (Community feedback on incident reports)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.report_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES public.transit_reports(id) ON DELETE CASCADE,
    author TEXT NOT NULL,
    comment TEXT NOT NULL,
    user_locality TEXT DEFAULT 'Ahmedabad',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for Report Comments
ALTER TABLE public.report_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on report_comments"
    ON public.report_comments FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert on report_comments"
    ON public.report_comments FOR INSERT
    WITH CHECK (true);

-- ====================================================================
-- INITIAL SEED DATA FOR REPORTS
-- ====================================================================
INSERT INTO public.transit_reports (id, reporter_name, report_type, severity, title, description, location_name, route_tag, upvotes, status)
VALUES
(
    'c0000000-0000-0000-0000-000000000001',
    'Vikram Desai',
    'Waterlogging',
    'high',
    'Heavy Waterlogging under Iskcon Flyover',
    'Underpass service road flooded up to 1.5 ft after heavy showers. BRTS buses are operating via main flyover deck; autos avoiding service lanes.',
    'Iskcon Cross Road, SG Highway',
    'Corridor #9 BRTS',
    28,
    'VERIFIED'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Kiran Shah',
    'Metro Delay',
    'medium',
    'Signal Maintenance at Kalupur Concourse',
    'Metro East-West Line 1 trains held for 6-8 mins at Kalupur platform 2. Technicians on site; crowd moderate.',
    'Kalupur Railway Interchange',
    'Metro Line 1',
    19,
    'ACTIVE'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'Sameer P.',
    'Heavy Crowd',
    'low',
    'Rush at Vastrapur Feeder Bus Bay',
    'High university student rush for feeder buses toward PDPU / Gandhinagar. Electric bus 4U arriving in 4 mins.',
    'Vastrapur Lake Bus Stand',
    'Route 4U Electric',
    12,
    'ACTIVE'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.report_comments (id, report_id, author, comment, user_locality)
VALUES
(
    'd0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'Dev Patel',
    'Confirmed. Took flyover top deck and saved 20 minutes. Avoid ground level underpass.',
    'SG Highway'
),
(
    'd0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'Traffic Warden',
    'Traffic police diverting two-wheelers toward Judges Bungalow road.',
    'Bodakdev'
),
(
    'd0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000002',
    'Harsh M.',
    'Metro frequency back to 7 mins as of 10 mins ago.',
    'Kalupur'
)
ON CONFLICT (id) DO NOTHING;
