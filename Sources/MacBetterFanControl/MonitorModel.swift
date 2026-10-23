import Foundation
import Observation
import OSLog

@MainActor @Observable
final class MonitorModel {
    let settings: MonitorSettings
    private(set) var snapshot: HardwareSnapshot?
    private(set) var error: String?
    private(set) var isPaused = false
    private(set) var isRefreshing = false
    private(set) var now = Date()
    private let reader: any HardwareReading
    private let logger = Logger(subsystem: "local.mac-better-fan-control", category: "monitoring")
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var clockTask: Task<Void, Never>?
    private var session = UUID()
    private var lastLoggedIssue: String?

    init(reader: any HardwareReading = SMCReader(), settings: MonitorSettings = MonitorSettings()) {
        self.reader = reader
        self.settings = settings
    }

    deinit {
        pollTask?.cancel()
        clockTask?.cancel()
    }

    var isLive: Bool {
        guard !isPaused, error == nil, let snapshot, snapshot.hasReadings else { return false }
        return snapshot.isFresh(at: now, interval: settings.interval)
    }

    var status: String {
        if isPaused { return "Monitoring paused" }
        if error != nil { return snapshot?.hasReadings == true ? "Readings stale" : "Connection failed" }
        guard let snapshot else { return "Connecting…" }
        if !snapshot.hasReadings { return "Readings unavailable" }
        if !isLive { return "Readings stale" }
        return snapshot.hasIssues ? "Live · some unavailable" : "Live"
    }

    var summaries: [TemperatureSummary] {
        TemperatureSummary.make(from: snapshot?.temperatures ?? [])
    }

    var menuTemperature: (name: String, value: Double)? {
        guard isLive, !settings.menuSensor.isEmpty else { return nil }
        if let group = summaries.first(where: { $0.group.menuID == settings.menuSensor }), let value = group.maximum {
            return ("\(group.group.name) · highest", value)
        }
        guard let sensor = snapshot?.temperatures.first(where: { $0.id == settings.menuSensor }),
              let value = sensor.temperature.value else { return nil }
        return (sensor.descriptor?.name ?? sensor.id, value)
    }

    func start() {
        guard pollTask == nil else { return }
        restart()
    }

    func restart() {
        let previous = pollTask
        previous?.cancel()
        session = UUID()
        let currentSession = session
        isPaused = false
        isRefreshing = true
        error = nil
        snapshot = nil
        now = Date()
        startClock()
        pollTask = Task { [weak self, reader] in
            await previous?.value
            await reader.disconnect()
            guard !Task.isCancelled else { return }
            while !Task.isCancelled {
                guard let self, self.session == currentSession else { break }
                self.isRefreshing = true
                do {
                    let sample = try await reader.read()
                    guard !Task.isCancelled, self.session == currentSession else { break }
                    self.snapshot = sample
                    self.now = Date()
                    self.error = nil
                    let issue = sample.fanIssue ?? sample.sensorIssue
                        ?? (sample.hasIssues ? "Some hardware readings are unavailable." : nil)
                    self.logIssue(issue)
                    if !sample.hasReadings { await reader.disconnect() }
                } catch is CancellationError {
                    break
                } catch {
                    guard !Task.isCancelled, self.session == currentSession else { break }
                    self.error = error.localizedDescription
                    self.logIssue(error.localizedDescription)
                    await reader.disconnect()
                }
                self.isRefreshing = false
                let hasLiveSource = self.error == nil && self.snapshot?.hasReadings == true
                let delay = hasLiveSource ? self.settings.interval : max(5, self.settings.interval)
                do { try await Task.sleep(for: .seconds(delay)) }
                catch { break }
            }
            await reader.disconnect()
        }
    }

    func pause() {
        isPaused = true
        isRefreshing = false
        session = UUID()
        pollTask?.cancel()
        // Retain the cancelled task so a restart waits for its connection cleanup.
        clockTask?.cancel()
        clockTask = nil
        logger.info("Monitoring paused; hardware access is read-only.")
    }

    private func startClock() {
        guard clockTask == nil else { return }
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
                self?.now = Date()
            }
        }
    }

    private func logIssue(_ issue: String?) {
        guard issue != lastLoggedIssue else { return }
        lastLoggedIssue = issue
        if let issue { logger.error("Monitoring issue: \(issue, privacy: .public)") }
        else { logger.info("Hardware readings recovered.") }
    }
}
