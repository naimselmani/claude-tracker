# Teli — Google Play Store Submission Checklist

**Version:** 1.0.0 (Android — Phase 5)
**Last Updated:** 2026-05-18
**Note:** Android development begins in Phase 5. This checklist is prepared in advance to guide the Android build.

---

## Section 1: SDK & Build Configuration

- [ ] **Target SDK: API 35 (Android 15)** — `targetSdkVersion 35` in `build.gradle`. Required to publish new apps as of Google Play policy.
- [ ] **Minimum SDK: API 31 (Android 12)** — `minSdkVersion 31`. Android 12 provides full `VibrationEffect` haptics and Oboe library compatibility.
- [ ] **Compile SDK: API 35** — `compileSdkVersion 35`.
- [ ] **64-bit native libraries required** — If Oboe (C++ audio library) is used, provide arm64-v8a slice. 32-bit only apps are rejected.
- [ ] **App bundle (AAB) format used** — Upload `.aab` (Android App Bundle), not `.apk`, to Play Console. Required for new apps.
- [ ] **ProGuard/R8 minification enabled in release build** — Reduces binary size and obfuscates code.
- [ ] **Kotlin version: 1.9+** — Matches Jetpack Compose compatibility matrix.
- [ ] **Jetpack Compose version: 1.6+** — Stable release with full Material 3 support.

---

## Section 2: Permissions

### Declared in AndroidManifest.xml

- [ ] **`VIBRATE` permission declared** — Required for haptic feedback via `VibrationEffect`.
- [ ] **`USE_EXACT_ALARM` NOT declared** — Not needed; no scheduled alarms.
- [ ] **No `RECORD_AUDIO` permission** — Microphone not used in MVP. Must not be declared.
- [ ] **No location permissions** — `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` not declared.
- [ ] **No `READ_CONTACTS` or `WRITE_CONTACTS`** — Not applicable.
- [ ] **No `CAMERA` permission** — Not applicable.
- [ ] **No `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE`** — Samples are bundled in APK; no external storage access needed in MVP.
- [ ] **`INTERNET` NOT declared** — MVP has no network calls. Omitting this permission provides an extra security assurance to users.
- [ ] **Sensor access declared** — `android.hardware.sensor.accelerometer` listed under `<uses-feature>` with `android:required="false"` (graceful degradation if unavailable).

### Runtime Permissions

- [ ] **No runtime permission dialogs in MVP** — `VIBRATE` is a normal permission (no dialog needed). Accelerometer access requires no runtime permission on Android.
- [ ] **Confirm SensorManager access requires no permission** — Verified: accessing `SensorManager` for `TYPE_ACCELEROMETER` and `TYPE_GAME_ROTATION_VECTOR` does not require runtime permission on Android 12+.

---

## Section 3: Data Safety Section

The Play Console requires a Data Safety section (analogous to Apple's Privacy Nutrition Labels).

- [ ] **Data Safety section completed in Play Console** — Access: Play Console → App content → Data safety.
- [ ] **"No data collected" declared** — Teli MVP collects no user data. Select: "This app does not collect or share any user data."
- [ ] **No data shared with third parties declared** — Confirmed: no third-party SDKs in MVP.
- [ ] **Security practices section completed:**
  - [ ] "Data is encrypted in transit" — N/A (no network); confirm field handling.
  - [ ] "You can request that data be deleted" — N/A (no data stored); confirm field handling.
- [ ] **Privacy policy URL entered in Play Console** — Must be a live URL before submission.

---

## Section 4: App Content Rating

- [ ] **IARC content rating questionnaire completed** — Accessible via Play Console → App content → App content rating.
- [ ] **Expected rating: EVERYONE (E)** — No violence, no suggestive content, no user interaction, no language.
- [ ] **Questionnaire answers reviewed for accuracy** — Answer honestly; misrepresentation can result in app removal.

---

## Section 5: Store Listing Content

- [ ] **App title: "Teli"** — 30-character limit; within limit.
- [ ] **Short description: 80 characters max** — Concise value proposition. Example: "Play real instruments by shaking your phone. No music skills needed."
- [ ] **Full description: up to 4000 characters** — Detailed explanation, feature list, no misleading claims.
- [ ] **App icon: 512 × 512 px PNG** — Full-color, no alpha, no rounded corners (Play adds rounding).
- [ ] **Feature graphic: 1024 × 500 px** — Required for being featured. Show instrument and app name.
- [ ] **Screenshots: minimum 2, maximum 8** — Show actual app UI. Recommended: 4–6 screenshots.
  - [ ] Phone screenshots: 16:9 or 9:16 ratio
  - [ ] Tablet screenshots: optional but recommended for broader reach
- [ ] **Promo video: optional YouTube link** — If available, shows the motion-to-sound interaction.
- [ ] **No keyword stuffing in description** — Play store algorithm does not reward this and may penalize.
- [ ] **Developer contact email provided** — Required field in Play Console.
- [ ] **Privacy policy URL in Play Console** — Required for all apps; must be live.

---

## Section 6: App Functionality & Policies

- [ ] **App meets minimum functionality threshold** — Not a demo or stub; all three instruments playable. Play requires at least minimal useful functionality.
- [ ] **No deceptive behavior** — App does exactly what is described. No hidden functionality, no bait-and-switch.
- [ ] **No impersonation of system or other apps** — Teli's UI is distinct from system apps and other music apps.
- [ ] **No copyrighted content without authorization** — Audio samples are original or properly licensed. (See LEGAL_IP_CHECKLIST.md)
- [ ] **Google Play Families policy: not targeting children under 13** — MVP is not specifically targeted at under-13s. If future family-friendly positioning: comply with Families policy.
- [ ] **No ads policy violation** — No ads in MVP; N/A.
- [ ] **No financial services, gambling, or cryptocurrency** — Not applicable.

---

## Section 7: Technical Requirements

### Performance

- [ ] **Tested on Android 12 (API 31) device** — Minimum supported OS. Full play session tested without crash.
- [ ] **Tested on Android 14 (API 34) and Android 15 (API 35)** — Ensure no API deprecation issues.
- [ ] **Tested on low-end and high-end devices** — e.g., Pixel 4a (low-end) and Pixel 8 (current flagship).
- [ ] **Audio latency < 30ms** — Oboe library configured for EXCLUSIVE mode; measure with Oboe's latency tester.
- [ ] **CPU < 15% sustained during play** — Measured with Android Profiler.
- [ ] **Memory < 150 MB** — Measured with Android Profiler → Memory.
- [ ] **No ANR (Application Not Responding) events** — No blocking calls on main thread. SensorManager callbacks run on sensor event thread.
- [ ] **Crash-free rate ≥ 99.9%** — Verified via Play Console → Android Vitals.

### Audio (Oboe)

- [ ] **Oboe configured for low-latency output stream** — `PerformanceMode::LowLatency`, `SharingMode::Exclusive`.
- [ ] **Oboe callback runs without allocations** — No `new`/`malloc` in the audio callback; all buffers pre-allocated.
- [ ] **AAudio vs OpenSL ES fallback** — Oboe handles this automatically; confirm Oboe version is current.
- [ ] **Audio Focus handling implemented** — Request `AudioManager.AUDIOFOCUS_GAIN` on play screen appear; abandon on disappear. Handle `AUDIOFOCUS_LOSS` by pausing.
- [ ] **Do Not Disturb mode handling** — App respects system audio routing; no workarounds for DND.

### Sensor (SensorManager)

- [ ] **`TYPE_ACCELEROMETER` registration with `SENSOR_DELAY_GAME`** — This corresponds to ~100Hz, matching iOS implementation.
- [ ] **`TYPE_GAME_ROTATION_VECTOR` registration for tilt** — Provides orientation data without compass; suitable for indoor use.
- [ ] **Unregister sensor listeners in `onPause()`** — Prevent battery drain when app is backgrounded.
- [ ] **Re-register listeners in `onResume()`** — Restore motion detection when foregrounded.

---

## Section 8: APK/AAB Optimization

- [ ] **Enable R8 minification and resource shrinking** — `minifyEnabled true`, `shrinkResources true` in release build config.
- [ ] **Audio samples reviewed for size** — 3 instruments × ~30 samples × ~200KB each ≈ 18MB uncompressed. Verify compressed size in final AAB.
- [ ] **`android:extractNativeLibs="false"` in manifest** — Recommended for AAB; Play extracts native libs during install.
- [ ] **AAB size reviewed** — Target < 150MB download size after delivery optimizations.
- [ ] **Play Asset Delivery (PAD) considered if bundle is large** — If audio samples exceed the AAB limit, use PAD to deliver samples as install-time asset packs. Plan for this in Phase 5.

---

## Section 9: Internal Testing & Review

- [ ] **Internal testing track created in Play Console** — Upload first AAB to internal track.
- [ ] **Closed testing (alpha) track used before production** — At least 20 external testers.
- [ ] **Android Vitals baseline established** — Monitor crash rate and ANR rate before moving to production.
- [ ] **Play Console pre-launch report reviewed** — Google's automated testing (Firebase Test Lab) runs against your APK; review results for crashes.
- [ ] **Permissions warning reviewed** — Play Console flags unusual permissions; confirm `VIBRATE` is correctly categorized.

---

## Section 10: Post-Launch

- [ ] **In-app update API integrated (Phase 6)** — Use `Play In-App Updates` library to prompt for updates.
- [ ] **Play Billing Library integrated (Phase 6)** — For instrument pack IAPs; use Billing Library 6+.
- [ ] **Play Console analytics configured** — Monitor installs, active users, and rating trends.
- [ ] **Staged rollout configured** — Release to 10% of users first; monitor crash rate before full rollout.
- [ ] **Reply to reviews** — Engage with user feedback in Play Console to improve rating and visibility.
