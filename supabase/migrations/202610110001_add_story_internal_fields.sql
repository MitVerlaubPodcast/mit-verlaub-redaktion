-- Add internal editorial fields for story research.
-- Run this once in the Supabase SQL Editor for the project used by redaktion.mitverlaub.de.
alter table public.stories
  add column if not exists top_comments text not null default '',
  add column if not exists translation_notes text not null default '';
