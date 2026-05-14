import Foundation
import AppKit

/// Resolves and persists access to ~/Movies/Motion Templates.localized/Titles.localized/
/// using a security-scoped bookmark (required for MAS sandbox).
final class MotionTemplatesManager {
    static let shared = MotionTemplatesManager()

    private let bookmarkKey = "motionTemplatesTitlesBookmark"

    // Cached URL — resolvedBookmark() acquires a security-scoped resource that must
    // not be re-acquired on every access. Acquire once, hold for the app's lifetime,
    // release in deinit (a belt-and-suspenders — the OS releases on process exit).
    private var cachedURL: URL?

    var titlesFolder: URL? {
        if cachedURL == nil {
            cachedURL = resolvedBookmark() ?? defaultTitlesURL()
        }
        return cachedURL
    }

    deinit {
        cachedURL?.stopAccessingSecurityScopedResource()
    }

    /// Call at first launch if titlesFolder is inaccessible.
    /// Opens an NSOpenPanel so the user grants access to the folder.
    @MainActor
    func requestAccess(in window: NSWindow?) async -> Bool {
        let panel = NSOpenPanel()
        panel.message = "3D to FCP needs access to your Motion Templates folder to save titles."
        panel.prompt = "Grant Access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = defaultTitlesURL()

        let response: NSApplication.ModalResponse
        if let window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = panel.runModal()
        }

        guard response == .OK, let url = panel.url else { return false }

        // Release the previously held bookmark access (if any) before replacing it.
        cachedURL?.stopAccessingSecurityScopedResource()
        cachedURL = nil

        saveBookmark(for: url)
        return true
    }

    // MARK: - Private

    private func defaultTitlesURL() -> URL? {
        let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        // Try the .localized variant first (standard on macOS), then fall back to plain name
        let localized = movies?.appendingPathComponent("Motion Templates.localized/Titles.localized")
        let plain     = movies?.appendingPathComponent("Motion Templates/Titles")

        if let l = localized, FileManager.default.fileExists(atPath: l.path) { return l }
        if let p = plain,     FileManager.default.fileExists(atPath: p.path) { return p }
        return localized // return preferred path even if it doesn't exist yet; we'll create it
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
