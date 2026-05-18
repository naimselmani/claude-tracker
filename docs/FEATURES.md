# Teli — Feature List

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18

---

## Core MVP Features (P0 — Must Ship)

These 15 features define the minimum viable product. The app must not ship without all P0 items complete and tested.

---

### Feature 1 — Motion-Controlled Instrument Playing
**Priority:** P0
**Description:** The primary interaction model. Users shake, tilt, or swipe the device to produce musical notes and chords from the currently loaded instrument. Motion is read from CoreMotion at 100Hz, smoothed with an exponential moving average, and mapped to audio trigger events. Each gesture type (shake, tilt, swipe) is handled by a separate detection path in the MotionEngine.

**Acceptance criteria:**
- Shake gesture reliably triggers audio within 30ms of threshold crossing
- Motion detection runs without UI lag or dropped frames
- Works on iPhone 12 through iPhone 16 series

---

### Feature 2 — Guitar Instrument
**Priority:** P0
**Description:** A six-string acoustic guitar with standard tuning. Includes chord mode (strum a preset chord on shake) and individual note access. Velocity layers (soft/medium/hard) are selected based on shake intensity. Reverb is applied at 15% wet mix by default.

**Acceptance criteria:**
- At least 4 chords playable (Am, G, C, D)
- 3 velocity layers per note produce perceptibly different dynamics
- Audio is clean, free of clipping or artifacts

---

### Feature 3 — Çiftelija Instrument
**Priority:** P0
**Description:** A double-stringed plucked instrument with a traditional Balkan character. Features scale preset selection (Traditional Phrygian, Major). Shorter cooldown and lower threshold than guitar to allow faster pluck patterns. Reverb at 20% wet mix.

**Acceptance criteria:**
- Two scale presets selectable from the play screen
- Scale notes trigger cleanly in sequence on swipe gesture
- Pluck texture audibly distinct from guitar

---

### Feature 4 — Lahuta Instrument
**Priority:** P0
**Description:** A one-stringed bowed instrument from the Albanian Highland tradition. Slow, controlled device movement simulates bowing; tilt angle selects pitch. Higher reverb (35% wet mix) creates sustained, archaic tone character.

**Acceptance criteria:**
- Bowing gesture produces a sustained note (not a sharp transient)
- Tilt mapping moves through at least 8 distinct pitches
- Reverb tail is audible and musically appropriate

---

### Feature 5 — Chord Selection (Guitar)
**Priority:** P0
**Description:** The play screen bottom area shows large pill-shaped chord buttons. Tapping a chord button selects it as the active chord. The selected state is visually distinct (amber highlight). Only one chord is active at a time. Chords are defined in instruments.json and loaded dynamically.

**Acceptance criteria:**
- Minimum 56pt tap target on all chord buttons
- Selected chord persists across shake gestures until user changes it
- Button labels use the chord name (e.g., "Am", "G")
- VoiceOver announces chord name on selection

---

### Feature 6 — Scale Preset Selection (Çiftelija)
**Priority:** P0
**Description:** Similar to chord selection, the Çiftelija play screen shows preset scale buttons. Selecting a preset changes the note set used for all subsequent gesture triggers.

**Acceptance criteria:**
- At least 2 scale presets available in v1.0 (Traditional, Major)
- Scale change takes effect immediately (no latency)
- VoiceOver announces preset name

---

### Feature 7 — Velocity-Sensitive Audio
**Priority:** P0
**Description:** The shake intensity (accelerometer magnitude above threshold) is mapped to a velocity value (0.0–1.0). This maps to one of three sample layers (soft: 0–33%, medium: 34–66%, hard: 67–100%). The playback volume is also linearly scaled from 0.3 to 1.0 across the intensity range. This creates expressive dynamics.

**Acceptance criteria:**
- Three perceptibly different dynamic levels
- Soft, medium, and hard samples are distinct recordings (not volume-scaled copies)
- Velocity mapping is smooth and predictable

---

### Feature 8 — Haptic Feedback
**Priority:** P0
**Description:** CoreHaptics (CHHapticEngine) plays a transient haptic event synchronized with each audio trigger. The haptic intensity is proportional to shake intensity. Three haptic patterns: "strum" (guitar), "pluck" (çiftelija), "bow" (lahuta). Haptics can be disabled in Settings.

**Acceptance criteria:**
- Haptic fires within 5ms of audio trigger
- Haptic intensity varies perceptibly between soft and hard strikes
- Haptic toggle in Settings immediately affects behavior

---

### Feature 9 — Per-Instrument Reverb
**Priority:** P0
**Description:** AVAudioUnitReverb is inserted in the audio chain after the player nodes and before the limiter. Each instrument has a configured wet/dry mix in instruments.json (guitar: 15%, çiftelija: 20%, lahuta: 35%). Users can adjust reverb wet mix via a slider in Settings (0–50% range).

**Acceptance criteria:**
- Reverb audibly present on all three instruments
- No reverb artifacts or feedback
- Settings slider updates reverb in real time

---

### Feature 10 — Anti-Clipping Limiter
**Priority:** P0
**Description:** AVAudioUnitEffect configured as a Dynamics Processor (limiter) sits at the end of the audio chain before the main output. Prevents digital clipping when multiple notes are triggered simultaneously (e.g., full chord strum with hard velocity).

**Acceptance criteria:**
- No audible digital clipping during any normal use scenario
- Limiter adds no perceptible latency (< 5ms)

---

### Feature 11 — Debounce and Cooldown System
**Priority:** P0
**Description:** Two complementary false-trigger prevention systems:
1. **Debounce:** Minimum configurable interval between successive triggers of the same note (default 80ms per instrument config).
2. **Cooldown:** After a gesture is detected, the motion engine enters a cooldown state (default 150ms) during which no new gesture is registered.
3. **Consecutive samples:** At least 3 consecutive samples above threshold required before a gesture fires.

**Acceptance criteria:**
- Shaking continuously does not produce faster-than-intentional note triggers
- Accidental pocket/bag motion does not trigger audio
- False-positive rate under normal use < 2%

---

### Feature 12 — Instrument Tutorial Overlay
**Priority:** P0
**Description:** On first launch of each instrument, a 3-step overlay tutorial is displayed over the play screen. Each step highlights a specific UI element and shows an instruction. Steps are defined in instruments.json per instrument. Tutorial state is stored in UserDefaults (one key per instrument ID). Users can dismiss early by tapping anywhere outside the highlight.

**Acceptance criteria:**
- Tutorial appears exactly once per instrument per installation
- All 3 steps are navigable with "Next" button
- VoiceOver reads instruction text for each step
- Dismissing early prevents re-showing on next launch

---

### Feature 13 — Settings Screen
**Priority:** P0
**Description:** Accessible from the instrument selection screen via a gear icon. Settings include:
- Haptic feedback toggle (on/off)
- Motion sensitivity adjustment (low/medium/high — scales shake threshold)
- Reverb wet mix slider (global override)
- Left-handed mode toggle (mirrors play screen UI horizontally)
- Reduced motion toggle (disables instrument animation on triggers)
- Link to Credits/Licenses screen
- Link to Privacy Policy (opens web browser to privacy policy URL)

**Acceptance criteria:**
- All settings persist across app restarts
- Left-handed mode mirrors layout correctly
- VoiceOver navigates all settings controls

---

### Feature 14 — Credits / Licenses Screen
**Priority:** P0
**Description:** Lists all audio sample licenses, third-party credits, open-source library attributions, and app version information. Required for App Store compliance.

**Acceptance criteria:**
- All sample sources documented
- Open-source licenses quoted in full where required
- App version number displayed
- Accessible via Settings screen

---

### Feature 15 — Dark Premium Visual Theme
**Priority:** P0
**Description:** The app uses a dark (#0D0D0D) background with warm amber/gold (#C8963E) accent color throughout. Instrument images are displayed large and centered in the upper play area. A subtle scale animation triggers on each successful gesture. Glass-morphism panels (`.ultraThinMaterial`) are used for control areas. Typography uses SF Pro Display for headings and SF Pro Text for body text.

**Acceptance criteria:**
- Consistent use of dark background and amber accent across all screens
- Instrument image animates on trigger (scale pulse, duration ~0.15s)
- All text passes WCAG AA contrast ratio (≥ 4.5:1) against dark background
- Animation is suppressed when Reduce Motion is enabled in system settings

---

## Future Phase Features

### Phase 2 / Phase 3 (Instrument Expansion)

| Feature | Description | Priority |
|---------|-------------|----------|
| Additional scale presets for Çiftelija | Add Chromatic, Hijaz, Rast scales | P1 |
| Note mode for Guitar | Single-note play mode alongside chord mode | P1 |
| Lahuta drone mode | Continuous sustain while device is in motion | P1 |
| Instrument image animation library | Multiple animations per instrument | P2 |

### Phase 4 (Recording & Export)

| Feature | Description | Priority |
|---------|-------------|----------|
| Session recording | Capture live performance to audio buffer | P1 |
| Export to .wav / .m4a | Export recording to Files app | P1 |
| Loop recording | Record a loop and play it back while adding layers | P2 |
| Metronome | Optional visual/haptic beat guide | P2 |

### Phase 5 (Android Port)

| Feature | Description | Priority |
|---------|-------------|----------|
| Android app parity with iOS MVP | All MVP features on Android | P0 for Phase 5 |
| Android-specific haptic patterns | Using VibrationEffect API | P1 |

### Phase 6 (Monetization)

| Feature | Description | Priority |
|---------|-------------|----------|
| StoreKit 2 integration | In-app purchase for instrument packs | P0 for Phase 6 |
| Premium instrument pack slot | UI card for locked instruments | P1 |
| Pro unlock IAP | Recording/export behind one-time purchase | P1 |
| Restore purchases | Required for App Store compliance | P0 for Phase 6 |

---

## Accessibility Features

| Feature | Description | Priority |
|---------|-------------|----------|
| VoiceOver support | All interactive elements labeled | P0 |
| Dynamic Type | All text scales with system font size setting | P0 |
| Reduce Motion mode | Suppresses trigger animations, keeps audio/haptics | P0 |
| Haptic toggle | Disable haptics independently of audio | P0 |
| Left-handed mode | Mirrors UI so controls are thumb-accessible on right side | P0 |
| High contrast | Respects system increased contrast setting | P1 |
| Button size compliance | Minimum 56pt tap targets on all interactive controls | P0 |
| Color-independent state | Selected/unselected states use shape+text, not color alone | P1 |

---

## Settings Features

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Haptic Feedback | Toggle | On | Enable/disable CoreHaptics output |
| Motion Sensitivity | Segment (Low/Med/High) | Medium | Scales shake threshold ×1.5 / ×1.0 / ×0.75 |
| Reverb Level | Slider 0–100% | Per instrument | Overrides instrument default wet mix |
| Left-Handed Mode | Toggle | Off | Mirrors play screen horizontally |
| Reduce Motion | Toggle | Follows system | Disables trigger animations |
| Instrument Tutorial Reset | Button | — | Resets all tutorial-seen flags |
| Privacy Policy | Link | — | Opens external browser |
| Credits & Licenses | Link | — | Opens in-app screen |
| App Version | Label | — | Displays current version string |
