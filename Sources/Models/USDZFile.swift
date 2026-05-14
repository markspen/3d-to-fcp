import Foundation

@Observable
final class USDZFile: Identifiable {
    let id = UUID()
    let url: URL
    var status: ProcessingStatus = .queued
    var conflictResolution: ConflictResolution?

    var displayName: String { url.deletingPathExtension().lastPathComponent }
    var fileName: String { url.lastPathComponent }

    init(url: URL) {
        self.url = url
    }
}
