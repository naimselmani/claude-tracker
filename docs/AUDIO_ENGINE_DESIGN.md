# Teli — Audio Engine Design

**Version:** 1.0.0 MVP
**Framework:** AVFoundation / AVAudioEngine (iOS)
**Last Updated:** 2026-05-18

---

## 1. Overview

The Teli audio engine is built on `AVAudioEngine`. It uses a node-graph architecture where multiple `AVAudioPlayerNode` instances feed into an `AVAudioUnitReverb`, which feeds into a dynamics processor limiter, which feeds into the main output mixer. All sample buffers are preloaded at instrument load time to eliminate file I/O on the critical playback path.

---

## 2. AVAudioEngine Graph

```
AVAudioPlayerNode [guitar_E2_soft]  ─┐
AVAudioPlayerNode [guitar_E2_medium] ─┤
AVAudioPlayerNode [guitar_E2_hard]  ─┤
AVAudioPlayerNode [guitar_A2_soft]  ─┤
AVAudioPlayerNode [guitar_A2_medium] ─┤
  ... (one node per note × velocity) ─┼──→ AVAudioUnitReverb ──→ DynamicsProcessor ──→ AVAudioEngine.mainMixerNode ──→ Output
AVAudioPlayerNode [ciftelija_D4_soft] ─┤
  ...                                  ─┘
```

**Node responsibilities:**
- `AVAudioPlayerNode`: Schedules and plays a single preloaded `AVAudioPCMBuffer`. One node per (instrument, note, velocity-layer) triple.
- `AVAudioUnitReverb`: Applies room reverb. `wetDryMix` is set per instrument from JSON config. Preset: `AVAudioUnitReverbPreset.mediumHall`.
- `AVAudioUnitEffect` (DynamicsProcessor): Configured as a limiter. Prevents digital clipping when multiple nodes play simultaneously. Threshold: −3 dBFS, attack: 0.001s, release: 0.1s.
- `AVAudioEngine.mainMixerNode`: Final output mixer before hardware output.

---

## 3. AVAudioSession Configuration

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
try session.setPreferredIOBufferDuration(0.005)  // 5ms buffer = ~240 samples @ 48kHz
try session.setPreferredSampleRate(44100)
try session.setActive(true)
```

**Key decisions:**
- `.playback` category: allows audio when screen is locked, silences the ringer switch
- `.mixWithOthers` option: does not interrupt music playing in the background (Maps, Spotify, etc.)
- `preferredIOBufferDuration = 0.005`: requests 5ms I/O buffer from the system — significantly reduces hardware-induced latency
- **Note:** The system does not guarantee exactly 5ms; actual buffer size depends on hardware. iPhone 12+ typically achieves 6–8ms hardware latency.

---

## 4. Sample Preloading Strategy

All samples for the currently active instrument are loaded into memory at instrument selection time, before the play screen appears. This means:

1. `AppState` loads `instruments.json` at app launch (decodes JSON only — no audio I/O)
2. When a user selects an instrument, `NavigationLink` is followed
3. `PlayView.onAppear()` → `PlayViewModel.onAppear()` → `AudioEngine.preloadSamples(for: instrument)`
4. `preloadSamples` iterates all (note, velocityLayer) combinations and reads each `.wav` file into an `AVAudioPCMBuffer`
5. Buffers are stored in `sampleBuffers: [String: AVAudioPCMBuffer]` keyed by `"{prefix}_{note}_{velocity}"`
6. Play screen is shown after preloading completes (or after a maximum 500ms timeout with graceful fallback)

**Memory estimate (guitar, 6 notes × 3 layers × ~200KB avg):** ~3.6MB per instrument. All three instruments loaded: ~11MB. Well within the 150MB target.

**Graceful degradation:** If a sample file is not found in the bundle, the key is simply absent from `sampleBuffers`. The `triggerNote` function checks for the buffer's presence before scheduling playback and silently no-ops if missing.

---

## 5. Velocity Layers

Each note has three recorded sample files at different dynamic levels:

| Layer | Intensity Range | Sample suffix | Playback volume scale |
|-------|----------------|---------------|----------------------|
| soft | 0.0 – 0.329 | `_soft` | 0.30 – 0.54 |
| medium | 0.330 – 0.659 | `_medium` | 0.54 – 0.76 |
| hard | 0.660 – 1.0 | `_hard` | 0.76 – 1.0 |

Volume scaling formula: `volume = 0.3 + intensity × 0.7`

This means even the softest trigger plays at 30% volume (not silent), and a full-force shake plays at 100% volume. The volume scaling within a layer provides continuous expression between layer boundaries.

---

## 6. Debounce Logic

Debounce prevents the same note from retriggering faster than a configurable minimum interval. This is independent of the motion engine's cooldown (which prevents re-detecting a gesture). Debounce is per-note, not per-gesture.

**Default debounce intervals (from instruments.json):**
- Guitar: 80ms
- Çiftelija: 60ms
- Lahuta: 100ms

**Key:** Debounce is keyed on `"{samplePrefix}_{note}"` — so two different notes can trigger simultaneously (for a chord strum), but the same note cannot retrigger within the debounce window.

---

## 7. Anti-Clipping Configuration

The DynamicsProcessor (limiter) is configured via `AudioUnitSetParameter`:

```
Threshold: -3.0 dBFS
HeadRoom: 5.0 dB
ExpansionRatio: 2.0
AttackTime: 0.001 s
ReleaseTime: 0.05 s
MasterGain: 0.0 dB
CompressionAmount: (read-only, monitoring)
InputAmplitude: (read-only, monitoring)
OutputAmplitude: (read-only, monitoring)
```

The limiter engages transparently during normal play. It is only audible when all notes of a hard-velocity chord strum fire simultaneously — in that case it prevents a brief (+3–6 dB) transient peak from reaching the output.

---

## 8. Optional Reverb

`AVAudioUnitReverb` is always in the chain but its wet/dry mix is set per instrument. A `wetDryMix` of 0 effectively disables reverb.

**Preset:** `AVAudioUnitReverbPreset.mediumHall`
- This preset provides a neutral, room-sized reverb appropriate for all three instruments
- Future versions may add per-instrument preset selection

**`wetDryMix` parameter:** 0–100 (Apple's API), stored as a 0.0–1.0 fraction in instruments.json and converted: `reverb.wetDryMix = Float(audioProfile.reverbWetMix * 100)`

**Default settings:**
- Guitar: `reverbWetMix = 0.15` → `wetDryMix = 15`
- Çiftelija: `reverbWetMix = 0.20` → `wetDryMix = 20`
- Lahuta: `reverbWetMix = 0.35` → `wetDryMix = 35`

**User override:** Settings screen slider (0–100%) writes to UserDefaults and updates `reverb.wetDryMix` in real time.

---

## 9. Sample Naming Convention

See `SAMPLE_NAMING_CONVENTION.md` for the full spec. Quick reference:

```
{instrument}_{note}_{velocity}.wav

Examples:
  guitar_A3_soft.wav
  guitar_A3_medium.wav
  guitar_A3_hard.wav
  ciftelija_D4_soft.wav
  ciftelija_Bb4_hard.wav       ← flat = literal "b" (e.g., Bb4)
  lahuta_Fs4_medium.wav        ← sharp = "s" (e.g., F#4 → Fs4)
```

**Audio spec for all samples:**
- Format: WAV (uncompressed PCM)
- Sample rate: 44100 Hz
- Bit depth: 16-bit
- Channels: Mono
- Peak level: −3 dBFS (normalized)
- Duration: 2–4 seconds with natural decay
- Pre-roll silence: < 5ms trimmed
- Release tail: natural (no artificial fade-out)

---

## 10. Smooth Motion Input

The audio engine receives an `intensity: Double` value (0.0–1.0) from the motion engine, which has already applied smoothing. However, the audio engine also maintains a rolling average of the last 5 intensity values for chord strum scenarios where notes fire in rapid sequence from a single gesture.

**Rolling average (5-sample window):**
```swift
private var intensityHistory: [Double] = []

func smoothedIntensity(_ raw: Double) -> Double {
    intensityHistory.append(raw)
    if intensityHistory.count > 5 { intensityHistory.removeFirst() }
    return intensityHistory.reduce(0, +) / Double(intensityHistory.count)
}
```

This prevents the situation where the first note of a chord strum (detected at the gesture onset) has a slightly different intensity than subsequent notes (detected slightly later in the shake arc).

---

## 11. Pseudocode

### 11.1 `triggerNote(instrument, note, intensity)`

```
function triggerNote(prefix: String, note: String, intensity: Double):
    // Step 1: Debounce guard
    debounceKey = prefix + "_" + note
    if lastTriggerTime[debounceKey] exists:
        elapsed = now() - lastTriggerTime[debounceKey]
        if elapsed < debounceInterval:
            return  // too soon, skip this trigger
    
    // Step 2: Select velocity layer
    layer = selectVelocityLayer(intensity)
    
    // Step 3: Look up sample buffer
    sampleKey = prefix + "_" + note + "_" + layer.rawValue
    buffer = sampleBuffers[sampleKey]
    if buffer is nil:
        return  // sample not found, fail silently
    
    // Step 4: Get or create player node
    player = playerNodes[sampleKey] ?? makePlayerNode(sampleKey)
    
    // Step 5: Schedule playback with interruption
    player.stop()
    player.scheduleBuffer(buffer, options: .interrupts)
    
    // Step 6: Set volume
    volume = clamp(0.3 + intensity * 0.7, min: 0.0, max: 1.0)
    player.volume = Float(volume)
    
    // Step 7: Play
    player.play()
    
    // Step 8: Record trigger time for debounce
    lastTriggerTime[debounceKey] = now()
```

### 11.2 `calculateVelocity(accelerometerMagnitude)`

```
function calculateVelocity(magnitude: Double) -> Double:
    // magnitude: raw accelerometer magnitude in g-force units
    // shakeThreshold: minimum g to register a gesture (e.g., 1.5g)
    // maxExpected: maximum g we design for (3× threshold = 4.5g)
    
    if magnitude <= shakeThreshold:
        return 0.0
    
    maxExpected = shakeThreshold * 3.0
    clamped = clamp(magnitude, min: shakeThreshold, max: maxExpected)
    velocity = (clamped - shakeThreshold) / (maxExpected - shakeThreshold)
    
    return velocity  // 0.0 to 1.0
```

### 11.3 `selectVelocityLayer(velocity)`

```
function selectVelocityLayer(velocity: Double) -> VelocityLayer:
    if velocity < 0.33:
        return .soft
    else if velocity < 0.66:
        return .medium
    else:
        return .hard
```

### 11.4 Debounce Guard Logic

```
class DebounceGuard:
    lastTriggerTimes: Dictionary<String, Timestamp> = {}
    debounceInterval: Duration  // e.g., 80ms
    
    function canTrigger(key: String) -> Bool:
        last = lastTriggerTimes[key]
        if last is nil:
            return true
        return (now() - last) >= debounceInterval
    
    function recordTrigger(key: String):
        lastTriggerTimes[key] = now()
    
    // Usage at call site:
    if debounceGuard.canTrigger(key: noteKey):
        playSound(note)
        debounceGuard.recordTrigger(key: noteKey)
```

---

## 12. Performance Considerations

| Concern | Approach |
|---------|----------|
| Buffer scheduling latency | Preloaded `AVAudioPCMBuffer` — no disk I/O on playback path |
| Node creation latency | `AVAudioPlayerNode` created at preload time, not at trigger time |
| Thread safety | All node operations called from main thread; AVAudioEngine render is on render thread (no shared state) |
| Simultaneous notes | Each note/layer has its own `AVAudioPlayerNode` — parallel playback without interference |
| Memory | ~3.6MB per instrument; all 3 instruments = ~11MB — acceptable |
| CPU (render thread) | Minimal — scheduling preloaded buffers is a pointer assignment |

---

## 13. Future Enhancements (Not in MVP)

- **Per-instrument reverb preset selection** (e.g., small room for guitar, cathedral for lahuta)
- **Pitch shifting** for continuous tilt-based pitch bend (using `AVAudioUnitTimePitch`)
- **Recording** via `AVAudioEngine` tap on the main mixer output node
- **EQ** per instrument using `AVAudioUnitEQ`
- **Chorus/flanger** effects for Çiftelija character
