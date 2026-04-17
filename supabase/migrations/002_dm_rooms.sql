-- =============================================================================
-- 1. Create all tables first (no cross-references at policy level yet)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.rooms (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.room_members (
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.direct_messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id          UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  sender_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_username  TEXT NOT NULL,
  content          TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT dm_content_not_empty  CHECK (char_length(trim(content)) > 0),
  CONSTRAINT dm_content_max_length CHECK (char_length(content) <= 2000)
);


-- =============================================================================
-- 2. Enable RLS on all three tables
-- =============================================================================

ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- 3. RLS policies (room_members now exists for all cross-references)
-- =============================================================================

-- rooms: users can only see rooms they belong to
-- (rows are inserted by the SECURITY DEFINER RPC, so no INSERT policy needed)
CREATE POLICY "rooms_select_member"
  ON public.rooms FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = rooms.id AND user_id = auth.uid()
    )
  );

-- room_members: users can see membership rows for rooms they belong to
-- (rows are inserted by the SECURITY DEFINER RPC, so no INSERT policy needed)
CREATE POLICY "room_members_select_member"
  ON public.room_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id AND rm.user_id = auth.uid()
    )
  );

-- direct_messages: users can read messages in rooms they belong to
CREATE POLICY "dm_select_member"
  ON public.direct_messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = direct_messages.room_id AND user_id = auth.uid()
    )
  );

-- direct_messages: users can only insert as themselves, in rooms they belong to
CREATE POLICY "dm_insert_own"
  ON public.direct_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = direct_messages.room_id AND user_id = auth.uid()
    )
  );

-- Messages are immutable (no UPDATE / DELETE policies)


-- =============================================================================
-- 4. Realtime publication
-- =============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;


-- =============================================================================
-- 5. RPC: get_or_create_dm_room(other_user_id)
--    Returns the room UUID for a DM between the caller and other_user_id.
--    Creates one atomically if it does not exist.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_dm_room(other_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  existing_room_id UUID;
  new_room_id      UUID;
BEGIN
  -- Look for an existing room shared by the caller and other_user_id
  SELECT rm1.room_id INTO existing_room_id
  FROM   public.room_members rm1
  JOIN   public.room_members rm2
         ON  rm1.room_id = rm2.room_id
  WHERE  rm1.user_id = auth.uid()
    AND  rm2.user_id = other_user_id
  LIMIT  1;

  IF existing_room_id IS NOT NULL THEN
    RETURN existing_room_id;
  END IF;

  -- Create a new room and add both members
  INSERT INTO public.rooms DEFAULT VALUES RETURNING id INTO new_room_id;
  INSERT INTO public.room_members (room_id, user_id) VALUES (new_room_id, auth.uid());
  INSERT INTO public.room_members (room_id, user_id) VALUES (new_room_id, other_user_id);

  RETURN new_room_id;
END;
$$;
