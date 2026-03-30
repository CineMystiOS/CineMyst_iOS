-- Fix RLS policies for applications table
-- This allows directors to update applications for their jobs

-- First, check if the policy exists and drop it if needed
DROP POLICY IF EXISTS "Directors can update applications for their jobs" ON applications;

-- Create the UPDATE policy
CREATE POLICY "Directors can update applications for their jobs"
ON applications
FOR UPDATE
USING (
  -- The director owns the job this application is for
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = applications.job_id
    AND jobs.director_id = auth.uid()
  )
)
WITH CHECK (
  -- Same check for the new values
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = applications.job_id
    AND jobs.director_id = auth.uid()
  )
);

-- Also ensure there's a SELECT policy (for reading)
DROP POLICY IF EXISTS "Directors can view applications for their jobs" ON applications;

CREATE POLICY "Directors can view applications for their jobs"
ON applications
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = applications.job_id
    AND jobs.director_id = auth.uid()
  )
);

-- Verify RLS is enabled
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
