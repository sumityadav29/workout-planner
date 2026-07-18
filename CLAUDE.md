# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Summit** — a static weekly workout plan app, — a single self-contained `index.html` with no build step, package manager, tests, or linter. To run it, open the file directly or serve the repo root (e.g. `python3 -m http.server`).

Deployment is GitLab Pages: `.gitlab-ci.yml` copies `index.html` into `public/` on pushes to `main`. Any new file must be added to that CI script or it won't deploy.

## Architecture

`index.html` is a PostHog-styled page using the Tailwind CDN with a custom theme config (inline `tailwind.config`), plus vanilla JS. Content is **data-driven**: a `PLAN` array of day objects — `sections`/`ex` for lift days, `run` for cardio/rest days — rendered into `#panel` via template strings in `render()`. Edit the workout plan (exercises, sets, rest times, warm-ups/cool-downs) by editing `PLAN`, not the markup.

It's a two-view SPA with hash routing (`#home`/`#workout`, `showView()`/`go()`):

- **Home** (default): a month calendar (`renderCal()`) marking each past day green (all of that day's slots checked) or yellow (some), computed by `dayState()` from current-week state plus the `hist` archive. Below it, a "Start today's workout" button jumps to today's tab in the workout view.
- **Workout**: the day-tabs + exercise-checklist experience, with a "← Calendar" link back.

Conventions:

- Day indices are 0=Monday…6=Sunday; "today" is computed as `[6,0,1,2,3,4,5][new Date().getDay()]`.
- The `done` completion arrays are built by `daySlots()`: **slot 0 is the run** if the day has one (the "Mark run complete" button, so cardio shows on the calendar), followed by one slot per exercise; the rest day has none. Days can be run-only, lift-only, or hybrid (`run` + `sections`, e.g. intervals + core) — `render()` composes the run block and checklist from whichever fields exist, offsetting exercise toggle indices by 1 when a run slot is present.
- Each day has an accent color (`color` field, mapped through the `BADGE` and `BAR` lookup tables).
- Only today's plan is editable by default (`isEditable()`): other days render read-only — disabled checkboxes, no run/reset buttons — with a banner whose Edit button unlocks that day via `unlockDay()` (session-only `unlocked` set, resets on reload).
- The first unchecked slot is the "current activity": `render()` gives that row (or the run block) the day-accent tint and checkbox ring via `nextIdx`, and tags it `id="nextrow"`. Checking a slot smooth-scrolls to the new next (`scrollToNext()`); a finished rest timer auto-closes after 1.5s and pulses it (`pulseNext()`, `.pulse-next` keyframes).
- Rest timer overlay (SVG ring countdown, `openTimer`/`closeTimer`) with WebAudio `beep()` chimes and `navigator.vibrate` haptics. Rest durations are seconds in the `rs` field; the human-readable label is `r` (a `null` `r` renders "no rest →" for superset members, tagged via `ss`).

## Persistence and sync

Checkbox state persists offline-first, keyed by ISO week (`isoWeek()`, e.g. `2026-W29`) so the workout view auto-resets each Monday. **Supabase is the system of record; localStorage caches only the current week** (`wp-progress`: `{ week, done, pending }`; a short-lived multi-week `wp-progress-v2` format is migrated back on load). Past weeks live solely in Supabase and are held in the in-memory `hist` map (`week -> [[bool]]`) to feed the calendar — signed out, the calendar can only show the current week.

- Every `toggle()`/`resetDay()` calls `persist(day)`, which saves locally, marks the day in a `pending` set, and tries to push.
- Sync: email + password auth (Sign in button in the header becomes an avatar chip with a green/yellow sync-status dot; the sign-in form doubles as sign-up — magic-link/OTP was abandoned because iOS home-screen apps can't receive the Safari session, and free-tier Supabase can't customize email templates to include an OTP code). One row per `(user_id, week, day)` in the `progress` table, upserted per day. On sign-in/load, `pullAll()` fetches all weeks — but current-week days with pending local changes win over the server copy. Pending pushes are retried on the browser `online` event.
- The Supabase URL and publishable key are embedded in `index.html`; that's safe by design — access control is row-level security (see `supabase-setup.sql`, the one-time schema/policy setup run in the Supabase SQL editor; it is not deployed).
- The app degrades gracefully: if the Supabase CDN script or network is unavailable, everything still works locally (client init is wrapped in try/catch; `pushDay` no-ops without a session).
