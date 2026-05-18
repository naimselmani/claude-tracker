# Teli — Technical Architecture

**Version:** 1.0.0 MVP
**Platform:** iOS (Swift) with Android future-state notes
**Last Updated:** 2026-05-18

---

## 1. High-Level Architecture

Teli uses a strict layered architecture. Each layer communicates only with adjacent layers. There are no circular dependencies. The layers from top to bottom:

```
┌─────────────────────────────────────────┐
│           UI Layer (SwiftUI Views)       │
│  InstrumentSelectView / PlayView /       │
│  SettingsView / TutorialOverlayView      │
├─────────────────────────────────────────┤
│         ViewModel Layer                  │
│  PlayViewModel / SettingsViewModel       │
│  (mediates between UI and engines)       │
├──────────────────┬──────────────────────┤
│  Motion Engine   │   Audio Engine        │
│  (CoreMotion)    │   (AVAudioEngine)     │
│  Gesture detect  │   Sample playback     │
│  State machine   │   Reverb / Limiter    │
├──────────────────┴──────────────────────┤
│         Instrument Logic Layer           │
│  Velocity mapping / Note selection /     │
│  Chord/scale resolution / Debounce       │
├─────────────────────────────────────────┤
│         Data / Config Layer              │
│  instruments.json / UserDefaults /       │
│  InstrumentConfig models / AppSettings   │
└─────────────────────────────────────────┘
```

---

## 2. iOS Technology Stack

| Concern | Technology | Version |
|---------|-----------|---------|
| Language | Swift | 5.9+ |
| UI Framework | SwiftUI | iOS 16+ |
| Motion | CoreMotion (CMMotionManager) | iOS 16+ |
| Audio playback | AVAudioEngine / AVFoundation | iOS 16+ |
| Haptics | CoreHaptics (CHHapticEngine) | iOS 16+ |
| In-app purchase (future) | StoreKit 2 | iOS 16+ |
| Persistence | UserDefaults | All iOS |
| Concurrency | Swift Structured Concurrency (async/await) + Combine | Swift 5.5+ |
| Build system | Xcode 15+ / Swift Package Manager | — |
| Minimum iOS | iOS 16.0 | — |
| Minimum device | iPhone 12 | — |

---

## 3. Android Future Stack (Phase 5)

| Concern | Technology |
|---------|-----------|
| Language | Kotlin 1.9+ |
| UI Framework | Jetpack Compose |
| Motion | SensorManager (TYPE_ACCELEROMETER + TYPE_GAME_ROTATION_VECTOR) |
| Audio | Oboe (Google low-latency audio library, C++ with Kotlin wrapper) |
| Haptics | VibrationEffect API (API 26+) |
| In-app purchase | Google Play Billing Library 6+ |
| Persistence | DataStore (replaces SharedPreferences) |
| Concurrency | Kotlin Coroutines + Flow |
| Minimum SDK | API 31 (Android 12) |

### Shared Cross-Platform Concepts
- **instruments.json** format is identical on both platforms — same schema, same sample naming convention
- **Velocity layer logic** is identical (same threshold boundaries: 33%, 66%)
- **Debounce and cooldown timing** values are defined in JSON so both platforms read the same config
- **Sample naming convention** (`{instrument}_{note}_{velocity}.wav`) is the same — same audio files can be repackaged for Android

---

## 4. Layer Descriptions

### 4.1 UI Layer (SwiftUI)

**Responsibilities:**
- Render instrument selection, play screen, settings, tutorial overlay, credits
- Observe `@Published` properties from ViewModels via `@ObservedObject` / `@StateObject`
- Send user input events (chord selection, settings changes) to ViewModels
- Apply accessibility labels, dynamic type, and reduced motion

**Key views:**
- `InstrumentSelectView` — scrollable list of instrument cards with NavigationLink
- `PlayView` — full-screen play experience, split 40/60 (instrument visual / controls)
- `InstrumentVisualView` — animated instrument image, reacts to shake/tilt
- `ControlPanelView` — chord/scale buttons, mode picker, tilt indicator
- `TutorialOverlayView` — step-through highlight overlay, stored in UserDefaults
- `SettingsView` — all settings controls
- `CreditsView` — static license/credit text

**State flow:**
```
AppState (top-level @StateObject)
  └── instruments: [InstrumentConfig]   ← loaded from JSON at launch
  └── hasCompletedOnboarding: Bool

PlayViewModel (@StateObject per PlayView instance)
  ├── subscribes to MotionEngine.gesturePublisher
  ├── calls AudioEngine.triggerNote()
  ├── publishes lastShakeIntensity, currentTiltAngle → drives animations
  └── manages haptic engine lifecycle
```

### 4.2 ViewModel Layer

**Responsibilities:**
- Bridge UI events to engine calls
- Subscribe to Combine publishers from MotionEngine
- Drive animation state via `@Published` properties
- Manage `CHHapticEngine` lifecycle (start on appear, stop on disappear)
- Apply instrument config to both engines on screen appear

**`PlayViewModel` key properties:**
- `playMode: PlayMode` — `.auto` (motion only) vs `.manual` (tap to play)
- `selectedChordId: String` — currently selected chord
- `selectedScaleId: String` — currently selected scale preset
- `lastShakeIntensity: Double` — drives instrument image animation scale
- `currentTiltAngle: Double` — drives tilt indicator

### 4.3 Motion Engine Layer

**Responsibilities:**
- Manage CMMotionManager lifecycle (start/stop accelerometer + device motion)
- Apply smoothing algorithm (exponential moving average, α=0.3)
- Run gesture state machine (idle → detecting → triggered → cooldown)
- Publish recognized gestures via Combine `PassthroughSubject<MotionGesture, Never>`
- Apply per-instrument config (threshold, cooldown, consecutive sample requirement)

**Key output type:**
```swift
enum MotionGesture {
    case shake(intensity: Double, direction: SIMD3<Double>)
    case swipe(direction: SwipeDirection, speed: Double)
    case tilt(angle: Double)
}
```

See `MOTION_ENGINE_DESIGN.md` for full algorithm details.

### 4.4 Audio Engine Layer

**Responsibilities:**
- Configure and start AVAudioEngine at app launch
- Preload all samples for the active instrument into `AVAudioPCMBuffer` instances
- Manage an `AVAudioPlayerNode` per sample slot
- Apply debounce guard before scheduling playback
- Set playback volume proportional to intensity
- Route all nodes through AVAudioUnitReverb → Dynamics Processor limiter → main output

See `AUDIO_ENGINE_DESIGN.md` for full audio graph and algorithm details.

### 4.5 Instrument Logic Layer

**Responsibilities (implemented inline in ViewModel and AudioEngine):**
- Resolve current chord or scale to a list of notes
- Map accelerometer magnitude to velocity value (0.0–1.0)
- Select velocity layer (soft/medium/hard) from velocity value
- Select correct sample buffer key from (prefix, note, layer) triple

### 4.6 Data / Config Layer

**Responsibilities:**
- Load `instruments.json` from app bundle at launch
- Decode into `[InstrumentConfig]` model objects
- Provide `AppSettings` model backed by `UserDefaults`
- Expose settings to ViewModels

---

## 5. State Management

### @Observable vs ObservableObject
Teli targets iOS 16 as minimum, so `@Observable` (iOS 17+) is **not** used. The app uses:
- `ObservableObject` + `@Published` for `AppState`, `PlayViewModel`, `SettingsViewModel`
- `@StateObject` for owning ViewModels
- `@ObservedObject` for passing ViewModels down the hierarchy
- `@EnvironmentObject` for `AppState` passed from root

### Single Source of Truth
- `AppState` owns the instruments array (loaded once from JSON)
- `PlayViewModel` owns all play-screen transient state
- `UserDefaults` is the persistence layer for settings and tutorial flags
- No external state management library is used

---

## 6. Navigation

Navigation uses `NavigationStack` (iOS 16+):

```
ContentView (root)
  └── if !onboardingComplete → OnboardingView (modal)
  └── InstrumentSelectView (NavigationStack root)
        ├── → PlayView(instrument:)  [NavigationLink]
        └── → SettingsView           [toolbar button]
               └── → CreditsView     [list row]
```

- Back navigation uses the system back button (custom back button on PlayView to dismiss and stop motion engine)
- No deep linking required in MVP
- No tab bar — single linear navigation stack

---

## 7. Concurrency Model

| Thread | What runs there |
|--------|----------------|
| Main thread | All SwiftUI updates, all Combine `.receive(on: DispatchQueue.main)` |
| CMMotionManager callback queue | OperationQueue.main (configured explicitly) |
| AVAudioEngine render thread | Real-time audio render (no Swift runtime, no allocations) |
| DispatchQueue.main async | Cooldown timer callbacks |

**Rules:**
- Never allocate on the audio render thread
- All `@Published` mutations happen on main thread
- MotionEngine callbacks are dispatched to main queue before Combine publish

---

## 8. Error Handling Strategy

### Graceful Degradation Hierarchy

| Failure | Response |
|---------|----------|
| CMMotionManager unavailable | Show "Motion not available" overlay; enable tap-to-play manual mode |
| AVAudioSession activation fails | Log error silently; retry on next foreground |
| Sample file missing from bundle | Skip note trigger; do not crash |
| CHHapticEngine unavailable | Disable haptics silently; UI toggle hidden |
| instruments.json missing or corrupt | Show error screen with "Reinstall app" guidance |
| UserDefaults read failure | Use in-memory defaults; do not persist |

### No Fatal Errors in Production
- All `try?` for non-critical operations (haptic player, file reads)
- Structured `do-catch` with logging for engine setup
- No `fatalError()` calls in production paths

---

## 9. Audio Session Lifecycle

```
App Launch
  └── AudioEngine.setupEngine()
        ├── AVAudioSession category = .playback
        ├── preferredIOBufferDuration = 0.005 (5ms)
        └── AVAudioEngine.start()

Instrument Selected
  └── AudioEngine.preloadSamples(for: instrument)
        └── loads all (note × velocityLayer) buffers into memory

Play Screen Appears
  └── MotionEngine.start(config: instrument.motionProfile)

Play Screen Disappears
  └── MotionEngine.stop()
  └── (AudioEngine continues running — no teardown between instruments)

App Enters Background
  └── AVAudioSession auto-interrupted (iOS handles this)
  └── MotionEngine.stop() (in scenePhase handler)

App Returns to Foreground
  └── AVAudioSession reactivated
  └── MotionEngine.start() if play screen is active
```

---

## 10. Cross-Platform JSON Config

The `instruments.json` file is the single source of truth for:
- Instrument identity and display name
- Motion profile parameters (per instrument)
- Audio profile parameters (per instrument)
- Note lists, chord definitions, scale presets
- Tutorial step content
- Haptic pattern identifier

This means:
- New instruments can be added without changing Swift/Kotlin code
- iOS and Android use the same JSON schema
- Instrument parameter tuning is done in JSON, not in code
- A/B testing of parameters is possible by shipping alternate JSON via a future remote config (not in MVP)

### Sample Naming Convention
See `SAMPLE_NAMING_CONVENTION.md` for the complete spec. Summary:
- Format: `{instrument}_{note}_{velocity}.wav`
- Example: `guitar_A3_soft.wav`, `ciftelija_D4_hard.wav`, `lahuta_Fs4_medium.wav`
- `#` replaced with `s` in note name (e.g., F# → Fs)

---

## 11. Security Considerations

- No network calls → no TLS, no API keys, no injection surface
- No user-generated content stored
- No external process communication
- Bundle contents signed by Apple code signature
- No dynamic library loading
- No JavaScript execution or WebView in MVP
- UserDefaults stores only primitive types (Bool, Double, String) — no serialized objects from external sources

---

## 12. Build Configuration

| Configuration | Purpose |
|---|---|
| Debug | Local development, simulator and device. Verbose logging enabled. |
| Release | App Store submission. Logging disabled. Optimizations enabled. |

- No staging/beta build configuration in MVP (use TestFlight for beta with Release build)
- `DEBUG` flag gates verbose logging
- No feature flags system in MVP (planned for Phase 4+)
