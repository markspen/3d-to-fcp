import Foundation

enum USDZValidator {
    static func validate(_ url: URL) throws {
        guard url.pathExtension.lowercased() == "usdz" else {
            throw TemplateError.invalidUSDZ("File must have a .usdz extension.")
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int ?? 0
        guard size > 0 else {
            throw TemplateError.invalidUSDZ("File is empty.")
        }

        // A valid USDZ is a ZIP archive — magic bytes are PK (0x50 0x4B)
        let handle = try FileHandle(forReadingFrom: url)
        defer { handle.closeFile() }
        let magic = handle.readData(ofLength: 2)
        guard magic.count == 2, magic[0] == 0x50, magic[1] == 0x4B else {
            throw TemplateError.invalidUSDZ("File does not appear to be a valid USDZ archive.")
        }
    }
}
