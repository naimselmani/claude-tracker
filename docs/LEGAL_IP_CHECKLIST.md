# Teli — Legal & IP Checklist

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18
**Status:** Pre-development review

This checklist must be reviewed and all items confirmed before App Store submission. Each item should be signed off by the responsible party.

---

## Section 1: App Name & Trademark

- [ ] **App name trademark search completed** — Search for "Teli" in USPTO (US), EUIPO (EU), and WIPO databases across Class 9 (software) and Class 41 (entertainment/education services). Document search results.
- [ ] **No conflicting registered trademarks found** — If conflicts found, consult trademark attorney before proceeding.
- [ ] **Domain names secured** — `teliapp.com`, `teliapp.io`, or equivalent acquired.
- [ ] **Social media handles secured** — @teliapp (or equivalent) reserved on major platforms.
- [ ] **App name does not match existing iOS/Android apps** — Search App Store and Google Play for "Teli" and variants.
- [ ] **Trademark application filed (optional for MVP)** — Consider filing in key markets (US, EU) before or shortly after launch.

---

## Section 2: Audio Samples

- [ ] **No copyrighted commercial recordings used** — All audio samples are either original recordings or sourced from verifiably royalty-free libraries.
- [ ] **Sample source documented for each instrument** — Maintain a spreadsheet: instrument, note, velocity layer, source, license type, license URL, license expiration (if any).
- [ ] **Original recordings: performer consent obtained** — If samples recorded from live musicians, written consent and work-for-hire agreement in place.
- [ ] **Royalty-free samples: license confirmed for commercial app use** — Many "royalty-free" libraries prohibit commercial redistribution inside apps; verify each license specifically permits this.
- [ ] **Royalty-free samples: license permits modification** — Velocity layers may involve sample editing; ensure license permits this.
- [ ] **No samples derived from commercial recordings** — Do not use samples extracted from any commercial music release, even if "transformed."
- [ ] **No Kontakt/proprietary library samples** — Samples from commercial sample libraries (Kontakt, EastWest, etc.) typically prohibit redistribution in apps.
- [ ] **Sample license documentation stored in /legal/sample_licenses/** — All license files, receipts, and contracts archived.
- [ ] **Perpetual license or multi-year license confirmed** — Avoid sample licenses that expire, as this would require removing the app or updating samples.

---

## Section 3: Musical Content

- [ ] **No copyrighted melodies used as demonstration content** — Default chord progressions and scale examples are in the public domain or original.
- [ ] **No copyrighted songs triggered by default instrument configurations** — Chord presets (Am, G, C, D) are generic musical building blocks, not derived from any specific copyrighted work.
- [ ] **No loops, beats, or backing tracks included** — MVP contains only individual note samples; no pre-composed content.
- [ ] **Traditional scales (Phrygian, etc.) are in public domain** — Musical scales and modes are not copyrightable; confirmed.

---

## Section 4: Icons, Images, and Visual Assets

- [ ] **All app icons are original artwork** — Created by commissioned designer or in-house. No stock icon services used without license review.
- [ ] **Instrument images are original artwork** — SVG/PNG illustrations of instruments are original, not traced from copyrighted photographs.
- [ ] **SF Symbols usage complies with Apple's terms** — SF Symbols require an Apple platform app and attribution where required. Confirmed compliance with SF Symbols License.
- [ ] **No stock photography from unlicensed sources** — Any photographs used (unlikely in MVP) must have commercial use license.
- [ ] **Fonts are properly licensed** — SF Pro is Apple's system font, licensed for use on Apple platforms. No third-party fonts used in MVP. Confirmed.
- [ ] **App icon does not resemble Apple's default icons** — Verified visually distinct from system apps.
- [ ] **Gradient colors and visual style are original** — Amber/dark palette is a common design choice and not copyrightable; confirmed.

---

## Section 5: App Content & Claims

- [ ] **No claim of being "official," "authentic," or "endorsed"** — App description and all in-app text must not claim official status regarding any traditional instrument or cultural institution.
- [ ] **Cultural instrument descriptions are educational, not appropriative** — Instrument descriptions are presented as introductions to the instruments' origin, not as authoritative cultural statements.
- [ ] **No specific cultural institution named as endorsing the app** — Do not reference any government, museum, or cultural organization without written permission.
- [ ] **Instrument names spelled accurately and with care** — "Çiftelija" and "Lahuta" are spelled correctly and consistently throughout the app and marketing.
- [ ] **No medical, therapeutic, or healing claims made** — The app must not claim to provide music therapy or health benefits.
- [ ] **App rating claim compliance** — Content rated 4+ is consistent with actual content (no violence, no adult content, no user-generated content).

---

## Section 6: Privacy & Data Compliance

- [ ] **Privacy Policy document exists and is publicly hosted** — URL: `https://[domain]/privacy`. Policy must be up-to-date before launch.
- [ ] **Privacy Policy accurately reflects MVP data practices** — States that no personal data is collected, no analytics, no crash reporting with personal data.
- [ ] **Terms of Service accessible** — Basic ToS available at `https://[domain]/terms` and linked from the app's Settings screen.
- [ ] **GDPR Article 13 notice not required (no data collected)** — Confirmed: no processing of personal data, so Article 13 notice is not mandatory. Document this determination.
- [ ] **CCPA compliance: no sale of personal information** — Confirmed: no personal data collected or sold. Document this determination.
- [ ] **COPPA: no data collected from any user** — No age gate required because no data is collected from anyone. Document this determination.
- [ ] **App Tracking Transparency (ATT) prompt: not required** — Confirmed: no tracking, no advertising IDs. No ATT prompt needed.
- [ ] **Future analytics plan documented** — If analytics is added in a future version, a consent mechanism must be implemented. This is tracked in the roadmap.

---

## Section 7: Credits & Licenses Screen

- [ ] **Credits/Licenses screen implemented in app** — Accessible from Settings screen.
- [ ] **All open-source libraries listed** — Any Swift packages, fonts, or other OSS components listed with their license type and copyright notice.
- [ ] **Audio sample sources credited** — All sample sources credited per their license terms.
- [ ] **App version number displayed** — Build number and version string visible to users.
- [ ] **"Teli is not affiliated with..." disclaimer included** — If mentioning cultural traditions, a disclaimer clarifying the app is an independent creative work.

---

## Section 8: Third-Party SDKs & Frameworks

- [ ] **No third-party SDKs used in MVP** — MVP uses only Apple first-party frameworks: CoreMotion, AVFoundation, CoreHaptics, SwiftUI, StoreKit. Confirmed.
- [ ] **If a third-party library is added: license reviewed** — Any future addition must be reviewed for commercial use compatibility.
- [ ] **StoreKit (Phase 6): Apple's standard, no additional license required** — Confirmed.

---

## Section 9: Export Compliance

- [ ] **Encryption export compliance answered in App Store Connect** — The app uses Apple's standard AES encryption (HTTPS not present in MVP; local encryption if any is via Apple APIs). Answer: "No custom encryption."
- [ ] **Audio compression (AAC/WAV) is not export-controlled** — Standard audio formats are not controlled under US EAR. Confirmed.
- [ ] **CoreMotion data processing is not export-controlled** — Motion data is processed locally, not a controlled technology. Confirmed.

---

## Section 10: Ongoing Legal Obligations

- [ ] **GDPR breach notification plan in place** — Even with no data collected, a plan exists for the unlikely event of a supply chain compromise.
- [ ] **App Store review guidelines reviewed** — Latest guidelines confirmed compatible with Teli's design (no IAP pressure, no misleading claims, no private APIs).
- [ ] **Intellectual property monitoring** — Plan to monitor for trademark conflicts with "Teli" in major markets annually.
- [ ] **Sample license renewals tracked** — If any sample licenses have expiration dates, renewal dates are calendared.
- [ ] **Open-source license obligations monitored** — If any GPL-licensed code is added in future, distribution obligations must be met.

---

*This checklist was prepared for reference purposes and does not constitute legal advice. Consult a qualified attorney for trademark, copyright, and privacy law guidance.*
