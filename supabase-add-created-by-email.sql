-- Add the creator email for the internal editorial overview.
-- Run this once in Supabase SQL Editor.
alter table public.stories
  add column if not exists created_by_email text;

-- Backfill the email when a story already has a creator UUID matching the
-- currently authenticated user is not possible from this client-side migration.
-- Existing rows without an email will display "Unbekannt" until edited/updated.
