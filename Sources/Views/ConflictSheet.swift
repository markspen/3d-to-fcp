import SwiftUI

struct ConflictSheet: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Some titles already exist")
                    .font(.headline)
                Text("\(viewModel.conflictingFiles.count) title\(viewModel.conflictingFiles.count == 1 ? "" : "s") with the same name \(viewModel.conflictingFiles.count == 1 ? "already exists" : "already exist") in \"3D to FCP\".")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Picker("For each conflict:", selection: $viewModel.selectedConflictResolution) {
                Text("Overwrite existing title").tag(ConflictResolution.overwrite)
                Text("Skip and keep existing").tag(ConflictResolution.skip)
                Text("Rename (add number)").tag(ConflictResolution.rename)
            }
            .pickerStyle(.radioGroup)

            if viewModel.conflictingFiles.count > 1 {
                Toggle("Apply to all conflicts", isOn: $viewModel.applyConflictToAll)
            }

            if !viewModel.applyConflictToAll && viewModel.conflictingFiles.count > 1 {
                GroupBox("Conflicting files") {
                    ForEach(viewModel.conflictingFiles) { file in
                        HStack {
                            Text(file.displayName)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { file.conflictResolution ?? viewModel.selectedConflictResolution },
                                set: { file.conflictResolution = $0 }
                            )) {
                                Text("Overwrite").tag(ConflictResolution.overwrite)
                                Text("Skip").tag(ConflictResolution.skip)
                                Text("Rename").tag(ConflictResolution.rename)
                            }
                            .frame(width: 120)
                            .accessibilityLabel("Conflict resolution for \(file.displayName)")
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    viewModel.state = .reviewing
                }

                Spacer()

                Button("Continue") {
                    Task {
                        await viewModel.resolveConflictsAndProcess(window: NSApp.keyWindow)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 400)
    }
}
