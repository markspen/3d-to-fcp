import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                section("What it does") {
                    Text("3D to FCP turns USDZ 3D model files into draggable titles in Final Cut Pro. No Motion installation required.")
                }

                section("Quick start") {
                    numberedList([
                        "Drag one or more USDZ files onto the app window — or click **Add Files**.",
                        "Optionally edit the **Titles Browser Category** name.",
                        "Click **Create**.",
                        "Open Final Cut Pro. Your titles appear in the Titles Browser under that category."
                    ])
                }

                section("Customizing the category") {
                    Text("The **Titles Browser Category** field controls where your titles appear in Final Cut Pro. The default is \"3D to FCP\". Change it to group titles by project, client, or any other label. The name is remembered between launches.")
                }

                section("Handling conflicts") {
                    Text("If a title with the same name already exists in that category, you'll see a conflict prompt with three choices:")
                    bulletList([
                        "**Overwrite** — replace the existing title with the new version.",
                        "**Skip** — keep the existing title; don't process this one.",
                        "**Rename** — keep both. The new title gets a numbered suffix."
                    ])
                }

                section("Where your files live") {
                    Text("Created titles are stored at:")
                    Text("~/Movies/Motion Templates.localized/Titles.localized/[Category Name]/")
                        .font(.system(.callout, design: .monospaced))
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Each USDZ becomes a Motion template bundle inside that folder.")
                }

                section("Requirements") {
                    bulletList([
                        "macOS 14 (Sonoma) or later",
                        "Final Cut Pro installed (or Final Cut Pro Creator Studio)",
                        "A USDZ file to convert"
                    ])
                }

                section("Troubleshooting") {
                    troubleshootingItem(
                        question: "My titles don't appear in Final Cut Pro.",
                        answer: "Quit Final Cut Pro and reopen it. FCP scans the Titles folder when it launches."
                    )
                    troubleshootingItem(
                        question: "I see \"No access to Motion Templates folder.\"",
                        answer: "On first launch, the app asks for permission to read and write the Motion Templates folder. Click **Grant Access** and choose the Motion Templates folder when prompted. This is a one-time step."
                    )
                    troubleshootingItem(
                        question: "The title processed, but FCP shows a default cube instead of my model.",
                        answer: "The USDZ file may be too small, corrupted, or not a valid USDZ. The app validates files before processing — check the file row for any error icon."
                    )
                }

                section("Credits") {
                    Text("3D to FCP was created by Mark Spencer in partnership with Ripple Training.")
                    Link("Visit rippletraining.com →", destination: URL(string: "https://rippletraining.com")!)
                        .font(.callout)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520, minHeight: 600)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("3D to FCP")
                .font(.largeTitle.bold())
            Text("Turn USDZ 3D models into Final Cut Pro titles.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func numberedList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(idx + 1).")
                        .foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .trailing)
                    Text(.init(item))
                }
            }
        }
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(.secondary)
                    Text(.init(item))
                }
            }
        }
    }

    private func troubleshootingItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question).font(.body.bold())
            Text(.init(answer)).foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }
}
