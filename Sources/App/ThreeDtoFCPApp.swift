import SwiftUI
import AppKit

@main
struct ThreeDtoFCPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 560, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) {}  // hide New Window menu item
            HelpCommands()
        }

        Window("3D to FCP Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 580, height: 680)
        .windowResizability(.contentMinSize)
    }
}

private struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("3D to FCP Help") {
                openWindow(id: "help")
            }
            .keyboardShortcut("?", modifiers: [.command])

            Divider()

            Button("Visit Ripple Training") {
                if let url = URL(string: "https://rippletraining.com") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
