# Deploy Fit Track AI to the App Store (first-timer guide)

This app has **three parts** that work together:

| Part | What it does | Where it runs |
|------|----------------|---------------|
| **iPhone app** | Onboarding, paywall, photos, charts | App Store |
| **Superwall** | Shows paywalls & checks subscriptions | Superwall + Apple |
| **Backend** (`backend/`) | Hides your OpenAI key; analyzes photos | Vercel (free tier) |

You must finish **all three** before real users can pay and scan.

---

## Part A — Deploy the backend (~10 minutes)

The OpenAI key stays on Vercel, not in the app.

### 1. Create a Vercel account

Go to [vercel.com](https://vercel.com) and sign up (free).

### 2. Deploy (no global install needed)

You do **not** need `npm install -g vercel` (that often fails with `EACCES` on Mac). Use `npx` instead:

```bash
cd backend
npx vercel
```

First run downloads the CLI temporarily; log in when prompted.

**If you prefer a global install** (optional), fix permissions once:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g vercel
```

### 3. Production deploy

- Link to your account, create a new project, accept defaults.
- When asked for settings, confirm the `api` folder is detected.

### 4. Set secrets on Vercel

In the [Vercel dashboard](https://vercel.com) → your project → **Settings → Environment Variables**, add:

| Name | Value |
|------|--------|
| `OPENAI_API_KEY` | Your OpenAI key (`sk-...`) |
| `FITTRACK_API_SECRET` | A long random string you invent (e.g. 32+ chars). **Same value** goes in the app config below. |

Redeploy after adding variables:

```bash
cd backend
npx vercel --prod
```

### 5. Copy your API URL

After deploy you get a URL like:

`https://fittrack-xxxxx.vercel.app/api/analyze`

Test it (replace `SECRET` and use a tiny base64 image or skip until the app works):

```bash
curl -X POST https://YOUR-URL.vercel.app/api/analyze \
  -H "Authorization: Bearer YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"imageBase64":"..."}'
```

---

## Part B — Superwall + Apple subscriptions (~30–45 minutes)

### 1. Apple Developer Program

- Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/) (**$99/year**).
- You need this before you can sell on the App Store.

### 2. App Store Connect — create subscriptions

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+** New App.
2. Set **Bundle ID** (e.g. `com.yourname.fittrackai`) — must match Xcode later.
3. **Subscriptions** → create a **Subscription Group** → add products, for example:
   - `fittrack_monthly` — $9.99/month  
   - `fittrack_yearly` — $59.99/year  
4. Note the **exact Product IDs** — you’ll paste them into Superwall.

### 3. Superwall setup

1. [superwall.com](https://superwall.com) → create an app (iOS).
2. Copy the **Public API Key** (`pk_...`).
3. **Products** — link the same App Store product IDs.
4. **Paywalls** — design at least one paywall and attach products.
5. **Placements** — create these names **exactly** (the app uses them):

| Placement name | When it shows |
|----------------|---------------|
| `onboarding_paywall` | End of onboarding |
| `main_gate` | User finished onboarding but isn’t subscribed |
| `body_fat_scan` | User taps “Analyze Photo” without access |

6. Connect **App Store Connect** in Superwall (API key / shared secret from App Store Connect → Users and Access → Integrations).

### 4. Sandbox testing

- App Store Connect → **Users and Access → Sandbox** → create a **Sandbox Apple ID**.
- On your iPhone: **Settings → App Store → Sandbox Account** — sign in with that test account.
- Purchases won’t charge real money.

---

## Part C — Configure Xcode (~10 minutes)

### 1. Secrets file

```bash
cp FitTrackAI/Config/Secrets.xcconfig.example FitTrackAI/Secrets.xcconfig
```

Edit **`FitTrackAI/Secrets.xcconfig`** (project root — the file Xcode links):

```
SUPERWALL_API_KEY = pk_your_real_key
FITTRACK_API_URL = https:/$()/your-app.vercel.app/api/analyze
FITTRACK_API_SECRET = same_secret_as_vercel
BYPASS_PAYWALL = 1
```

**Important:** In `.xcconfig` files, `//` starts a comment. Never write `https://` directly or the URL is cut off to `https:` and analysis fails with “not configured”. Use `https:/$()/` as shown.

### 2. Attach xcconfig to the target

1. Open `FitTrackAI.xcodeproj` in Xcode.
2. Click the **FitTrackAI** project (blue icon) → **Info** tab.
3. Under **Configurations**, set **Debug** and **Release** to **`FitTrackAI/Secrets.xcconfig`** for the FitTrackAI target.

If the file isn’t in the project: drag `Secrets.xcconfig` into Xcode (don’t copy to target — reference only).

### 3. Signing & bundle ID

1. Select **FitTrackAI** target → **Signing & Capabilities**.
2. Choose **your** Team.
3. Change **Bundle Identifier** from `com.demo.fittrackai` to the one you created in App Store Connect.

### 4. Info.plist keys (via Build Settings)

The target should pass secrets into the app. If scans fail with “not configured”, add to **Build Settings → User-Defined** or ensure these exist in Debug/Release:

- `INFOPLIST_KEY_SUPERWALL_API_KEY` = `$(SUPERWALL_API_KEY)`
- `INFOPLIST_KEY_FITTRACK_API_URL` = `$(FITTRACK_API_URL)`
- `INFOPLIST_KEY_FITTRACK_API_SECRET` = `$(FITTRACK_API_SECRET)`

(Already set in the project if you pulled latest code.)

### 5. Local testing without paying

**Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:**

| Name | Value |
|------|--------|
| `BYPASS_PAYWALL` | `1` |

Use only for development. **Remove before App Store release.**

### 6. Run on a real device

Simulator can’t test real IAP. Use a physical iPhone with Sandbox account.

---

## Part D — Submit to App Store (~20 minutes + review wait)

### 1. App Store listing

In App Store Connect, fill in:

- **Screenshots** (6.7" and 6.5" iPhone required)
- **Description**, **keywords**, **support URL**, **privacy policy URL** (required)
- **App Privacy** questionnaire (photos → used for analysis; purchases → yes)

### 2. Archive & upload

1. Xcode → select **Any iOS Device (arm64)**.
2. **Product → Archive**.
3. **Distribute App → App Store Connect → Upload**.

### 3. Submit for review

- App Store Connect → your build → **Submit for Review**.
- Answer export compliance (HTTPS only → typically “No” for custom encryption).
- Review often takes **24–48 hours**.

---

## Quick checklist

- [ ] Vercel deployed with `OPENAI_API_KEY` + `FITTRACK_API_SECRET`
- [ ] `Secrets.xcconfig` filled in and linked to target
- [ ] Superwall `pk_` key + placements `onboarding_paywall`, `main_gate`, `body_fat_scan`
- [ ] App Store subscription products created and linked in Superwall
- [ ] Bundle ID + signing team set in Xcode
- [ ] Tested purchase with Sandbox Apple ID on a real device
- [ ] Privacy policy URL live
- [ ] Removed `BYPASS_PAYWALL` from Release builds

---

## How money flows

1. User subscribes in Superwall → Apple charges them.
2. Apple keeps 15–30%; pays you monthly to your bank (after tax/banking setup in App Store Connect).
3. You pay OpenAI per photo scan on Vercel.
4. Superwall has a free tier; paid plans if you scale.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Paywall never appears | Check `SUPERWALL_API_KEY` starts with `pk_`; placements exist in dashboard |
| “Analysis server not configured” | Check `FITTRACK_API_URL` and `FITTRACK_API_SECRET` in xcconfig |
| 401 from backend | App `FITTRACK_API_SECRET` must match Vercel |
| Purchase succeeds but app locked | Tap Restore; check Superwall ↔ App Store product IDs match |
| Build fails on Superwall | File → Packages → Reset Package Caches |

---

## What’s mock vs real

| Feature | Status |
|---------|--------|
| Onboarding scan animation | Mock (marketing funnel) |
| Main app body fat scan | **Real** (via Vercel + OpenAI) |
| Paywall UI | **Real** (Superwall + Apple) |
| Charts / history | Real (local on device) |

Good luck with your first launch.
