# 3D to FCP — TestFlight Metadata

_What to paste into App Store Connect → TestFlight tab when prepping the first build._

---

## App Store Connect → TestFlight → Test Information

These are the fields TestFlight requires before testers can install. Internal testers only see some of these; external testers see all.

### Beta App Description (4000 chars max)

```
3D to FCP turns USDZ 3D model files into draggable titles inside Final Cut Pro.

Drag one or more USDZ files onto the app, and they appear instantly in FCP's Titles Browser — fully styled, draggable onto any project timeline. No Motion required. No template wrangling. No manual file copying.

This is a beta build. We'd love feedback on:
- Drag-and-drop reliability with USDZ files from different sources (Reality Composer, Object Capture, Sketchfab, Adobe Substance, etc.)
- Performance with large batches of files
- Whether the resulting titles render correctly in your FCP timeline
- Any rough edges in the UI, accessibility, or messaging

If something breaks, please send a screenshot via the TestFlight feedback button — it auto-captures the app state.

Thanks for testing!
```

### What to Test (4000 chars max — shown to testers, internal + external)

```
PRIMARY FLOWS

1. Drag one USDZ file onto the app window. Click Create. Open Final Cut Pro and verify the title appears in the Titles Browser under "3D to FCP" (or the category name you chose).

2. Drag multiple USDZ files at once. Watch the queue process them. Verify all created titles appear in FCP.

3. Try Create on a file that already exists in the category. The conflict sheet should let you Overwrite, Skip, or Rename. Try each option.

4. Edit the "Titles Browser Category" field on the file-list screen. Verify the category folder in FCP matches what you typed.

5. Open the Help menu → "3D to FCP Help". Verify the help window opens with readable content.

EDGE CASES TO TRY

- A USDZ file with special characters in the filename (spaces, ampersands, quotes, dollar signs, etc.) — the resulting title should still load correctly in FCP.
- A very small or large USDZ.
- Closing FCP and reopening it — your new titles should still be in the Titles Browser.
- Using the app with FCP already open vs. starting from scratch.

WHAT WE DO NOT NEED YOU TO TEST

- Internet features (the app makes no network calls).
- Payment / sign-in (none — app is free, no account).
- Other Apple platforms (this is a Mac-only app).
```

### Feedback Email

```
markspencer@mac.com
```

### Marketing URL (optional)

```
https://rippletraining.com
```

### Privacy Policy URL (required for external testers)

```
https://markspen.github.io/3d-to-fcp/privacy.html
```

> Hosted via GitHub Pages on `markspen/3d-to-fcp` (public repo, `/docs` folder on `main`).

---

## Beta App Review Notes (only needed when promoting first build to external testers)

These notes go to the App Review team, not to testers. The goal is to make their job fast.

```
3D to FCP is a Mac-only utility that converts USDZ 3D model files into Motion template bundles for Final Cut Pro.

HOW TO TEST

1. Launch the app. You'll see a drop zone reading "Add 3D objects in the USDZ format".
2. Drag a USDZ file onto the window. Apple's sample USDZ files are available at: https://developer.apple.com/augmented-reality/quick-look/ (e.g. "Toy Biplane" or "Robot").
3. The app validates the USDZ and adds it to the queue.
4. Optionally edit the "Titles Browser Category" field (defaults to "3D to FCP").
5. Click "Create". On first run, the app requests access to ~/Movies/Motion Templates/ via NSOpenPanel — grant access.
6. The app writes a Motion template bundle (.localized folder containing a .moti XML and the user's USDZ in a Media/ subfolder).
7. To verify the result, open Final Cut Pro and check the Titles Browser. A new category will contain the converted title.

SCOPE AND SAFETY

- No network requests. No analytics. No telemetry.
- No login. No account. No in-app purchases.
- Sandbox-compliant: file access via NSOpenPanel + security-scoped bookmark only.
- Privacy manifest declares "data not collected" across all categories (PrivacyInfo.xcprivacy).
- The Help menu includes a "Visit Ripple Training" link that opens rippletraining.com in the user's default browser — a marketing/educational reference, not a content channel.

TEST ACCOUNT

Not required — no login.

EXPECTED USER EXPERIENCE

Drag in, click Create, find your titles in FCP. Total time: under 30 seconds for a single file. Batch processing handles many files in series.
```

---

## Tester Group Plan

Suggested groups to create in App Store Connect → TestFlight:

1. **Internal — Mark + Ripple core** (instant builds, no review). Add yourself first; smoke test before inviting anyone else.
2. **Ripple Training partners / collaborators** (small external group, 5-20 people). First build needs beta review; subsequent builds usually skip full review.
3. **Public beta — FCP editors** (open external group with a public link, capped at e.g. 200 if you want manageable feedback volume). Use after you've validated with group #2.

Public link option lets you hand a single URL to FCP communities (forums, Twitter/X, Discord) without inviting people individually.

---

## Build Cadence

- TestFlight builds expire **90 days** from upload (per Apple's current docs).
- Plan to upload a fresh build every 60–75 days during extended beta, so testers don't get stranded with an expiring build.
- Each new build to an existing external group typically does NOT need a full review again (only the first one does), so the cadence is cheap.

---

## Quick Pre-Submit Checklist

Before clicking Distribute → Upload in Xcode:

- [ ] App icon present (`AppIcon.xcassets` wired in)
- [ ] Bundle ID `com.markspencer.ThreeDtoFCP` registered in Apple Developer portal
- [ ] App Store Connect record created with that bundle ID
- [ ] Privacy policy URL is live (host `tasks/privacy-policy.html` somewhere)
- [ ] Privacy answers in App Store Connect set to "Data Not Collected" across all categories
- [ ] Export compliance answered: "No, doesn't use encryption" (uses only system frameworks)
- [ ] Archive built in Release config, signed with Apple Distribution cert (team `56S86LMNZ6`)
- [ ] `_Placeholder.moti` is the final version (with Inspector params published, if that's done by then)
- [ ] Smoke-tested locally end-to-end (drop USDZ → create → open in FCP → drag title onto timeline)

---

## Open Questions

- [x] Confirm feedback email — `markspencer@mac.com`
- [x] Confirm privacy policy URL — `https://markspen.github.io/3d-to-fcp/privacy.html` (GitHub Pages)
- [ ] Decide group structure (internal-only first, then expand?)
- [ ] Decide build cadence — weekly during active beta, or only when something material changes?
