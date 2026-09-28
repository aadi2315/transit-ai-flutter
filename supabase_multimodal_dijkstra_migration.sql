-- ====================================================================
-- TRANSIT AI: SUPABASE MULTIMODAL ROUTE-STOP SEQUENCE & DIJKSTRA MIGRATION
-- Project URL: https://<your-project-id>.supabase.co
-- How to run: Supabase Dashboard -> SQL Editor -> Paste & Run (▶)
-- ====================================================================

-- 1. CREATE TABLE gtfs_route_stops
CREATE TABLE IF NOT EXISTS public.gtfs_route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id TEXT NOT NULL REFERENCES public.gtfs_routes(route_id) ON DELETE CASCADE,
    stop_id TEXT NOT NULL REFERENCES public.gtfs_stops(stop_id) ON DELETE CASCADE,
    stop_sequence INT NOT NULL,
    travel_time_from_prev_mins INT DEFAULT 3,
    headway_mins INT DEFAULT 15,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_route_stop_sequence UNIQUE (route_id, stop_sequence),
    CONSTRAINT uq_route_stop_id UNIQUE (route_id, stop_id)
);

-- Indexes for high-performance graph construction
CREATE INDEX IF NOT EXISTS idx_route_stops_route_id ON public.gtfs_route_stops(route_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_stop_id ON public.gtfs_route_stops(stop_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_seq ON public.gtfs_route_stops(route_id, stop_sequence);

-- 2. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.gtfs_route_stops ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read for gtfs_route_stops" ON public.gtfs_route_stops;
CREATE POLICY "Public read for gtfs_route_stops"
    ON public.gtfs_route_stops FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow public insert and update on gtfs_route_stops" ON public.gtfs_route_stops;
CREATE POLICY "Allow public insert and update on gtfs_route_stops"
    ON public.gtfs_route_stops FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3. INGEST GTFS ROUTES (Bus 9U & Bus 8D)
INSERT INTO public.gtfs_routes (
    route_id,
    route_short_name,
    operator,
    origin_name,
    destination_name,
    distance_km,
    duration_mins,
    fare_amount,
    encoded_polyline,
    polyline_points
)
VALUES
(
    '9U',
    '9U',
    'BRTS',
    'Vasantnagar township',
    'Maninagar BRTS',
    23.3,
    69,
    15.00,
    'cb`lC_atyLnr@}g@nmApS~h@`K~x@bTf`@ah@nJuR`M_OlRuWtK{U~OiWdVlJbTbOzj@xZjXfK~]fVz`@|DvEw]uCpCyEel@}GyGsQmRya@mIhj@sRdXei@XygAxJk|@vAeNrK}TfE{Mba@iPxf@`@rRfGhFwQrSgAxQec@bEke@mBkg@oLn@',
    '[{"lat": 23.107063273048233, "lng": 72.525118566862}, {"lat": 23.09882190970811, "lng": 72.5316655380259}, {"lat": 23.08625724137644, "lng": 72.5283828245331}, {"lat": 23.07954054134499, "lng": 72.52645062638375}, {"lat": 23.070264045227912, "lng": 72.52307026104003}, {"lat": 23.064939606283776, "lng": 72.52963846686066}, {"lat": 23.063104020397038, "lng": 72.53278573987572}, {"lat": 23.06085468054271, "lng": 72.53534716500954}, {"lat": 23.057739087711994, "lng": 72.53929935190713}, {"lat": 23.05570978532818, "lng": 72.54296224781508}, {"lat": 23.05298875766829, "lng": 72.54685191686033}, {"lat": 23.049277936629686, "lng": 72.54502145336772}, {"lat": 23.045899207997333, "lng": 72.54244011536919}, {"lat": 23.03888094367864, "lng": 72.53798802368445}, {"lat": 23.034817100414607, "lng": 72.53603315336736}, {"lat": 23.0298565291687, "lng": 72.53231223432189}, {"lat": 23.024436591603756, "lng": 72.53135719754614}, {"lat": 23.023355255090856, "lng": 72.53628308035172}, {"lat": 23.024105340874716, "lng": 72.53555345537252}, {"lat": 23.025195173153378, "lng": 72.5427840496651}, {"lat": 23.026634955274677, "lng": 72.54418591103874}, {"lat": 23.029607328664632, "lng": 72.5472972840538}, {"lat": 23.035184520080083, "lng": 72.54897258405401}, {"lat": 23.028252243609842, "lng": 72.55210860733683}, {"lat": 23.02421915628851, "lng": 72.55885840733671}, {"lat": 23.0240928665176, "lng": 72.57050667082919}, {"lat": 23.02219746573153, "lng": 72.58033099014239}, {"lat": 23.021764594540844, "lng": 72.58276361103852}, {"lat": 23.019742864107453, "lng": 72.5862679655448}, {"lat": 23.018744474110555, "lng": 72.5886496398743}, {"lat": 23.01327752882501, "lng": 72.59142241103824}, {"lat": 23.0069058390427, "lng": 72.59124968405315}, {"lat": 23.003768892725628, "lng": 72.58992838220209}, {"lat": 23.002603494431963, "lng": 72.59293082638132}, {"lat": 22.999297871240874, "lng": 72.59328999569445}, {"lat": 22.996285304819057, "lng": 72.5990835028991}, {"lat": 22.995312171003636, "lng": 72.60521523987353}, {"lat": 22.99585501205344, "lng": 72.61168466373469}, {"lat": 22.998015801148426, "lng": 72.61144076685858}]'
),
(
    '8D',
    '8D',
    'BRTS',
    'Naroda Gam',
    'Bhadaj Circle',
    21.6,
    64,
    15.00,
    'ufzkCyqmzLn_@bh@`m@bh@~RnPjb@`i@hM|ThOdXbYdg@`MtRtNpT~NxTnKjxAiAf^gJvTqMbFcS`HwUlGkr@xaAq]Ec\BqFbRJf]jQho@`NbRx[vUzKle@eLdXgQ~UwMhPmKnRa]xj@eOhg@wMp]sMb]{S~i@sO~Y',
    '[{"lat": 23.077071, "lng": 72.655812}, {"lat": 23.071868, "lng": 72.649228}, {"lat": 23.064505, "lng": 72.642646}, {"lat": 23.061302, "lng": 72.639847}, {"lat": 23.055643, "lng": 72.633123}, {"lat": 23.05335, "lng": 72.629608}, {"lat": 23.050745, "lng": 72.625576}, {"lat": 23.04656, "lng": 72.619151}, {"lat": 23.044309, "lng": 72.616002}, {"lat": 23.041798, "lng": 72.612551}, {"lat": 23.039243, "lng": 72.609065}, {"lat": 23.037244, "lng": 72.594756}, {"lat": 23.037613, "lng": 72.589757}, {"lat": 23.039412, "lng": 72.586281}, {"lat": 23.04174, "lng": 72.585138}, {"lat": 23.044965, "lng": 72.583686}, {"lat": 23.048595, "lng": 72.582342}, {"lat": 23.056817, "lng": 72.571647}, {"lat": 23.061707, "lng": 72.571677}, {"lat": 23.066371, "lng": 72.571663}, {"lat": 23.067575, "lng": 72.568599}, {"lat": 23.067515, "lng": 72.563763}, {"lat": 23.064584, "lng": 72.556035}, {"lat": 23.062166, "lng": 72.552973}, {"lat": 23.057561, "lng": 72.549326}, {"lat": 23.055501, "lng": 72.543178}, {"lat": 23.057611, "lng": 72.539154}, {"lat": 23.060528, "lng": 72.535474}, {"lat": 23.062892, "lng": 72.532704}, {"lat": 23.064879, "lng": 72.529577}, {"lat": 23.069693, "lng": 72.522567}, {"lat": 23.072279, "lng": 72.516118}, {"lat": 23.074644, "lng": 72.511234}, {"lat": 23.076982, "lng": 72.506412}, {"lat": 23.080317, "lng": 72.499527}, {"lat": 23.08298, "lng": 72.495212}]'
)
ON CONFLICT (route_id) DO UPDATE SET
    route_short_name = EXCLUDED.route_short_name,
    operator = EXCLUDED.operator,
    origin_name = EXCLUDED.origin_name,
    destination_name = EXCLUDED.destination_name,
    distance_km = EXCLUDED.distance_km,
    duration_mins = EXCLUDED.duration_mins,
    fare_amount = EXCLUDED.fare_amount,
    encoded_polyline = EXCLUDED.encoded_polyline,
    polyline_points = EXCLUDED.polyline_points;

-- 4. INGEST GTFS STOPS (All 9U & 8D Stations)
INSERT INTO public.gtfs_stops (stop_id, stop_name, latitude, longitude, transit_type)
VALUES
('STOP_VASANTNAGAR', 'Vasantnagar township', 23.107063, 72.525119, 'BRTS'),
('STOP_GOTA_CROSS_ROADS', 'Gota cross roads', 23.098822, 72.531666, 'BRTS'),
('STOP_SOLA_BHAGWAT', 'Sola Bhagwat', 23.086257, 72.528383, 'BRTS'),
('STOP_GUJARAT_HIGH_COURT', 'Gujarat high court', 23.079541, 72.526451, 'BRTS'),
('STOP_SCIENCE_CITY_APPROACH', 'science city approach', 23.070264, 72.523070, 'BRTS'),
('STOP_SOLA_BRIDGE', 'sola bridge brts', 23.064940, 72.529638, 'BRTS'),
('STOP_SATTADHAR_CHAR_RASTA', 'sattadhar char rasta', 23.063104, 72.532786, 'BRTS'),
('STOP_BHUYANGDEV', 'bhuyang dev', 23.060855, 72.535347, 'BRTS'),
('STOP_PARSHWANATH_JAIN_MANDIR', 'Parshwath Jain Mandir BRTS', 23.057739, 72.539299, 'BRTS'),
('STOP_PARASNAGAR', 'Parasnagar BRTS', 23.055710, 72.542962, 'BRTS'),
('STOP_SOLA_CROSS_ROAD', 'Sola Cross Road BRTS', 23.052989, 72.546852, 'BRTS'),
('STOP_VALINATH_CHOWK', 'Shree Valinath Chowk BRTS', 23.049278, 72.545021, 'BRTS'),
('STOP_MEMNAGAR', 'memnagar brts', 23.045899, 72.542440, 'BRTS'),
('STOP_UNIVERSITY', 'university brts', 23.038881, 72.537988, 'BRTS'),
('STOP_ANDHJAN_MANDAL', 'andhjan mandal brts', 23.034817, 72.536033, 'BRTS'),
('STOP_HIMMAT_LAL_PARK', 'Himmat Lal park brts', 23.029857, 72.532312, 'BRTS'),
('STOP_SHIVRANJANI', 'shivranjani brts', 23.024437, 72.531357, 'BRTS'),
('STOP_JHANSI_KI_RANI', 'Jhansi ki rani brts', 23.023355, 72.536283, 'BRTS'),
('STOP_NEHRUNAGAR', 'Nehrunagar brts', 23.024105, 72.535553, 'BRTS'),
('STOP_L_COLONY', 'L colony', 23.025195, 72.542784, 'BRTS'),
('STOP_PANJRAPOLE_CHAR_RASTA', 'Panjrapole Char Rasta BRTS', 23.026635, 72.544186, 'BRTS'),
('STOP_GULBAI_TEKRA_APPROACH', 'Gulbai Tekra Approach BRTS', 23.029607, 72.547297, 'BRTS'),
('STOP_LD_ENGG_COLLEGE', 'ld engg. college brts', 23.035185, 72.548973, 'BRTS'),
('STOP_VASUNDHARA', 'Vasundhara brts', 23.028252, 72.552109, 'BRTS'),
('STOP_LAW_GARDEN', 'law garden brts', 23.024219, 72.558858, 'BRTS'),
('STOP_MJ_LIBRARY', 'MJ library brts', 23.024093, 72.570507, 'BRTS'),
('STOP_LOKAMANYA_TILAK', 'lokamanya tilak brts', 23.022197, 72.580331, 'BRTS'),
('STOP_RAIKHAD_CHAR_RASTA', 'raikhad char rasta brts', 23.021765, 72.582764, 'BRTS'),
('STOP_MUNICIPAL_CORP_OFFICE', 'municipal corporation office', 23.019743, 72.586268, 'BRTS'),
('STOP_ASTODIA_CHAKLA', 'astodia chakla', 23.018744, 72.588650, 'BRTS'),
('STOP_GEETA_MANDIR', 'geeta mandir brts', 23.013278, 72.591422, 'BRTS'),
('STOP_BHULABHAI_PARK', 'bhulabhai park brts', 23.006906, 72.591250, 'BRTS'),
('STOP_MANGAL_PARK', 'mangal park brts', 23.003769, 72.589928, 'BRTS'),
('STOP_KANKARIYA_TEL_EXCHANGE', 'Kankariya Telephone Exchange BRTS', 23.002603, 72.592931, 'BRTS'),
('STOP_MIRA_CINEMA', 'Mira Cinema, Char Rasta', 22.999298, 72.593290, 'BRTS'),
('STOP_BHAIRAVNATH_ROAD', 'bhairavnath road brts', 22.996285, 72.599084, 'BRTS'),
('STOP_JAWAHAR_CHOWK', 'Jawahar chowk brts', 22.995312, 72.605215, 'BRTS'),
('STOP_SWAMINARAYAN', 'swaminayaran brts', 22.995855, 72.611685, 'BRTS'),
('STOP_MANINAGAR', 'Maninagar BRTS', 22.998016, 72.611441, 'BRTS'),
('STOP_NARODA_GAM', 'Naroda Gam', 23.077071, 72.655812, 'BRTS'),
('STOP_BETHAK', 'Bethak', 23.071868, 72.649228, 'BRTS'),
('STOP_NARODA_ST_WORKSHOP', 'Naroda S. T. Workshop', 23.064505, 72.642646, 'BRTS'),
('STOP_SAIJPUR_TOWERS', 'Saijpur Towers', 23.061302, 72.639847, 'BRTS'),
('STOP_MUNICIPAL_NORTH_ZONE', 'Municipal North Zone Office', 23.055643, 72.633123, 'BRTS'),
('STOP_MEMCO_CROSS_ROAD', 'Memco Cross Road', 23.053350, 72.629608, 'BRTS'),
('STOP_NARODA_FRUIT_MARKET', 'Naroda Fruit Market', 23.050745, 72.625576, 'BRTS'),
('STOP_ASHOK_MILL', 'Ashok Mill', 23.046560, 72.619151, 'BRTS'),
('STOP_JEENING_PRESS', 'Jeening Press', 23.044309, 72.616002, 'BRTS'),
('STOP_ARVIND_MILL', 'Arvind Mill', 23.041798, 72.612551, 'BRTS'),
('STOP_GCS_HOSPITAL', 'G.C.S. Hospital', 23.039243, 72.609065, 'BRTS'),
('STOP_PREM_DARWAJA', 'Prem Darwaja', 23.037244, 72.594756, 'BRTS'),
('STOP_DELHI_DARWAJA', 'Delhi Darwaja', 23.037613, 72.589757, 'BRTS'),
('STOP_LITHO_PRESS_CABIN', 'Sarkari Litho Press Cabin', 23.039412, 72.586281, 'BRTS'),
('STOP_LITHO_PRESS', 'Sarkari Litho Press', 23.041740, 72.585138, 'BRTS'),
('STOP_HANUMANPURA', 'Hanumanpura', 23.044965, 72.583686, 'BRTS'),
('STOP_GURUDWARA', 'Gurudwara', 23.048595, 72.582342, 'BRTS'),
('STOP_JUNA_VADAJ', 'Juna Vadaj', 23.056817, 72.571647, 'BRTS'),
('STOP_RAMAPIR_NO_TEKARO', 'Ramapir No Tekaro', 23.061707, 72.571677, 'BRTS'),
('STOP_NR_PATEL_PARK', 'NR Patel Park', 23.066371, 72.571663, 'BRTS'),
('STOP_BHAVSAR_HOSTEL', 'Bhavsar Hostel', 23.067575, 72.568599, 'BRTS'),
('STOP_AKHBARNAGAR', 'Akhbarnagar', 23.067515, 72.563763, 'BRTS'),
('STOP_PRAGATINAGAR', 'Pragatinagar', 23.064584, 72.556035, 'BRTS'),
('STOP_SHASTRINAGAR', 'Shastrinagar', 23.062166, 72.552973, 'BRTS'),
('STOP_JAIMANGAL', 'Jaimangal', 23.057561, 72.549326, 'BRTS'),
('STOP_SHUKAN_MALL', 'Shukan Mall', 23.072279, 72.516118, 'BRTS'),
('STOP_RK_ROYAL', 'Rk Royal', 23.074644, 72.511234, 'BRTS'),
('STOP_GALAXY_SIGNATURE', 'Galaxy Signature', 23.076982, 72.506412, 'BRTS'),
('STOP_SCIENCE_CITY', 'Science City', 23.080317, 72.499527, 'BRTS'),
('STOP_BHADAJ_CIRCLE', 'Bhadaj Circle', 23.082980, 72.495212, 'BRTS')
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    transit_type = EXCLUDED.transit_type;

-- 5. INGEST GTFS ROUTE STOPS (Sequential Stop Orders, Travel Times & Headways)
INSERT INTO public.gtfs_route_stops (route_id, stop_id, stop_sequence, travel_time_from_prev_mins, headway_mins)
VALUES
('9U', 'STOP_VASANTNAGAR', 1, 0, 15),
('9U', 'STOP_GOTA_CROSS_ROADS', 2, 3, 15),
('9U', 'STOP_SOLA_BHAGWAT', 3, 4, 15),
('9U', 'STOP_GUJARAT_HIGH_COURT', 4, 2, 15),
('9U', 'STOP_SCIENCE_CITY_APPROACH', 5, 3, 15),
('9U', 'STOP_SOLA_BRIDGE', 6, 2, 15),
('9U', 'STOP_SATTADHAR_CHAR_RASTA', 7, 2, 15),
('9U', 'STOP_BHUYANGDEV', 8, 2, 15),
('9U', 'STOP_PARSHWANATH_JAIN_MANDIR', 9, 2, 15),
('9U', 'STOP_PARASNAGAR', 10, 2, 15),
('9U', 'STOP_SOLA_CROSS_ROAD', 11, 2, 15),
('9U', 'STOP_VALINATH_CHOWK', 12, 2, 15),
('9U', 'STOP_MEMNAGAR', 13, 2, 15),
('9U', 'STOP_UNIVERSITY', 14, 2, 15),
('9U', 'STOP_ANDHJAN_MANDAL', 15, 2, 15),
('9U', 'STOP_HIMMAT_LAL_PARK', 16, 2, 15),
('9U', 'STOP_SHIVRANJANI', 17, 2, 15),
('9U', 'STOP_JHANSI_KI_RANI', 18, 2, 15),
('9U', 'STOP_NEHRUNAGAR', 19, 2, 15),
('9U', 'STOP_L_COLONY', 20, 2, 15),
('9U', 'STOP_PANJRAPOLE_CHAR_RASTA', 21, 2, 15),
('9U', 'STOP_GULBAI_TEKRA_APPROACH', 22, 2, 15),
('9U', 'STOP_LD_ENGG_COLLEGE', 23, 2, 15),
('9U', 'STOP_VASUNDHARA', 24, 2, 15),
('9U', 'STOP_LAW_GARDEN', 25, 2, 15),
('9U', 'STOP_MJ_LIBRARY', 26, 3, 15),
('9U', 'STOP_LOKAMANYA_TILAK', 27, 3, 15),
('9U', 'STOP_RAIKHAD_CHAR_RASTA', 28, 2, 15),
('9U', 'STOP_MUNICIPAL_CORP_OFFICE', 29, 2, 15),
('9U', 'STOP_ASTODIA_CHAKLA', 30, 2, 15),
('9U', 'STOP_GEETA_MANDIR', 31, 2, 15),
('9U', 'STOP_BHULABHAI_PARK', 32, 2, 15),
('9U', 'STOP_MANGAL_PARK', 33, 2, 15),
('9U', 'STOP_KANKARIYA_TEL_EXCHANGE', 34, 2, 15),
('9U', 'STOP_MIRA_CINEMA', 35, 2, 15),
('9U', 'STOP_BHAIRAVNATH_ROAD', 36, 2, 15),
('9U', 'STOP_JAWAHAR_CHOWK', 37, 2, 15),
('9U', 'STOP_SWAMINARAYAN', 38, 2, 15),
('9U', 'STOP_MANINAGAR', 39, 2, 15),
('8D', 'STOP_NARODA_GAM', 1, 0, 15),
('8D', 'STOP_BETHAK', 2, 2, 15),
('8D', 'STOP_NARODA_ST_WORKSHOP', 3, 3, 15),
('8D', 'STOP_SAIJPUR_TOWERS', 4, 2, 15),
('8D', 'STOP_MUNICIPAL_NORTH_ZONE', 5, 2, 15),
('8D', 'STOP_MEMCO_CROSS_ROAD', 6, 2, 15),
('8D', 'STOP_NARODA_FRUIT_MARKET', 7, 2, 15),
('8D', 'STOP_ASHOK_MILL', 8, 2, 15),
('8D', 'STOP_JEENING_PRESS', 9, 2, 15),
('8D', 'STOP_ARVIND_MILL', 10, 2, 15),
('8D', 'STOP_GCS_HOSPITAL', 11, 2, 15),
('8D', 'STOP_PREM_DARWAJA', 12, 4, 15),
('8D', 'STOP_DELHI_DARWAJA', 13, 2, 15),
('8D', 'STOP_LITHO_PRESS_CABIN', 14, 2, 15),
('8D', 'STOP_LITHO_PRESS', 15, 2, 15),
('8D', 'STOP_HANUMANPURA', 16, 2, 15),
('8D', 'STOP_GURUDWARA', 17, 2, 15),
('8D', 'STOP_JUNA_VADAJ', 18, 4, 15),
('8D', 'STOP_RAMAPIR_NO_TEKARO', 19, 2, 15),
('8D', 'STOP_NR_PATEL_PARK', 20, 2, 15),
('8D', 'STOP_BHAVSAR_HOSTEL', 21, 2, 15),
('8D', 'STOP_AKHBARNAGAR', 22, 2, 15),
('8D', 'STOP_PRAGATINAGAR', 23, 2, 15),
('8D', 'STOP_SHASTRINAGAR', 24, 2, 15),
('8D', 'STOP_JAIMANGAL', 25, 2, 15),
('8D', 'STOP_PARASNAGAR', 26, 2, 15),
('8D', 'STOP_PARSHWANATH_JAIN_MANDIR', 27, 2, 15),
('8D', 'STOP_BHUYANGDEV', 28, 2, 15),
('8D', 'STOP_SATTADHAR_CHAR_RASTA', 29, 2, 15),
('8D', 'STOP_SOLA_BRIDGE', 30, 2, 15),
('8D', 'STOP_SCIENCE_CITY_APPROACH', 31, 2, 15),
('8D', 'STOP_SHUKAN_MALL', 32, 2, 15),
('8D', 'STOP_RK_ROYAL', 33, 2, 15),
('8D', 'STOP_GALAXY_SIGNATURE', 34, 2, 15),
('8D', 'STOP_SCIENCE_CITY', 35, 2, 15),
('8D', 'STOP_BHADAJ_CIRCLE', 36, 2, 15)
ON CONFLICT (route_id, stop_id) DO UPDATE SET
    stop_sequence = EXCLUDED.stop_sequence,
    travel_time_from_prev_mins = EXCLUDED.travel_time_from_prev_mins,
    headway_mins = EXCLUDED.headway_mins;