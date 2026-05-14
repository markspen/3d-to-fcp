import SwiftUI

struct FileListView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.files) { file in
                    FileRowView(file: file) {
                        viewModel.removeFile(file)
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            HStack(spacing: 8) {
                Text("Titles Browser Category:")
                    .foregroundStyle(.secondary)
                TextField("", text: $viewModel.categoryName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Titles Browser Category")
                    .accessibilityHint("The name of the category your titles will appear under in Final Cut Pro's Titles Browser.")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            HStack {
                Button("Add More…") {
                    openFilePicker()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.files.count) file\(viewModel.files.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                Button("Create") {
                    Task {
                        await viewModel.startCreate(window: NSApp.keyWindow)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canCreate)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.usdz]
        panel.prompt = "Add"
        if panel.runModal() == .OK {
            viewModel.addFiles(panel.urls)
        }
    }
}

struct FileRowView: View {
    let file: USDZFile
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.fill")
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.body)
                Text(file.fileName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(file.displayName), \(statusDescription)")

            Spacer()

            statusBadge

            if case .queued = file.status {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(file.displayName)")
            }
        }
        .padding(.vertical, 4)
    }

    private var statusDescription: String {
        switch file.status {
        case .queued: "queued"
        case .processing: "processing"
        case .succeeded: "done"
        case .skipped: "skipped"
        case .failed(let msg): "error: \(msg)"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch file.status {
        case .queued:
            EmptyView()
        case .processing:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
        case .succeeded:
            Label("Done", systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
        case .skipped:
            Label("Skipped", systemImage: "minus.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.red)
                .help(msg)
                .accessibilityHidden(true)
        }
    }
}
