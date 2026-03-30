-- Query to check what constraints exist on the conversations table
-- Run this in your Supabase SQL Editor to see the actual constraint

SELECT 
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM 
    pg_constraint con
    INNER JOIN pg_class rel ON rel.oid = con.conrelid
    INNER JOIN pg_namespace nsp ON nsp.oid = connamespace
WHERE 
    rel.relname = 'conversations'
    AND con.contype = 'c'  -- 'c' means CHECK constraint
ORDER BY 
    con.conname;
