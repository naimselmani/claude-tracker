# Teli — Audio Sample Naming Convention

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18

This document defines the naming convention, format specification, and quality requirements for all audio samples used in Teli. Every person contributing audio samples to the project must follow this document exactly.

---

## 1. File Name Format

```
{instrument}_{note}_{velocity}.wav
```

All three components are **mandatory**. No spaces. No capital letters. Underscores as separators only.

---

## 2. Component Definitions

### `{instrument}`

The lowercase machine-readable instrument ID, matching the `"id"` field in `instruments.json`.

| Instrument | ID |
|-----------|-----|
| Guitar | `guitar` |
| Çiftelija | `ciftelija` |
| Lahuta | `lahuta` |
| (future) | (TBD per instruments.json) |

### `{note}`

Scientific pitch notation with the following rules:

| Rule | Description | Example |
|------|-------------|---------|
| Octave | Appended immediately after the letter | A3, D4, G5 |
| Sharp (`#`) | Replace with lowercase `s` | F#4 → `Fs4` |
| Flat (`b`) | Use lowercase `b` | Bb4 → `Bb4`, Eb4 → `Eb4` |
| Natural | No symbol appended | C4 → `C4` |
| Double sharp | Avoid — retune or use enharmonic | — |
| Double flat | Avoid — retune or use enharmonic | — |

**Valid note examples:**

| Written | File name component |
|---------|-------------------|
| A3 | `A3` |
| A#3 / Bb3 | `As3` or `Bb3` (use whichever is the instrument's natural notation) |
| F#4 | `Fs4` |
| G4 | `G4` |
| C5 | `C5` |
| D4 | `D4` |
| Eb4 | `Eb4` |
| Ab4 | `Ab4` |
| Cs5 | `Cs5` (C#5) |

### `{velocity}`

One of exactly three values:

| Velocity | Range | Suffix |
|----------|-------|--------|
| Soft | 0–33% intensity | `soft` |
| Medium | 34–66% intensity | `medium` |
| Hard | 67–100% intensity | `hard` |

---

## 3. Complete File Name Examples

```
guitar_A2_soft.wav
guitar_A2_medium.wav
guitar_A2_hard.wav
guitar_D3_soft.wav
guitar_G3_medium.wav
guitar_B3_hard.wav
guitar_E4_soft.wav
guitar_Fs4_medium.wav         ← F#4 for D chord
guitar_C3_hard.wav
guitar_C4_soft.wav

ciftelija_D4_soft.wav
ciftelija_D4_medium.wav
ciftelija_D4_hard.wav
ciftelija_Eb4_soft.wav        ← Eb4 for Phrygian scale
ciftelija_F4_medium.wav
ciftelija_G4_hard.wav
ciftelija_Ab4_soft.wav        ← Ab4 for Phrygian scale
ciftelija_Bb4_medium.wav
ciftelija_C5_hard.wav
ciftelija_Cs5_soft.wav        ← C#5 for Major scale
ciftelija_D5_medium.wav

lahuta_G3_soft.wav
lahuta_G3_medium.wav
lahuta_G3_hard.wav
lahuta_A3_soft.wav
lahuta_B3_medium.wav
lahuta_C4_hard.wav
lahuta_D4_soft.wav
lahuta_E4_medium.wav
lahuta_Fs4_hard.wav
lahuta_G4_soft.wav
```

---

## 4. Audio Format Specification

All samples **must** conform to this format. Non-conforming files will be rejected by the audio review process.

| Parameter | Value |
|-----------|-------|
| Container | WAV (RIFF WAVE) |
| Encoding | PCM (uncompressed) |
| Sample rate | 44100 Hz |
| Bit depth | 16-bit |
| Channels | Mono (1 channel) |
| Peak level | −3 dBFS (normalized to this peak, not louder) |
| DC offset | Zero (or < 0.1% — remove any DC offset before normalizing) |
| Dither | Triangular dither applied when converting from 24-bit source |

---

## 5. Duration Requirements

| Parameter | Requirement |
|-----------|-------------|
| Minimum duration | 2.0 seconds |
| Maximum duration | 4.0 seconds |
| Pre-roll silence | < 5ms (trim silence at the start to within 5ms of the attack) |
| Release tail | Natural — do not apply artificial fade-out |
| Trailing silence | Up to 0.5s of natural decay tail is acceptable; do not truncate the natural sustain |

---

## 6. Recording Quality Requirements

### Attack Character

Each velocity layer should have a distinctly different attack character:
- **Soft**: Gentle onset, quiet, rounded attack
- **Medium**: Clear onset, medium brightness
- **Hard**: Sharp attack, full brightness, maximum sustain

Velocity layers must **not** be created by volume-scaling a single recording. They must be separate performances or separate microphone/pickup positions at different playing intensities.

### Consistency Within a Set

All samples for a given instrument must be:
- Recorded in the same session with the same microphone placement and room
- Tuned to equal temperament (A4 = 440Hz) unless instrument tradition dictates otherwise (in which case, document the deviation)
- Free of background noise (traffic, HVAC, room tone) — use a treated recording space or noise gate
- Free of finger noise, pick noise, string buzz, or bow scratch (unless the character of the instrument makes this unavoidable — for Lahuta, slight bow articulation noise is acceptable and adds authenticity)

### Stereo Source to Mono

If the instrument is recorded in stereo, sum to mono by averaging both channels:
`mono = (left + right) / 2`

Do not just take one channel — this can cause uneven frequency response if the mic array is asymmetric.

---

## 7. Processing Chain

The **only** acceptable processing steps before delivering a sample file:

1. **Trim** leading silence to < 5ms before the attack
2. **Noise reduction** (gentle; do not denature the instrument's tone)
3. **Sum to mono** (if stereo source)
4. **Remove DC offset** (high-pass at 10Hz or DC offset removal in DAW)
5. **Normalize** peak to −3 dBFS
6. **Dither** to 16-bit (triangular dither, TPDF)
7. **Export** as WAV, 44100Hz, 16-bit, mono

**Do not apply:**
- Compression or limiting (the AudioEngine applies its own limiter)
- EQ beyond gentle high-pass for DC/rumble removal
- Reverb (the AudioEngine applies its own reverb)
- Saturation or harmonic enhancement
- Time-stretching or pitch-shifting

---

## 8. Delivery Checklist

Before delivering samples to the project:

- [ ] All file names follow the `{instrument}_{note}_{velocity}.wav` convention exactly
- [ ] All three velocity layers present for each note
- [ ] Format verified: 44100Hz, 16-bit, mono WAV (use MediaInfo or `ffprobe` to verify)
- [ ] Peak level: −3 dBFS ± 0.5 dB (verify with DAW or Audacity)
- [ ] Duration: 2–4 seconds (verify in DAW)
- [ ] Pre-roll: < 5ms (visually verify in DAW waveform view)
- [ ] No clipping: 0 samples at 0 dBFS (verify with DAW clip indicator)
- [ ] License documentation attached: source, license type, license URL, license file
- [ ] Tuning verified: A4 = 440Hz (or deviation documented)

---

## 9. Verification Script

Use this shell command to verify a set of WAV files:

```bash
# Verify sample rate and channels using ffprobe (part of ffmpeg)
for f in *.wav; do
    echo "$f"
    ffprobe -v quiet -select_streams a:0 \
        -show_entries stream=sample_rate,channels,bits_per_sample \
        -of csv=p=0 "$f"
done
```

Expected output for each file: `44100,1,16`

---

## 10. Sample Set Size Reference

| Instrument | Notes | Velocity Layers | Total Files |
|-----------|-------|----------------|-------------|
| Guitar | ~18 (all chord tones) | 3 | 54 |
| Çiftelija | 13 (full chromatic scale) | 3 | 39 |
| Lahuta | 8 | 3 | 24 |
| **Total MVP** | | | **~117** |

Estimated total uncompressed size: 117 × 200KB average = ~23MB
Compressed in IPA: ~15–18MB (WAV files compress moderately well with ZIP)

This is well within App Store binary size limits.
