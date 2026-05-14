import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .dropping:
                DropZoneView(viewModel: viewModel)

            case .reviewing:
                FileListView(viewModel: viewModel)

            case .conflictCheck:
                FileListView(viewModel: viewModel)
                    .sheet(isPresented: .constant(true)) {
                        ConflictSheet(viewModel: viewModel)
                    }

            case .processing:
                FileListView(viewModel: viewModel)

            case .success(let count):
                SuccessView(
                    count: count,
                    categoryName: viewModel.categoryName,
                    onAddMore: { viewModel.reset() },
                    onReveal: { viewModel.revealInFinder() },
                    onOpenFCP: { viewModel.openFinalCutPro() }
                )
            }
        }
        .frame(minWidth: 480, minHeight: 400)
        .animation(.easeInOut(duration: 0.2), value: stateKey)
    }

    // Used to drive animation without requiring AppState: Equatable
    private var stateKey: String {
        switch viewModel.state {
        case .dropping: "dropping"
        case .reviewing: "reviewing"
        case .conflictCheck: "conflict"
        case .processing: "processing"
        case .success: "success"
        }
    }
}
