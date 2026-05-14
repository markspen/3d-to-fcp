import Testing
import Foundation
@testable import ThreeDtoFCP

/// Tests for the XML-patching pipeline that substitutes filenames into the placeholder .moti.
/// Exercises both XML entity escaping and NSRegularExpression template-string escaping.
@Suite("TemplateBuilder.patch — XML and regex-template escaping")
struct TemplateBuilderPatchTests {

    /// A miniature stand-in for `_Placeholder.moti` that mirrors all locations
    /// the patcher modifies. Models the post-Robot-swap state: cycle=148 frames (Robot's
    /// 2.47s animation), End Duration=452 frames (filling out a 10s project default).
    static let template = """
        <root>
        <layer name="3D Object" id="10003">
        <scenenode name="Replace Me" id="DEF456" factoryID="15" version="5">
        <timing in="0 1 1 0" out="1533440 153600 1 0" offset="0 1 1 0"/>
        <parameter name="Properties" id="1" flags="8589938704">
            <parameter name="Retime Value" id="309" flags="8590065938">
                <curve type="1" default="1" value="1" retimingExtrapolation="1">
                    <numberOfKeypoints>2</numberOfKeypoints>
                    <postExtrapolation>3</postExtrapolation>
                    <keypoint interpolation="1" flags="0">
                        <time>0 1 1 0</time>
                        <value>1</value>
                    </keypoint>
                    <keypoint interpolation="1" flags="0">
                        <time>378880 153600 1 0</time>
                        <value>149</value>
                    </keypoint>
                </curve>
            </parameter>
            <parameter name="Retime Value Cache" id="316" flags="8590065682">
                <curve type="1" default="1" value="1">
                    <numberOfKeypoints>2</numberOfKeypoints>
                    <keypoint interpolation="1" flags="128">
                        <time>0 1 1 0</time>
                        <value>1</value>
                    </keypoint>
                    <keypoint interpolation="1" flags="128">
                        <time>378880 153600 1 0</time>
                        <value>149</value>
                    </keypoint>
                </curve>
            </parameter>
            <parameter name="End Condition" id="311" flags="8590000146" default="0" value="1"/>
            <parameter name="End Duration" id="312" flags="8589934610" default="0" value="452"/>
            <parameter name="Duration Cache" id="317" flags="8589934610" default="0" value="148"/>
        </parameter>
        </scenenode>
        </layer>
        <scenenode name="Robot" id="ABC123" factoryID="4" version="5">
            <relativeURL>Media/Robot.usdz</relativeURL>
            <flags>0</flags>
            <timing in="0 1 1 0" out="376320 153600 1 0" offset="0 1 1 0"/>
        </scenenode>
        </root>
        """

    // MARK: - Happy path

    @Test("Plain ASCII filenames patch both locations")
    func plainName() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Penguin",
            usdzFileName: "Penguin.usdz"
        )
        #expect(result.contains(#"<scenenode name="Penguin" id="ABC123" factoryID="4" version="5">"#))
        #expect(result.contains("<relativeURL>Media/Penguin.usdz</relativeURL>"))
        // The placeholder asset name should be gone from the footage scenenode.
        #expect(!result.contains(#"name="Robot""#))
    }

    // MARK: - XML entity escaping

    @Test("Ampersand is XML-escaped")
    func ampersand() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Rock & Roll",
            usdzFileName: "Rock & Roll.usdz"
        )
        #expect(result.contains(#"name="Rock &amp; Roll""#))
        #expect(result.contains("<relativeURL>Media/Rock &amp; Roll.usdz</relativeURL>"))
    }

    @Test("Less-than is XML-escaped")
    func lessThan() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Less<Than",
            usdzFileName: "Less<Than.usdz"
        )
        #expect(result.contains(#"name="Less&lt;Than""#))
        #expect(result.contains("Media/Less&lt;Than.usdz"))
    }

    @Test("Greater-than is XML-escaped")
    func greaterThan() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "More>Than",
            usdzFileName: "More>Than.usdz"
        )
        #expect(result.contains(#"name="More&gt;Than""#))
    }

    @Test("Double-quote is XML-escaped")
    func doubleQuote() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: #"My "Cool" Robot"#,
            usdzFileName: #"My "Cool" Robot.usdz"#
        )
        #expect(result.contains(#"name="My &quot;Cool&quot; Robot""#))
    }

    @Test("Single-quote / apostrophe is XML-escaped")
    func apostrophe() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "It's Cool",
            usdzFileName: "It's Cool.usdz"
        )
        #expect(result.contains(#"name="It&apos;s Cool""#))
    }

    // MARK: - Regex template metacharacter escaping

    @Test("Dollar sign survives regex template (would otherwise be backreference)")
    func dollarSign() throws {
        // Without escaping, "$1" inside the replacement would be interpreted by
        // NSRegularExpression as backreference #1 (the prefix). Verifies our
        // regexTemplateEscape neutralises it.
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Cost$50",
            usdzFileName: "Cost$50.usdz"
        )
        #expect(result.contains(#"name="Cost$50""#))
        #expect(result.contains("Media/Cost$50.usdz"))
    }

    @Test("Backslash survives regex template (would otherwise escape next char)")
    func backslash() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: #"path\file"#,
            usdzFileName: #"path\file.usdz"#
        )
        #expect(result.contains(#"name="path\file""#))
    }

    @Test("Combined XML- and regex-special characters all encode correctly")
    func combined() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: #"Cost$50 & "Robot""#,
            usdzFileName: #"Cost$50 & "Robot".usdz"#
        )
        #expect(result.contains(#"name="Cost$50 &amp; &quot;Robot&quot;""#))
        #expect(result.contains(#"<relativeURL>Media/Cost$50 &amp; &quot;Robot&quot;.usdz</relativeURL>"#))
    }

    // MARK: - Determinism

    @Test("Patching is idempotent for input that doesn't match the regex")
    func nonMatching() throws {
        // A template with no scenenode/relativeURL should pass through unchanged
        // (scenenode regex fails -> throws; verify that).
        let plain = "<root>no scenenode here</root>"
        #expect(throws: Never.self) {
            // Patch will not throw — the regex compiles fine, it just won't match anything.
            // So output equals input.
            let out = try TemplateBuilder.patch(template: plain, baseName: "X", usdzFileName: "X.usdz")
            #expect(out == plain)
        }
    }

    // MARK: - Animation cycle patching (Loop end-condition support)

    @Test("loopCycleSeconds nil → static USDZ defaults (Duration Cache=600, End Duration=0)")
    func loopCycleNil() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Statue",
            usdzFileName: "Statue.usdz",
            loopCycleSeconds: nil
        )
        // Static reset: cycle=600 frames (10s), no extension
        #expect(result.contains(#"name="Duration Cache" id="317" flags="8589934610" default="0" value="600""#))
        #expect(result.contains(#"name="End Duration" id="312" flags="8589934610" default="0" value="0""#))
        #expect(result.contains(#"<time>1536000 153600 1 0</time>"#))
        #expect(result.contains(#"<value>601</value>"#))
        // Layer + footage scenenode at 10s
        #expect(result.contains(#"<timing in="0 1 1 0" out="1536000 153600 1 0" offset="0 1 1 0"/>"#))
        // Robot's baked-in cycle values are gone
        #expect(!result.contains(#"value="148""#))
        #expect(!result.contains(#"value="452""#))
        #expect(!result.contains(#"<time>378880 153600 1 0</time>"#))
    }

    @Test("loopCycleSeconds=3.0 → animated USDZ (Duration Cache=180, End Duration=3420, layer extended to 60s)")
    func loopCycleThreeSeconds() throws {
        let result = try TemplateBuilder.patch(
            template: Self.template,
            baseName: "Penguin",
            usdzFileName: "Penguin.usdz",
            loopCycleSeconds: 3.0
        )
        // 3s × 60 = 180 frames natural cycle
        #expect(result.contains(#"name="Duration Cache" id="317" flags="8589934610" default="0" value="180""#))
        // End Duration fills out 60s layer: 3600 - 180 = 3420
        #expect(result.contains(#"name="End Duration" id="312" flags="8589934610" default="0" value="3420""#))
        // Retime endpoint time = 3s × 153600 = 460800
        #expect(result.contains(#"<time>460800 153600 1 0</time>"#))
        // Retime endpoint value = 180 + 1 = 181
        #expect(result.contains(#"<value>181</value>"#))
        // Footage scenenode out matches natural cycle: 460800
        #expect(result.contains(#"<timing in="0 1 1 0" out="460800 153600 1 0" offset="0 1 1 0"/>"#))
        // Layer scenenode extended to 60s: 60 × 153600 = 9216000
        #expect(result.contains(#"<timing in="0 1 1 0" out="9216000 153600 1 0" offset="0 1 1 0"/>"#))
        // Stale Robot-derived values should be gone
        #expect(!result.contains(#"value="148""#))
        #expect(!result.contains(#"value="452""#))
        #expect(!result.contains(#"<time>378880 153600 1 0</time>"#))
        #expect(!result.contains(#"<value>149</value>"#))
    }
}
