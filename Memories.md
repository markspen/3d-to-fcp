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

## Submission Status (as of 2026-05-28)
- **App is feature-complete v1.** 12 tests green, build clean. GitHub `markspen/3d-to-fcp` (public, `main`).
- **Bundle ID:** `com.markspencer.ThreeDtoFCP`. SKU `3DTOFCP-001`.
- **Build history:**
  - 1.0(1) — rejected. Guideline 2.1(a): no sample files provided. Guideline 4: no way to reopen window after close. Both fixed in 1.0(2).
  - 1.0(2) — current build. Uploaded 2026-05-28. Fixes: (1) quit app on window close via `AppDelegate.applicationShouldTerminateAfterLastWindowClosed`; (2) added `LSApplicationCategoryType` and `ITSAppUsesNonExemptEncryption` to Info.plist. Mark smoke-tested — quit-on-close confirmed working.
- **TestFlight internal:** Build 1.0(2) status "Testing" in internal group. Mark verified on device.
- **TestFlight external:** Build 1.0(2) submitted for Beta App Review on 2026-05-28, status "Waiting for Review". Iain Anderson (funwithstuff@icloud.com) added to external group — invite will auto-send once Beta App Review clears.
- **Sample files for App Review:** 9 Apple sample USDZ files in `sample-files/` folder of GitHub repo. Provided in response to Guideline 2.1(a) rejection.
- **App Store review delays (systemic, May 2026):** Apple Developer Forums show widespread reports of 5–40+ day waits. Normal to wait.
- **App Store listing:** fully filled in. Build deliberately NOT attached — will attach 1.0(2) after external testing wraps clean.
- **Support URL:** `https://github.com/markspen/3d-to-fcp/issues`
- **Privacy Policy URL:** `https://markspen.github.io/3d-to-fcp/privacy.html`
- **App Store category:** Graphics & Design (primary), Video (secondary). `LSApplicationCategoryType` = `public.app-category.video`.
- **Next steps:** (1) wait for Beta App Review → Iain tests; (2) once external testing clean, attach 1.0(2) to App Store submission and submit for full review.

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
