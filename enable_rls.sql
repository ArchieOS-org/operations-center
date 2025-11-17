-- Enable Row Level Security on blocked tables
-- This activates existing policies and allows anonymous access with proper permissions

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.realtors ENABLE ROW LEVEL SECURITY;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('activities', 'staff', 'realtors', 'listings')
ORDER BY tablename;
