-- ============================================================================
-- bd_contacts — Thrive BD master contact list (added 11/9/26)
-- Run once in the Supabase SQL editor (project fussjixekyhwuromauff).
--
-- One row per business contact (never clients, never PHI). Rows come from:
--   web_form      → the public "Connect with Thrive" form (connect.html).
--                    Anyone on the internet can INSERT, nobody outside BD can READ.
--   bd_lead       → synced from a contact on a BD pipeline lead (appdata bd_leads)
--   county_board  → synced from the County Boards tab (appdata bd_boards)
--   manual        → typed into the Contacts tab by BD
--
-- A real table (not an appdata blob) so public submissions, BD edits and the
-- engagement import can all write at once without last-save-wins overwrites.
-- ============================================================================

create table if not exists public.bd_contacts (
  id                   uuid primary key default gen_random_uuid(),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  updated_by           text,

  -- where the contact came from
  source               text not null default 'web_form'
                       check (source in ('web_form','bd_lead','county_board','manual')),
  source_tag           text,          -- e.g. 'adamhs-deck', 'roads-to-recovery', 'email-signature'
  review_status        text not null default 'pending'
                       check (review_status in ('pending','accepted','dismissed')),
  reviewed_by          text,
  reviewed_at          timestamptz,

  -- the person
  first_name           text,
  last_name            text,
  title                text,
  org                  text,
  org_type             text,
  county               text,
  email                text,
  phone                text,
  interests            text[] not null default '{}',
  message              text,

  -- newsletter permission
  --   opted_in               checked the box on the form (or told BD yes)
  --   existing_relationship  business contact we already work with; can receive
  --                          the newsletter with an unsubscribe link
  --   not_asked              submitted the form but left the box unchecked → NOT exported
  --   opted_out              unsubscribed or asked to be removed → never exported
  newsletter_consent   text not null default 'not_asked'
                       check (newsletter_consent in ('opted_in','existing_relationship','not_asked','opted_out')),
  consent_at           timestamptz,

  -- links back into the hub
  lead_id              text,          -- bd_leads[].id
  board_id             text,          -- OHIO_BOARDS[].id
  owner                text,          -- BD owner initials/name

  -- marketing round-trip
  last_exported_at     timestamptz,
  engagement           jsonb not null default '[]'::jsonb,  -- [{issue, opened, clicked, replied, imported_at}]
  followup_status      text check (followup_status in ('needs_followup','routed','done')),
  followup_reason      text,
  followup_owner       text,
  followup_updated_at  timestamptz,

  -- keep junk out of a publicly writable table
  constraint bd_contacts_len check (
    coalesce(length(first_name),0) <= 80  and coalesce(length(last_name),0) <= 80 and
    coalesce(length(title),0)      <= 120 and coalesce(length(org),0)       <= 160 and
    coalesce(length(org_type),0)   <= 60  and coalesce(length(county),0)    <= 60  and
    coalesce(length(email),0)      <= 160 and coalesce(length(phone),0)     <= 40  and
    coalesce(length(message),0)    <= 1500 and coalesce(length(source_tag),0) <= 60 and
    coalesce(array_length(interests,1),0) <= 12
  )
);

create index if not exists bd_contacts_email_idx   on public.bd_contacts (lower(email));
create index if not exists bd_contacts_review_idx  on public.bd_contacts (review_status);
create index if not exists bd_contacts_follow_idx  on public.bd_contacts (followup_status);

alter table public.bd_contacts enable row level security;

-- ── Who can do what ────────────────────────────────────────────────────────
-- Public (anon) and any signed-in non-BD user: INSERT ONLY, and only a fresh,
-- pending web-form row. They get no SELECT, so the form posts with
-- Prefer: return=minimal and nobody can read the list back.
revoke all on public.bd_contacts from anon, authenticated;
grant insert (first_name, last_name, title, org, org_type, county, email, phone,
              interests, message, newsletter_consent, consent_at, source_tag)
  on public.bd_contacts to anon, authenticated;
grant select, insert, update on public.bd_contacts to authenticated;  -- narrowed by the policies below

drop policy if exists bd_contacts_public_insert on public.bd_contacts;
create policy bd_contacts_public_insert on public.bd_contacts
  for insert to anon, authenticated
  with check (
    source = 'web_form' and review_status = 'pending'
    and newsletter_consent in ('opted_in','not_asked')
    and lead_id is null and board_id is null and followup_status is null
    and engagement = '[]'::jsonb
    and email is not null and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  );

-- org_wide (BD hub users): full read, insert (sync/manual), and update.
drop policy if exists bd_contacts_orgwide_select on public.bd_contacts;
create policy bd_contacts_orgwide_select on public.bd_contacts
  for select to authenticated
  using (exists (select 1 from public.reviewers r where r.id = auth.uid() and r.role = 'org_wide'));

drop policy if exists bd_contacts_orgwide_insert on public.bd_contacts;
create policy bd_contacts_orgwide_insert on public.bd_contacts
  for insert to authenticated
  with check (exists (select 1 from public.reviewers r where r.id = auth.uid() and r.role = 'org_wide'));

drop policy if exists bd_contacts_orgwide_update on public.bd_contacts;
create policy bd_contacts_orgwide_update on public.bd_contacts
  for update to authenticated
  using      (exists (select 1 from public.reviewers r where r.id = auth.uid() and r.role = 'org_wide'))
  with check (exists (select 1 from public.reviewers r where r.id = auth.uid() and r.role = 'org_wide'));

-- No DELETE policy on purpose: dismissed / opted-out rows stay for the record
-- (an opted-out row is what keeps that email off future exports).

-- keep updated_at current
create or replace function public.bd_contacts_touch() returns trigger
language plpgsql as $$ begin new.updated_at := now(); return new; end $$;
drop trigger if exists bd_contacts_touch on public.bd_contacts;
create trigger bd_contacts_touch before update on public.bd_contacts
  for each row execute function public.bd_contacts_touch();
