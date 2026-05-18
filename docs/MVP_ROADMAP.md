# Teli — MVP Development Roadmap

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18
**Total estimated timeline:** 25 weeks (6 phases)

---

## Overview

| Phase | Name | Duration | Cumulative |
|-------|------|----------|-----------|
| 1 | iOS Guitar Prototype | 4 weeks | Week 4 |
| 2 | Add Çiftelija | 3 weeks | Week 7 |
| 3 | Add Lahuta | 3 weeks | Week 10 |
| 4 | Recording & Export | 3 weeks | Week 13 |
| 5 | Android Version | 8 weeks | Week 21 |
| 6 | Monetization | 4 weeks | Week 25 |

---

## Phase 1: iOS Guitar Prototype

**Duration:** 4 weeks
**Goal:** Deliver a functional single-instrument iOS app with the guitar, motion control, and all core infrastructure in place. This phase proves the core concept and establishes the architecture that all subsequent phases build on.

### Week 1: Foundation & Architecture

**Goals:**
- Xcode project created, Swift Package Manager configured
- Folder structure established per `FOLDER_STRUCTURE.md`
- `instruments.json` schema finalized and first guitar entry written
- `InstrumentConfig.swift` models implemented and JSON decoding working
- `AppState` loading instruments from bundle
- Basic SwiftUI navigation shell: InstrumentSelectView → PlayView skeleton

**Deliverables:**
- [ ] Xcode project compiles and runs on simulator
- [ ] instruments.json decoded correctly into InstrumentConfig models
- [ ] NavigationStack navigation between InstrumentSelectView and PlayView

**Acceptance Criteria:**
- JSON decode unit tests pass for all model types
- Navigation links function correctly
- No force-unwraps in production code paths

**Risks:**
- JSON schema changes late in phase cause model refactoring — mitigate by finalizing schema in week 1 before writing dependent code

---

### Week 2: Motion Engine

**Goals:**
- `MotionEngine.swift` fully implemented per `MOTION_ENGINE_DESIGN.md`
- Shake detection working on physical device
- Tilt detection working on physical device
- Gesture state machine implemented and tested
- Combine publisher emitting `MotionGesture` events
- Unit tests for velocity mapping, threshold logic, debounce

**Deliverables:**
- [ ] Shake gesture detected reliably on iPhone 12, 13, 14, 15
- [ ] Tilt angle published continuously
- [ ] False-positive rate < 2% (manual test protocol defined)
- [ ] Unit tests for `mapIntensityToVelocity`, `detectShake` threshold logic

**Acceptance Criteria:**
- Shake triggers in < 30ms from threshold crossing (measured)
- 3-consecutive-sample requirement prevents single-bump false trigger
- Motion engine stops completely when `stop()` is called

**Risks:**
- Simulator cannot test motion — all motion testing requires physical device. Ensure device-based testing is in the workflow from day one.
- Calibration of threshold values may require iteration. Budget 1 day for calibration with physical testers.

---

### Week 3: Audio Engine

**Goals:**
- `AudioEngine.swift` fully implemented per `AUDIO_ENGINE_DESIGN.md`
- AVAudioEngine graph set up with reverb and limiter
- Sample preloading from bundle working
- `triggerNote` function with debounce implemented
- Velocity layer selection implemented
- Placeholder guitar samples added to bundle (3 notes × 3 velocities minimum for prototype)

**Deliverables:**
- [ ] Three guitar notes (e.g., A3, D3, G3) with soft/medium/hard layers preloaded and playable
- [ ] Audio trigger latency < 30ms (measured with test harness)
- [ ] Debounce guard preventing rapid-fire repeats
- [ ] Reverb audible at 15% wet mix
- [ ] Limiter preventing clipping on simultaneous note triggers

**Acceptance Criteria:**
- Playing a chord (3 simultaneous notes) does not produce audible clipping
- Changing from one instrument back to the same instrument does not require engine restart
- Audio continues after device screen lock (`.playback` category confirmed)

**Risks:**
- Placeholder samples may have poor audio quality — use high-quality royalty-free samples from day one, not generated tones
- Audio latency may exceed 30ms on older hardware — test early and adjust `preferredIOBufferDuration` if needed

---

### Week 4: Integration, UI Polish, Testing

**Goals:**
- `PlayViewModel` connecting MotionEngine gestures to AudioEngine triggers
- `InstrumentVisualView` with shake animation
- Chord buttons (Am, G, C, D) functional with visual selection state
- Settings screen (haptic toggle, sensitivity, reverb slider)
- Tutorial overlay (3 steps for guitar)
- Credits screen
- Haptic feedback via CoreHaptics
- VoiceOver labels on all controls
- Full guitar chord set (Am, G, C, D, Em, F) — all notes of each chord sampled
- TestFlight internal beta build created

**Deliverables:**
- [ ] Complete guitar experience end-to-end
- [ ] Tutorial overlay shown on first launch, not repeated
- [ ] Settings persist across restarts
- [ ] Haptic feedback synchronized with audio
- [ ] VoiceOver narration tested for all interactive elements
- [ ] TestFlight build uploaded

**Acceptance Criteria:**
- 30-minute guitar play session completes without crash on iPhone 12 and iPhone 15 Pro
- CPU < 15%, memory < 150MB throughout session
- All chord buttons are accessible via VoiceOver
- Tutorial can be dismissed and does not re-appear

**Risks:**
- Haptic engine fails to start on some devices — implement silent fallback
- Full chord sample set may be large — measure IPA size and optimize if needed

---

## Phase 2: Add Çiftelija

**Duration:** 3 weeks
**Goal:** Add the Çiftelija instrument to the app, demonstrating that the JSON-driven architecture supports a second instrument with a distinct playing style (scale presets instead of chords, faster debounce, different motion profile).

### Weeks 5–6: Çiftelija Implementation

**Goals:**
- Çiftelija entry added to `instruments.json`
- Scale preset selection UI (replacing chord buttons)
- Swipe gesture detection in MotionEngine (not used by guitar)
- Çiftelija audio samples recorded and added to bundle
- Motion profile tuned (lower threshold, shorter cooldown) for pluck character
- Tutorial overlay for Çiftelija (3 steps)

**Deliverables:**
- [ ] Two scale presets (Traditional Phrygian, Major) selectable
- [ ] Swipe gesture triggers note run
- [ ] Çiftelija samples: 8 notes × 3 velocity layers = 24 samples
- [ ] Motion profile distinct from guitar (perceptibly different feel)

**Acceptance Criteria:**
- Selecting Çiftelija from instrument list loads Çiftelija-specific motion and audio config
- Playing Çiftelija does not produce accidental guitar samples (correct `samplePrefix` used)
- Tutorial shows scale-specific instructions

**Risks:**
- Swipe detection conflict with shake detection — implement priority logic (shake takes precedence over swipe during shake cooldown)
- Sample recording quality — use same recording conditions as guitar samples for consistency

### Week 7: Integration & Testing

**Goals:**
- Full regression test of guitar after Çiftelija addition
- Instrument switching (guitar → çiftelija → guitar) tested
- Memory verified: both instruments preloaded sequentially, not simultaneously
- TestFlight build with both instruments

**Acceptance Criteria:**
- Switching instruments updates motion profile and audio config without audio artifacts
- Memory stays < 150MB regardless of which instrument is active
- No guitar samples play when Çiftelija is selected

---

## Phase 3: Add Lahuta

**Duration:** 3 weeks
**Goal:** Add the Lahuta instrument, which has the most distinct playing model (bowing, continuous sustained motion, tilt-based pitch). This phase also completes the MVP instrument set.

### Weeks 8–9: Lahuta Implementation

**Goals:**
- Lahuta entry added to `instruments.json`
- Bow gesture: slow, sustained motion (lower threshold, sustained trigger model)
- Tilt-to-note mapping for Lahuta (continuous pitch change)
- Lahuta audio samples: 8 notes × 3 velocity layers = 24 samples, with natural sustain
- Higher reverb (35% wet mix) configured
- Tutorial overlay for Lahuta (3 steps)

**Deliverables:**
- [ ] Lahuta "bow" gesture feels distinct from guitar strum
- [ ] Tilt changes which note plays (at minimum 8 distinct pitch positions)
- [ ] Reverb tail noticeably longer than guitar
- [ ] Tutorial correctly describes the bowing metaphor

**Acceptance Criteria:**
- Sustained bowing motion produces continuously triggered notes (not a single trigger)
- Tilt-pitch mapping covers the full G3–G4 note range
- Lahuta reverb tail audible for ≥ 1.5 seconds after trigger

**Risks:**
- Sustained trigger model requires different state machine handling — may conflict with cooldown. Design: during bow motion, cooldown is shortened to 50ms to allow re-triggering.
- Sample sustain quality is critical — recorded samples must have natural sustain of ≥ 2s

### Week 10: Polish, Full Regression, App Store Prep

**Goals:**
- All three instruments tested end-to-end
- App Store screenshots captured on iPhone 15 Pro Max and iPhone 15
- Privacy Nutrition Labels verified
- App Store listing text written and reviewed
- Legal IP checklist completed
- Onboarding flow finalized
- App Store submission ready

**Acceptance Criteria:**
- All items in `APPSTORE_CHECKLIST.md` checked
- All items in `LEGAL_IP_CHECKLIST.md` checked
- App submitted to App Store review

---

## Phase 4: Recording & Export Feature

**Duration:** 3 weeks
**Goal:** Add the ability to record a live performance session and export it as an audio file. This feature is gated behind a "Pro" unlock (StoreKit IAP). Phase 6 activates the paywall; Phase 4 delivers the feature (can be free during beta).

### Week 11: Recording Infrastructure

**Goals:**
- AVAudioEngine tap installed on main mixer output node
- Audio buffer recording to in-memory ring buffer
- Recording start/stop controls in play screen
- Recording state indication in UI (red dot, timer)
- Maximum recording length: 5 minutes (to bound memory usage)

**Deliverables:**
- [ ] Tap-based recording captures all instrument audio including reverb
- [ ] Recording does not affect playback audio quality or latency
- [ ] UI clearly shows recording state (on/off)

**Acceptance Criteria:**
- Recorded audio is bit-for-bit identical to playback (no lossy processing)
- Memory usage during 5-minute recording < 50MB additional (at 44100Hz/16-bit/mono: ~25MB)

### Week 12: Export

**Goals:**
- Export recorded buffer to `.m4a` (AAC, 128kbps) via `AVAssetWriter`
- Save to Files app (user's chosen location via `UIDocumentPickerViewController`)
- Share sheet integration (`UIActivityViewController`)
- Export progress indicator

**Deliverables:**
- [ ] Exported file playable in Files app and any audio player
- [ ] File named `Teli_recording_YYYY-MM-DD_HH-MM.m4a`

### Week 13: Integration, Metronome, Polish

**Goals:**
- Optional visual/haptic metronome (no audio click track — pure haptic beat guide)
- Integration test: record a 30-second guitar session and export
- Pro unlock gate UI (teaser for Phase 6)
- TestFlight build with recording feature

---

## Phase 5: Android Version

**Duration:** 8 weeks
**Goal:** Deliver full feature parity with iOS MVP on Android (API 31+). All three instruments, motion control, reverb/limiter, haptics, settings, tutorial, credits.

### Weeks 14–15: Android Project Setup & Architecture

**Goals:**
- Android Studio project created
- Kotlin + Jetpack Compose scaffold
- Oboe audio library integrated via CMake
- `instruments.json` reused from iOS (identical file)
- Data models (Kotlin data classes) mirroring Swift `InstrumentConfig` models
- SensorManager setup for accelerometer and rotation vector

**Risks:**
- Oboe JNI bridge requires C++ knowledge — allocate developer with NDK experience
- `instruments.json` schema must not change during this phase (coordinate with iOS team)

### Weeks 16–17: Motion & Audio Engine (Android)

**Goals:**
- `MotionEngine.kt` implementing same state machine as iOS
- Shake/tilt/swipe detection with same thresholds (read from JSON)
- Oboe-based `AudioEngine` with preloaded sample playback
- Debounce logic in Kotlin, same algorithm as Swift implementation
- Same velocity layer logic

### Weeks 18–19: UI Implementation (Compose)

**Goals:**
- InstrumentSelectScreen, PlayScreen, SettingsScreen in Jetpack Compose
- Same dark amber visual style (Material 3 dark theme customized)
- Chord and scale buttons
- Instrument visual area with animation
- Tutorial overlay

### Weeks 20–21: Testing, Play Store Prep, Submission

**Goals:**
- Full test suite on Android 12, 13, 14, 15
- All items in `GOOGLEPLAY_CHECKLIST.md` checked
- Play Store listing created
- Internal and closed testing tracks used
- Production submission

---

## Phase 6: Monetization

**Duration:** 4 weeks
**Goal:** Activate StoreKit 2 (iOS) and Play Billing Library (Android) for instrument pack in-app purchases and the Pro unlock. The instrument expansion packs should contain at least one complete new instrument.

### Week 22: StoreKit 2 Integration (iOS)

**Goals:**
- Products defined in App Store Connect
- `StoreKit` purchase flow for Pro unlock and instrument packs
- Receipt validation (StoreKit 2 transaction API)
- Restore Purchases button in Settings
- Family Sharing compatible

**Acceptance Criteria:**
- Purchase, restore, and refund flows all work correctly in StoreKit sandbox
- Locked instrument cards unlock immediately after purchase
- Pro features (recording/export) unlock immediately after Pro purchase

### Week 23: Play Billing Integration (Android)

**Goals:**
- Products defined in Play Console
- `BillingClient` integration
- Same products as iOS
- Restore purchases on Android (via `queryPurchasesAsync`)

### Week 24: Instrument Pack #1 Content

**Goals:**
- First premium instrument pack created (new instrument + samples)
- Instrument data added to `instruments.json` with `"isUnlocked": false`
- Purchase flow tested end-to-end

### Week 25: Final QA & Marketing

**Goals:**
- Both iOS and Android monetization tested end-to-end
- App Store and Play Store listings updated with IAP information
- Press kit and launch marketing materials prepared
- Phase 6 release submitted

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Audio sample recording delays | Medium | High | Start sample recording in parallel with Phase 1 development |
| App Store rejection | Low | High | Follow APPSTORE_CHECKLIST.md strictly; use TestFlight for pre-review |
| Motion calibration requiring rework | Medium | Medium | Budget calibration time in each phase; JSON-driven thresholds allow fast iteration |
| Oboe Android audio latency issues | Medium | High | Prototype Oboe integration early in Phase 5 (week 14); have fallback to MediaPlayer if Oboe fails |
| StoreKit IAP sandbox issues | Low | Medium | Test purchase flows 2 weeks before submission |
| Binary size exceeding App Store limit | Low | Medium | Monitor IPA size from Phase 1; compress samples if needed |
