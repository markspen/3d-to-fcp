import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct ThreeDtoFCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

        Window("3D to Timeline Help", id: "help") {
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
            Button("3D to Timeline Help") {
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
