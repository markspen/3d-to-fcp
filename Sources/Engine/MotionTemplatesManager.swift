import Foundation
import AppKit

/// Resolves and persists access to ~/Movies/Motion Templates.localized/Titles.localized/
/// using a security-scoped bookmark (required for MAS sandbox).
final class MotionTemplatesManager {
    static let shared = MotionTemplatesManager()

    private let bookmarkKey = "motionTemplatesTitlesBookmark"

    // The security-scoped folder the user granted (their Movies folder, normally).
    // resolvedBookmark() acquires the scoped resource; acquire once, hold for the
    // app's lifetime, release in deinit (belt-and-suspenders — the OS releases on exit).
    private var scopedRoot: URL?

    // The FCP titles folder to write into, derived from the user-granted folder:
    // ~/Movies/Motion Templates.localized/Titles.localized. Returns nil until the
    // user grants access — the app is sandboxed with only user-selected access, so
    // there is no silent default path (nil means "prompt with requestAccess()").
    // The .localized intermediates are created on demand by TemplateBuilder; FCP
    // only recognizes the ".localized" folder names.
    var titlesFolder: URL? {
        if scopedRoot == nil {
            scopedRoot = resolvedBookmark()
        }
        guard let root = scopedRoot else { return nil }
        return titlesSubfolder(of: root)
    }

    deinit {
        scopedRoot?.stopAccessingSecurityScopedResource()
    }

    /// Call at first launch if titlesFolder is inaccessible.
    /// Opens an NSOpenPanel so the user grants access to the folder.
    @MainActor
    func requestAccess(in window: NSWindow?) async -> Bool {
        guard let movies = moviesURL() else { return false }

        let panel = NSOpenPanel()
        panel.message = "Select your Movies folder and click Grant Access."
        panel.prompt = "Grant Access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        // Open inside Movies so clicking Grant Access with no navigation grants the
        // Movies folder (the recommended location). The user is free to choose any
        // folder (App Review requires a genuine choice); titlesSubfolder(of:) maps
        // whatever they grant to the Motion Templates/Titles path inside it.
        panel.directoryURL = movies

        let response: NSApplication.ModalResponse
        if let window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = panel.runModal()
        }

        guard response == .OK, let url = panel.url else { return false }

        // Release the previously held bookmark access (if any) before replacing it.
        scopedRoot?.stopAccessingSecurityScopedResource()
        scopedRoot = nil

        saveBookmark(for: url)
        return true
    }

    // MARK: - Private

    /// The user's Movies folder — the open panel's starting location. The user
    /// grants this (or, if they navigate in, an existing Motion Templates / Titles
    /// folder); titlesSubfolder(of:) maps whatever they grant to the FCP titles path.
    private func moviesURL() -> URL? {
        FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
    }

    /// Maps the user-granted folder to …/Motion Templates.localized/Titles.localized.
    /// FCP only recognizes the ".localized" folder names. The intermediates are
    /// created later by TemplateBuilder via withIntermediateDirectories, which reuses
    /// any that already exist (e.g. an FCP+Motion user's folder) and creates any that
    /// are missing (e.g. an FCP-only user who has never used Motion) — without
    /// disturbing existing sibling templates.
    private func titlesSubfolder(of root: URL) -> URL {
        switch root.lastPathComponent {
        case "Titles.localized":
            return root
        case "Motion Templates.localized":
            return root.appendingPathComponent("Titles.localized")
        default:
            return root
                .appendingPathComponent("Motion Templates.localized")
                .appendingPathComponent("Titles.localized")
        }
    }

    private func saveBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    private func resolvedBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }

        if stale { saveBookmark(for: url) }
        _ = url.startAccessingSecurityScopedResource()
        return url
    }
}
