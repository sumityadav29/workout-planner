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
- Completion state is in-memory only — no localStorage; a reload resets all checkboxes. This is intentional simplicity, not an oversight to fix in passing.
