-- ====================================================================
-- TRANSIT AI - SUPABASE ROUTE POLYLINE CACHE MIGRATION
-- Enables Fetch-Once-and-Store for Google Directions API Polylines
-- Project: https://<your-project-id>.supabase.co
-- ====================================================================

-- 1. Upgrade gtfs_routes table with driving route & caching columns
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS origin_name TEXT;
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS destination_name TEXT;
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS waypoints TEXT[];
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS encoded_polyline TEXT;
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS distance_km NUMERIC(6, 2);
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS duration_mins INT;
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS fare_amount NUMERIC(10, 2);
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS route_steps JSONB;
ALTER TABLE public.gtfs_routes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Update Row Level Security (RLS) to permit reading and caching
ALTER TABLE public.gtfs_routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read for gtfs_routes" ON public.gtfs_routes;
DROP POLICY IF EXISTS "Allow public insert and update on gtfs_routes" ON public.gtfs_routes;

CREATE POLICY "Public read for gtfs_routes"
    ON public.gtfs_routes FOR SELECT
    USING (true);

CREATE POLICY "Allow public insert and update on gtfs_routes"
    ON public.gtfs_routes FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3. Seed initial driving routes for Ahmedabad Multimodal Corridors
INSERT INTO public.gtfs_routes (
    route_id,
    route_short_name,
    operator,
    origin_name,
    destination_name,
    waypoints,
    distance_km,
    duration_mins,
    fare_amount,
    encoded_polyline
)
VALUES
(
    'ROUTE_SOLA_ISKCON',
    'BRTS 9U ➔ BRTS 8D',
    'BRTS',
    'Sola Bhagwat (BRTS Hub)',
    'Iskcon Cross Road',
    ARRAY['Shivranjani Cross Road'],
    7.4,
    14,
    9.00,
    'wi{kC{wtyLnA[b@Gt@GCf@MlASlCWpBJF|Er@zLxBvK|BfB\rInB~Ch@pI~A|@RtDl@nEp@BTxAXfCf@lEt@zGjAhDz@bHzAtDt@dB`@~Bd@rDl@hE`AjI|AhCj@lCh@vK~B~IfBhBb@nHjBfGjBdH~BpEbBvGhCbQzGbGvBdE`B~FxBvAn@bC`A`A\dBp@~CpAnIbDdJvCjAZnAXjAX|AZn@M^BbDv@vJxBtCl@SfAw@QUGeFkAiFeAaDu@kDo@a@KIA?NDlADd@Jl@t@hC'
),
(
    'ROUTE_VASTRAPUR_KALUPUR',
    'AMTS 4U Direct',
    'AMTS',
    'Vastrapur Lake Stand',
    'Kalupur Railway Interchange',
    ARRAY['Income Tax Circle', 'Delhi Darwaja'],
    9.5,
    24,
    9.00,
    'smrkCw}tyLs@GTyBe@?i@Ae@JiCTM?K}@O}AI_AMgBAc@@gABK~@iCv@mBr@oB|@oCh@yANeAHc@JMdAsBt@yAcC}@kAg@sFwB{CiAoEkBeBaAiBmAsCsBi@c@M?KAyBuAuBoAwC}A_Ag@LeAdBmQJiAPwAh@kBf@iANY\s@dB{ClByD_Ag@qDuB}B}AgA}@w@y@{A{BYk@cAoBqAmDM@OGGIAMBe@DUGq@aAaFWcB]uCOSQm@Fg@NULAD?|@}@jDwEz@_BbA_CPYRUBELKJy@Hk@JUPc@h@}@fAsAj@k@|@gA^m@BQnBa@~Ac@tDqAdEwAfA[vBo@HOHOLc@BOI_@_@sBWsBWoDW}DOmEAgB@iBH_H@kBAkBR}I^oHf@mMd@cF^eELmALwDDgBf@uHVoCPqAjCiR\wBJsAd@{FTcBBo@Ac@KmAIqB@iD@gBE?GCGICM?MJ{ABEHGLo@b@aCf@aBj@uA\w@FSTW`@i@f@m@b@c@\YzBuAv@s@DSHGJIr@MNDPGfDg@zFeAtA[bDuAREQwBYkCHYPGvBAdD?'
)
ON CONFLICT (route_id) DO UPDATE SET
    origin_name = EXCLUDED.origin_name,
    destination_name = EXCLUDED.destination_name,
    waypoints = EXCLUDED.waypoints,
    distance_km = EXCLUDED.distance_km,
    duration_mins = EXCLUDED.duration_mins,
    fare_amount = EXCLUDED.fare_amount,
    encoded_polyline = EXCLUDED.encoded_polyline,
    updated_at = NOW();
