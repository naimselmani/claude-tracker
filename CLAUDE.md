# Claude Tracker — Project Guide

This file tells Claude Code how this repository works.

---

## Repository purpose

This is the development workspace for **Teli** — a motion-controlled virtual instrument web app (Guitar, Çiftelija, Lahuta). The repo also contains full iOS Swift architecture, documentation, and deployment automation.

---

## Branch & deployment model

### Feature branches
- All work happens on feature branches (e.g. `claude/some-feature-XxXx`)
- Every push to a feature branch automatically deploys a **preview**
- Preview URL format:
  ```
  https://naimselmani.github.io/claude-tracker/preview/{sanitized-branch-name}/
  ```
  Branch name is lowercased; `/`, `_`, spaces → `-`; non-alphanumeric chars stripped.
- If a PR is open for the branch, the preview URL is posted/updated as a PR comment automatically

### Main branch (production)
- Merging to `main` triggers the **production deploy**
- Production URL:
  ```
  https://naimselmani.github.io/claude-tracker/
  ```
- The `web/` folder is deployed to the root of `gh-pages`
- Existing `previews/` subfolders on `gh-pages` are preserved (`keep_files: true`)

### PR closed / branch deleted
- When a PR is closed (merged or abandoned), the preview subfolder is automatically removed from `gh-pages`

---

## GitHub Actions workflows

| File | Trigger | What it does |
|------|---------|--------------|
| `.github/workflows/pages.yml` | Push to **any branch** (+ manual) | Single workflow: main → prod root, any other branch → `gh-pages/preview/{slug}/`; posts/updates preview URL comment on open PRs |
| `.github/workflows/cleanup-preview.yml` | PR closed | Removes `gh-pages/preview/{slug}/` |

Key details of `pages.yml` (aligned with xhevops-claude/claude-default pattern):
- Concurrency group `pages-deploy` — serialises deploys, no gh-pages conflicts
- Slug: branch name lowercased, `/`, `_`, spaces → `-`, non-alphanumeric stripped
- Cache-busting on preview: appends `?v=<sha>` to `.js`/`.css` refs in HTML so browsers never serve stale assets
- Uses `peaceiris/actions-gh-pages@v4` with `keep_files: true` so prod and previews coexist
- Prints deploy URL as a GitHub Actions notice after every deploy

### GitHub Pages setup (one-time)
In repo **Settings → Pages**:
- Source: `Deploy from a branch`
- Branch: `gh-pages`
- Folder: `/ (root)`

The repo must be **public** (or GitHub Enterprise) for Pages to be free.

---

## Project structure

```
web/                        # The deployable web app (single HTML file)
  index.html                # Teli — Guitar & Çiftelija, Karplus-Strong synthesis

teli-ios/                   # Native iOS Swift skeleton
  TeliApp/
    Config/instruments.json # Instrument definitions (shared source of truth)
    Sources/
      App/                  # Entry point, AppState
      AudioEngine/          # AVAudioEngine, Karplus-Strong inspired design
      MotionEngine/         # CoreMotion shake/tilt/swipe detection
      Models/               # Codable data models
      ViewModels/           # ObservableObject play logic
      Views/                # SwiftUI screens

docs/                       # Full architecture documentation
  APP_SPEC.md
  FEATURES.md
  TECHNICAL_ARCHITECTURE.md
  AUDIO_ENGINE_DESIGN.md
  MOTION_ENGINE_DESIGN.md
  UX_DESIGN.md
  LEGAL_IP_CHECKLIST.md
  APPSTORE_CHECKLIST.md
  GOOGLEPLAY_CHECKLIST.md
  MVP_ROADMAP.md
  TESTING_CHECKLIST.md
  MONETIZATION.md
  FOLDER_STRUCTURE.md
  SAMPLE_NAMING_CONVENTION.md

.github/workflows/          # CI/CD (see above)
```

---

## Web app (`web/index.html`)

- Single self-contained HTML file — no build step, no dependencies
- Sounds synthesised in-browser via Karplus-Strong algorithm (Web Audio API)
- Motion via `DeviceMotionEvent` (requires HTTPS + user permission on iOS 13+)
- Swipe-to-strum via touch events (fallback when motion not available)
- Works offline once loaded; installable as PWA via Safari "Add to Home Screen"

**To test locally:**
```bash
cd web
python3 -m http.server 8080
# Open http://localhost:8080 in browser
# Note: DeviceMotion requires HTTPS — use preview URL for iPhone testing
```

---

## Instruments

| ID | Name | Sound model | Motion |
|----|------|-------------|--------|
| `guitar` | Guitar | 6-string KS, no detune | Shake = strum chord, swipe = strum, tilt shown |
| `ciftelija` | Çiftelija | 2-course KS, +9¢ detune | Shake = pluck note, tap = select note |
| `lahuta` | Lahuta | planned Phase 3 | bow simulation |

Instrument config lives in `teli-ios/TeliApp/Config/instruments.json`.

---

## Audio sample naming convention

If real samples are added later (Phase 3+):
```
{instrument}_{note}_{velocity}.wav
```
- `note`: scientific pitch, `#` written as `s` (e.g. `Fs4`)
- `velocity`: `soft` | `medium` | `hard`
- Format: 44100 Hz, 16-bit mono WAV, peak –3 dBFS, silence < 5 ms at start

---

## Development rules

- **Never merge or push to `main` without explicit user instruction.** All work stays on feature branches until the user says "merge to main" or equivalent.
- All new instrument/feature work goes on a feature branch — never commit directly to `main`
- The `web/index.html` must remain a **single self-contained file** (no external CDN links, no separate JS/CSS files)
- Do not add tracking, analytics, or user accounts to the web app
- Do not collect personal data — privacy policy: no data collected in MVP
- Keep `instruments.json` as the single source of truth for instrument config
- Before merging to main, verify the preview URL works on a real iPhone
