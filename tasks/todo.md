# 3D to FCP — Task List

## Phase 0: Pre-Build Verification
- [ ] **Confirm bundle ID** — get Developer account name (Day Street Productions vs personal)
- [ ] **Inspect real .moti bundle on disk** — find an installed Motion template in ~/Movies/Motion Templates/ or /Library/Application Support/Final Cut Pro/Templates and confirm internal structure (package layout, XML filename, Media/ folder)
- [ ] **Verify category naming** — confirm FCP reads category name from folder name on disk

## Phase 1: Xcode Project Scaffold
- [ ] Create new Xcode project (SwiftUI App, macOS 14+, bundle ID TBD — awaiting Developer account)
- [x] Configure sandbox entitlements → `ThreeDtoFCP.entitlements`
- [x] Security-scoped bookmark for ~/Movies/Motion Templates/ — `MotionTemplatesManager.swift`
- [ ] Embed _Placeholder.moti in app bundle (done when project created)

## Phase 2: Core Engine ✅
- [x] `TemplateBuilder.swift` — regex-patches XML (scenenode name + relativeURL), copies USDZ, handles overwrite/skip/rename
- [x] Output structure: flat `[name].moti` + `Media/[name].usdz` alongside it (confirmed from real templates)
- [x] Conflict detection + resolution (overwrite / skip / rename with auto-numbering)
- [x] `USDZValidator.swift` — extension check, size check, ZIP magic byte check
- [ ] Unit tests for TemplateBuilder

## Phase 3: UI — Main Window ✅
- [x] `DropZoneView.swift` — dashed drop target, shake on bad drop, "Add Files" button
- [x] `FileListView.swift` — per-file status badges, remove button, Create button
- [x] `AppViewModel.swift` — state machine (dropping → reviewing → conflict → processing → success)

## Phase 4: UI — Conflict Sheet ✅
- [x] `ConflictSheet.swift` — overwrite/skip/rename picker, per-file overrides, apply-to-all toggle

## Phase 5: UI — Success Screen ✅
- [x] `SuccessView.swift` — count, Reveal in Finder, Open FCP, Add More

## Phase 6: Preferences ✅
- [x] `PreferencesView.swift` — category name, UserDefaults

## Phase 7: App Entry Point ✅
- [x] `ThreeDtoFCPApp.swift` — @main, WindowGroup, Settings scene
- [x] `ContentView.swift` — state-driven view switcher with animation

## Phase 7: Polish & App Store Prep
- [ ] App icon (all required sizes)
- [ ] First-launch experience / onboarding tooltip
- [ ] Accessibility: VoiceOver labels on all interactive elements
- [ ] Privacy manifest (no data collection)
- [ ] App Store screenshots (at least 3, macOS sizes)
- [ ] App Store metadata: description, keywords, support URL
- [ ] Review entitlements for MAS submission
- [ ] Archive + validate in Xcode Organizer
- [ ] Submit for review

## Lessons Learned
_Updated as we go_
