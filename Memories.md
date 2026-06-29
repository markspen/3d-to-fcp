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
  - 1.0(4) — submitted 2026-06-23. Other ASC metadata fixed that round: Description carries "for Final Cut Pro" (referential, allowed); 5 new 1440×900 screenshots (old ones showed "3D to FCP" in the window title bar + the FCP Titles Browser category); keywords scrubbed of all Apple marks; reviewer reply posted.
  - 1.0(4) — **REJECTED AGAIN 2026-06-24, same Guideline 5.2.5.** Root cause: the App Store Connect **listing Name was never actually saved** — it silently failed on 06-23 amid the ASC connection errors, so the reviewer still saw the app name "3D to FCP". The binary was fine (`CFBundleDisplayName` = "3D to Timeline", verified), only the ASC Name field was wrong. **TELL we both missed: the ASC page header kept showing "3D to FCP" through every screenshot, including "Waiting for Review" — that was the signal the Name hadn't saved.**
  - 1.0(4) — **RE-SUBMITTED (same build, metadata-only) 2026-06-24 → "Waiting for Review".** Fix: set App Information → Name = "3D to Timeline" and **verified the header flipped to "3D to Timeline"** before resubmitting. Also removed "Final Cut Pro" from the **Subtitle** (had been "Get 3D files to Final Cut Pro" — prominent metadata, trademark risk after two strikes) → generic subtitle. No new binary needed. Same Submission ID `6c4e9d00-1328-46f6-94b3-352ea86e62d9`. **Bundle ID `com.markspencer.ThreeDtoFCP` (contains "FCP") is FINE and must stay** — internal identifier, never user-visible, not subject to 5.2.5; Apple warns changing it orphans the app. NOTE: 5.2.5 turnaround was ~1 day each round, not the 5–40 day queue.
    - Upload gotcha (Belize, flaky connection): Xcode Distribute first failed with HTTP 500 ("Error Downloading App Information"), then succeeded with "Upload completed with warnings" (skipped client-side validation + an Akamai `errors.edgesuite.net` HTML error page). **Both were transient CDN/network noise — the binary uploaded fine.** Don't re-upload on ambiguous warnings; confirm via the TestFlight "ready to test" email or the App Store Connect iOS app first (a duplicate build number is rejected as redundant).
    - The TestFlight email title still read "3D to FCP 1.0 (4)" because the ASC **app-name field** is still the old name (renaming it is a pending metadata edit). The binary's display name is correctly "3D to Timeline" (verified inside the archive).
- **Sample files for App Review:** 9 Apple sample USDZ files in `sample-files/` folder of GitHub repo. Provided in response to Guideline 2.1(a) rejection.
- **App Store review delays (systemic, May–June 2026):** Apple Developer Forums show widespread reports of 5–40+ day waits. The submission UI's "up to 48 hours" message is optimistic boilerplate.
- **App Store listing:** fully filled in. Build 1.0(3) attached and submitted 2026-06-15.
- **Support URL:** `https://github.com/markspen/3d-to-fcp/issues`
- **Privacy Policy URL:** `https://markspen.github.io/3d-to-fcp/privacy.html`
- **App Store category:** Graphics & Design (primary), Video (secondary). `LSApplicationCategoryType` = `public.app-category.video`.
- **Decisions on 1.0(3):** skipped TestFlight round, went straight to App Store review. Mark personally tested the Motion template + Add More flow locally. Acceptable risk given the 5–40 day review wait.
- **Next steps:** 1.0(4) re-submitted (metadata-only, name fixed) and "Waiting for Review" as of 2026-06-24. Verdict turnaround has been ~1 day per round. Emails → markspencer@mac.com. If approved → live (confirm release setting under Pricing and Availability first). If rejected → read the cited term carefully and verify the ASC header reflects every metadata change before resubmitting.

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
- **After changing the App Store Connect listing Name, VERIFY the page header actually changes to the new name.** A Name save can silently fail (esp. amid ASC connection errors) — the field may even appear updated while the saved value stays old. This cost a 2nd 5.2.5 rejection of 1.0(4): the binary was correctly "3D to Timeline" but the ASC listing Name was still "3D to FCP", and the giveaway (header still reading "3D to FCP") went unnoticed through the whole submit flow. The reviewer reads the ASC listing Name, not the binary, for the "app name" check.
- **Bundle ID is NOT subject to 5.2.5** — it's an internal identifier, never user-visible. Apple explicitly warns NOT to change it (orphans the app). `com.markspencer.ThreeDtoFCP` containing "FCP" is fine forever.
- **"Final Cut Pro" belongs ONLY in the description body** (referential, allowed). Keep it out of Name, Subtitle, and Keywords — Subtitle especially is prominent metadata and a trademark-rejection risk.
- **Guideline 5.2.5 (trademark) scope is ALL metadata, not just the name.** When clearing it, also scrub: **keywords** (had "FCP", "Final Cut Pro", "Motion", "Reality Composer", "Object Capture" — all Apple marks; replaced with generic terms), **screenshots** (old ones showed "3D to FCP" in the app window title bar AND in the FCP Titles Browser category sidebar), and the in-app default category. "Final Cut Pro" is fine ONLY as a referential phrase in the **description body** ("for Final Cut Pro"), never in name/subtitle/keywords. Verified rule at apple.com/legal/intellectual-property.
- **Mac App Store screenshots must be EXACTLY 1280×800, 1440×900, 2560×1600, or 2880×1800.** Off-by-a-few sizes (e.g. 1440×972) are rejected at upload. Fix with `sips -c 900 1440 in --out out` (center-crop) for too-tall shots, or `sips -z 900 1440` (resample) for slightly-off width. Mark's established format = 1440×900 JPG.
- **App Store Connect "Subtitle" lives on the App Information page (under Name), NOT the version page** — and it's optional. The version page holds Description, Keywords, Promo Text, URLs, screenshots, build.
- **Swapping the attached build:** when a build is already attached there's no "+"; hover the existing build row to reveal a remove control, detach it, then "Add Build" appears to pick the new one.
- **ASC web flakiness (esp. from abroad / on VPN):** symptoms seen in one session — "Try again later", HTTP 500 "Error Downloading App Information", "400 Bad Request: Request Header Or Cookie Too Large", "An unexpected error was encountered when submitting". Fixes in order: (1) the 400 cookie error → clear apple.com/appstoreconnect.apple.com/idmsa.apple.com cookies; (2) use a NORMAL (non-private) window — ASC breaks in private mode; (3) hard-refresh (⌘R) to clear stale disabled-button states; (4) check apple.com/support/systemstatus to rule out a real outage; (5) the App Store Connect iOS app uses a different backend and often works when the web doesn't. Retrying almost always clears these — none were real content problems.
- **Resubmitting a rejected version reuses the SAME Submission ID** and the original reviewer message thread stays on the submission-detail page (reachable via "View Submission") — you can reply there, or use the version page's App Review Information → Notes field. Status flow: Rejected → (edit + Save) Ready for Review → Resubmit to App Review → Waiting for Review.

## 3rd Review Outcome (2026-06-26) — 5.2.5 CLEARED, two NEW issues
- **Reviewed:** 1.0(4), MacBook Air (15", M2, 2023), same Submission ID `6c4e9d00-1328-46f6-94b3-352ea86e62d9`.
- **GOOD NEWS: the name change worked — no 5.2.5 this round.** "3D to Timeline" cleared the trademark check. The rename saga is closed.
- **Two new info-needed issues, BOTH resolved by a single Resolution Center reply — NO new binary, NO Developer Reject:**
  1. **Guideline 2.4.5(i) (Performance — entitlements):** reviewer said `com.apple.security.assets.movies.read-write` "does not appear to have matching functionality." It DOES — the app writes the generated Final Cut Pro title template to the fixed macOS location `~/Movies/Motion Templates/Titles/<Category>/` (default category "3D Models"), which is the entitlement's whole purpose (`MotionTemplatesManager.swift`, `TemplateBuilder.swift`). Reviewer simply couldn't reach the feature because of issue #2. Apple offered the no-binary path: reply and explain. **The entitlement is legitimately needed — do NOT remove it.**
  2. **Guideline 2.1(a) (Information Needed):** reviewer needed sample USDZ files hosted at a persistent location to run the workflow. The 9 sample USDZ files are already public at `https://github.com/markspen/3d-to-fcp/tree/main/sample-files` (verified raw download returns HTTP 200). Gave that URL + two direct raw links + step-by-step repro that ties the Movies-folder write to the entitlement (closing both issues at once).
- **The two issues were linked:** the reviewer couldn't see the entitlement used because they had no sample to run -> 2.1(a) and 2.4.5(i) answered together in one reply.
- **App's only input format is USDZ** (drag-drop or NSOpenPanel, `panel.allowedContentTypes = [UTType.usdz]`). Action button is **"Create"** (not "Convert").
- **Reply posted to Resolution Center 2026-06-26 and confirmed visible in the thread.** Status stayed "Rejected" after replying — that is NORMAL; a reply does NOT flip status to "In Review", the team re-evaluates the same submission in place. No resubmit button for an info-needed reply. Now waiting on verdict (~1-2 day turnaround).
- **LESSON: replying in Resolution Center keeps the status "Rejected" until the reviewer acts.** Don't mistake the unchanged status for the reply not working — confirm the reply shows in the message thread with a timestamp instead. Do NOT Developer Reject (that path is only for uploading a new binary, e.g. if removing an entitlement).
- **LESSON: keep entitlements minimal, but a USED entitlement is defensible by reply.** When 2.4.5(i) fires, first check whether code actually exercises the entitlement (grep the source). If yes -> reply with the exact code path + repro. If no -> remove it and ship a new binary. Here it was genuinely used.

## Motion Template Version / FCP Compatibility (researched 2026-06-29)
**Why this matters:** the app ships a bundled Motion title template (`_Placeholder.moti`) whose version stamp dictates which Final Cut Pro versions can open the generated titles. Got it wrong = customer/reviewer sees a red alert-badge, title won't load. This is the likely root cause of the Guideline 2.1 demo-video request (see below).

### The two version tags in a .moti (lines 3 & 5)
```
<ozml version="5.14">              <- file FORMAT version (coarse; bumps rarely)
<displayversion>6.2</displayversion>   <- = the Motion APP version, exactly (1:1)
```
- **ozml** = document format. `5.14` first shipped with FCP 10.8 / Motion 5.8 (Jun 20 2024) and is UNCHANGED through FCP 12.2. So ozml 5.14 = openable by FCP 10.8+ at the format level.
- **displayversion** = the exact Motion version that wrote the file ("displayversion is exactly the same as the Motion version number"). `6.2` = Motion 6.2.
- FCP checks BOTH; a host older than the displayversion's generation throws the red alert-badge. That's why backdating tools rewrite both numbers.

### Motion <-> FCP ship in LOCKSTEP (same dates). Key rows (Apple release notes):
- Motion 6.2 = **FCP 12.2** = Apr 9 2026 (CURRENT latest)
- Motion 6.0 = FCP 12.0 = Jan 28 2026
- Motion 5.11 = FCP 11.2 = Sep 19 2025
- Motion 5.10 = FCP 11.1 = Mar 27 2025
- Motion 5.9 = FCP 11.0 = Nov 13 2024  (displayversion 5.9, ozml 5.14)
- Motion 5.8 = FCP 10.8 = Jun 20 2024  (displayversion 5.8, ozml 5.14 <- first ozml 5.14)
- Full table + backdater tool: https://fcpxtemplates.com/fcpx-motion-compatibility/
- Apple sources: Motion release notes support.apple.com/en-us/102746 ; FCP release notes support.apple.com/en-us/102825

### Our shipped template = `displayversion 6.2` / `ozml 5.14` -> requires FCP 12.2 (latest)
- **This is a FALSE lockout.** Feature audit of `_Placeholder.moti` shows nothing newer than mid-2023: 3D Object/USDZ (Motion 5.4.6 / FCP 10.4.9, Aug 2020), Camera+Depth of Field, Rig/Widget, Fade, Drop Zone, HDR-aware color / ColorSpaceID (Motion 5.6.4 / FCP 10.6.6, May 2023). NO 6.x features (no Magnetic Mask, Apple Intelligence, Image Playground, spatial). The 6.2 stamp is only because Mark authored it in the latest Motion.
- **True feature floor: ~FCP 10.6.6 (2023).** Likely root cause of the 2.1 video request: the reviewer's MacBook Air runs an FCP older than 12.2, so the title loads as a red badge -> "unable to access part of the app."

### Backdating plan (HOLDING until Mark confirms an older FCP to test against)
- **Recommended (safe): set `<displayversion>5.8</displayversion>`, KEEP `<ozml version="5.14">`** -> opens in FCP 10.8+ (Jun 2024 onward, ~2yr of installs). ozml unchanged = zero format risk.
- Max reach (FCP 10.6.6) would also need `ozml` -> `5.13`; more risk, little gain. Don't bother.
- **Clean to apply:** the app's runtime patcher (`TemplateBuilder.patch`) only rewrites the USDZ scenenode name, `relativeURL`, and animation timing — it NEVER touches lines 3 & 5. So edit `_Placeholder.moti` once and every generated title inherits the lower stamp.
- **Hard requirement before shipping:** TEST a generated title in a real non-12.2 FCP (e.g. 11.x) and confirm it appears in the Titles browser with NO red alert-badge. Feature analysis is necessary but not sufficient — only an older-FCP load is proof.
- It's a binary change -> new build -> new review cycle. Does NOT unblock the current review faster than the demo video. It's the ROOT-CAUSE fix (helps the reviewer's older FCP + all customers not on 12.2). Candidate for next build, or this one if fixing the cause is preferred over sending a video.
