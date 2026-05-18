# Teli — App Specification

**Version:** 1.0.0 MVP  
**Tagline:** Play with Motion  
**Platform:** iOS (Android planned for Phase 5)  
**Document Status:** Approved for Development

---

## 1. Overview

Teli is a motion-controlled virtual instrument app that lets anyone pick up their phone and play music immediately — no prior musical training required. By mapping physical gestures to musical output, Teli removes the barrier of learning instrument mechanics and puts expressive sound creation within reach of casual players, cultural enthusiasts, and beginners alike.

The name "Teli" is a neutral invented word suggesting strings and resonance — deliberately devoid of geographic or cultural ownership, so the app can serve as a universal platform for diverse instruments from around the world.

---

## 2. Vision Statement

Music is a human universal. Playing an instrument is not. Teli bridges that gap by turning motion — the most natural form of human expression — into music. The app celebrates acoustic instruments from multiple traditions while keeping the experience joyful, accessible, and private.

---

## 3. Target Audience

### Primary Users
- **Beginners (ages 12–35):** People who have always wanted to play an instrument but felt intimidated by the learning curve of physical instruments.
- **Cultural music enthusiasts:** Diaspora communities and curious listeners who want to explore the tonal character of instruments from their heritage or other traditions.
- **Casual players:** Users who want a fun, low-commitment musical experience — playing along with music, relaxing, or demonstrating sounds to others.

### Secondary Users
- Music educators looking for accessible demonstration tools
- Travelers wanting a lightweight cultural experience app
- Parents introducing children to music concepts

### Non-Target (MVP)
- Professional musicians seeking studio-quality production tools
- Users requiring MIDI output or DAW integration (future phase)
- Children under 12 as primary audience (the app is 4+ rated but not specifically designed for young children)

---

## 4. Core Concept

### Motion as Instrument
Teli uses the iPhone's built-in motion sensors — accelerometer and gyroscope — to detect playing gestures and translate them into musical output. Each instrument maps its natural playing motion to phone gestures:

| Real Motion | Phone Gesture | Example |
|---|---|---|
| Strumming guitar strings | Horizontal shake | Guitar chord strum |
| Plucking a string | Short sharp shake | Çiftelija pluck |
| Drawing a bow | Slow controlled shake | Lahuta bow stroke |
| Changing pitch (bending) | Device tilt | Pitch/register variation |
| Swipe technique | Touch+swipe on screen | Individual string selection |

### Offline First
Teli requires no network connection. All samples are bundled at install time. There are no login screens, no social features, no cloud sync in the MVP. The app opens directly to instrument selection.

### Privacy by Design
The MVP collects zero personal data. Motion sensors, haptics, audio playback, and local storage are the only system capabilities used. This is not a policy choice made reluctantly — it is a foundational design constraint.

---

## 5. Instruments (MVP)

### 5.1 Guitar
A six-string acoustic guitar with standard tuning (E2 A2 D3 G3 B3 E4). Players select a chord (Am, G, C, D) and strum by shaking the device. Tilt angle adjusts the strum velocity register. The guitar is the most familiar instrument for the widest audience and serves as the onboarding instrument.

**Playing gestures:**
- Shake (horizontal, rapid): Strum selected chord
- Tilt forward/back: Soft vs. hard velocity
- Touch swipe: Individual string pluck (future enhancement)

### 5.2 Çiftelija
A double-stringed plucked instrument from the Balkans, typically tuned to D and played in modal scales. In Teli, the Çiftelija is played by selecting a scale preset (Traditional/Phrygian or Major) and plucking individual notes via shake or touch swipe. Its lower shake threshold and shorter cooldown allow for faster ornamental playing.

**Playing gestures:**
- Shake (short, sharp): Rhythmic pluck
- Swipe across play area: Sequential note run
- Tilt: Modulate between scale degrees

### 5.3 Lahuta
A one-stringed bowed instrument from the Albanian Highlands, traditionally used as an epic storytelling companion. In Teli, the Lahuta produces sustained bow-like tones via slow, controlled device movement. It has the highest reverb mix of the three instruments, creating the resonant, archaic sound character of the original.

**Playing gestures:**
- Slow controlled shake: Bow stroke (sustain trigger)
- Tilt (continuous): Pitch selection from note set
- Speed of motion: Bow pressure / intensity

### 5.4 Expansion Slots
The instrument loading system is JSON-driven. Future instrument packs can be delivered as in-app purchases without rebuilding the app binary. The UI includes placeholder cards for locked expansion instruments.

---

## 6. Feature Summary (MVP)

1. Motion-controlled instrument playing (shake, tilt, swipe)
2. Three base instruments: Guitar, Çiftelija, Lahuta
3. Chord selection for Guitar
4. Scale preset selection for Çiftelija
5. Note set navigation for Lahuta
6. Velocity-sensitive audio (soft/medium/hard layers)
7. Haptic feedback synchronized with audio triggers
8. Per-instrument reverb with configurable wet mix
9. Anti-clipping limiter in audio chain
10. Debounce and cooldown guards preventing false triggers
11. 3-step instrument tutorial overlay (first launch per instrument)
12. Settings screen (haptics toggle, motion sensitivity, left-handed mode)
13. Credits/Licenses screen
14. Dark premium visual theme with animated instrument image
15. Reduced-motion accessibility mode

---

## 7. Technical Platform

### iOS (MVP)
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Motion:** CoreMotion (CMMotionManager)
- **Audio:** AVAudioEngine, AVFoundation
- **Haptics:** CoreHaptics (CHHapticEngine)
- **Persistence:** UserDefaults (settings only)
- **Minimum OS:** iOS 16.0
- **Minimum Device:** iPhone 12 (supports CoreMotion + CoreHaptics)

### Android (Phase 5)
- **Language:** Kotlin
- **UI:** Jetpack Compose
- **Motion:** SensorManager (TYPE_ACCELEROMETER, TYPE_GAME_ROTATION_VECTOR)
- **Audio:** Oboe (low-latency audio library)
- **Haptics:** VibrationEffect API
- **Minimum OS:** Android 12 (API 31)

---

## 8. Privacy Specification

### Data Collected (MVP): None
Teli MVP collects no data whatsoever. There are no analytics SDKs, no crash reporting SDKs with network calls, no advertising identifiers, no user accounts.

### System Capabilities Used
| Capability | Purpose | Stored? |
|---|---|---|
| Accelerometer | Detect shake/swipe gestures | No — real-time only |
| Gyroscope | Detect tilt and rotation | No — real-time only |
| Haptic engine | Feedback on trigger | No |
| AVAudioEngine | Play audio samples | No |
| UserDefaults | Store app settings locally | Local device only |

### App Store Privacy Nutrition Labels
- Data Linked to You: None
- Data Used to Track You: None
- Data Not Linked to You: None (not even crash data in MVP)

### Future Privacy Considerations
If analytics or crash reporting is added in future versions, it must be:
- Opt-in only
- Disclosed in an updated privacy policy
- GDPR and CCPA compliant from day one of introduction

---

## 9. Monetization Model

- Base app: Free download, all 3 instruments included
- Premium instrument packs: One-time in-app purchase via StoreKit 2
- Pro unlock: One-time purchase for recording/export and advanced effects
- No subscriptions, no ads, no data monetization

Full monetization details in `MONETIZATION.md`.

---

## 10. Out of Scope (MVP)

The following are explicitly excluded from version 1.0.0:
- Recording or audio export
- Social sharing of recordings
- User accounts or cloud sync
- MIDI output
- Multiplayer/jam session features
- In-app purchases (present in Phase 6)
- Android version
- Landscape orientation support
- iPad-optimized layout (functional but not optimized)
- Background audio playback
- Audio input / listening features
- Any form of network communication

---

## 11. Success Metrics (MVP Launch)

| Metric | Target |
|---|---|
| App Store rating | ≥ 4.2 stars within 60 days |
| Crash-free sessions | ≥ 99.9% |
| Audio trigger latency | < 30ms |
| Motion false-positive rate | < 2% |
| Day-1 retention | ≥ 40% |
| Day-7 retention | ≥ 20% |
| Session length (median) | ≥ 3 minutes |

---

## 12. Document History

| Version | Date | Author | Notes |
|---|---|---|---|
| 0.1 | 2025-01-01 | Product | Initial draft |
| 0.9 | 2025-03-01 | Product | Pre-dev review |
| 1.0 | 2025-05-01 | Product | Approved for development |
