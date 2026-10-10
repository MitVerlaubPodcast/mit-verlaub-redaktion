-- Mit Verlaub Redaktion: Folgenverwaltung
-- Einmal im Supabase SQL Editor ausführen, bevor die aktualisierte Redaktion benutzt wird.
-- Die Migration ergänzt die Folgenstruktur und übernimmt vorhandene Folgenzuordnungen.
-- Sie lässt die bestehende stories-Tabelle und den Website-Sync intakt.

CREATE TABLE IF NOT EXISTS public.episodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_number integer NOT NULL UNIQUE CHECK (episode_number > 0),
  title text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'recorded', 'published')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by_email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.episode_stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_id uuid NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  story_id uuid NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_episode', 'archived')),
  proposed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  proposed_by_email text,
  position integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (episode_id, story_id)
);

CREATE INDEX IF NOT EXISTS episode_stories_episode_idx
  ON public.episode_stories (episode_id, position, created_at);
CREATE INDEX IF NOT EXISTS episode_stories_story_idx
  ON public.episode_stories (story_id);

ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.episode_stories ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.episodes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.episode_stories TO authenticated;

DROP POLICY IF EXISTS "Authenticated users can manage episodes" ON public.episodes;
CREATE POLICY "Authenticated users can manage episodes"
  ON public.episodes FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can manage episode stories" ON public.episode_stories;
CREATE POLICY "Authenticated users can manage episode stories"
  ON public.episode_stories FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- Bestehende Folgennummern aus stories übernehmen, ohne bestehende Einträge zu überschreiben.
INSERT INTO public.episodes (episode_number, title, status)
SELECT
  s.episode_number,
  'Folge ' || s.episode_number,
  CASE
    WHEN bool_or(s.status = 'published' AND COALESCE(s.approved_for_website, false)) THEN 'published'
    WHEN bool_or(s.status = 'recorded') THEN 'recorded'
    ELSE 'draft'
  END
FROM public.stories s
WHERE s.episode_number IS NOT NULL AND s.episode_number > 0
GROUP BY s.episode_number
ON CONFLICT (episode_number) DO NOTHING;

INSERT INTO public.episode_stories (
  episode_id, story_id, status, proposed_by, proposed_by_email, created_at, updated_at
)
SELECT
  e.id,
  s.id,
  CASE WHEN s.status = 'published' THEN 'in_episode' ELSE 'open' END,
  s.created_by,
  s.created_by_email,
  COALESCE(s.created_at, now()),
  COALESCE(s.updated_at, now())
FROM public.stories s
JOIN public.episodes e ON e.episode_number = s.episode_number
WHERE s.episode_number IS NOT NULL AND s.episode_number > 0
ON CONFLICT (episode_id, story_id) DO NOTHING;
