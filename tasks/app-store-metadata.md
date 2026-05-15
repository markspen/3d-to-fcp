# 3D to FCP — App Store Metadata Draft

_First draft for Mark to review and edit. Counts shown reflect App Store Connect limits._

---

## App Name (30 characters max)

**3D to FCP**
_(9 chars — well under limit)_

---

## Subtitle (30 characters max)

Three drafts — pick one or remix:

1. **Drag USDZ. Get FCP Titles.** _(26 chars)_
2. **Turn 3D Models into Titles** _(27 chars)_
3. **USDZ to Final Cut Pro Titles** _(28 chars)_

> Recommendation: #1. It mirrors the app's actual experience and uses verbs.

---

## Promotional Text (170 characters max — editable any time, no review needed)

Drop USDZ files. Get drag-and-drop 3D titles inside Final Cut Pro — no Motion required. Batch processing, conflict handling, ready to use in seconds.

_(168 chars)_

---

## Description (4000 characters max)

```
Turn any USDZ 3D model into a Final Cut Pro title in seconds.

3D to FCP is the fastest way to bring 3D objects into your edits. Drag one or more USDZ files onto the app, and they appear instantly in Final Cut Pro's Titles Browser — fully styled, draggable into any project. No Motion required. No template wrangling. No manual file copying.

KEY FEATURES

• Drag-and-drop: Drop one USDZ or a hundred. Batch processing is built in.
• One-click conversion: Each model becomes a proper Motion-compatible title bundle, ready to drag onto your timeline.
• Smart conflict handling: Overwrite, skip, or rename in one tap when a title with that name already exists.
• Custom category: Choose where titles appear in the Titles Browser. Default category is "3D to FCP", but you can change it.
• Sandboxed and secure: Full Mac App Store compliance. Your files stay on your Mac.
• Thumbnail previews: Each title gets an auto-generated preview, so you know what's inside before dragging it in.

HOW IT WORKS

1. Drag your USDZ files onto 3D to FCP (or click Add Files).
2. Choose a category name (or use the default).
3. Click Create.
4. Open Final Cut Pro. Your titles are waiting in the Titles Browser.

That's it. No Motion installation needed. No XML editing. No template hunting.

WHO IT'S FOR

• Final Cut Pro editors working with 3D assets from Reality Composer, Object Capture, Sketchfab, Adobe Substance, or any other USDZ source.
• Motion graphics designers who want to ship 3D-enhanced titles fast.
• Educators and tutorial creators who need a repeatable pipeline for 3D content.
• Anyone tired of manually copying USDZ files into Motion Templates folders.

REQUIREMENTS

• macOS 14 (Sonoma) or later
• Final Cut Pro (any recent version) — or Final Cut Pro Creator Studio

Created by Mark Spencer, in partnership with Ripple Training — your source for world-class Final Cut Pro and Motion tutorials.
```

_(~1,800 chars — well under 4,000)_

---

## Keywords (100 characters max, comma-separated, no spaces around commas)

**Primary set (try this first):**
```
USDZ,3D,Final Cut Pro,FCP,Motion,titles,template,convert,import,Reality Composer,Object Capture
```
_(99 chars)_

**Alternative set if keyword tool says one of those is weak:**
```
USDZ,3D model,FCP title,Final Cut,Motion template,import,convert,Reality Composer,sketchfab,Apple
```

> Strategy notes:
> - Don't repeat words from the app name/subtitle — Apple already indexes those.
> - "Reality Composer" and "Object Capture" target Apple's first-party 3D tools users.
> - "Motion template" catches users searching for FCP-adjacent tooling.

---

## What's New (For first release: 4000 characters, but keep short)

```
Initial release. Drop USDZ files. Get Final Cut Pro titles. That's the whole app.
```

---

## Support URL (required)

**DECIDED:** `https://github.com/markspen/3d-to-fcp/issues`

Users file bugs and feature requests directly on the public repo's Issues page.

---

## Marketing URL (optional)

Same options as above. Could be the same URL or a marketing landing page.

---

## Privacy Policy URL (required for any app — even ones that collect nothing)

**Must be set before submission.** Apple requires this even if the app collects zero data (which 3D to FCP does — confirmed in `PrivacyInfo.xcprivacy`).

**Recommendation:** Create a simple one-page privacy policy hosted at `rippletraining.com/3dtofcp-privacy` or similar saying:

> "3D to FCP does not collect, store, transmit, or share any personal information. The app reads USDZ files you select and writes Motion template bundles to your local Motion Templates folder. Nothing leaves your Mac."

---

## Category

- **Primary:** Graphics & Design
- **Secondary:** Video

---

## Age Rating

4+ (no objectionable content)

---

## App Privacy "Data Not Collected" Declaration

In App Store Connect, declare all categories as **"Data Not Collected"**:
- Contact Info: not collected
- Health & Fitness: not collected
- Financial Info: not collected
- Location: not collected
- Sensitive Info: not collected
- Contacts: not collected
- User Content: not collected
- Browsing History: not collected
- Search History: not collected
- Identifiers: not collected
- Purchases: not collected
- Usage Data: not collected
- Diagnostics: not collected
- Other Data: not collected

_(This matches the `PrivacyInfo.xcprivacy` manifest already in the project.)_

---

## Screenshots Plan (separate task, but noted here)

Apple requires at least 1, recommends 3+, max 10. Minimum size: 1280×800 (16:10) or 2560×1600 for Retina-quality.

**Recommended 5 shots:**
1. Drop zone (empty state) — "Drag USDZ files here"
2. File list with 3-4 USDZ files queued + the Titles Browser Category field
3. Conflict resolution sheet (overwrite/skip/rename)
4. Success screen with "3 titles created" + Ripple footer
5. FCP Titles Browser showing the resulting titles _(taken in Final Cut Pro itself)_

> Screenshot #5 is the most powerful — it proves the output. Take in a clean FCP project with the dock hidden.

---

## Review Notes (info for Apple's reviewer, internal)

```
3D to FCP is a utility app that converts USDZ 3D model files into Motion template bundles for use in Final Cut Pro.

To test:
1. Launch the app. You'll see a drop zone.
2. Drag any USDZ file onto the window (sample USDZ files available at developer.apple.com/augmented-reality/quick-look/ — e.g. "Toy Biplane" or "Robot").
3. Click Create. The app will prompt for access to ~/Movies/Motion Templates/ (security-scoped bookmark).
4. Grant access. The template is created.
5. Open Final Cut Pro and check the Titles Browser. A new category "3D to FCP" will appear with your converted USDZ as a title.

The app does not collect any user data, does not connect to the internet (except for the Ripple Training learn-more link, which opens the user's default browser), and operates entirely on local files within the Mac App Store sandbox.

Test account: not required (no login).
```

---

## Open Questions for Mark

- [x] Support URL — `https://github.com/markspen/3d-to-fcp/issues`
- [x] Privacy policy URL — hosted: `https://markspen.github.io/3d-to-fcp/privacy.html`
- [ ] Subtitle preference (#1, #2, #3, or different)?
- [ ] Pricing: confirmed free?
- [ ] Anything to change in the description copy?
- [ ] Should we mention Ripple Training in the description, or keep that to the in-app footer only? _(Currently included — easy to remove)_
