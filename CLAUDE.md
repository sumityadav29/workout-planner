# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A static weekly workout plan app — a single self-contained `index.html` with no build step, package manager, tests, or linter. To run it, open the file directly or serve the repo root (e.g. `python3 -m http.server`).

Deployment is GitLab Pages: `.gitlab-ci.yml` copies `index.html` into `public/` on pushes to `main`. Any new file must be added to that CI script or it won't deploy.

## Architecture

`index.html` is a PostHog-styled page using the Tailwind CDN with a custom theme config (inline `tailwind.config`), plus vanilla JS. Content is **data-driven**: a `PLAN` array of day objects — `sections`/`ex` for lift days, `run` for cardio/rest days — rendered into `#panel` via template strings in `render()`. Edit the workout plan (exercises, sets, rest times, warm-ups/cool-downs) by editing `PLAN`, not the markup.

Conventions:

- Day indices are 0=Monday…6=Sunday; "today" is computed as `[6,0,1,2,3,4,5][new Date().getDay()]`.
- Each day has an accent color (`color` field, mapped through the `BADGE` and `BAR` lookup tables).
- Rest timer overlay (SVG ring countdown, `openTimer`/`closeTimer`) with WebAudio `beep()` chimes and `navigator.vibrate` haptics. Rest durations are seconds in the `rs` field; the human-readable label is `r` (a `null` `r` renders "no rest →" for superset members, tagged via `ss`).

## Persistence and sync

Checkbox state persists offline-first, keyed by ISO week (`isoWeek()`, e.g. `2026-W29`) so progress auto-resets each Monday:

- **localStorage** (`wp-progress`) is the source of truth: every `toggle()`/`resetDay()` calls `persist(day)`, which saves locally, marks the day in a `pending` set, and tries to push.
- **Supabase** layers cross-device sync on top: magic-link email auth (Sync button in the header), one row per `(user_id, week, day)` in the `progress` table, upserted per day. On sign-in/load, `pullWeek()` fetches the week's rows — but days with pending local changes win over the server copy. Pending pushes are retried on the browser `online` event.
- The Supabase URL and publishable key are embedded in `index.html`; that's safe by design — access control is row-level security (see `supabase-setup.sql`, the one-time schema/policy setup run in the Supabase SQL editor; it is not deployed).
- The app degrades gracefully: if the Supabase CDN script or network is unavailable, everything still works locally (client init is wrapped in try/catch; `pushDay` no-ops without a session).
