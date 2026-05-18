# Teli — Folder Structure

**Last Updated:** 2026-05-18
**Platform:** iOS (teli-ios/), Documentation (docs/)

---

## Complete Directory Tree

```
teli-ios/
├── TeliApp/
│   ├── App/
│   │   ├── TeliApp.swift               ← @main entry point, AppState, ContentView, OnboardingView, SettingsView, CreditsView stubs
│   │   └── ContentView.swift           ← Root view (onboarding gate → InstrumentSelectView)
│   │
│   ├── Sources/
│   │   ├── AudioEngine/
│   │   │   ├── AudioEngine.swift       ← AVAudioEngine graph, sample preloading, triggerNote(), debounce
│   │   │   └── AudioProfile+Extensions.swift  ← Convenience helpers on AudioProfile (future)
│   │   │
│   │   ├── MotionEngine/
│   │   │   ├── MotionEngine.swift      ← CMMotionManager, gesture state machine, shake/tilt/swipe detection
│   │   │   └── GestureRecognizer.swift ← Isolated swipe delta algorithm (extracted for testability)
│   │   │
│   │   ├── Models/
│   │   │   ├── InstrumentConfig.swift  ← All Codable models: InstrumentConfig, MotionProfile, AudioProfile, ChordConfig, ScalePreset, TutorialStep, AppSettings
│   │   │   └── AppSettings.swift       ← UserDefaults-backed settings (if split from InstrumentConfig.swift)
│   │   │
│   │   ├── ViewModels/
│   │   │   ├── PlayViewModel.swift     ← @MainActor ObservableObject mediating motion→audio; haptics; tutorial state
│   │   │   └── SettingsViewModel.swift ← ObservableObject for settings screen (future extraction from AppState)
│   │   │
│   │   └── Views/
│   │       ├── InstrumentSelectView.swift  ← Home screen: InstrumentCard, ExpansionSlotCard, Color(hex:) extension
│   │       ├── PlayView.swift              ← Play screen: InstrumentVisualView, ControlPanelView, TutorialOverlayView
│   │       ├── InstrumentVisualView.swift  ← Animated instrument image (extracted if PlayView.swift grows large)
│   │       ├── ControlPanelView.swift      ← Chord/scale buttons, mode picker, tilt indicator (extracted if needed)
│   │       ├── TutorialOverlayView.swift   ← Tutorial overlay (extracted if needed)
│   │       ├── SettingsView.swift          ← Full settings UI (toggling, sliders, navigation to credits)
│   │       └── CreditsView.swift           ← Credits & licenses screen
│   │
│   ├── Config/
│   │   └── instruments.json            ← Single source of truth for all instrument configurations
│   │
│   ├── Resources/
│   │   ├── Sounds/
│   │   │   ├── guitar_A2_soft.wav
│   │   │   ├── guitar_A2_medium.wav
│   │   │   ├── guitar_A2_hard.wav
│   │   │   ├── guitar_D3_soft.wav
│   │   │   ├── guitar_D3_medium.wav
│   │   │   ├── guitar_D3_hard.wav
│   │   │   ├── guitar_G3_soft.wav
│   │   │   ├── guitar_G3_medium.wav
│   │   │   ├── guitar_G3_hard.wav
│   │   │   ├── guitar_B3_soft.wav
│   │   │   ├── guitar_B3_medium.wav
│   │   │   ├── guitar_B3_hard.wav
│   │   │   ├── guitar_E2_soft.wav
│   │   │   ├── guitar_E2_medium.wav
│   │   │   ├── guitar_E2_hard.wav
│   │   │   ├── guitar_E4_soft.wav
│   │   │   ├── guitar_E4_medium.wav
│   │   │   ├── guitar_E4_hard.wav
│   │   │   ├── guitar_C3_soft.wav       ← Chord tones
│   │   │   ├── guitar_C3_medium.wav
│   │   │   ├── guitar_C3_hard.wav
│   │   │   ├── guitar_C4_soft.wav
│   │   │   ├── guitar_C4_medium.wav
│   │   │   ├── guitar_C4_hard.wav
│   │   │   ├── guitar_Fs4_soft.wav      ← F#4 for D chord
│   │   │   ├── guitar_Fs4_medium.wav
│   │   │   ├── guitar_Fs4_hard.wav
│   │   │   │                            ← ... all other guitar chord tones
│   │   │   ├── ciftelija_D4_soft.wav
│   │   │   ├── ciftelija_D4_medium.wav
│   │   │   ├── ciftelija_D4_hard.wav
│   │   │   ├── ciftelija_E4_soft.wav
│   │   │   ├── ciftelija_E4_medium.wav
│   │   │   ├── ciftelija_E4_hard.wav
│   │   │   │                            ← ... all 8 Çiftelija notes × 3 layers = 24 files
│   │   │   ├── lahuta_G3_soft.wav
│   │   │   ├── lahuta_G3_medium.wav
│   │   │   ├── lahuta_G3_hard.wav
│   │   │   │                            ← ... all 8 Lahuta notes × 3 layers = 24 files
│   │   │   └── README.md               ← Sample source documentation (not shipped in app bundle)
│   │   │
│   │   ├── Images.xcassets/
│   │   │   ├── AppIcon.appiconset/
│   │   │   │   └── Contents.json
│   │   │   ├── guitar.imageset/
│   │   │   │   ├── guitar@2x.png
│   │   │   │   ├── guitar@3x.png
│   │   │   │   └── Contents.json
│   │   │   ├── ciftelija.imageset/
│   │   │   │   ├── ciftelija@2x.png
│   │   │   │   ├── ciftelija@3x.png
│   │   │   │   └── Contents.json
│   │   │   └── lahuta.imageset/
│   │   │       ├── lahuta@2x.png
│   │   │       ├── lahuta@3x.png
│   │   │       └── Contents.json
│   │   │
│   │   └── Fonts/
│   │       └── (empty — using system SF Pro; no custom fonts in MVP)
│   │
│   └── Tests/
│       ├── MotionEngineTests.swift     ← Unit tests for threshold logic, velocity mapping, state machine, debounce
│       ├── AudioEngineTests.swift      ← Unit tests for debounce, velocity layer selection, sample key format
│       ├── InstrumentConfigTests.swift ← Unit tests for JSON decoding, model validation
│       └── PlayViewModelTests.swift    ← Unit tests for note resolution, gesture handling
│
├── TeliApp.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/
│       └── xcschemes/
│           ├── TeliApp.xcscheme        ← Main run scheme
│           └── TeliAppTests.xcscheme   ← Test scheme (CI)
│
└── TeliApp.xctestplan                  ← Test plan for Xcode Test Plans (CI integration)

docs/
├── APP_SPEC.md                  ← Full app specification
├── FEATURES.md                  ← Feature list by priority (P0/P1/P2)
├── TECHNICAL_ARCHITECTURE.md   ← Layer architecture, stack, concurrency, navigation
├── AUDIO_ENGINE_DESIGN.md       ← AVAudioEngine graph, sample strategy, pseudocode
├── MOTION_ENGINE_DESIGN.md      ← CoreMotion setup, state machine, pseudocode
├── UX_DESIGN.md                 ← Visual style, layouts, accessibility, spacing
├── LEGAL_IP_CHECKLIST.md        ← Trademark, samples, icons, privacy compliance
├── APPSTORE_CHECKLIST.md        ← Apple App Store submission checklist
├── GOOGLEPLAY_CHECKLIST.md      ← Google Play submission checklist (Phase 5)
├── MVP_ROADMAP.md               ← 6-phase development roadmap with acceptance criteria
├── TESTING_CHECKLIST.md         ← Unit, integration, UI, device, performance tests
├── MONETIZATION.md              ← Revenue model, IAP strategy, ethical guardrails
├── FOLDER_STRUCTURE.md          ← This file
└── SAMPLE_NAMING_CONVENTION.md  ← Audio file naming rules and format spec
```

---

## File Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Swift source files | PascalCase, descriptive | `PlayViewModel.swift` |
| View files | `[Name]View.swift` | `InstrumentSelectView.swift` |
| ViewModel files | `[Name]ViewModel.swift` | `PlayViewModel.swift` |
| Engine files | `[Name]Engine.swift` | `AudioEngine.swift` |
| Model files | descriptive nouns | `InstrumentConfig.swift` |
| Test files | `[TestedClass]Tests.swift` | `MotionEngineTests.swift` |
| Audio samples | `{instrument}_{note}_{velocity}.wav` | `guitar_A3_soft.wav` |
| Image assets | lowercase instrument ID | `guitar.imageset` |
| JSON configs | lowercase with underscores | `instruments.json` |

---

## Module / Target Structure

In MVP, all Swift files are in a single app target (`TeliApp`). Future refactoring may split:

- `TeliCore` (Swift Package): MotionEngine, AudioEngine, Models — testable in isolation, reusable for Android RPC bridge
- `TeliUI` (Swift Package): Views and ViewModels — depends on TeliCore
- `TeliApp` (App target): Entry point, AppState, Info.plist — depends on TeliUI

This modularization is not required for MVP but is worth considering before Phase 5 to facilitate code sharing with Android via Kotlin Multiplatform (if pursued).

---

## Build Products

| Product | Description |
|---------|-------------|
| `TeliApp.app` | Main app binary |
| `TeliAppTests.xctest` | Unit and integration test bundle |

---

## Key Files at a Glance

| File | Why It Matters |
|------|---------------|
| `instruments.json` | Single source of truth; changing parameters here changes behavior without code changes |
| `MotionEngine.swift` | Core gesture detection; all motion logic lives here |
| `AudioEngine.swift` | All audio playback; the critical-path code for < 30ms latency |
| `InstrumentConfig.swift` | All data models; JSON contract |
| `PlayViewModel.swift` | The "brain" connecting motion → audio → UI |
| `PlayView.swift` | The most-used screen; UX quality determines the app's rating |
