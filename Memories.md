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

## Submission Status (as of 2026-05-15)
- **App is feature-complete v1.** 12 tests green, build clean. GitHub `markspen/3d-to-fcp` (public, `main`).
- **Bundle ID:** `com.markspencer.ThreeDtoFCP`. SKU `3DTOFCP-001`.
- **TestFlight:** Build 1.0(1) submitted for Beta App Review on 2026-05-14, status "Waiting for Review" (~24h elapsed as of 2026-05-15). Mark smoke-tested the TestFlight build — all good. Iain Anderson (funwithstuff@icloud.com) added as external tester but can't test yet — external testers are gated on Beta App Review approval.
- **App Store listing:** fully filled in (description, keywords, screenshots ×5, age rating, privacy declarations, content rights, contact info). Build deliberately NOT attached — plan is to ship a fresh 1.0(2) after TestFlight testing wraps.
- **Support URL:** `https://github.com/markspen/3d-to-fcp/issues`
- **Privacy Policy URL:** `https://markspen.github.io/3d-to-fcp/privacy.html` (GitHub Pages, declared no data collected)
- **App Store category:** Graphics & Design (primary), Video (secondary). `LSApplicationCategoryType` in Info.plist = `public.app-category.video`.
- **Next steps:** (1) wait for Beta App Review to clear → Iain's invite auto-sends; (2) once external testing wraps clean, archive build 1.0(2); (3) attach 1.0(2) to the App Store submission and submit for review.

## Submission Gotchas (learned during submission)
- Automatic signing + a hardcoded `CODE_SIGN_IDENTITY` in project.yml = archive failure (conflicting provisioning). Remove the per-config identity lines; let automatic signing pick.
- Missing `LSApplicationCategoryType` = App Store validation failure. Must be declared in the infoPlist block.
- `ITSAppUsesNonExemptEncryption: false` in Info.plist avoids the per-build encryption-compliance prompt.
- "No Builds Available" for an external tester does NOT mean the build failed — it means Beta App Review hasn't approved external distribution yet.
