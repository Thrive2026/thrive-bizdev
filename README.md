# Thrive Business Development

Standalone hub in the Thrive Tools ecosystem — leads pipeline and referral-source
volume tracking for the BD team, with a weekly "This Week's Focus" panel that flags
where to prioritize outreach energy.

## Files

- `index.html` — landing page (entry point)
- `business-development.html` — the dashboard itself (Overview / Leads / Referral Volume tabs)

## Stack

Single-file HTML/CSS/JS, no build step. Same shared Supabase project as the rest of
the ecosystem (`fussjixekyhwuromauff.supabase.co`), using the generic `appdata`
key/value table (`bd_leads`, `bd_referrals` keys). Same design system as the other
Thrive hub landing pages: Fraunces + IBM Plex Sans/Mono, navy `#3c50a0` / yellow
`#f0c814` on `#f7f3ec`.

Login gate is Supabase Auth + the shared `reviewers` table (`role='org_wide'`),
same pattern as Case Review Hub and Director Hub.

## Deploy

Same as every other hub in this ecosystem: push to GitHub, connect the repo in
Render as a static site (or Node static server, matching however thrive-hub /
Thrive-Tools are currently deployed), auto-deploy on push to `main`.

## Setting this up as its own repo

This folder is git-initialized with one commit, ready to push:

```
git remote add origin https://github.com/Thrive2026/<repo-name>.git
git branch -M main
git push -u origin main
```

Pick a repo name consistent with the other two (`thrive-hub`, `Thrive-Tools`) —
e.g. `Thrive2026/thrive-bizdev` or `Thrive2026/thrive-business-development`.
