import AppKit
import SwiftUI

@main
struct ClawEditApp: App {
    @StateObject private var model = CompanionViewModel()

    init() {
        DispatchQueue.main.async {
            ClawEditArt.applyAppIconIfAvailable()
        }
    }

    var body: some Scene {
        WindowGroup("ClawEdit") {
            ContentView(model: model)
                .frame(minWidth: 920, minHeight: 640)
        }
        .defaultSize(width: 980, height: 700)
        .commands {
            ClawEditMenuCommands()
        }

        Window("About ClawEdit", id: "about-clawedit") {
            AboutClawEditView(model: model)
                .frame(width: 520, height: 420)
        }
        .windowResizability(.contentSize)

        Window("ClawEdit Snake", id: "clawedit-snake") {
            SnakeArcadeView()
                .frame(width: 540, height: 640)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(model: model)
                .frame(width: 520, height: 460)
        }
    }
}

private struct ClawEditMenuCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About ClawEdit") {
                if currentModifierFlags.contains(.option) {
                    openWindow(id: "clawedit-snake")
                } else {
                    openWindow(id: "about-clawedit")
                }
            }
        }
    }

    private var currentModifierFlags: NSEvent.ModifierFlags {
        NSApp.currentEvent?.modifierFlags ?? []
    }
}
