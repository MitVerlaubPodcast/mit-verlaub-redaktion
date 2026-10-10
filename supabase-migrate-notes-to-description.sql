-- Einmalig im Supabase SQL Editor ausführen.
-- Verschiebt die bisherigen Vorschautexte aus "Notizen für die Aufnahme" (notes)
-- in das öffentliche Feld "Vorschautext für die Seite" (description).
--
-- Sicherheitsverhalten:
-- 1. Überschreibt keine bereits vorhandene description.
-- 2. Verschiebt nur nicht-leere notes in eine leere description.
-- 3. Leert notes erst bei den Zeilen, deren Text tatsächlich verschoben wurde.
-- 4. Der vorhandene Sync-Trigger aktualisiert damit auch veröffentlichte Website-Storys.

WITH moved AS (
  UPDATE public.stories
  SET
    description = NULLIF(BTRIM(notes), ''),
    notes = NULL,
    updated_at = NOW()
  WHERE NULLIF(BTRIM(notes), '') IS NOT NULL
    AND NULLIF(BTRIM(description), '') IS NULL
  RETURNING id, description, status, approved_for_website
)
SELECT
  COUNT(*) AS verschobene_vorschautexte,
  COUNT(*) FILTER (
    WHERE status = 'published' AND approved_for_website = true
  ) AS davon_auf_website_veroeffentlicht
FROM moved;
