# FitTrackAI (ActionX)

AI body-fat analysis iOS app with Superwall subscriptions and a Vercel analysis backend.

## Quick start (after clone)

1. **iOS secrets** — copy the example config and add your keys (file stays local, not in git):

   ```bash
   cp FitTrackAI/Secrets.xcconfig.example FitTrackAI/Secrets.xcconfig
   ```

   Fill in `SUPERWALL_API_KEY`, `FITTRACK_API_URL`, and `FITTRACK_API_SECRET`. See [FitTrackAI/DEPLOY.md](FitTrackAI/DEPLOY.md).

2. **Open** `FitTrackAI/FitTrackAI.xcodeproj` in Xcode and run on Simulator or device.

3. **Backend** — deploy `backend/` to Vercel; set `OPENAI_API_KEY` and `FITTRACK_API_SECRET` in the Vercel dashboard (not in git).

4. **Fastlane** (optional) — `cp FitTrackAI/.env.example FitTrackAI/.env` and add App Store Connect API key paths.

Your real `Secrets.xcconfig` on this machine is gitignored — the app keeps working here after push.
