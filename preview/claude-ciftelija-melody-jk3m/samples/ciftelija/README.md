# Çifteli Sample Files

Place one MP3 (or WAV/OGG) per note here, named exactly as listed below.
The app auto-detects these files and uses them instead of synthesis.

## Files needed

| File | Note | Freq (Hz) |
|------|------|-----------|
| `B3.mp3`  | B3 — open drone string | 246.94 |
| `E4.mp3`  | E4 — open melody string | 329.63 |
| `F4.mp3`  | F4 | 349.23 |
| `G4.mp3`  | G4 | 392.00 |
| `Ab4.mp3` | Ab4 / G#4 | 415.30 |
| `Bb4.mp3` | Bb4 / A#4 | 466.16 |
| `B4.mp3`  | B4 | 493.88 |
| `C5.mp3`  | C5 | 523.25 |
| `E5.mp3`  | E5 | 659.25 |

WAV and OGG are also accepted (app tries mp3 → wav → ogg in order).

## How to get the samples

### Option A — Decent Samples free library (recommended)

1. Go to https://www.decentsamples.com/product/cifteli-free/
2. Add to cart and check out (free, no payment needed)
3. Download the `.dslibrary` file — it is a ZIP archive
4. Unzip: `unzip Cifteli.dslibrary -d Cifteli`
5. Find the WAV files inside and run the rename script:

```bash
cd web/samples/ciftelija
bash setup.sh /path/to/extracted/Cifteli
```

### Option B — Record your own

Record a single pluck of each fret position on a real çifteli, saved as mono MP3,
normalised to -6 dBFS, no silence at the start (< 5 ms), 2–4 s long.

### Option C — Use any free çifteli sample

Any clean single-note çifteli recording will work. Name it to match the table above.
