# Thrive Business Development

*Updated 10/29/26.*

The BD team's hub: Goals & Priorities, county caseload capacity, the leads pipeline, the Shared Leads inbox, Klip referral-source trends, and BD deliverables.

**Live URL:** `https://thrive-businessdevelopment.onrender.com` (linked from the Thrive Hub landing page)

## Files

- `index.html`: landing page (entry point)
- `business-development.html`: the dashboard

## Tabs

- **Overview:** the Goals & Priorities panel (the BD team enters these, key `bd_goals`) above the county caseload/capacity map and table.
- **Leads:** the pipeline (add, edit, delete; key `bd_leads`) plus the **Shared Leads inbox**. Staff send leads with "Share a Lead" in any hub, and they land in the `bd_lead_submissions` table. For each one, BD can add it to the pipeline, link it to an existing lead, or dismiss it. The submitter sees the outcome in their own hub.
- **Referral Volume:** hidden since 9/10/26. Bulk CSV import for `bd_referrals` lives in Data Hub.
- **Referral Insights:** a read-only Klip referral-source snapshot. It's built into the file and frozen as of `KLIP_SNAPSHOT_DATE` (9/1/26), so it isn't live.
- **Deliverables:** a read-only rollup over Leads for BD accountability.

## Sign-in

Supabase Auth plus the shared `reviewers` table. Only `role = 'org_wide'` gets in, and every org_wide account can both view and edit. Nothing loads before sign-in. Requests send the user's session token, not the anon key.

## Data

The page uses one shared Supabase project (`fussjixekyhwuromauff`):

- **Reads from `appdata`:** only these keys: `staff`, `pm_overrides`, `pd`, `bd_leads`, `bd_referrals`, `bd_goals`. They refresh every 60 seconds.
- **Writes to `appdata`:** `bd_leads`, `bd_referrals`, `bd_goals`, using the upsert-with-`on_conflict=key` pattern.
- **Reads and updates `bd_lead_submissions`:** a real table with RLS. Anyone signed in can insert rows and read their own; org_wide can read and update every row.
- **No client-level data:** leads are organizations and business contacts.

## Deploy

Render Static Site connected to this repo. Leave the build command empty, set the publish directory to the repo root, and add no environment variables. It auto-deploys on push to `main`.

## Gotchas

- `bd_leads` is saved as a single array. If two people edit leads at the same moment, the last save wins. That's fine for one BD lead. Move it to a real table if the team grows.
- Organization matching (Leads ↔ Klip ↔ inbox) uses `orgNamesMatch()`/`normOrgName()`, which compares normalized names word by word. There's no shared Organization table yet.
- The `PROVIDER_MAP_DATA` seed holds no notes or hire dates (stripped 10/29/26, because this file is publicly served). Overview's note signals come from the live `pm_overrides` notes and the roster note field.

