import Foundation
import ModelIO

enum TemplateBuilder {
    /// When the source USDZ has any animation, we extend the layer scenenode's display
    /// window so Motion has room to tile cycles. 60s covers typical FCP title durations
    /// and then some.
    private static let extendedLayerOutSeconds: Double = 60

    static func build(
        from usdzURL: URL,
        into titlesFolder: URL,
        categoryName: String,
        conflictResolution: ConflictResolution = .overwrite
    ) throws -> URL {
        let baseName = usdzURL.deletingPathExtension().lastPathComponent
        let categoryFolder = titlesFolder.appendingPathComponent(categoryName)
        let templateFolder = categoryFolder.appendingPathComponent(baseName + ".localized")
        let outputMotiURL = templateFolder.appendingPathComponent(baseName + ".moti")
        let outputMediaFolder = templateFolder.appendingPathComponent("Media")
        let outputUSDZURL = outputMediaFolder.appendingPathComponent(usdzURL.lastPathComponent)

        // Conflict check
        if FileManager.default.fileExists(atPath: templateFolder.path) {
            switch conflictResolution {
            case .skip:
                throw TemplateError.conflict
            case .overwrite:
                try FileManager.default.removeItem(at: templateFolder)
            case .rename:
                return try build(
                    from: usdzURL,
                    into: titlesFolder,
                    categoryName: categoryName,
                    conflictResolution: .overwrite,
                    renaming: baseName,
                    counter: 2
                )
            }
        }

        let duration = usdzDuration(at: usdzURL)
        let xml = try loadAndPatchTemplate(
            baseName: baseName,
            usdzFileName: usdzURL.lastPathComponent,
            loopCycleSeconds: duration > 0 ? duration : nil
        )

        try FileManager.default.createDirectory(at: outputMediaFolder, withIntermediateDirectories: true)
        do {
            try xml.write(to: outputMotiURL, atomically: true, encoding: .utf8)
            try FileManager.default.copyItem(at: usdzURL, to: outputUSDZURL)
        } catch {
            try? FileManager.default.removeItem(at: templateFolder)
            throw error
        }

        return templateFolder
    }

    // Recursive rename helper (appends " 2", " 3", etc.)
    private static func build(
        from usdzURL: URL,
        into titlesFolder: URL,
        categoryName: String,
        conflictResolution: ConflictResolution,
        renaming baseName: String,
        counter: Int
    ) throws -> URL {
        let newName = "\(baseName) \(counter)"
        let newUSDZName = newName + ".usdz"
        let categoryFolder = titlesFolder.appendingPathComponent(categoryName)
        let templateFolder = categoryFolder.appendingPathComponent(newName + ".localized")
        let outputMotiURL = templateFolder.appendingPathComponent(newName + ".moti")
        let outputMediaFolder = templateFolder.appendingPathComponent("Media")
        let outputUSDZURL = outputMediaFolder.appendingPathComponent(newUSDZName)

        if FileManager.default.fileExists(atPath: templateFolder.path) {
            return try build(from: usdzURL, into: titlesFolder, categoryName: categoryName,
                             conflictResolution: conflictResolution, renaming: baseName, counter: counter + 1)
        }

        let duration = usdzDuration(at: usdzURL)
        let xml = try loadAndPatchTemplate(
            baseName: newName,
            usdzFileName: newUSDZName,
            loopCycleSeconds: duration > 0 ? duration : nil
        )

        try FileManager.default.createDirectory(at: outputMediaFolder, withIntermediateDirectories: true)
        do {
            try xml.write(to: outputMotiURL, atomically: true, encoding: .utf8)
            try FileManager.default.copyItem(at: usdzURL, to: outputUSDZURL)
        } catch {
            try? FileManager.default.removeItem(at: templateFolder)
            throw error
        }

        return templateFolder
    }

    private static func loadAndPatchTemplate(
        baseName: String,
        usdzFileName: String,
        loopCycleSeconds: Double? = nil
    ) throws -> String {
        guard let templateURL = Bundle.main.url(forResource: "_Placeholder", withExtension: "moti"),
              let xmlString = try? String(contentsOf: templateURL, encoding: .utf8) else {
            throw TemplateError.templateNotFound
        }
        return try patch(
            template: xmlString,
            baseName: baseName,
            usdzFileName: usdzFileName,
            loopCycleSeconds: loopCycleSeconds
        )
    }

    /// Pure patching function exposed for unit testing.
    ///
    /// Always substitutes the 3D-object scenenode name + relativeURL with safe
    /// (XML- and regex-template-escaped) versions of the user filename.
    ///
    /// If `loopCycleSeconds` is provided (i.e. the user's USDZ is animated), also rewrites
    /// the Animation parameter group's cached cycle length so Motion's "End Condition = Loop"
    /// cycles at the user's natural animation length instead of the Airplane placeholder's
    /// baked-in 10s. Specifically updates:
    ///   - `Duration Cache` (frames at 60 units/sec)
    ///   - The `Retime Value` curve's end keypoint (time + value)
    ///   - The `Retime Value Cache` curve's end keypoint (time + value)
    ///   - The footage and layer scenenode `<timing out=...>` (extended to ~60s so longer
    ///     FCP titles still have room to tile multiple cycles)
    static func patch(
        template: String,
        baseName: String,
        usdzFileName: String,
        loopCycleSeconds: Double? = nil
    ) throws -> String {
        var xmlString = template

        // Filenames are inserted into XML *and* passed through NSRegularExpression's template
        // string, so they must be escaped twice: once for XML entity safety, then again for
        // the regex template's `$` / `\` metacharacters.
        let safeBaseName = regexTemplateEscape(xmlEscape(baseName))
        let safeUSDZName = regexTemplateEscape(xmlEscape(usdzFileName))

        // Patch the footage scenenode name attribute.
        // Anchor on factoryID="4" — there is exactly one such scenenode in the placeholder
        // (the media-pool USDZ reference). Motion may set the name to just the asset's
        // bare filename (e.g., "Robot") or to a full path, so we don't anchor on the name.
        let scenodePattern = #"(<scenenode name=")[^"]*(" id="[^"]*" factoryID="4"[^>]*)"#
        if let regex = try? NSRegularExpression(pattern: scenodePattern) {
            let range = NSRange(xmlString.startIndex..., in: xmlString)
            xmlString = regex.stringByReplacingMatches(in: xmlString, range: range,
                withTemplate: "$1\(safeBaseName)$2")
        } else {
            throw TemplateError.usdzNodeNotFound
        }

        // Patch the relativeURL (Media/Airplane.usdz → Media/newfile.usdz)
        let relativeURLPattern = #"(<relativeURL>Media/)[^<]+(</relativeURL>)"#
        if let regex = try? NSRegularExpression(pattern: relativeURLPattern) {
            let range = NSRange(xmlString.startIndex..., in: xmlString)
            xmlString = regex.stringByReplacingMatches(in: xmlString, range: range,
                withTemplate: "$1\(safeUSDZName)$2")
        }

        // Adjust the Animation parameter group to match whether the user's USDZ is animated
        // or static. The placeholder ships with Robot.usdz's cycle baked in; we override it
        // either to the user's natural cycle (animated) or to a no-loop static configuration.
        xmlString = patchAnimationCycle(in: xmlString, loopCycleSeconds: loopCycleSeconds)

        return xmlString
    }

    /// Rewrites the Animation parameter group's cached cycle values + scenenode display
    /// windows to match the user's USDZ.
    ///
    /// Motion's "Duration Cache" is measured in 60 units/sec (frames at 60fps). Endpoint
    /// values are `frames + 1` (1-indexed convention). The layer's total duration is
    /// `Duration Cache + End Duration` frames — to extend looping, we make End Duration
    /// big enough to fill a generous 60s layer for animated assets.
    private static func patchAnimationCycle(in xml: String, loopCycleSeconds: Double?) -> String {
        var result = xml

        // Decide the target configuration.
        let cycleFrames: Int64
        let endDurationFrames: Int64
        let cycleTimeNumerator: Int64
        let layerOutSeconds: Double

        if let seconds = loopCycleSeconds, seconds > 0 {
            // Animated USDZ: cycle = user's animation duration, layer extended to 60s.
            cycleFrames = Int64((seconds * 60).rounded())
            cycleTimeNumerator = Int64((seconds * 153600).rounded())
            let totalFrames: Int64 = 3600  // 60s × 60fps
            endDurationFrames = max(0, totalFrames - cycleFrames)
            layerOutSeconds = extendedLayerOutSeconds
        } else {
            // Static USDZ: reset to no-loop defaults — cycle == total, end duration == 0.
            cycleFrames = 600  // 10s × 60fps
            cycleTimeNumerator = 1536000  // 10s × 153600
            endDurationFrames = 0
            layerOutSeconds = 10
        }

        let cycleFramesStr = String(cycleFrames)
        let endDurationStr = String(endDurationFrames)
        let endpointTimeStr = "\(cycleTimeNumerator) 153600 1 0"
        let endpointValueStr = String(cycleFrames + 1)
        let layerOutStr = motionTiming(forSeconds: layerOutSeconds)
        let footageOutStr = endpointTimeStr  // footage out matches the natural cycle time

        // 1. Duration Cache
        let dcPattern = #"(<parameter name="Duration Cache"[^>]*value=")[^"]*(")"#
        result = replace(in: result, pattern: dcPattern, withTemplate: "$1\(cycleFramesStr)$2")

        // 2. End Duration (the explicit "extension beyond natural cycle" field)
        let edPattern = #"(<parameter name="End Duration"[^>]*value=")[^"]*(")"#
        result = replace(in: result, pattern: edPattern, withTemplate: "$1\(endDurationStr)$2")

        // 3. Retime Value curve's end (second) keypoint - time and value
        let rvPattern = #"(<parameter name="Retime Value"[\s\S]*?<keypoint[^>]*>\s*<time>0 1 1 0</time>\s*<value>1</value>\s*</keypoint>\s*<keypoint[^>]*>\s*<time>)[^<]+(</time>\s*<value>)[^<]+(</value>)"#
        result = replace(in: result, pattern: rvPattern,
            withTemplate: "$1\(regexTemplateEscape(endpointTimeStr))$2\(endpointValueStr)$3")

        // 4. Retime Value Cache curve's end keypoint
        let rvcPattern = #"(<parameter name="Retime Value Cache"[\s\S]*?<keypoint[^>]*>\s*<time>0 1 1 0</time>\s*<value>1</value>\s*</keypoint>\s*<keypoint[^>]*>\s*<time>)[^<]+(</time>\s*<value>)[^<]+(</value>)"#
        result = replace(in: result, pattern: rvcPattern,
            withTemplate: "$1\(regexTemplateEscape(endpointTimeStr))$2\(endpointValueStr)$3")

        // 5. Footage scenenode timing out (matches the natural cycle)
        let footageTimingPattern = #"(<relativeURL>Media/[^<]+</relativeURL>\s*<flags>[^<]*</flags>\s*<timing in="[^"]*" out=")[^"]*(" offset="[^"]*"/>)"#
        result = replace(in: result, pattern: footageTimingPattern,
            withTemplate: "$1\(regexTemplateEscape(footageOutStr))$2")

        // 6. Layer scenenode timing out (full layer window: cycle + end duration)
        let layerTimingPattern = #"(<layer name="3D Object"[^>]*>\s*<scenenode[\s\S]*?<timing in="[^"]*" out=")[^"]*(" offset="[^"]*"/>)"#
        result = replace(in: result, pattern: layerTimingPattern,
            withTemplate: "$1\(regexTemplateEscape(layerOutStr))$2")

        return result
    }

    private static func replace(in xml: String, pattern: String, withTemplate template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return xml }
        let range = NSRange(xml.startIndex..., in: xml)
        return regex.stringByReplacingMatches(in: xml, range: range, withTemplate: template)
    }

    /// Returns the natural animation duration of a USDZ in seconds. Returns 0 for
    /// static (non-animated) USDZ files. Uses ModelIO's MDLAsset which loads only the
    /// scene metadata (fast — no GPU/render involved).
    private static func usdzDuration(at url: URL) -> TimeInterval {
        let asset = MDLAsset(url: url)
        return max(0, asset.endTime - asset.startTime)
    }

    /// Converts a duration in seconds to Motion's 4-component timing format:
    /// `value timescale 1 0` where the implicit fraction is value/timescale seconds.
    /// We match the timescale (153600) Motion uses throughout the placeholder.
    private static func motionTiming(forSeconds seconds: TimeInterval) -> String {
        let value = Int64(seconds * 153600)
        return "\(value) 153600 1 0"
    }

    private static func xmlEscape(_ s: String) -> String {
        var result = s
        result = result.replacingOccurrences(of: "&", with: "&amp;")  // must run first
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    private static func regexTemplateEscape(_ s: String) -> String {
        var result = s
        result = result.replacingOccurrences(of: "\\", with: "\\\\")  // must run first
        result = result.replacingOccurrences(of: "$", with: "\\$")
        return result
    }
}
