-- ====================================================================
-- TRANSIT AI / PRAVHA: COMMUNITY ASK ROUTE - EDIT & DELETE MIGRATION
-- Enables creators to edit and delete their posted route questions.
--
-- INSTRUCTIONS TO RUN:
-- 1. Open Supabase Dashboard: https://supabase.com/dashboard
-- 2. Select your project: 'your-project-id'
-- 3. Click "SQL Editor" on the left navigation bar
-- 4. Click "New Query", paste this entire script, and click "Run" (▶)
-- ====================================================================

-- 1. Add user_id and updated_at columns to route_questions if they don't already exist
ALTER TABLE public.route_questions 
    ADD COLUMN IF NOT EXISTS user_id TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Create index on user_id for faster query lookups
CREATE INDEX IF NOT EXISTS idx_route_questions_user_id 
    ON public.route_questions(user_id);

-- 3. Ensure Row Level Security (RLS) is enabled
ALTER TABLE public.route_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_answers ENABLE ROW LEVEL SECURITY;

-- 4. Enable DELETE & UPDATE policies on route_questions
DROP POLICY IF EXISTS "Public delete route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Allow public delete on route_questions" ON public.route_questions;
CREATE POLICY "Public delete route_questions" 
    ON public.route_questions FOR DELETE 
    USING (true);

DROP POLICY IF EXISTS "Public update route_questions" ON public.route_questions;
DROP POLICY IF EXISTS "Allow public update on route_questions" ON public.route_questions;
CREATE POLICY "Public update route_questions" 
    ON public.route_questions FOR UPDATE 
    USING (true)
    WITH CHECK (true);

-- 5. Enable DELETE policy on route_answers so replies can also be removed
DROP POLICY IF EXISTS "Public delete route_answers" ON public.route_answers;
DROP POLICY IF EXISTS "Allow public delete on route_answers" ON public.route_answers;
CREATE POLICY "Public delete route_answers" 
    ON public.route_answers FOR DELETE 
    USING (true);

-- 6. Ensure foreign key constraint cascades on delete
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'route_answers_question_id_fkey'
    ) THEN
        ALTER TABLE public.route_answers 
            DROP CONSTRAINT route_answers_question_id_fkey;
    END IF;
    
    ALTER TABLE public.route_answers
        ADD CONSTRAINT route_answers_question_id_fkey 
        FOREIGN KEY (question_id) 
        REFERENCES public.route_questions(id) 
        ON DELETE CASCADE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Foreign key setup notice: %', SQLERRM;
END $$;
