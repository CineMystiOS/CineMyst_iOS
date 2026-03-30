-- ============================================
-- PostgreSQL Function: get_or_create_conversation
-- ============================================
-- This function handles conversation creation on the server side,
-- ensuring the participant ordering constraint is satisfied.
--
-- Run this in your Supabase SQL Editor
-- ============================================

CREATE OR REPLACE FUNCTION get_or_create_conversation(
    user1_id UUID,
    user2_id UUID
)
RETURNS conversations
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    existing_conv conversations;
    new_conv conversations;
    p1_id UUID;
    p2_id UUID;
BEGIN
    -- Check that users are different
    IF user1_id = user2_id THEN
        RAISE EXCEPTION 'Cannot create conversation with yourself';
    END IF;
    
    -- Check if conversation already exists (both orderings)
    SELECT * INTO existing_conv
    FROM conversations
    WHERE (participant1_id = user1_id AND participant2_id = user2_id)
       OR (participant1_id = user2_id AND participant2_id = user1_id)
    LIMIT 1;
    
    -- Return existing conversation if found
    IF FOUND THEN
        RETURN existing_conv;
    END IF;
    
    -- Order participants: smaller UUID first
    IF user1_id < user2_id THEN
        p1_id := user1_id;
        p2_id := user2_id;
    ELSE
        p1_id := user2_id;
        p2_id := user1_id;
    END IF;
    
    -- Create new conversation with ordered participants
    INSERT INTO conversations (
        participant1_id,
        participant2_id,
        unread_count,
        created_at,
        updated_at
    )
    VALUES (
        p1_id,
        p2_id,
        0,
        NOW(),
        NOW()
    )
    RETURNING * INTO new_conv;
    
    RETURN new_conv;
END;
$function$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_or_create_conversation(UUID, UUID) TO authenticated;

-- ============================================
-- Explanation:
-- ============================================
-- This function:
-- 1. Checks if conversation already exists (both orderings)
-- 2. Returns existing conversation if found
-- 3. Orders participants by UUID (smaller first)
-- 4. Creates new conversation with correct ordering
-- 5. Returns the new conversation
--
-- Benefits:
-- - Handles ordering logic server-side (reliable)
-- - Avoids race conditions
-- - Single atomic operation
-- - Works regardless of client-side ordering logic
-- ============================================
