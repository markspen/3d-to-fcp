## These are the requirements for the library-safe duplicate media app

Working name: **[to be decided]**. Status: **draft for review, 2026-11-05. Nothing is built yet.**

Source material: the ThunderBay cleanup (vault note "2026-10-22 Session Handover 3" and its 2026-10-23 correction), the "Library-safe storage cleanup" entry in the vault note "AI Business Ideas", the Ripple Short outline, and the working scripts in `~/Desktop/Claude/Projects/fcp-dupe-cleanup/`.

## Decisions so far

| Date | Decision | Why |
|---|---|---|
| 2026-11-05 | Sold under Mark's own name, like 3D to Timelines | Mark's choice |
| 2026-11-05 | Version 1 finds duplicate original media only, with library-aware safety. Render, proxy, optimized, and cache cleanup is out of scope | Arctic and FCP Cleaner already do that; finding duplicate originals safely is what nobody does |
| 2026-11-05 | One-time purchase on the Mac App Store | Mark's choice. Price still open |
| 2026-10-29 (thread `thr_2uai39mv63`) | **The app does all the work itself.** The editor never opens libraries in Final Cut Pro to consolidate or relink; the editor only quits Final Cut while the app runs | Mark's requirement |
| 2026-11-05 (approved by Mark) | Version 1 removes loose copies *and* collapses same-drive duplicates in place (hard link on HFS+, clone on APFS), if scratch-library test 1 passes. Cross-drive relinking and moving media in or out of libraries come later, gated on tests 2 and 3 | Same-drive collapse changes no path a library knows; the cross-drive moves depend on undocumented Final Cut behavior |

## Purpose

Video editors run out of space on their media drives, and a large share of that space is copies of the same camera files: one in a "From drives" folder, one on an old backup, one in a project folder, and one inside each Final Cut Pro library that imported it.

Today's tools miss this:

- **DaisyDisk and similar apps** show which folders are big, but not which files are copies.
- **Arctic and FCP Cleaner** remove render, proxy, and optimized files. They don't touch original media.
- **General duplicate finders** find identical files, but they don't know how Final Cut libraries use media. Deleting the wrong copy takes clips offline.

- **Hyperspace** (Mac App Store) reclaims space by turning identical files into APFS clones, but it only works on APFS. Many editing RAIDs are spinning disks formatted HFS+ (Mac OS Extended), including Mark's ThunderBay, and Hyperspace can't help them.

This app finds byte-identical copies of media across a user's drives and works out which copies Final Cut libraries depend on. It removes the copies nothing uses, and it collapses the copies libraries do use into one stored file without changing any path a library knows, on HFS+ and APFS alike. Nothing is deleted until the user has tested their projects, and the editor never has to open a library to relink or consolidate.

Proof it's worth doing: on Mark's 18 TB ThunderBay RAID it found 1,017 groups of identical files and freed 477 GB with no library breaking. Free space went from 161.7 GB to 815 GB over the whole cleanup.

## Customer experience

1. The customer launches the app. The window says "Choose the drives to scan" and has a button to add drives (one or more). The app remembers the drives next time.
2. Before scanning, the app checks whether Final Cut Pro is open and asks the customer to quit it. It shows how many Final Cut libraries it found on the chosen drives.
3. The customer clicks **Scan**. A progress view shows what's happening ("Finding candidates," "Checking files are identical," "Reading your libraries") with a time estimate. The customer can pause and resume, or quit and resume later.
4. The results screen leads with one number: **"You can safely free 477 GB."** Below it, every duplicate falls into one of three plain-language groups:
   - **Safe to remove:** extra copies that no library uses. Another identical copy stays.
   - **Can be shared in place:** copies a library links to or stores inside itself. The app keeps every one of these files at its own path, but makes them share one stored copy on the drive (a hard link on HFS+, a clone on APFS). Libraries see no change.
   - **Can't be combined:** copies on different drives, inside other apps' packages (Photos, Lightroom, Logic), or flagged as files that apps edit in place. Kept, with an explanation.
5. The customer can open any group to see every copy, which one is being kept, and why. They can choose a different copy to keep, as long as the safety rules below allow it.
6. The customer clicks **Free space**. With Final Cut Pro quit, the app moves the safe-to-remove copies into one holding folder on the same drive (seconds, even for hundreds of gigabytes) and shares the in-place copies. Nothing is deleted.
7. The app immediately re-checks every library on the scanned drives and confirms that none of them link to a moved file. It then suggests a test period: "Open your projects over the next week. If anything is missing, restore it here."
8. Later, the customer comes back and chooses **Restore** (everything, one folder, or one file) or **Delete for good**. Delete for good asks for confirmation and shows the space it will free.

## What the app needs to do

### 1. Get access to the drives
- Use the standard Open panel so the customer picks each drive or folder. Apple's sandbox rules give the app access to everything inside it: "When the URL your app receives from a standard user interface interaction represents a folder, the operating system extends your app's sandbox to items within that folder, and recursively in nested folders" ([Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox), checked 2026-11-05).
- Save a security-scoped bookmark for each drive so access survives quitting and relaunching (same page).
- Entitlements: user-selected read-write file access and app-scoped bookmarks. No full-disk access is needed.
- If a library links to media on a drive the customer didn't pick, say so and offer to add that drive.

### 2. Build the inventory
- Walk each drive and record every regular file above a size floor (default 250 MB, adjustable). Skip the system folders at the top of a drive (`.Trashes`, `.Spotlight-V100`, `.fseventsd`, `.DocumentRevisions-V100`, `.TemporaryItems`).
- For each file, record its path, size, modification date, device and inode number, and link count.
- Never treat a symlink as a candidate; symlinks are pointers.

### 3. Know what's inside packages
- Detect packages (Finder shows them as one file). For Final Cut libraries (`.fcpbundle`), record that a file is inside a library and which one.
- Ignore generated folders inside libraries (Render Files, Transcoded Media, Analysis Files). That cleanup is out of scope.
- Files inside other app packages (`.photoslibrary`, `.migratedphotolibrary`, Lightroom catalogs, Logic `.logicx`, GarageBand `.band`) are never candidates for removal.

### 4. Read what every library links to
- For every `.fcpbundle` on the scanned drives, find each symlink inside it and resolve its target.
- Every target is **in use** and is never moved.
- Record targets on drives that weren't scanned, and warn about them (see section 1).

### 5. Find identical files quickly
- Group by exact size first. Unlike the prototype script, don't require matching names, because renamed copies are common.
- For groups with two or more files, compare a fast sample (for example, the first and last few megabytes) to discard most non-matches.
- For files that survive, compute a full checksum with CryptoKit (SHA-256 is built into macOS). Only files with matching checksums are duplicates.
- Cache checksums keyed by device, inode, size, and modification date, so a rescan only reads new or changed files.
- The prototype took about 72 minutes to hash 2,586 candidates on Mark's RAID. The app must show progress, pause and resume, and survive being quit.

### 6. Count the real space
- **Hard links:** two paths with the same device and inode are one file. Final Cut creates hard links itself. Count space as freed only when every name for that inode is removed. On Mark's RAID, this turned 590 GB of listed copies into 477 GB actually freed, and duplicates within a single library into 0 GB.
- **APFS clones:** on APFS drives, Finder copies can share storage, so deleting one frees little or nothing. The macOS SDK on Mark's Mac (`sys/attr.h`, `sys/stat.h`) provides `getattrlist` attributes for this: `EF_SHARES_ALL_BLOCKS` ("file shares all of its blocks with another file"), `EF_MAY_SHARE_BLOCKS`, `ATTR_CMNEXT_PRIVATESIZE` (bytes not shared with any other file), and, on volumes reporting `VOL_CAP_FMT_CLONE_MAPPING`, `ATTR_CMNEXT_CLONEID` and `ATTR_CMNEXT_CLONE_REFCNT`. Use these to report space freed accurately. **Must be tested on a real APFS drive** before the space numbers are trusted.
- When the app can't be sure, it says "up to" and explains why.

### 7. Classify every copy and choose what to keep
Each copy in a group of identical files is one of:
- **Inside a Final Cut library**
- **Linked to by a library** (outside every library, and the target of a library symlink)
- **Inside another app's package**
- **Loose** (none of the above)

Keep rules, in order:
1. Never move a copy inside a library, a copy a library links to, or a copy inside another package.
2. In every group, at least one copy must remain. If a group has no protected copy, keep one loose copy.
3. When choosing which loose copy to keep, prefer one a library links to, then folders the customer marks as preferred, then the shortest path. Copies in folders the customer marks as "dumps" (like "From drives" or "Restored from backup") are removed first.
4. Keep a loose copy even when an in-library copy exists, if the customer turns on "Keep one shareable copy." (A loose copy is the only kind several libraries can share; an in-library copy can never be shared.)

### 8. Stage instead of delete
- Move each removable copy into a holding folder at the top of the same drive (for example, `<Drive>/<App> Holding/2026-11-05/<original path>`). A move within one drive is instant and changes nothing but the file's folder.
- Never move across drives. If a same-drive move isn't possible, skip the file and say why.
- Right before each move, confirm that the kept copy still exists with the same size and modification date. (On the ThunderBay, Arctic ran between the scan and the move.)
- Write a manifest inside the holding folder (original path, kept copy, bytes) as well as in the app, so the holding folder makes sense on its own.

### 8b. Share copies in place (same drive only)
For copies a library links to or stores inside itself, the app keeps every path and replaces each extra copy's data with the keeper's:
- **HFS+:** replace the extra copy with a hard link to the keeper. One file on disk, several names. Final Cut already creates hard links itself when it copies same-drive media into a library, so libraries handle them.
- **APFS:** replace the extra copy with a clone of the keeper (`clonefile`). The names share storage until one is changed; then only the changed blocks are copied.
- Only when Final Cut Pro is quit, only within one drive, and only after re-confirming that both files are byte-identical immediately before the swap.
- **Hard-link risk:** if an app later edits one name in place, every name sees the change. Final Cut doesn't write to original media, so camera originals are low risk. **[ ]** Verify that. Files that other apps edit in place (for example, music files that a tagging app writes metadata into) go in the "Can't be combined" group, or use a clone where available.
- **Undo:** record every swap in the manifest. Undoing a hard link means making an independent copy again, which needs the free space back, so the app shows that cost before undo.
- **Backups:** Time Machine and Carbon Copy Cloner preserve hard links; other backup tools may copy each name as a full file. Clones are copied as full files by most backups. Say this in the app.
- **[ ]** Gated on scratch-library test 1 (see the test plan). **[ ]** Verify that a sandboxed app can create hard links and clones inside a user-selected folder (sandbox spike).

### 8c. Later versions: copies on different drives, and moving media in or out of libraries
Hard links and clones can't span drives. Two file-level operations could still do this without Final Cut:
- **Relink without Final Cut:** point the symlink in the library's `Original Media` folder at the keeper on the other drive, then remove the duplicate.
- **Consolidate out or in without Final Cut:** move an internal file to a chosen folder and leave a symlink in its place (this is how Final Cut stores external media), or reverse it.
Both depend on Final Cut following the symlink and nothing else. The library database might also store a file ID or bookmark per clip. This is undocumented and could change with any Final Cut release, so these features ship only if scratch-library tests 2 and 3 pass. **Never write to a library's database file** (`CurrentVersion.fcpevent`); if the tests fail, the fallback is FCPXML export and import.
An archiving feature follows from this: move finished libraries' media to a cold drive while keeping media shared.

### 9. Check, restore, and delete
- After staging, re-resolve every library symlink on the scanned drives and confirm none point into the holding folder or to a missing file.
- Restore everything, one folder, or one file, back to its original path.
- Delete for good: move the holding folder to the Trash, or delete it permanently after a second confirmation. Show the space it frees, using the counting rules in section 6.

### 10. Never
- Never delete anything without the customer clicking Delete for good.
- Never touch anything inside a package.
- Never touch files outside the drives the customer picked.
- Never suggest relinking a library's clip to a copy inside another library. Final Cut can't do that.
- Never ask the editor to open Final Cut to relink or consolidate. The app does the work; the editor only quits Final Cut while it runs.
- Never edit a Final Cut library's database.

## Safety rules, from how Final Cut works (Mark, 2026-10-23)

These rules are the core of the product. A general duplicate finder doesn't know them.

1. An asset inside a library belongs to that library. No other library uses it, and it can't be relinked to a copy inside a different library.
2. A library can link only to a file outside every library, through a symlink in the library's Original Media folder.
3. Several libraries can link to the same outside file. Removing it takes the clip offline in all of them.
4. Final Cut uses hard links in some cases, so apparent duplicates often take no extra space.
5. So a copy is safe to remove only if it's outside every library and every package, no library links to it, and another identical copy remains.

**[ ]** Check the import-option details (Copy to library, Leave files in place, external storage location) against Apple's Final Cut Pro User Guide before writing help text.

## Design considerations
- It must be dead simple to use. The customer should understand the three groups without knowing what a symlink or inode is.
- It must look sleek, modern, and native (SwiftUI), and support Dark Mode and VoiceOver.
- Every destructive step must say exactly what will happen and how to undo it.
- Plain-language explanations on demand ("Why is this copy kept?").

## What it can't see (state this in the app and the App Store description)
- DaVinci Resolve, Premiere Pro, and Motion projects that point to files by path.
- Final Cut libraries on drives the customer didn't pick.
- The holding folder and the test period exist to cover these.

## Competitors (checked 2026-11-05)

| App | What it does | Duplicate originals? | Library-aware? |
|---|---|---|---|
| Arctic (Hedge) | Library management; removes generated files | No | Yes, for generated files |
| FCP Cleaner (ankermann.tv) | Removes render, proxy, optimized, analysis, and cache files. One-time purchase, license key. Its site says original media "is never removed automatically" | No | Yes, for generated files |
| Hyperspace (John Siracusa, Mac App Store, Feb 2025) | Replaces identical files with APFS clones; $9.99 or $49.99 ([FAQ](https://hypercritical.co/hyperspace/)) | Yes, by cloning | No. **APFS only**, so it can't help HFS+ editing RAIDs |
| Gemini 2 (MacPaw, Mac App Store) | Duplicate finder; scans external drives and deletes duplicates ([listing](https://apps.apple.com/us/app/gemini-2-the-duplicate-finder/id1090488118)) | Yes | No |
| DaisyDisk and similar | Shows what's using space | No | No |
| General duplicate finders | Find identical files | Yes | No |
| FCP's Delete Generated Library Files | Built in | No | n/a |

**[ ]** Do a fuller check of the Mac App Store and the general duplicate finders before the price is set.

## App Store considerations
- Guideline 2.4.5 ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), checked 2026-10-29) is the Mac App Store section. The parts that shape this app: Mac apps "must be appropriately sandboxed"; they "may not request escalation to root privileges"; they may not "spawn processes that continue to run without consent after a user has quit the app"; and they "may not present a license screen at launch, require license keys, or implement their own copy protection" (one-time purchase through the store fits).
- Precedent: Gemini 2 and Hyperspace are both on the Mac App Store, and both change or delete duplicate files. This app does less: it stages, and the user decides when to delete.
- Sandboxed, with user-selected read-write access and bookmarks. No other entitlements expected. **[ ]** Check the first-time "access files on a removable volume" prompt with a test build.
- **Restore is built into the app** (a Restore button reading the manifest). The prototype's separate `restore.py` doesn't fit a sandboxed app.
- **Give the reviewer a way to test it.** App Review won't have a RAID full of Final Cut libraries. Include a small sample setup (a test library, a linked file, a loose copy) or step-by-step review notes.
- **Keep claims modest:** "Finds byte-identical copies and shows which ones your libraries use," not "frees terabytes."
- Privacy manifest: no data collected, nothing leaves the Mac.
- Apply the submission traps from Ripple Tips (memory `reference_app_store_submission_traps.md`): RGB screenshots, OCR screenshots for anything private (client and project names on drive paths count), and a new build number for every upload.

## Test plan

### First: sandbox spike and scratch-library tests (before the engine)
A minimal sandboxed test app that picks a volume, lists the symlinks inside a `.fcpbundle`, moves one file into a staging folder, and creates one hard link and one clone. That confirms the sandbox behaviors the app depends on in an afternoon.

Then three tests in scratch libraries only, never a real one:
1. **Hard-link swap:** import one clip into two test libraries with "Copy to library." Quit Final Cut, hard-link one library's copy to the other's, then open both. Passing this unlocks section 8b.
2. **Symlink retarget:** import a clip with "Leave files in place," quit Final Cut, copy the clip to another drive, point the library's symlink at the copy, remove the original, then open the library.
3. **Internal to symlink:** in a copied-media library, move the clip out and leave a symlink behind, then open the library. Afterward, check File > Consolidate Library Files to see whether Final Cut now treats the clip as external.
Tests 2 and 3 unlock section 8c.

### Then: the engine
Build two small test drives as disk images, one HFS+ and one APFS, with a known case for each rule:
- Identical loose copies in two folders, including one renamed copy
- Two files with the same name and size but different content
- A hard-linked pair
- An APFS clone pair (APFS image only)
- A library with copied-in media
- A library with "Leave files in place" media (symlinks)
- Two libraries linking to the same outside file
- A Photos library containing a file identical to a loose one
- A "backup" folder holding a library found nowhere else
- A library linking to a file on a second, unscanned image
- A kept copy that's changed or deleted between the scan and the move

Pass criteria:
- After staging, no library on the test drives shows offline media, checked by opening each one in Final Cut Pro.
- The predicted space freed matches the measured change in free space after Delete for good, on both drives.
- Restore puts every file back at its original path.

Then a read-only scan of the ThunderBay, compared with the October results in `dupes.csv`.

## Phases
1. **Research (done 2026-11-05):** sandbox access, APFS clone attributes, competitors, App Review guideline 2.4.5.
1b. **Market check and spike:** ask the Ripple audience one question ("Is your media RAID formatted HFS+ or APFS, and how full is it?") to size the HFS+ market Hyperspace can't serve; build the sandbox spike; run the three scratch-library tests.
2. **Engine prototype:** a command-line Swift version of sections 2 to 9, run against the test drives, then read-only against the ThunderBay.
3. **App:** the SwiftUI interface around the tested engine.
4. **TestFlight:** a few editors from the Ripple audience, on their own drives.
5. **App Store submission.**
6. **Launch:** the Ripple Short, recorded so it can double as the App Store preview.

## Open questions
- Name
- Price (good topic for `/strategist`)
- Minimum macOS version
- Network drives (SMB, NAS): inode and hard-link information may be unreliable there. Exclude from version 1, or allow with a warning?
- Default size floor (250 MB worked on the ThunderBay; editors with many small clips may want lower)
- Should the app also replace loose duplicates with hard links/clones instead of staging them, so nothing is ever deleted? (Simpler mental model; but staging frees space on any drive and is easier to undo.)
- Version 2 ideas: cross-drive relinking and moving media in or out of libraries (section 8c, if tests pass), archiving finished libraries to a cold drive, and finding media no project uses (read-only, from FCPXML rather than the database)
- Marketing: publish the Ripple Short's reference section as a long-form page on rippletraining.com with a waitlist signup, to test demand before building
