# Fit Track AI — Simple monetization guide

Apple’s setup is a lot of steps. **Your app in Xcode is already built for subscriptions.** This guide is the shortest path to making money. Ignore the long docs until you need details.

**Deep dives (optional):** [SUPERWALL_SETUP.md](SUPERWALL_SETUP.md) · [DEPLOY.md](DEPLOY.md)

---

## What’s already done in code

- Onboarding → paywall → main app  
- Superwall placements: `onboarding_paywall`, `main_gate`, `body_fat_scan`  
- “Analyze Photo” requires subscription (unless bypass is on)  
- AI photos via your Vercel backend  

You don’t need to rewrite the app — only **Apple + Superwall dashboard + a working build**.

---

## Phase 1 — Use the app today (no payments yet)

**Goal:** Keep building in Xcode without signing or device headaches.

1. In Xcode, set the run destination to **iPhone Simulator** (e.g. iPhone 16).  
   **Not** your physical iPhone, **not** “Any iOS Device”.
2. In **`FitTrackAI/Secrets.xcconfig`** (the file Xcode uses — project root), keep:
   - `BYPASS_PAYWALL = 1` — skips paywalls while you develop  
   - `FITTRACK_API_URL` and `FITTRACK_API_SECRET` — for photo analysis  
   - URLs must use `https:/$()/...` in xcconfig (see DEPLOY.md)  
3. **Product → Run** (⌘R).

You get the full app in the Simulator. That’s enough for daily work.

**Stop here** until you’re ready for Phase 2.

---

## Phase 2 — Turn on real payments (~one afternoon)

**Goal:** A user can subscribe and unlock the app.

Do these **in order**.

### A. Apple ($99/year)

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) if you haven’t.
2. [App Store Connect](https://appstoreconnect.apple.com) → create your app.
3. Choose **one** bundle ID, e.g. `com.yourname.fittrackai`.
4. **Subscriptions** → create at least one product (monthly is fine).  
   Note the **Product ID** (e.g. `fittrack_monthly`).

### B. Superwall

1. [superwall.com](https://superwall.com) → iOS app → copy **Public API Key** (`pk_…`).
2. In **`FitTrackAI/Secrets.xcconfig`**:
   ```
   SUPERWALL_API_KEY = pk_your_real_key_here
   ```
3. **Products** → add the **same** Product ID as App Store Connect.
4. Create **one paywall** and attach that product.
5. **Campaign** → add placements (names must match exactly):
   - `onboarding_paywall`
   - `main_gate`
   - `body_fat_scan`  
   Point them at your **one paywall** → **Publish** the campaign.
6. Open the paywall → **Settings** (left sidebar in editor) → **Feature Gating** → **Gated**.

You do **not** need three paywall designs — one paywall can serve all three placements.

### C. Xcode (two changes)

1. **Signing & Capabilities** → **Bundle Identifier** = same as App Store Connect (replace `com.demo.fittrackai`).
2. **Team** = your Apple Developer team, **Automatically manage signing** on.

### D. Test a real purchase (when you can get the app on an iPhone)

Simulator is **not** reliable for subscriptions.

- **Easiest:** plug iPhone in once → select it in Xcode → Run.  
- **No cable:** use **TestFlight** later (Archive → upload → install via TestFlight app).

Before testing paywall: remove `BYPASS_PAYWALL = 1` from `Secrets.xcconfig`, clean build, run on device.

**Sandbox:** App Store Connect → Sandbox tester → on iPhone: **Settings → App Store → Sandbox Account**.

You can finish Phase 2 dashboard work before Phase 2D if the phone is hard right now.

---

## Phase 3 — App Store (when the app is ready)

Not urgent. Checklist:

- [ ] Privacy policy URL  
- [ ] Screenshots  
- [ ] Remove `BYPASS_PAYWALL` from **Release** builds  
- [ ] Xcode **Product → Archive** → upload → submit for review  

See [DEPLOY.md](DEPLOY.md) Part D for details.

---

## What to ignore for now

| Skip | Why |
|------|-----|
| Long DEPLOY / SUPERWALL guides | Use this file first |
| Physical iPhone + red signing errors | Simulator + bypass in Phase 1 |
| Multiple paywall designs | One paywall is enough |
| Superwall **Flows** | Use a **Paywall**, not a Flow |
| Perfect sandbox testing on day one | TestFlight or one cable session later |

---

## Troubleshooting (one line each)

| Problem | Fix |
|---------|-----|
| Red signing errors | Run destination = **Simulator**, not real device |
| “Analysis not configured” | Fix `FITTRACK_API_URL` in `FitTrackAI/Secrets.xcconfig` — use `https:/$()/...` |
| Paywall never shows | Real `pk_` key, campaign **published**, placement names exact |
| App works but no paywall in Simulator | Normal — use device or TestFlight for purchase tests |
| Purchase works, app still locked | Restore purchases; product IDs match in Superwall + Apple |

---

## One-line summary

**Now:** Simulator + `BYPASS_PAYWALL = 1` → use the app you love.  
**Monetize:** Apple subscription → Superwall key + one paywall + 3 placements → same bundle ID in Xcode → test on a real iPhone when you can.
