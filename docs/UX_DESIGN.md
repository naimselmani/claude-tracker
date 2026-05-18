# Teli — UX Design Specification

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18

---

## 1. Design Philosophy

Teli's visual design serves one purpose: getting out of the way so the user can focus on making music. The UI is minimal, dark, and tactile. Every interactive element is large enough to hit with a thumb during motion. Every animation communicates instrument response without distraction.

**Three design principles:**
1. **Motion is the product** — the screen complements gesture, not the other way around
2. **Premium without complexity** — dark and polished, not cluttered
3. **Reachability** — all controls accessible one-handed in portrait

---

## 2. Visual Style

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#0D0D0D` | All screen backgrounds |
| Surface | `#1A1A1A` | Card/panel backgrounds (behind glass) |
| Accent Primary | `#C8963E` | Buttons, highlights, icons, gradients |
| Accent Light | `#F0C060` | Gradient endpoint, hover states |
| Text Primary | `#FFFFFF` | Headings, primary labels |
| Text Secondary | `rgba(255,255,255,0.60)` | Subheadings, descriptions |
| Text Tertiary | `rgba(255,255,255,0.35)` | Hints, disabled states |
| Separator | `rgba(200,150,62,0.30)` | Dividers, panel borders |
| Glass Fill | `rgba(255,255,255,0.12)` | `.ultraThinMaterial` background approximation |
| Danger | `#E05252` | Error states (rare in MVP) |

### Glass Panel Style
All floating UI panels (control area, chord buttons, settings cards) use `.ultraThinMaterial` in SwiftUI with a 1pt amber border at 30% opacity. Corner radius: 16pt. This creates a premium "frosted glass" aesthetic that layers over the dark background.

### Gradients
- **App title gradient:** `#C8963E` → `#F0C060`, horizontal left-to-right
- **Instrument card gradient (selected):** Subtle radial glow from `#C8963E` at 10% opacity on the left edge

---

## 3. Typography

| Use | Font | Size | Weight |
|-----|------|------|--------|
| App title (Teli) | SF Pro Display | 42pt | Bold |
| Screen heading | SF Pro Display | 28pt | Semibold |
| Section heading | SF Pro Display | 20pt | Semibold |
| Body | SF Pro Text | 16pt | Regular |
| Chord/note labels | SF Pro Display | 18pt | Semibold |
| Caption | SF Pro Text | 12pt | Regular |
| Button label | SF Pro Text | 16pt | Semibold |
| Monospace (config, credits) | SF Mono | 13pt | Regular |

All text uses Dynamic Type semantic styles where possible:
- App title → `.largeTitle`
- Screen heading → `.title2`
- Body → `.body`
- Caption → `.caption`

Chord buttons use a fixed minimum size to ensure tap targets, but scale up with Dynamic Type.

---

## 4. Screen Layouts

### 4.1 Instrument Select Screen

```
┌─────────────────────────────┐
│  [⚙ Settings]        [Teli] │  ← Navigation bar (transparent)
├─────────────────────────────┤
│                             │
│         T e l i             │  ← App name, amber gradient
│    Play with Motion         │  ← Tagline, 60% white
│                             │
│  ┌─────────────────────┐    │
│  │ [img]  Guitar       │    │  ← Instrument card
│  │        String    ›  │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ [img]  Çiftelija    │    │
│  │        String    ›  │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ [img]  Lahuta       │    │
│  │        Bowed     ›  │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  🔒 Coming Soon     │    │  ← Locked expansion slot
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

**Details:**
- Cards have glass fill + amber border
- Locked cards use 40% opacity and a lock icon
- Card height: 80pt minimum
- Instrument thumbnail: 64×64pt, rounded rect (cornerRadius 12)

### 4.2 Play Screen

```
┌─────────────────────────────┐
│  [‹]    Guitar              │  ← Navigation bar
├─────────────────────────────┤
│                             │
│                             │  ← TOP 40%: Instrument Visual Area
│         [Guitar Image]      │  ← Large instrument image, centered
│         ~~~~waves~~~~       │  ← Subtle animation on trigger
│                             │
├─────────────────────────────┤  ← Amber separator line
│                             │
│   ┌──────┐  ┌──────┐       │  ← Mode picker: Auto | Manual
│   │ Auto │  │Manual│       │
│   └──────┘  └──────┘       │
│                             │
│  ╔═══╗  ╔═══╗  ╔═══╗  ╔═══╗│  ← Chord buttons (pill-shaped)
│  ║ Am║  ║ G ║  ║ C ║  ║ D ║│  ← Selected: amber fill
│  ╚═══╝  ╚═══╝  ╚═══╝  ╚═══╝│
│                             │
│       ─ ─ Tilt ─ ─          │  ← Tilt indicator (horizontal bar)
│       ────●────             │  ← Dot moves with device tilt
│                             │
│         BOTTOM 60%          │
└─────────────────────────────┘
```

### 4.3 Settings Screen

Standard grouped list style on dark background. Sections:
1. **Playback** — Haptic toggle, Reverb slider
2. **Motion** — Sensitivity picker (Low/Medium/High)
3. **Display** — Left-Handed Mode, Reduce Motion
4. **About** — Credits & Licenses, Privacy Policy, Version

### 4.4 Tutorial Overlay (per instrument)

```
┌─────────────────────────────┐
│  (dimmed play screen)       │
│  ╔═══════════════════════╗  │
│  ║  Step 1 of 3          ║  │  ← Progress dots
│  ║                       ║  │
│  ║  Select a chord       ║  │  ← Instruction text
│  ║  below                ║  │
│  ║                       ║  │
│  ║        [Next →]       ║  │  ← CTA button (amber)
│  ╚═══════════════════════╝  │
│                             │
│  [highlighted element]      │  ← Glowing amber ring on target
└─────────────────────────────┘
```

- Background dimmed to 60% opacity
- Target element highlighted with amber glow (pulsing animation)
- Tap outside card to dismiss early
- Progress shown as three dots (filled/empty)

---

## 5. Instrument Visual Area (Top 40%)

The instrument image reacts to gestures with a subtle animation:

| Gesture | Animation |
|---------|-----------|
| Shake (soft) | Scale 1.0 → 1.03 → 1.0, duration 0.15s |
| Shake (medium) | Scale 1.0 → 1.06 → 1.0, duration 0.15s |
| Shake (hard) | Scale 1.0 → 1.10 → 1.0, duration 0.15s + brief amber glow |
| Tilt | Continuous subtle rotation (-3° to +3°) tracking tilt angle |

**Reduced Motion mode:** All animations are suppressed. The instrument image is static. Audio and haptics continue to function normally.

**Instrument images:** Custom SVG/PNG assets, centered in the visual area, `scaledToFit`, maximum 280pt wide.

---

## 6. Chord / Note Button Design

```
╔══════════════╗
║    Am        ║  ← Pill-shaped, 56pt minimum height
╚══════════════╝
```

**States:**

| State | Background | Border | Text |
|-------|-----------|--------|------|
| Unselected | Glass (12% white) | 30% amber | 60% white |
| Selected | Amber (#C8963E) | None | #0D0D0D (dark) |
| Pressed | Scale 0.95, amber fill | None | #0D0D0D |
| Disabled (locked) | 20% white | None | 35% white |

**Layout:**
- Arranged in a horizontal scrollable row
- Minimum tap target: 56pt height × 72pt width
- Horizontal padding: 20pt per button
- Gap between buttons: 12pt
- Corner radius: 28pt (fully rounded pill)

---

## 7. Tilt Indicator

A horizontal bar at the bottom of the control area showing the current device tilt angle.

```
   ←  ─────────●─────────  →
```

- Full width of the control panel
- Track: 4pt tall, 50% white
- Indicator dot: 16pt circle, amber fill
- Dot moves smoothly (spring animation) tracking `currentTiltAngle`
- Range: ±1.0 normalized, mapped to ±(barWidth/2 − dotRadius) pixels
- No text label (purely visual; VoiceOver announces "Tilt indicator" with angle value)

---

## 8. Navigation Structure

```
ContentView
  ├── OnboardingView (modal, shown once at first launch)
  └── InstrumentSelectView (NavigationStack root)
        ├── PlayView(instrument:)
        │     (accessed via NavigationLink on instrument card)
        └── SettingsView
              └── CreditsView
```

**Navigation rules:**
- No tabs, no bottom nav bar
- Play screen hides navigation bar back button; uses custom back button (amber chevron)
- Settings accessible from instrument select only (not from play screen — reduces cognitive load during play)
- All navigation is portrait-only; landscape is unsupported in MVP

---

## 9. One-Hand Usability

All primary controls are reachable with the right thumb in portrait orientation:

| Element | Position | Thumb accessible? |
|---------|----------|------------------|
| Chord buttons | Bottom panel | Yes — within 180pt from bottom |
| Mode picker | Just above chord buttons | Yes |
| Back button | Top left (navigation bar) | Borderline — reachable with thumb stretch |
| Settings gear | Top right (instrument select) | Borderline — acceptable for infrequent access |

**Left-handed mode:** Mirrors the layout so chord buttons remain bottom-left and the back button moves to top right. The tilt indicator's directionality is also mirrored.

---

## 10. Onboarding Flow

3-screen modal shown on very first app launch:

**Screen 1:** App name + tagline, large instrument image, "Get Started" button
**Screen 2:** "Shake to play" instruction with a looping shake animation showing the motion
**Screen 3:** Instrument selection preview with "Choose your first instrument" CTA

- Skip button always visible
- Does not ask for permissions (no permissions required in MVP)
- Onboarding completion stored in `UserDefaults["onboardingComplete"]`

---

## 11. Accessibility

### VoiceOver

| Element | VoiceOver Label | Hint |
|---------|----------------|------|
| Instrument card (Guitar) | "Guitar, string instrument" | "Double tap to open Guitar play screen" |
| Chord button (Am) | "A minor chord" | "Double tap to select this chord" |
| Selected chord button | "A minor chord, selected" | "Double tap to deselect" |
| Tilt indicator | "Tilt indicator, [angle]%" | "Tilt your device to change this value" |
| Settings gear | "Settings" | "Double tap to open settings" |
| Back button | "Back to instrument selection" | — |

### Dynamic Type

All text elements use semantic text styles. Chord buttons grow vertically (height minimum) but not beyond 72pt to avoid layout breaking. Scroll views accommodate overflow at largest accessibility text sizes.

### Reduced Motion

When `UIAccessibility.isReduceMotionEnabled` is `true` OR when the user explicitly enables "Reduce Motion" in Teli Settings:
- Instrument image does not animate on trigger
- Tutorial highlight does not pulse
- Navigation transitions use simple cross-fade instead of slide
- Tilt indicator moves without spring (linear animation)
- Audio and haptics are unaffected

### High Contrast

Teli respects `UIAccessibility.isDarkerSystemColorsEnabled`. When active:
- Glass panel border opacity increases from 30% to 80%
- Text secondary opacity increases from 60% to 85%
- Text tertiary opacity increases from 35% to 60%

### Haptics Toggle

The haptic feedback toggle in Settings disables all `CHHapticEngine` output independently of audio. Users with sensory sensitivities can turn off haptics while keeping audio.

---

## 12. Error States

| Error | UI Presentation |
|-------|----------------|
| Motion not available | Yellow banner in play screen: "Shake detection unavailable. Tap chord buttons to play." Auto-dismisses after 3s. |
| Audio session interrupted (phone call) | Banner: "Audio interrupted" — automatically resumes when call ends |
| Sample file missing | No UI shown (silent failure) — note simply doesn't sound |
| instruments.json decode failure | Full-screen error with retry button and "Reinstall app" suggestion |

---

## 13. Spacing and Layout Constants

| Constant | Value |
|----------|-------|
| Screen horizontal padding | 20pt |
| Card corner radius | 16pt |
| Button corner radius (pill) | 28pt |
| Card internal padding | 20pt |
| Inter-card spacing | 16pt |
| Instrument visual area | 40% of screen height |
| Control panel area | 60% of screen height |
| Navigation bar height | System default (~44pt) |
| Minimum tap target size | 56 × 56pt |
| Amber border width | 1pt |
