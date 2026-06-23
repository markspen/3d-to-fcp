# 3D to FCP — Project Memory

## What This App Does
Converts USDZ files into Final Cut Pro titles by automating the creation of Motion template bundles.
Each USDZ becomes a draggable title in FCP's Titles Browser under the "3D to FCP" category.

## Decisions Locked In
- **Tech stack:** SwiftUI + AppKit drag-and-drop, Swift 5.10+, Xcode 16, macOS 14+
- **Distribution:** Mac App Store (requires sandbox + security-scoped bookmarks for ~/Movies/Motion Templates/)
- **Pricing:** Free
- **App name:** 3D to FCP
- **Bundle ID:** TBD — pending Developer account confirmation (Day Street Productions vs. personal)
  - Proposed: `com.daystreetproductions.ThreeDtoFCP`
- **No Motion detection:** user does not need Motion installed; titles work in FCP without it

## Feature Scope
- Drag-and-drop USDZ files onto window (multi-file supported)
- File picker button as alternative
- Batch progress UI with per-file status
- USDZ validation before processing
- Conflict handling when filename already exists in 3D to FCP category (overwrite/skip/rename)
- Success screen with "Reveal in Finder" + "Open Final Cut Pro" buttons
- User-editable category name in Preferences (default: "3D to FCP")

## Template File: _Placeholder.moti
- Located in project root (bundled inside the app at ship time)
- Format: flat XML (ozml 5.14), Motion 6.2, 4K 60fps, 10-second duration
- 3D Object scenenode uses `Airplane.usdz` from Motion Creator Studio's built-in library
- Two XML locations must be updated per output file:
  1. `name` attribute on the `<scenenode factoryID="2">` (full path to source USDZ)
  2. `<relativeURL>Media/Airplane.usdz</relativeURL>` → `Media/[userfile].usdz`
- **CONFIRMED FORMAT (verified against Buster.moti, a real user-created USDZ template):**
  The `.moti` is a flat XML file. The "bundle" is the containing folder, not the .moti itself.
  Output structure per USDZ:
  ```
  ~/Movies/Motion Templates.localized/Titles.localized/[Category Name]/
    [usdzname].localized/        ← per-template wrapper folder (this IS the "bundle")
      [usdzname].moti            ← flat XML (modified copy of _Placeholder.moti)
      Media/
        [usdzname].usdz          ← copy of user's USDZ file
  ```
  Optionally: large.png + small.png thumbnails (FCP generates these on first browse — not required)

- **Two XML locations to update per output file:**
  1. `name` attribute on `<scenenode factoryID="2">` in the footage section
     → Currently full path `/Applications/Motion Creator Studio.app/.../Airplane.usdz`
     → Must become just the filename without extension: e.g. `MyModel`
  2. `<relativeURL>Media/Airplane.usdz</relativeURL>`
     → Must become `<relativeURL>Media/MyModel.usdz</relativeURL>`

- **Category folder** = folder name inside Titles.localized/ — FCP reads this as the category name in Titles Browser.

## Sandbox / Entitlements Notes
- MAS sandbox requires user to grant access to ~/Movies/Motion Templates/ at first launch
- Use security-scoped bookmarks to persist access across sessions
- USDZ files dropped onto the app window use NSOpenPanel or drag-and-drop (both MAS-safe)

## Key Technical Risks
1. `.moti` bundle structure unknown — must verify before coding the engine
2. FCP title category naming — confirm "3D to FCP" shows correctly in Titles Browser without Motion open
3. USDZ validation: `usdchecker` (Apple CLI from USD tools) may not be present on user machines — need fallback

## App Name Change (2026-06-23) — "3D to FCP" → "3D to Timeline"
- **Why:** 1.0(3) was rejected under **Guideline 5.2.5 (Legal — Intellectual Property)**. Apple flagged "FCP" in the app name + macOS display name as a stand-in for the Final Cut Pro trademark. Metadata-only rejection; the conversion engine was never in question.
- **New name:** **3D to Timeline** ("timeline"/"NLE" is generic editing vocabulary, no Apple mark). Considered & rejected: anything with "FCP"/"Final Cut", "3D Portal" (icon has no portal — it's a clapperboard + low-poly 3D star), names with "Titles" (Mark: that's a publishing artifact, not the product).
- **Apple trademark rule (verified at apple.com/legal/intellectual-property):** You may NOT use an Apple mark "as or as part of a product name." You MAY use it referentially ("for Final Cut Pro", "compatible with") as long as it's *less prominent than your product name*. So: name = FCP-free; "Final Cut Pro" allowed in the **description body**; keep it OUT of the **subtitle** (prominent metadata) to avoid a second 5.2.5 bounce.
- **What changed in code (commit 704a90a on `main`, build bumped to 1.0(4)):** `CFBundleName`/`CFBundleDisplayName`/`PRODUCT_NAME` → "3D to Timeline"; `TEST_HOST` path updated; default Titles Browser category "3D to FCP" → **"3D Models"**; Help/UI strings updated, bare "FCP" expanded to "Final Cut Pro"; ConflictSheet now shows the live category name. **Bundle ID, target name, and module name UNCHANGED** (`com.markspencer.ThreeDtoFCP`) — changing the bundle ID would orphan the app per Apple's warning. 12/12 tests pass, built product is `3D to Timeline.app`.
- **Still TODO in App Store Connect (browser):** rename app to "3D to Timeline", set generic subtitle, ensure description has "for Final Cut Pro", reply in Resolution Center (Submission ID `6c4e9d00-1328-46f6-94b3-352ea86e62d9`), upload + attach + resubmit 1.0(4).

## Submission Status (as of 2026-06-23)
- **App is feature-complete v1.** 12 tests green, build clean. GitHub `markspen/3d-to-fcp` (public, `main`).
- **Bundle ID:** `com.markspencer.ThreeDtoFCP`. SKU `3DTOFCP-001`.
- **Build history:**
  - 1.0(1) — rejected. Guideline 2.1(a): no sample files provided. Guideline 4: no way to reopen window after close. Both fixed in 1.0(2).
  - 1.0(2) — uploaded 2026-05-28. Beta App Review approved; tested by Iain Anderson (external) and Steve Martin. Status "Testing".
  - 1.0(3) — uploaded + submitted 2026-06-15. **Rejected 2026-06-22 (reviewed on MacBook Pro 14" Nov 2024) under Guideline 5.2.5** — "FCP" in app name/display name = Final Cut Pro trademark. See "App Name Change" section above.
  - 1.0(4) — **SUBMITTED for App Store review 2026-06-23 at 12:43 PM → status "Waiting for Review".** Resolves the 5.2.5 rejection. Renames app "3D to FCP" → "3D to Timeline". Code merged to `main` (commit 704a90a) + pushed. Resubmission reused the same Submission ID `6c4e9d00-1328-46f6-94b3-352ea86e62d9`. App Store Connect metadata changes made: app Name → "3D to Timeline"; Description carries "for Final Cut Pro" (referential, allowed); 5 new 1440×900 screenshots (old ones showed "3D to FCP" in window title bar + the FCP Titles Browser category); keywords scrubbed of all Apple marks; reviewer reply posted in the submission thread. Subtitle left blank (optional; lives on App Information page under Name, not the version page).
    - Upload gotcha (Belize, flaky connection): Xcode Distribute first failed with HTTP 500 ("Error Downloading App Information"), then succeeded with "Upload completed with warnings" (skipped client-side validation + an Akamai `errors.edgesuite.net` HTML error page). **Both were transient CDN/network noise — the binary uploaded fine.** Don't re-upload on ambiguous warnings; confirm via the TestFlight "ready to test" email or the App Store Connect iOS app first (a duplicate build number is rejected as redundant).
    - The TestFlight email title still read "3D to FCP 1.0 (4)" because the ASC **app-name field** is still the old name (renaming it is a pending metadata edit). The binary's display name is correctly "3D to Timeline" (verified inside the archive).
- **Sample files for App Review:** 9 Apple sample USDZ files in `sample-files/` folder of GitHub repo. Provided in response to Guideline 2.1(a) rejection.
- **App Store review delays (systemic, May–June 2026):** Apple Developer Forums show widespread reports of 5–40+ day waits. The submission UI's "up to 48 hours" message is optimistic boilerplate.
- **App Store listing:** fully filled in. Build 1.0(3) attached and submitted 2026-06-15.
- **Support URL:** `https://github.com/markspen/3d-to-fcp/issues`
- **Privacy Policy URL:** `https://markspen.github.io/3d-to-fcp/privacy.html`
- **App Store category:** Graphics & Design (primary), Video (secondary). `LSApplicationCategoryType` = `public.app-category.video`.
- **Decisions on 1.0(3):** skipped TestFlight round, went straight to App Store review. Mark personally tested the Motion template + Add More flow locally. Acceptable risk given the 5–40 day review wait.
- **Next steps:** 1.0(4) is submitted and "Waiting for Review" as of 2026-06-23. Nothing to do but wait for Apple's verdict (5–40 day queue; emails go to markspencer@mac.com). If approved → live. If rejected → address feedback, bump to 1.0(5), resubmit.

## USDZ Conversion Toolchain
- **CLI script:** `~/scripts/usdz-convert` — converts OBJ, GLTF, GLB to USDZ from the terminal. Supports single file, named output, and batch (`*.glb`). Output written alongside input file by default.
- **Droplet:** `~/Desktop/USDZ Converter.app` — drag-and-drop any OBJ/GLTF/GLB onto it; USDZ appears in the same folder. Shows a macOS notification on success.
- **Claude skill:** `/usdz-convert` — invoke from within Claude to convert files.
- **How it works:** All three use Apple's `usdzconvert` Python 2.7 script bundled inside Reality Converter.app at `/Applications/Reality Converter.app/Contents/XPCServices/RealityConverterService.xpc/Contents/Resources/usdpython/usdzconvert/`. Requires Reality Converter to be installed. The bundled Python 2.7 binary must be used (system `/usr/bin/python` was removed in modern macOS).
- **Sample files for App Review:** 9 Apple sample USDZ files committed to `sample-files/` in the GitHub repo (`markspen/3d-to-fcp`). Provided to App Reviewers in response to Guideline 2.1(a) rejection on 2026-05-20.

## Submission Gotchas (learned during submission)
- Automatic signing + a hardcoded `CODE_SIGN_IDENTITY` in project.yml = archive failure (conflicting provisioning). Remove the per-config identity lines; let automatic signing pick.
- Missing `LSApplicationCategoryType` = App Store validation failure. Must be declared in the infoPlist block.
- `ITSAppUsesNonExemptEncryption: false` in Info.plist avoids the per-build encryption-compliance prompt.
- "No Builds Available" for an external tester does NOT mean the build failed — it means Beta App Review hasn't approved external distribution yet.
- **Guideline 5.2.5 (trademark) scope is ALL metadata, not just the name.** When clearing it, also scrub: **keywords** (had "FCP", "Final Cut Pro", "Motion", "Reality Composer", "Object Capture" — all Apple marks; replaced with generic terms), **screenshots** (old ones showed "3D to FCP" in the app window title bar AND in the FCP Titles Browser category sidebar), and the in-app default category. "Final Cut Pro" is fine ONLY as a referential phrase in the **description body** ("for Final Cut Pro"), never in name/subtitle/keywords. Verified rule at apple.com/legal/intellectual-property.
- **Mac App Store screenshots must be EXACTLY 1280×800, 1440×900, 2560×1600, or 2880×1800.** Off-by-a-few sizes (e.g. 1440×972) are rejected at upload. Fix with `sips -c 900 1440 in --out out` (center-crop) for too-tall shots, or `sips -z 900 1440` (resample) for slightly-off width. Mark's established format = 1440×900 JPG.
- **App Store Connect "Subtitle" lives on the App Information page (under Name), NOT the version page** — and it's optional. The version page holds Description, Keywords, Promo Text, URLs, screenshots, build.
- **Swapping the attached build:** when a build is already attached there's no "+"; hover the existing build row to reveal a remove control, detach it, then "Add Build" appears to pick the new one.
- **ASC web flakiness (esp. from abroad / on VPN):** symptoms seen in one session — "Try again later", HTTP 500 "Error Downloading App Information", "400 Bad Request: Request Header Or Cookie Too Large", "An unexpected error was encountered when submitting". Fixes in order: (1) the 400 cookie error → clear apple.com/appstoreconnect.apple.com/idmsa.apple.com cookies; (2) use a NORMAL (non-private) window — ASC breaks in private mode; (3) hard-refresh (⌘R) to clear stale disabled-button states; (4) check apple.com/support/systemstatus to rule out a real outage; (5) the App Store Connect iOS app uses a different backend and often works when the web doesn't. Retrying almost always clears these — none were real content problems.
- **Resubmitting a rejected version reuses the SAME Submission ID** and the original reviewer message thread stays on the submission-detail page (reachable via "View Submission") — you can reply there, or use the version page's App Review Information → Notes field. Status flow: Rejected → (edit + Save) Ready for Review → Resubmit to App Review → Waiting for Review.
