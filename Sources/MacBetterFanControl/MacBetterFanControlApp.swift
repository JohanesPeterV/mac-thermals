import AppKit
import OSLog
import SwiftUI

@main
struct MacBetterFanControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Mac Better Fan Control", id: "dashboard") {
            MonitorView(model: appDelegate.monitor)
        }
        .defaultSize(width: 980, height: 640)
        .windowResizability(.contentMinSize)

        Settings {
            MonitorSettingsView(settings: appDelegate.monitor.settings)
        }

        MenuBarExtra {
            FanMenu(model: appDelegate.monitor)
        } label: {
            Image(nsImage: AppLogo.image)
                .accessibilityLabel("Mac Better Fan Control")
            if let sensor = appDelegate.monitor.menuTemperature {
                Text(appDelegate.monitor.settings.unit.formatted(sensor.value))
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = MonitorModel()
    private var wasPausedBeforeSleep = false
    private let logger = Logger(subsystem: "local.mac-better-fan-control", category: "lifecycle")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        monitor.start()
        logger.info("Application started with read-only hardware monitoring.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.pause()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        logger.info("Application stopped.")
    }

    @objc private func willSleep(_ notification: Notification) {
        wasPausedBeforeSleep = monitor.isPaused
        monitor.pause()
    }

    @objc private func didWake(_ notification: Notification) {
        if !wasPausedBeforeSleep { monitor.restart() }
    }
}

private struct FanMenu: View {
    let model: MonitorModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(model.status)
        if let snapshot = model.snapshot {
            ForEach(snapshot.fans) { fan in
                Text("\(fan.name): \(model.isLive ? "" : "Last: ")\(fan.speed.value.map(formattedRPM) ?? "Unavailable")")
            }
            if let sensor = model.menuTemperature {
                Text("\(sensor.name): \(model.settings.unit.formatted(sensor.value))")
            }
        }

        Divider()

        Button("Show Mac Better Fan Control") {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button(model.isPaused ? "Resume Monitoring" : "Pause Monitoring") {
            if model.isPaused { model.restart() } else { model.pause() }
        }
        Button("Reconnect to Hardware") { model.restart() }
        SettingsLink()

        Divider()

        Button("Quit Mac Better Fan Control") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
