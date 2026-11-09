# Thrive Business Development

*Updated 11/9/26.*

The BD team's hub: Goals & Priorities, county caseload capacity, the leads pipeline, the Shared Leads inbox, County Boards outreach, the newsletter contact list, Klip referral-source trends, and BD deliverables.

**Live URL:** `https://thrive-businessdevelopment.onrender.com` (linked from the Thrive Hub landing page)

## Files

- `index.html`: landing page (entry point)
- `business-development.html`: the dashboard
- `connect.html`: the **public** "Connect with Thrive" lead form (the only page here meant for people outside Thrive). Share it as `connect.html?src=<tag>` so each contact shows where it came from. The board overview deck's QR code points to `?src=adamhs-deck`.
- `bd_contacts.sql`: run once in Supabase before the Contacts tab or the public form will work.

## Tabs

- **Overview:** the Goals & Priorities panel (the BD team enters these, key `bd_goals`) above the county caseload/capacity map and table.
- **Leads:** the pipeline (add, edit, delete; key `bd_leads`) plus the **Shared Leads inbox**. Staff send leads with "Share a Lead" in any hub, and they land in the `bd_lead_submissions` table. For each one, BD can add it to the pipeline, link it to an existing lead, or dismiss it. The submitter sees the outcome in their own hub.
- **Contacts** (11/9/26): the master contact list for the external newsletter.
  - **Website Inbox:** submissions from `connect.html`. For each: add and link to a matching lead, add and create a lead, add to contacts only, or dismiss (spam/duplicates). An email that's already in the list merges into the existing contact.
  - **Follow-up Queue:** contacts flagged by an engagement import. Route to a BD owner (logs activity on the linked lead and sets a follow-up date), add to the pipeline, or mark done.
  - **Quarterly export:** platform-neutral CSV of newsletter-ready contacts only (opted in, or an existing relationship). "New since last export" for routine quarters, "full list" for the first one, plus a do-not-email list for marketing's suppression list.
  - **Engagement import:** upload the platform's contact or activity report after each issue. Matches by email. Clicks and replies go to the Follow-up Queue (opens optional, off by default), and unsubscribes become opted out.
  - **Sync from Leads & County Boards:** copies every lead/board contact with an email into the list as an existing relationship. Re-runnable; existing emails are skipped.
- **County Boards:** all 49 Ohio ADAMH/MHRS boards with outreach tracking and the intro-letter template (key `bd_boards`).
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
- **Reads and updates `bd_contacts`:** a real table with RLS. The public (anon) can only **insert** a pending web-form row and can't read anything; org_wide can read, insert and update. No deletes, so opted-out rows keep those emails off future exports.
- **No client-level data:** leads and contacts are organizations and business contacts. The public form tells people not to include anyone's name or health details.

## Deploy

Render Static Site connected to this repo. Leave the build command empty, set the publish directory to the repo root, and add no environment variables. It auto-deploys on push to `main`.

## Gotchas

- `connect.html` posts with a plain `fetch` and the anon key (not supabase-js), so a staff browser that's signed in still submits as the public. Spam guards are a hidden honeypot field and a 3-second minimum; there's no rate limit, so watch the Website Inbox and use Dismiss.
- Newsletter permission values: `opted_in` (form box checked, or told BD yes), `existing_relationship` (synced business contact; send with an unsubscribe link), `not_asked` (form box unchecked; never exported), `opted_out` (never exported).

- `bd_leads` is saved as a single array. If two people edit leads at the same moment, the last save wins. That's fine for one BD lead. Move it to a real table if the team grows.
- Organization matching (Leads ↔ Klip ↔ inbox) uses `orgNamesMatch()`/`normOrgName()`, which compares normalized names word by word. There's no shared Organization table yet.
- The `PROVIDER_MAP_DATA` seed holds no notes or hire dates (stripped 10/29/26, because this file is publicly served). Overview's note signals come from the live `pm_overrides` notes and the roster note field.


