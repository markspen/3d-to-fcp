import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Bindable var viewModel: AppViewModel
    @State private var isTargeted = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("Add 3D Objects in the USDZ format")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Drag files here or click Add Files")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                    )
            )
            .padding(40)
            .offset(x: shakeOffset)
            .onDrop(of: [UTType.usdz, .fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("USDZ drop zone")
            .accessibilityHint("Drag USDZ files here, or use the Add Files button below.")

            Button("Add Files…") {
                openFilePicker()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Open the file picker to select one or more USDZ files.")

            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }

    // MARK: - Actions

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            let typeID = provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .usdz) == true
            }) ?? UTType.usdz.identifier

            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: typeID) { tempURL, error in
                defer { group.leave() }
                guard let tempURL, tempURL.pathExtension.lowercased() == "usdz" else { return }
                // Copy out of the ephemeral sandbox location before the callback returns
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(tempURL.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                if (try? FileManager.default.copyItem(at: tempURL, to: dest)) != nil {
                    urls.append(dest)
                }
            }
        }

        group.notify(queue: .main) {
            if urls.isEmpty {
                shake()
            } else {
                viewModel.addFiles(urls)
            }
        }
        return true
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.usdz]
        panel.prompt = "Add"
        panel.title = "Select USDZ Files"

        if panel.runModal() == .OK {
            viewModel.addFiles(panel.urls)
        }
    }

    private func shake() {
        let animation = Animation.easeInOut(duration: 0.06)
        withAnimation(animation) { shakeOffset = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(animation) { shakeOffset = 8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(animation) { shakeOffset = -4 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                    withAnimation(animation) { shakeOffset = 0 }
                }
            }
        }
    }
}

extension UTType {
    static let usdz = UTType(filenameExtension: "usdz")!
}
