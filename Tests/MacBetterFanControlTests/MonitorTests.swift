import Foundation
import Testing
@testable import MacBetterFanControl

private func sample(_ temperature: Double = 50, at date: Date = Date()) -> HardwareSnapshot {
    HardwareSnapshot(sampledAt: date, fans: [], fanIssue: nil,
                     temperatures: [TemperatureReading(id: "TB0T", temperature: Reading { temperature })], sensorIssue: nil)
}

@Test func staleAndFutureSamplesAreNotLive() {
    let date = Date(timeIntervalSince1970: 1_000)
    let reading = sample(at: date)
    #expect(reading.isFresh(at: date.addingTimeInterval(4), interval: 2))
    #expect(!reading.isFresh(at: date.addingTimeInterval(6), interval: 2))
    #expect(!reading.isFresh(at: date.addingTimeInterval(-1), interval: 2))
    #expect(reading.isFresh(at: date.addingTimeInterval(20), interval: 10))
    #expect(!reading.isFresh(at: date.addingTimeInterval(26), interval: 10))
}

@Test func failedReadingsAndFanlessHardwareStayDistinct() {
    let failed = Reading { throw HardwareError.unavailable("Access denied") }
    #expect(failed.value == nil)
    #expect(failed.issue == "Access denied")
    let fanless = HardwareSnapshot(sampledAt: Date(), fans: [], fanIssue: nil, temperatures: [], sensorIssue: nil)
    let failedQuery = HardwareSnapshot(sampledAt: Date(), fans: [], fanIssue: "Access denied", temperatures: [], sensorIssue: nil)
    #expect(!fanless.hasIssues)
    #expect(failedQuery.hasIssues)
    let invalidLimits = FanReading(id: 0, speed: Reading { 0 }, minimum: Reading { 5_000 }, maximum: Reading { 1_000 }, target: failed, mode: failed)
    #expect(invalidLimits.limits == nil)
    #expect(invalidLimits.speed.value == 0)
    #expect(invalidLimits.modeLabel == "Control mode unavailable")
}

@Test @MainActor func preferencesPersistAndRejectInvalidSavedValues() throws {
    let name = "MBF-tests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    defaults.set(0, forKey: "refreshInterval")
    defaults.set("kelvin", forKey: "temperatureUnit")
    defaults.set(["bad", "F0Ac", "TB0T"], forKey: "favoriteSensors")
    let settings = MonitorSettings(defaults: defaults)
    #expect(settings.interval == 2)
    #expect(settings.unit == .celsius)
    #expect(settings.favoriteSensors == ["TB0T"])
    settings.interval = 5
    settings.unit = .fahrenheit
    settings.menuSensor = "TB0T"
    settings.toggleFavorite("TB1T")
    let restored = MonitorSettings(defaults: defaults)
    #expect(restored.interval == 5)
    #expect(restored.unit == .fahrenheit)
    #expect(restored.menuSensor == "TB0T")
    #expect(restored.favoriteSensors == ["TB0T", "TB1T"])
    settings.menuSensor = SensorGroup.cpu.menuID
    #expect(MonitorSettings(defaults: defaults).menuSensor == "group:cpu")
}

private actor ControlledReader: HardwareReading {
    private var pending: CheckedContinuation<HardwareSnapshot, any Error>?
    private(set) var reads = 0
    private(set) var disconnects = 0

    func read() async throws -> HardwareSnapshot {
        reads += 1
        return try await withCheckedThrowingContinuation { pending = $0 }
    }

    func complete(_ result: Result<HardwareSnapshot, any Error>) {
        pending?.resume(with: result)
        pending = nil
    }

    func disconnect() { disconnects += 1 }
}

@MainActor private func waitFor(_ condition: () async -> Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: .seconds(3))
    while !(await condition()) {
        guard ContinuousClock.now < deadline else { throw HardwareError.unavailable("Test timed out") }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@Test @MainActor func onePollingOwnerDiscardsCancelledReadAndReconnects() async throws {
    let reader = ControlledReader()
    let model = MonitorModel(reader: reader)
    defer { model.pause() }
    model.start()
    model.start()
    try await waitFor { await reader.reads == 1 }
    model.pause()
    #expect(model.status == "Monitoring paused")
    #expect(!model.isLive)
    model.restart()
    await reader.complete(.success(sample(20)))
    try await waitFor { await reader.reads == 2 }
    #expect(model.snapshot == nil)
    await reader.complete(.success(sample(70)))
    try await waitFor { model.isLive }
    #expect(model.snapshot?.temperatures.first?.temperature.value == 70)
    model.pause()
    #expect(!model.isLive)
    #expect(model.menuTemperature == nil)
    try await waitFor { await reader.disconnects >= 3 }
}

@Test @MainActor func failedConnectionCanBeRetried() async throws {
    let reader = ControlledReader()
    let model = MonitorModel(reader: reader)
    defer { model.pause() }
    model.start()
    try await waitFor { await reader.reads == 1 }
    await reader.complete(.failure(HardwareError.unavailable("Permission denied")))
    try await waitFor { model.error != nil }
    #expect(model.status == "Connection failed")
    #expect(!model.isLive)
    model.restart()
    try await waitFor { await reader.reads == 2 }
    await reader.complete(.success(sample()))
    try await waitFor { model.isLive }
    #expect(model.error == nil)
}

@Test @MainActor func fullyUnavailableSampleReleasesConnectionForRediscovery() async throws {
    let reader = ControlledReader()
    let model = MonitorModel(reader: reader)
    defer { model.pause() }
    model.start()
    try await waitFor { await reader.reads == 1 }
    await reader.complete(.success(HardwareSnapshot(sampledAt: Date(), fans: [], fanIssue: "Read failed",
                                                    temperatures: [], sensorIssue: "Read failed")))
    try await waitFor { await reader.disconnects >= 2 }
    #expect(model.status == "Readings unavailable")
    #expect(!model.isLive)
}
