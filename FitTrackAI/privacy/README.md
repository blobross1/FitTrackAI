# Privacy Policy — GitHub Pages Setup

This folder contains your app's privacy policy, hosted on GitHub Pages.

## Your Privacy Policy URL

After enabling GitHub Pages, your policy will be available at:

**https://blobross1.github.io/FitTrackAI/privacy/**

Use this URL in:
- App Store Connect → App Privacy
- `fastlane/metadata/en-US/privacy_url.txt`
- Your app's settings screen (if required)

## Enable GitHub Pages

1. Push this repo to GitHub:
   ```bash
   git add privacy/
   git commit -m "Add privacy policy"
   git push
   ```

2. On GitHub.com, go to your repo → **Settings** → **Pages**

3. Under **Build and deployment**:
   - **Source:** Deploy from a branch
   - **Branch:** `main` (or `master`)
   - **Folder:** `/privacy`

4. Click **Save**. GitHub will build your site in ~1 minute.

5. Visit `https://blobross1.github.io/FitTrackAI/privacy/` to verify it works.

## Customize

Edit `privacy/index.html` to accurately describe your app's data practices.
Apple requires your privacy policy to match what you declare in App Store Connect.

## Alternative: docs/ folder

If you prefer the `/docs` folder convention:
```bash
mv privacy/index.html docs/index.html
# Then set GitHub Pages source to /docs
```
