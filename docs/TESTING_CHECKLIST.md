# Teli — Testing Checklist

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18

All items must be verified before App Store submission. Items marked P0 are blockers.

---

## Section 1: Unit Tests

Unit tests run in CI on every pull request. Coverage target: ≥ 80% of business logic code (models, engines, view models).

### Motion Engine Tests

- [ ] **P0** `test_shakeThreshold_notTriggeredBelowThreshold` — Simulate accelerometer samples at 0.9× threshold; verify no gesture published
- [ ] **P0** `test_shakeThreshold_triggeredAtThreshold` — Simulate 3 consecutive samples at exactly 1.0× threshold; verify `.shake` published
- [ ] **P0** `test_consecutiveSamples_notTriggeredWithFewerThanRequired` — 2 samples above threshold (requiredSamples=3); verify no trigger
- [ ] **P0** `test_consecutiveSamples_resetAfterDropBelowThreshold` — 2 samples above, 1 below, 2 above; verify counter resets and gesture not triggered prematurely
- [ ] **P0** `test_cooldown_preventsRetriggerDuringWindow` — Trigger gesture, immediately attempt another; verify second gesture not published
- [ ] **P0** `test_cooldown_allowsRetriggerAfterWindow` — Trigger gesture, wait > cooldownDuration, trigger again; verify second gesture published
- [ ] **P0** `test_velocityMapping_atThreshold_returnsZero` — magnitude = threshold → velocity = 0.0
- [ ] **P0** `test_velocityMapping_atMaxExpected_returnsOne` — magnitude = 3× threshold → velocity = 1.0
- [ ] **P0** `test_velocityMapping_aboveMax_clampsToOne` — magnitude = 10× threshold → velocity = 1.0 (clamped)
- [ ] **P0** `test_velocityMapping_midpoint_returnsCentered` — magnitude = 2× threshold → velocity = 0.5
- [ ] **P1** `test_exponentialSmoothing_highAlpha_respondsQuickly` — Verify α=0.3 smoothed output after N samples
- [ ] **P1** `test_gestureState_transitionsCorrectly` — State machine walks idle→detecting→triggered→cooldown→idle
- [ ] **P1** `test_swipeDetection_largeDelta_returnsDirection` — Feed 5-sample window with large X-axis delta; verify `.right` direction
- [ ] **P1** `test_swipeDetection_smallDelta_returnsNil` — Delta below swipeThreshold; verify nil direction (no swipe)

### Audio Engine Tests

- [ ] **P0** `test_debounce_sameNote_suppressesWithinInterval` — Call `triggerNote` twice within debounceInterval; verify second call produces no playback
- [ ] **P0** `test_debounce_sameNote_allowsAfterInterval` — Call `triggerNote`, wait > debounceInterval, call again; verify second call plays
- [ ] **P0** `test_debounce_differentNotes_triggerIndependently` — Call `triggerNote` for noteA and noteB within debounceInterval; verify both play
- [ ] **P0** `test_velocityLayerSelection_soft` — intensity = 0.2 → layer = .soft
- [ ] **P0** `test_velocityLayerSelection_medium` — intensity = 0.5 → layer = .medium
- [ ] **P0** `test_velocityLayerSelection_hard` — intensity = 0.8 → layer = .hard
- [ ] **P0** `test_velocityLayerSelection_boundaries` — intensity = 0.33 → .soft (exclusive upper bound); intensity = 0.66 → .medium
- [ ] **P0** `test_sampleKey_correctFormat` — sampleKey(prefix:"guitar", note:"A3", layer:.soft) == "guitar_A3_soft"
- [ ] **P1** `test_preloadSamples_missingFile_doesNotCrash` — Attempt to preload a non-existent sample file; verify no crash, no entry in sampleBuffers
- [ ] **P1** `test_triggerNote_missingSample_doesNotCrash` — Call triggerNote for a note with no preloaded buffer; verify silent no-op

### Model Tests (InstrumentConfig)

- [ ] **P0** `test_decodeGuitarConfig_allFieldsPresent` — Decode guitar entry from instruments.json; verify all fields populated
- [ ] **P0** `test_decodeCiftelijaConfig_scalePresets` — Verify scalePresets decoded correctly
- [ ] **P0** `test_decodeLahutaConfig_noChords` — Verify chords is nil for lahuta
- [ ] **P0** `test_decodeMotionProfile_values` — Verify shakeThreshold, cooldownMs, consecutiveSamplesRequired correct
- [ ] **P0** `test_decodeAudioProfile_values` — Verify debounceMs, velocityLayers, reverbEnabled correct
- [ ] **P0** `test_decodeTutorialSteps_count` — Verify each instrument has exactly 3 tutorial steps
- [ ] **P1** `test_decodeInstrumentList_allThreeInstruments` — Full instruments.json decode yields exactly 3 instruments
- [ ] **P1** `test_malformedJSON_doesNotCrash` — Feed malformed JSON to decoder; verify graceful failure (returns nil/throws, does not crash)

---

## Section 2: Integration Tests

Integration tests run on device or via Xcode Test Plans. Tests that require audio hardware are marked (device only).

### Audio Engine Integration

- [ ] **P0** `test_triggerNote_producesAudioOutput` (device only) — Verify AVAudioPlayerNode.isPlaying becomes true after triggerNote
- [ ] **P0** `test_engineStart_noExceptions` — `setupEngine()` completes without throwing on all test devices
- [ ] **P0** `test_reverbNodeAttached_inGraph` — Verify reverb node is connected between player nodes and main mixer
- [ ] **P0** `test_limiterNodeAttached_inGraph` — Verify dynamics processor is connected after reverb
- [ ] **P1** `test_audioSessionCategory_playback` — Verify `AVAudioSession.category == .playback` after `setupEngine()`
- [ ] **P1** `test_preloadAndTrigger_correctSamplePlays` (device only) — Preload guitar, trigger guitar_A3_soft; verify the correct player node is used

### Motion Engine Integration

- [ ] **P0** `test_motionEngineStart_accelerometerRunning` — After `start()`, `motionManager.isAccelerometerActive == true`
- [ ] **P0** `test_motionEngineStop_accelerometerStopped` — After `stop()`, `motionManager.isAccelerometerActive == false`
- [ ] **P0** `test_gesturePublisher_emitsOnShake` (device only, manual) — Shake device; verify gesture received on subscriber within 100ms
- [ ] **P1** `test_configApplied_thresholdUpdated` — `start(config:)` with custom shakeThreshold; verify `motionEngine.shakeThreshold` matches

### ViewModel Integration

- [ ] **P0** `test_playViewModel_onAppear_startsMotionEngine` — `onAppear()` calls `MotionEngine.shared.start()`
- [ ] **P0** `test_playViewModel_onDisappear_stopsMotionEngine` — `onDisappear()` calls `MotionEngine.shared.stop()`
- [ ] **P0** `test_playViewModel_shakeGesture_triggersAudio` — Publish `.shake(intensity: 0.5)` from MotionEngine; verify AudioEngine.triggerNote called

---

## Section 3: UI Tests (Xcode UI Testing)

UI tests run on simulator where possible; screenshot tests on device.

### Navigation

- [ ] **P0** `test_instrumentSelectToPlayView` — Tap first instrument card; verify PlayView appears with correct instrument name in navigation title
- [ ] **P0** `test_playViewBackNavigation` — In PlayView, tap back button; verify InstrumentSelectView appears
- [ ] **P0** `test_settingsNavigation` — Tap settings gear; verify SettingsView appears
- [ ] **P0** `test_creditsNavigation` — In Settings, tap Credits; verify CreditsView appears
- [ ] **P1** `test_tutorialDismiss` — First launch of instrument; verify tutorial overlay appears; tap dismiss; verify overlay gone

### Accessibility

- [ ] **P0** `test_voiceOver_chordButtons_hasLabels` — Enable VoiceOver; navigate to chord buttons; verify each has a non-empty accessibility label
- [ ] **P0** `test_voiceOver_instrumentCards_hasLabels` — Enable VoiceOver; navigate instrument list; verify each card has descriptive label
- [ ] **P0** `test_dynamicType_accessibilityExtraLarge_noCrash` — Set system text size to Accessibility Extra Large; verify no layout breakage or crash
- [ ] **P1** `test_reduceMotion_disablesAnimations` — Enable Reduce Motion (system); verify instrument image does not animate on shake trigger

### Interaction

- [ ] **P0** `test_chordButton_selection_changesState` — Tap chord button "G"; verify it appears selected (accessibility trait: selected)
- [ ] **P0** `test_chordButton_minimumTapTarget` — Verify all chord buttons have minimum frame of 56×56 points
- [ ] **P0** `test_modePickerToggle` — Tap "Auto" mode; verify mode changes to auto; tap "Manual"; verify back to manual

---

## Section 4: Device Tests

Manual testing on physical devices. Each device must complete the full test scenario.

### Device Matrix

| Device | iOS | Test Status |
|--------|-----|-------------|
| iPhone 12 | iOS 16.x | — |
| iPhone 13 mini | iOS 16.x | — |
| iPhone 13 | iOS 16.x | — |
| iPhone 14 | iOS 17.x | — |
| iPhone 14 Pro | iOS 17.x | — |
| iPhone 15 | iOS 17.x | — |
| iPhone 15 Pro | iOS 17.x | — |
| iPhone 15 Pro Max | iOS 17.x | — |
| iPhone 16 | iOS 18.x | — |
| iPhone 16 Pro | iOS 18.x | — |

### Per-Device Test Scenario (30 minutes)

- [ ] App cold launch; instrument select appears within 2 seconds
- [ ] Select Guitar; play screen appears; tutorial shown (first launch)
- [ ] Shake to strum Am chord; audio plays
- [ ] Change chord to G; shake; audio plays with G chord
- [ ] Tilt device; tilt indicator responds; Lahuta pitch varies
- [ ] Select Çiftelija; scale preset changes; shake produces different timbre
- [ ] Select Lahuta; bow gesture produces sustained note
- [ ] Open Settings; toggle haptics off and on
- [ ] Adjust reverb slider; audible change in reverb
- [ ] Change sensitivity; verify threshold effect (hard to trigger on "Low")
- [ ] Enable left-handed mode; verify UI mirrors
- [ ] Open Credits; verify content loads
- [ ] Return to play; 20 more minutes of play
- [ ] End: no crashes, no memory warning, no audio glitches

---

## Section 5: Performance Tests

### CPU Usage

- [ ] **P0** Sustained guitar play (5 minutes): CPU < 15% on iPhone 12 — measure with Instruments → CPU Profiler
- [ ] **P0** Sustained guitar play (5 minutes): CPU < 10% on iPhone 15 — measure with Instruments
- [ ] **P1** Instrument switching (all 3 instruments, 10× cycle): No CPU spike > 30% at any point

### Memory

- [ ] **P0** App launch: baseline memory < 80MB
- [ ] **P0** After instrument preload (guitar): memory < 100MB
- [ ] **P0** After all three instruments preloaded (once each): memory < 150MB
- [ ] **P1** No memory leaks after instrument switching — measure with Instruments → Leaks

### Audio Latency

- [ ] **P0** Audio trigger latency < 30ms on iPhone 12 (shake to first audio sample) — measure with audio analysis or Instruments
- [ ] **P0** Audio trigger latency < 20ms on iPhone 15 Pro
- [ ] **P1** Chord strum (5 simultaneous notes): no audible timing spread between notes

### Battery

- [ ] **P1** 30-minute play session: < 5% battery drain on iPhone 14 (charged to 100%, screen on, full play session)

### App Launch

- [ ] **P0** Cold start to instrument select: < 2 seconds on iPhone 12
- [ ] **P0** Cold start to instrument select: < 1 second on iPhone 15

---

## Section 6: Audio-Specific Tests

- [ ] **P0** `test_noAudioClipping_hardVelocityChord` — Strum a 5-note chord at hard velocity; verify no digital clipping in output (measure with audio meter; peak < −0.1 dBFS)
- [ ] **P0** `test_reverbPresent_lahuta` — Record Lahuta trigger; verify reverb tail > 1.0 second
- [ ] **P0** `test_velocityLayers_audiblyDistinct` — Play soft, medium, hard of same note; verify panel of 3 listeners can consistently distinguish layers
- [ ] **P1** `test_debounce_fastRepeat_noDoubleStrike` — Shake rapidly for 5 seconds; verify no note fires faster than debounceInterval
- [ ] **P1** `test_audioSessionInterruption_recovers` — Trigger an incoming phone call during play; hang up; verify audio resumes within 2 seconds
- [ ] **P1** `test_silentSwitch_audioMuted` — Engage silent switch on iPhone; verify Teli audio is NOT muted (`.playback` category respects this intention)

---

## Section 7: Motion False-Positive Tests

Test protocol: Mount device in a jig or hold naturally in the defined scenarios. Count gestured triggers per 60-second window. False-positive rate = unintended triggers / total triggers.

| Scenario | Allowed false positives per 60s |
|----------|--------------------------------|
| Device sitting on flat table | 0 |
| Holding device, watching video (no intention to play) | < 1 |
| Walking briskly, device in hand | < 2 |
| Typing on a laptop with device nearby | 0 |
| Normal conversation with hand gestures (device in hand) | < 1 |

- [ ] **P0** All scenarios above tested on iPhone 12 and iPhone 15
- [ ] **P0** Overall false-positive rate < 2% during a 30-minute play session

---

## Section 8: App Store Review Simulation

Before submitting, conduct an internal "App Store review simulation":

- [ ] **P0** Fresh install on an iPhone that has never had the app — verify no leftover state
- [ ] **P0** Verify app works without any previous UserDefaults state
- [ ] **P0** Verify tutorial appears on first launch
- [ ] **P0** Verify all three instruments play correctly
- [ ] **P0** Verify Settings screen is accessible and functional
- [ ] **P0** Verify Credits screen is present and accurate
- [ ] **P0** Verify Privacy Policy link opens in browser
- [ ] **P0** Verify app does not request any permissions
- [ ] **P0** Verify app does not crash when launched on minimum iOS version (16.0)
- [ ] **P0** Verify app runs on minimum device (iPhone 12)
- [ ] **P0** Verify VoiceOver navigation works through the full app flow
- [ ] **P1** Verify app handles "Low Power Mode" gracefully (no aggressive throttling issues)
- [ ] **P1** Verify app handles background app refresh being disabled gracefully
- [ ] **P1** Verify app passes `xcrun simctl privacy booted grant` for relevant permissions (N/A — no permissions in MVP)

---

## Section 9: Regression Testing Policy

- Run **all P0 unit tests** on every pull request (CI)
- Run **all P0 UI tests** on merge to main (CI, simulator)
- Run **full device matrix** before each App Store submission
- Run **audio and performance tests** manually before each TestFlight build
- Maintain a regression log for each test cycle (date, tester, device, result)
