import Foundation
import AppKit
import SwiftUI

enum AppState {
    case dropping
    case reviewing        // files added, not yet started
    case conflictCheck    // resolving conflicts before processing
    case processing
    case success(Int)     // count of titles created
}

@Observable
final class AppViewModel {
    var files: [USDZFile] = []
    var state: AppState = .dropping
    var conflictingFiles: [USDZFile] = []
    var applyConflictToAll = false
    var selectedConflictResolution: ConflictResolution = .overwrite

    var categoryName: String = UserDefaults.standard.string(forKey: "categoryName") ?? "3D to FCP" {
        didSet { UserDefaults.standard.set(categoryName, forKey: "categoryName") }
    }

    var canCreate: Bool {
        !files.isEmpty
        && files.allSatisfy { $0.status == .queued }
        && !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var processedCount: Int { files.filter { if case .succeeded = $0.status { true } else { false } }.count }
    var totalCount: Int { files.count }

    // MARK: - File Management

    func addFiles(_ urls: [URL]) {
        let new = urls
            .filter { $0.pathExtension.lowercased() == "usdz" }
            .filter { url in !files.contains { $0.url == url } }
            .map { USDZFile(url: $0) }
        files.append(contentsOf: new)
        if !files.isEmpty { state = .reviewing }
    }

    func removeFile(_ file: USDZFile) {
        files.removeAll { $0.id == file.id }
        if files.isEmpty { state = .dropping }
    }

    func reset() {
        files = []
        conflictingFiles = []
        state = .dropping
    }

    // MARK: - Processing

    @MainActor
    func startCreate(window: NSWindow?) async {
        // Validate all files first
        for file in files {
            do {
                try USDZValidator.validate(file.url)
            } catch {
                file.status = .failed(error.localizedDescription)
            }
        }

        let invalid = files.filter { if case .failed = $0.status { true } else { false } }
        if !invalid.isEmpty { return }

        // Ensure access to Motion Templates folder
        let manager = MotionTemplatesManager.shared
        if manager.titlesFolder == nil {
            let granted = await manager.requestAccess(in: window)
            if !granted { return }
        }

        // Check for conflicts
        guard let titlesFolder = manager.titlesFolder else { return }
        let category = categoryName
        conflictingFiles = files.filter { file in
            let dest = titlesFolder
                .appendingPathComponent(category)
                .appendingPathComponent(file.displayName + ".localized")
            return FileManager.default.fileExists(atPath: dest.path)
        }

        if !conflictingFiles.isEmpty {
            state = .conflictCheck
            return
        }

        await processAll(titlesFolder: titlesFolder)
    }

    @MainActor
    func resolveConflictsAndProcess(window: NSWindow?) async {
        if applyConflictToAll {
            for file in conflictingFiles {
                file.conflictResolution = selectedConflictResolution
            }
        }
        // Files with no explicit resolution get the selected default
        for file in conflictingFiles where file.conflictResolution == nil {
            file.conflictResolution = selectedConflictResolution
        }

        guard let titlesFolder = MotionTemplatesManager.shared.titlesFolder else { return }
        await processAll(titlesFolder: titlesFolder)
    }

    @MainActor
    private func processAll(titlesFolder: URL) async {
        state = .processing
        let category = categoryName
        var successCount = 0

        for file in files {
            guard file.status == .queued else { continue }
            file.status = .processing

            do {
                let resolution = file.conflictResolution ?? .overwrite
                let templateFolder = try TemplateBuilder.build(
                    from: file.url,
                    into: titlesFolder,
                    categoryName: category,
                    conflictResolution: resolution
                )
                file.status = .succeeded(templateFolder)
                successCount += 1
                await ThumbnailGenerator.generate(for: file.url, into: templateFolder)
            } catch TemplateError.conflict {
                file.status = .skipped
            } catch {
                file.status = .failed(error.localizedDescription)
            }
        }

        state = .success(successCount)
    }

    // MARK: - Success Actions

    func revealInFinder() {
        guard let titlesFolder = MotionTemplatesManager.shared.titlesFolder else { return }
        let categoryFolder = titlesFolder.appendingPathComponent(categoryName)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: categoryFolder.path)
    }

    func openFinalCutPro() {
        let candidates: [(name: String, path: String)] = [
            ("Final Cut Pro", "/Applications/Final Cut Pro.app"),
            ("Final Cut Pro Creator Studio", "/Applications/Final Cut Pro Creator Studio.app"),
        ]
        let found = candidates.filter { FileManager.default.fileExists(atPath: $0.path) }

        switch found.count {
        case 0:
            let alert = NSAlert()
            alert.messageText = "Final Cut Pro Not Found"
            alert.informativeText = "Could not locate Final Cut Pro on this Mac."
            alert.runModal()
        case 1:
            openApp(at: URL(fileURLWithPath: found[0].path))
        default:
            let alert = NSAlert()
            alert.messageText = "Open in Final Cut Pro"
            alert.informativeText = "Which version would you like to open?"
            found.forEach { alert.addButton(withTitle: $0.name) }
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            if index < found.count {
                openApp(at: URL(fileURLWithPath: found[index].path))
            }
        }
    }

    private func openApp(at url: URL) {
        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }
    }
}
