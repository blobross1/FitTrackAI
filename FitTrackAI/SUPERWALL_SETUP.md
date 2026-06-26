# Superwall + App Store setup (Fit Track AI)

Your app **already includes** SuperwallKit (SPM) and three placements in code. This guide is the dashboard + Apple side.

## What’s already in the app

| Placement | When it fires |
|-----------|----------------|
| `onboarding_paywall` | Last onboarding step (auto + “View Plans” button) |
| `main_gate` | Finished onboarding but not subscribed |
| `body_fat_scan` | “Analyze Photo” without subscription |

Configure runs in `FitTrackAIApp` → `SubscriptionManager.configure()`.

**Dev bypass:** `BYPASS_PAYWALL = 1` in `FitTrackAI/Secrets.xcconfig` skips paywalls (Debug only). **Remove before App Store release.**

---

## Part 1 — Superwall dashboard (~15 min)

1. Sign up at [superwall.com](https://superwall.com) → create an **iOS** app.
2. **Settings → Keys** → copy **Public API Key** (`pk_…`).
3. Put it in **`FitTrackAI/Secrets.xcconfig`** (not only `Config/`):

   ```
   SUPERWALL_API_KEY = pk_your_real_key_here
   ```

4. **Products** → add the **same Product IDs** you create in App Store Connect (e.g. `fittrack_monthly`, `fittrack_yearly`).
5. **Paywalls** → create **one** paywall (that’s enough) → attach your subscription products to it.
6. **Campaigns** → create a campaign (or use the default) → add **Placements** with these names **exactly**:

   - `onboarding_paywall`
   - `main_gate`
   - `body_fat_scan`

7. In the **campaign**, assign your **same paywall** to each placement (or to one audience that covers all users). You do **not** need three separate paywall designs — one paywall can power all three placements.
8. **Feature Gating** (on your one paywall):
   - Go to **Paywalls & Flows** → **click your paywall card** (not a Flow — Flows are multi-step; the app uses a single paywall).
   - In the editor, open the **Settings** tab/button in the **left sidebar** (gear icon — not a top-level “General” section).
   - Scroll to **Feature Gating** → choose **Gated** (user must subscribe before the app unlocks).
   - You set this once on that paywall; it applies everywhere the campaign shows it.
9. **Publish** the campaign (draft campaigns won’t show paywalls in the app).
10. **Settings → App Store Connect** → connect Apple (API key from App Store Connect → Users and Access → Integrations).

---

## Part 2 — App Store Connect (~20 min)

1. [developer.apple.com](https://developer.apple.com/programs/) — Apple Developer Program ($99/yr).
2. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+** New App.
3. **Bundle ID** must match Xcode (change from `com.demo.fittrackai` to yours, e.g. `com.yourname.fittrackai`).
4. **Subscriptions** → Subscription Group → add products:
   - Monthly (e.g. `fittrack_monthly`)
   - Yearly (e.g. `fittrack_yearly`)
5. Copy **Product IDs** into Superwall → Products.

---

## Part 3 — Xcode & device test (~10 min)

1. **Product → Clean Build Folder**, then run on a **physical iPhone** (Simulator IAP is limited).
2. Xcode → **FitTrackAI** target → **Signing** → your Team + Bundle ID.
3. App Store Connect → **Users and Access → Sandbox** → create **Sandbox Apple ID**.
4. On iPhone: **Settings → App Store → Sandbox Account** → sign in with sandbox account.
5. Turn off bypass for a real paywall test:
   - Remove `BYPASS_PAYWALL = 1` from `Secrets.xcconfig`, **or**
   - Edit Scheme → Run → Environment → disable `BYPASS_PAYWALL`.
6. Run app → complete onboarding → Superwall paywall should appear → purchase with sandbox (no real charge).
7. After purchase: app unlocks → **Analyze Photo** works without extra paywall.

**Restore:** Use “Restore Purchases” on paywall screens if a sandbox purchase succeeded but the app stays locked.

**Debug logs:** In Debug builds, Superwall logs at `.debug` in Xcode console.

---

## Part 4 — Before App Store submit

- [ ] Real `pk_…` in Release config (no `YOUR_` placeholder)
- [ ] **Remove** `BYPASS_PAYWALL` from Release / Archive builds
- [ ] Bundle ID matches App Store Connect
- [ ] Subscriptions **Ready to Submit** in App Store Connect
- [ ] Superwall products linked and campaign **published**
- [ ] Privacy policy URL + screenshots in App Store Connect
- [ ] Sandbox purchase + restore tested on device

---

## Cursor skill (optional)

Superwall’s agent skill is installed at `.agents/skills/superwall`. To reinstall:

```bash
npx skills add superwall/skills --skill superwall
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Paywall never shows | Placement name must match exactly; campaign published; real `pk_` key |
| Purchase works, app locked | Tap Restore; check product IDs match in Superwall + ASC |
| “Add SUPERWALL_API_KEY…” | Use `pk_…` in `FitTrackAI/Secrets.xcconfig`, Clean Build |
| Analyze works without paying | `BYPASS_PAYWALL=1` still on, or paywall set to **Non-Gated** |
| Build / package errors | File → Packages → Reset Package Caches |

More: [FitTrackAI/DEPLOY.md](DEPLOY.md) Part B & C.
