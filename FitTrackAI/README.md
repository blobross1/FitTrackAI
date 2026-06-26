# Fit Track AI — SwiftUI

Native iOS app: **onboarding → Superwall subscription → AI body fat %** from progress photos.

## First time here?

**Start here:** [SIMPLE_MONETIZE.md](SIMPLE_MONETIZE.md) — short path to subscriptions (Simulator now, payments later).

**More detail:** [DEPLOY.md](DEPLOY.md) (Vercel, App Store) · [SUPERWALL_SETUP.md](SUPERWALL_SETUP.md) (dashboard step-by-step).

## Quick local run (developers)

1. Open `FitTrackAI.xcodeproj` in Xcode.
2. Copy `Config/Secrets.xcconfig.example` → `Config/Secrets.xcconfig` and fill in keys (or use scheme env vars below).
3. Attach `Secrets.xcconfig` to the FitTrackAI target (see DEPLOY.md).
4. For testing **without** paying: **Edit Scheme → Run → Environment Variables** → `BYPASS_PAYWALL` = `1`.
5. Press **⌘R** (iOS 17+, iPhone simulator).

## Architecture

| Layer | Role |
|-------|------|
| **Onboarding** | Quiz + mock scan + Superwall paywall |
| **Superwall** | Subscriptions (`onboarding_paywall`, `main_gate`, `body_fat_scan`) |
| **Backend** (`/backend`) | Vercel proxy — OpenAI key stays on server |
| **App** | Photos, body fat %, weight & lean-mass charts (local JSON) |

## Tabs

- **Weight %** — upload photo → AI analysis (subscriber only)
- **Analytics** — weight, body fat %, lean body mass charts

## Body fat formula

1. OpenAI returns `body_fat_low` / `body_fat_high` + feedback  
2. `avg = (low + high) / 2`  
3. `estimate = -1.67 + 0.765 × avg + 0.0406 × avg²`
