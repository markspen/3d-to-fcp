import Foundation

enum ConflictResolution {
    case overwrite
    case skip
    case rename
}

enum ProcessingStatus: Equatable {
    case queued
    case processing
    case succeeded(URL)
    case skipped
    case failed(String)

    var isTerminal: Bool {
        switch self {
        case .succeeded, .skipped, .failed: return true
        case .queued, .processing: return false
        }
    }
}

enum TemplateError: Error, LocalizedError {
    case templateNotFound
    case invalidXML(Error)
    case usdzNodeNotFound
    case conflict
    case writeFailed(Error)
    case invalidUSDZ(String)

    var errorDescription: String? {
        switch self {
        case .templateNotFound: return "The internal Motion template is missing. Please reinstall the app."
        case .invalidXML(let e): return "Could not parse internal template: \(e.localizedDescription)"
        case .usdzNodeNotFound: return "The 3D object reference was not found in the template."
        case .conflict: return "A title with this name already exists."
        case .writeFailed(let e): return "Could not write output: \(e.localizedDescription)"
        case .invalidUSDZ(let reason): return "Invalid USDZ file: \(reason)"
        }
    }
}
