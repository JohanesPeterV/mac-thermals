import AppKit
import OSLog
import SwiftUI

@main
struct MacBetterFanControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Mac Better Fan Control", id: "dashboard") {
            MonitorView()
        }
        .defaultSize(width: 900, height: 520)
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            FanMenu()
        } label: {
            Image(nsImage: AppLogo.image)
                .accessibilityLabel("Mac Better Fan Control")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "local.mac-better-fan-control", category: "lifecycle")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        logger.info("Application started; hardware integration is not connected.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("Application stopped.")
    }
}

private struct FanMenu: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Hardware connection pending")

        Button("Show Mac Better Fan Control") {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Quit Mac Better Fan Control") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
