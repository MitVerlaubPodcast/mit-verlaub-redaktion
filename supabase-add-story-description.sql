-- Einmalig im Supabase SQL Editor ausführen.
-- Ergänzt eine öffentliche Kurzbeschreibung und synchronisiert sie nach dem bestehenden Website-Sync.

ALTER TABLE public.stories
  ADD COLUMN IF NOT EXISTS description text;

ALTER TABLE public.website_stories
  ADD COLUMN IF NOT EXISTS description text;

CREATE OR REPLACE FUNCTION public.sync_website_story_description()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Der bestehende sync_website_story-Trigger läuft vorher.
  -- Nur bereits veröffentlichte und freigegebene Stories bekommen eine öffentliche Beschreibung.
  IF NEW.status = 'published' AND NEW.approved_for_website = true THEN
    UPDATE public.website_stories
    SET description = NEW.description
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS zzz_sync_website_story_description ON public.stories;

CREATE TRIGGER zzz_sync_website_story_description
AFTER INSERT OR UPDATE OF description, status, approved_for_website
ON public.stories
FOR EACH ROW
EXECUTE FUNCTION public.sync_website_story_description();
