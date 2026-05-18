# Teli — Monetization Strategy

**Version:** 1.0.0 MVP
**Last Updated:** 2026-05-18
**Model:** Free app with optional one-time purchases. No subscriptions. No ads. No data selling.

---

## 1. Core Principles

Teli's monetization is designed to:

1. **Never compromise user trust** — no ads, no data selling, no dark patterns
2. **Never gate the core experience** — all three base instruments are permanently free
3. **Charge only for genuine added value** — expansion instruments and pro features
4. **Be legally straightforward** — no loot boxes, no consumables, no time-limited offers
5. **Respect the App Store and Play Store rules** — all purchases via StoreKit 2 / Play Billing

The free app is the product. Paid content is extra.

---

## 2. MVP Monetization (Phases 1–4: No Purchases Active)

During the MVP phases (instrument releases and recording feature), **no in-app purchases are available**. StoreKit is scaffolded in code but no products are created in App Store Connect.

**Rationale:**
- Establish trust and user base before monetizing
- Gather user feedback on which instruments and features are most valued
- Ensure the free app is genuinely excellent before asking for money

---

## 3. Phase 6 Monetization — Products

### 3.1 Free Forever (Base App)

| Content | Price |
|---------|-------|
| Guitar instrument | Free |
| Çiftelija instrument | Free |
| Lahuta instrument | Free |
| All tutorial content | Free |
| App itself | Free download |

No registration, no trial period, no "free for 7 days" messaging. Free means free, permanently.

### 3.2 Pro Unlock (One-Time Purchase)

**Product ID:** `com.teli.app.pro`
**Price tier:** $3.99 USD (or local equivalent)
**Type:** Non-consumable (permanent, transferable, Family Sharing eligible)

**What Pro unlocks:**
- Session recording (record live performance to audio buffer)
- Export recording as .m4a to Files app
- Share recording via share sheet
- Advanced reverb presets (3 additional presets beyond Medium Hall)
- Extended effects: per-instrument EQ preset selector

**What Pro does NOT do:**
- Does not unlock instruments (instruments are separate packs)
- Does not remove any core functionality limitations (there are none)

**Framing:** "Pro features for musicians who want to record and share their Teli performances."

### 3.3 Instrument Packs (One-Time Purchases)

Each instrument pack is a separate non-consumable IAP. Packs can be purchased independently.

**Pack structure:**
- Each pack adds 1–3 new instruments to the instrument list
- Instruments are delivered via app update (new entries in instruments.json + new audio samples in bundle)
- IAP purchase simply unlocks the instruments already present in the installed app
- No server-side content delivery in Phase 6 (simplifies legal and technical complexity)

**Planned packs (not committed):**

| Pack | Instruments (examples) | Price |
|------|------------------------|-------|
| Balkan Strings Pack | Tamburica, Saz | $2.99 |
| Nordic Strings Pack | Hardingfele, Nyckelharpa | $2.99 |
| World Winds Pack | Kaval, Fujara | $2.99 |

**Note:** Specific instruments in packs are subject to change based on sample recording availability and legal clearance (see LEGAL_IP_CHECKLIST.md). No specific cultural instrument will be named in marketing until samples are recorded, cleared, and the pack is ready for submission.

### 3.4 Bundle (Optional)

If 3+ instrument packs exist:

**Product ID:** `com.teli.app.bundle.all`
**Price:** 25% discount versus buying all packs individually
**Type:** Non-consumable bundle

---

## 4. StoreKit 2 Implementation (iOS)

### Transaction Flow

```swift
// Purchase
let result = try await Product.purchase(product)
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    await unlockPurchasedContent(for: transaction)
    await transaction.finish()
case .userCancelled, .pending:
    break
}

// Restore (called from Settings → Restore Purchases)
for await result in Transaction.currentEntitlements {
    let transaction = try checkVerified(result)
    await unlockPurchasedContent(for: transaction)
}
```

### Entitlement Persistence

- Purchased product IDs stored in `UserDefaults` as a `Set<String>` after verification
- On app launch: `Transaction.currentEntitlements` re-checked to refresh entitlements
- `instruments.json` `"isUnlocked": false` items are shown as locked cards with a purchase button
- After successful purchase: `isUnlocked` state is held in memory (overrides JSON); no JSON modification at runtime

### Family Sharing

All non-consumable products will have Family Sharing enabled in App Store Connect. This is a trust signal and costs nothing to implement (StoreKit handles it automatically).

### Restore Purchases

A "Restore Purchases" button is visible in Settings. Required by Apple's guidelines whenever non-consumables are sold.

```swift
// Settings screen restore button
Button("Restore Purchases") {
    Task {
        for await result in Transaction.currentEntitlements {
            // Re-process all current entitlements
        }
    }
}
```

---

## 5. Play Billing Implementation (Android, Phase 5)

Mirror of the iOS implementation using Google Play Billing Library 6+:

- Product types: `ONE_TIME` (equivalent to non-consumable)
- Acknowledgment required within 3 days of purchase (or refunded automatically by Google)
- `queryPurchasesAsync` called at app start and after successful purchase to verify entitlements
- Family Library (Google's equivalent) supported

---

## 6. Pricing Strategy

### Principles
- Price at the "thoughtless impulse buy" level — low enough to not require deliberation
- Instrument packs priced lower than a single cup of coffee in most target markets
- Pro unlock priced at app tier ($2.99–$4.99) — positions it as premium but not expensive

### Regional Pricing
- Use App Store and Play Store "comparable price" tiers for automatic regional pricing
- Do not manually set prices per territory in Phase 6 (complexity not worth it at launch scale)
- Review pricing after 6 months based on conversion data

---

## 7. No Ads Policy

Teli will not show advertising in the MVP or in Phase 6. Rationale:

1. **Brand positioning:** A premium, dark, minimal aesthetic is incompatible with advertising
2. **Privacy commitment:** Ad SDKs typically collect data; this contradicts Teli's privacy-first stance
3. **User experience:** Ads would interrupt the immersive music-making experience
4. **Revenue model:** IAP revenue from a smaller number of committed users is preferable to ad revenue from a larger number of disengaged users

Ads may be reconsidered if the app pivots to a free-with-ads model, but this would require a complete privacy policy update and App Store / Play Store re-submission.

---

## 8. No Subscription Policy

Teli will not introduce subscription purchases for any existing feature. If a subscription is introduced in a future major version:
- It must be for new, ongoing-value content (e.g., a new instrument every month)
- Existing one-time purchasers must retain their purchased content forever
- Subscription pricing must be clearly explained

---

## 9. No User Data Monetization

Teli will never:
- Sell user data to third parties
- License user behavior data to advertisers
- Use user data to build advertising profiles
- Share data with partners for monetization purposes

This is a founding constraint, not a policy that can be changed without a full re-architecture of the app and a new privacy policy.

---

## 10. Revenue Projections (Illustrative Only)

These are illustrative only — not forecasts or commitments.

| Scenario | Downloads (Month 3) | Conversion | ARPU | Monthly Revenue |
|----------|--------------------|-----------|----|----------------|
| Conservative | 5,000 | 2% Pro | $3.99 | ~$400 |
| Base | 15,000 | 3% Pro + 1% Pack | $4.50 | ~$2,025 |
| Optimistic | 40,000 | 4% Pro + 2% Pack | $5.00 | ~$8,000 |

**Key insight:** Teli's revenue model requires volume. The unit economics are good (margins ~70% after App Store/Play Store commission), but growth requires consistent marketing investment and a high-quality free experience that generates word-of-mouth.

---

## 11. Ethical Guardrails

- [ ] No countdown timers creating false urgency
- [ ] No "limited time offer" language unless genuinely time-limited
- [ ] No dark patterns (pre-selected upgrades, confusing cancel flows)
- [ ] Locked content is clearly shown as purchasable — no "bait" content that is actually unreachable
- [ ] Refund policy: Honor all App Store / Play Store refund requests without contest
- [ ] No differential pricing by user behavior (no "we see you've played for 100 hours, here's a targeted offer")
