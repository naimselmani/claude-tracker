# Teli — Apple App Store Submission Checklist

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18
**Target:** App Store (iOS, primary)

Complete all items before submitting the binary for App Store review.

---

## Section 1: App Identity & Registration

- [ ] **App name is unique on the App Store** — Search App Store for "Teli"; confirm no identical or confusingly similar app names in the Music category.
- [ ] **Bundle ID registered in Apple Developer portal** — `com.teli.app` (or chosen bundle ID) created and linked to provisioning profiles.
- [ ] **App ID created with correct capabilities** — CoreMotion does not require special entitlements; StoreKit (future) does. Confirm no unnecessary capabilities checked.
- [ ] **Team ID confirmed** — Correct Apple Developer team selected in Xcode build settings.
- [ ] **App version and build number set correctly** — Version: `1.0.0`, Build: `1` (or first release build number).
- [ ] **Minimum iOS version set** — `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in Xcode project settings.

---

## Section 2: Privacy Nutrition Labels

Apple requires accurate Privacy Nutrition Labels in App Store Connect before submission.

- [ ] **"Data Not Collected" declaration confirmed** — Since Teli collects zero data, select "We do not collect data from this app" in App Store Connect → App Privacy.
- [ ] **No analytics SDK present that reports to external servers** — Verified by code audit: no Firebase, Mixpanel, Segment, Amplitude, or similar SDKs in the binary.
- [ ] **No advertising SDK present** — Verified: no AdMob, Facebook Audience Network, or similar.
- [ ] **No crash reporting SDK with external network calls** — Verified: no Crashlytics, Sentry, or Bugsnag in MVP binary. (If added in future: update privacy labels and add consent mechanism.)
- [ ] **UserDefaults usage is local only** — Confirmed: only `UserDefaults.standard` used; no iCloud sync (`NSUbiquitousKeyValueStore`) in MVP.

---

## Section 3: Usage Description Strings (Info.plist)

CoreMotion does **not** require a usage description string (unlike Camera, Location, or Microphone). However, confirm:

- [ ] **`NSMotionUsageDescription` reviewed** — This key is NOT required for CoreMotion in most configurations. Confirm whether it is needed for the specific CoreMotion APIs used. Add if required by Apple's review process.
- [ ] **No Camera usage description** — `NSCameraUsageDescription` is absent (camera not used).
- [ ] **No Microphone usage description** — `NSMicrophoneUsageDescription` is absent (microphone not used).
- [ ] **No Location usage description** — All location permission keys absent.
- [ ] **No Contacts, Health, or Bluetooth usage descriptions** — Absent.
- [ ] **All Info.plist keys reviewed** — No stale permission strings from templates or copy-paste artifacts.

---

## Section 4: App Store Listing Content

- [ ] **App name: "Teli"** — 30-character limit; "Teli" is well within limit.
- [ ] **Subtitle: "Play with Motion"** — 30-character limit; within limit.
- [ ] **Description written (max 4000 characters)** — Clear, honest description of what Teli does. No keyword stuffing. No claims about other apps. No superlatives like "best" without substantiation.
- [ ] **Keywords field completed (max 100 characters)** — Relevant music/instrument/motion keywords selected. No competitor brand names.
- [ ] **Support URL provided** — Points to a working support page or email form.
- [ ] **Marketing URL provided (optional)** — Landing page URL if available.
- [ ] **Privacy Policy URL provided** — Required for all apps. URL must be live and accurate before submission.
- [ ] **"What's New" text for updates** — Not needed for v1.0.0 initial release.
- [ ] **No misleading claims in description** — Does not claim to be "the first," "the only," or make unverifiable performance claims.
- [ ] **Description does not reference competitors or third-party apps** — Removed all comparative language.

---

## Section 5: Screenshots & App Preview

### Required Screenshot Sizes

- [ ] **6.7" screenshots (iPhone 15 Pro Max / 14 Plus)** — Minimum 3, maximum 10. Size: 1290 × 2796 px.
- [ ] **6.1" screenshots (iPhone 15 / 14)** — Minimum 3, maximum 10. Size: 1179 × 2556 px.
- [ ] **5.5" screenshots (iPhone 8 Plus) — optional but recommended** — Size: 1242 × 2208 px.
- [ ] **iPad screenshots — if iPad supported** — Not required for iPhone-only app.
- [ ] **Screenshots show actual app UI** — No mock UIs, no device frames that misrepresent the app.
- [ ] **Screenshots include at least:** Home screen, instrument selection, play screen, settings screen.
- [ ] **No text overlays containing prohibited phrases** — Reviewed for compliance.

### App Preview Video (Optional)

- [ ] **App preview video recorded (optional)** — 15–30 second video showing actual app gameplay. Strongly recommended for a motion-based app.
- [ ] **Video shows gesture-to-sound interaction** — The shake → strum interaction is the key selling point; this should be visible.
- [ ] **No audio in preview that contains copyrighted music** — Only Teli's own samples audible in the preview.

---

## Section 6: Content Rating

- [ ] **Content rating questionnaire completed in App Store Connect** — Teli is rated **4+**.
- [ ] **No violence, no sexual content, no drug references** — Confirmed.
- [ ] **No user-generated content (UGC)** — MVP has no UGC; no moderation system needed.
- [ ] **No gambling, no simulated gambling** — Not applicable.
- [ ] **No horror or realistic violence** — Not applicable.

---

## Section 7: Technical Requirements

### Performance

- [ ] **Tested on minimum supported device: iPhone 12** — Full play session (30 minutes) completed without crash or significant performance degradation.
- [ ] **CPU usage during sustained play: < 15%** — Measured with Instruments → CPU Profiler.
- [ ] **Memory footprint: < 150 MB** — Measured with Instruments → Allocations.
- [ ] **Launch time: < 2 seconds (cold start)** — Measured with Instruments → App Launch.
- [ ] **Audio trigger latency: < 30ms** — Measured with Instruments → Audio (or AudioDeviceMetrics).
- [ ] **Battery drain: < 5% per 30-minute session** — Measured on device (Settings → Battery).
- [ ] **Crash-free rate target: ≥ 99.9%** — Validated via TestFlight beta with at least 100 sessions.

### Binary

- [ ] **No private API calls** — Verified using `nm` or a static analysis tool. No `@_silgen_name` tricks or private framework symbols.
- [ ] **Binary size < 500 MB** — App binary + assets. For MVP (bundled audio): measure IPA size. Audio samples will dominate; compress or reduce if over limit.
- [ ] **No simulator-only code in production binary** — All `#if targetEnvironment(simulator)` blocks verified.
- [ ] **64-bit only** — ARM64 only; no 32-bit slices. Confirmed in Xcode: `ARCHS = arm64`.
- [ ] **Bitcode setting reviewed** — Bitcode is deprecated since Xcode 14; ensure build settings are consistent with current Apple guidance.
- [ ] **Swift version** — Swift 5.9+ used; no deprecated API warnings at build time.

### Xcode Build Settings

- [ ] **Release configuration used for submission** — Not Debug.
- [ ] **Optimization level: `-O` (Whole Module Optimization recommended)** — Confirmed in Release config.
- [ ] **Debug symbols stripped from binary** — `STRIP_INSTALLED_PRODUCT = YES` in Release.
- [ ] **Valid signing certificate and provisioning profile** — Distribution certificate (not development) selected.
- [ ] **Entitlements file reviewed** — Only necessary entitlements present.

---

## Section 8: App Review Notes

Prepare notes for the App Store review team:

- [ ] **Review notes document written** — Explain how to test the app:
  - "Shake the device to trigger sounds."
  - "Select a chord by tapping the pill buttons at the bottom."
  - "Motion detection requires a physical device; does not function in the simulator."
- [ ] **Demo account not required** — No login needed.
- [ ] **Any special hardware or configuration explained** — "Please test on a physical iPhone (not simulator) for motion features."

---

## Section 9: TestFlight Pre-Submission

- [ ] **Internal testing completed** — All team members have tested on physical devices.
- [ ] **External TestFlight beta distributed** — At least 20 external testers across iPhone 12, 13, 14, 15 models.
- [ ] **Beta crash reports resolved** — All TestFlight crashes investigated and fixed.
- [ ] **Beta feedback incorporated** — Key UX issues from beta addressed before submission.
- [ ] **Beta build matches submission build** — Same version/build number or clear increment path.

---

## Section 10: Export Compliance

- [ ] **Export compliance answered in App Store Connect** — "Does your app use encryption beyond what is provided by the operating system?" Answer: **No** for MVP (no custom encryption, no HTTPS in MVP).
- [ ] **If HTTPS is added in future:** Confirm exemption (standard HTTPS) or complete BIS ENC filing.

---

## Section 11: Post-Submission

- [ ] **Monitor review status in App Store Connect** — Expected review time: 1–3 business days.
- [ ] **Respond to any review rejections within 24 hours** — Have the team available post-submission.
- [ ] **Phased release configured** — Consider phased release (7-day rollout) for v1.0 to catch issues with a subset of users.
- [ ] **App Analytics enabled in App Store Connect** — Review download metrics, crash rates, and session data (privacy-preserving aggregate data from Apple).
