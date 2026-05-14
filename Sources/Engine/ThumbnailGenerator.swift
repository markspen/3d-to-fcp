import Foundation
import QuickLookThumbnailing
import AppKit

enum ThumbnailGenerator {
    private static let sizes: [(name: String, size: CGSize)] = [
        ("large", CGSize(width: 640, height: 360)),
        ("small", CGSize(width: 192, height: 108))
    ]

    /// Renders the USDZ via Quick Look and writes large.png + small.png into templateFolder.
    /// Failures are silenced — missing thumbnails don't affect template functionality.
    static func generate(for usdzURL: URL, into templateFolder: URL) async {
        for (name, size) in sizes {
            let request = QLThumbnailGenerator.Request(
                fileAt: usdzURL,
                size: size,
                scale: 1.0,
                representationTypes: .thumbnail
            )
            guard let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request) else { continue }
            let dest = templateFolder.appendingPathComponent("\(name).png")
            savePNG(rep.nsImage, to: dest)
        }
    }

    private static func savePNG(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}
