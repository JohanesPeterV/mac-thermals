import Foundation

enum HardwareError: Error, LocalizedError, Equatable {
    case unavailable(String)
    case missingKey(String)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let message), .invalidData(let message): message
        case .missingKey(let key): "Sensor \(key) is unavailable."
        }
    }
}

struct Reading: Equatable, Sendable {
    let value: Double?
    let issue: String?

    init(_ operation: () throws -> Double) {
        do {
            value = try operation()
            issue = nil
        } catch {
            value = nil
            issue = error.localizedDescription
        }
    }
}

struct FanReading: Identifiable, Sendable {
    let id: Int
    let speed: Reading
    let minimum: Reading
    let maximum: Reading
    let target: Reading
    let mode: Reading

    var name: String { "Fan \(id + 1)" }

    var limits: ClosedRange<Double>? {
        guard let lower = minimum.value, let upper = maximum.value,
              lower >= 0, upper > lower, upper <= 30_000 else { return nil }
        return lower...upper
    }

    var modeLabel: String {
        switch mode.value {
        case 0, 3: "System automatic"
        case 1: "Manual (reported by hardware)"
        default: "Control mode unavailable"
        }
    }
}

struct TemperatureReading: Identifiable, Sendable {
    let id: String
    let temperature: Reading
    let descriptor: SensorDescriptor?

    init(id: String, temperature: Reading, descriptor: SensorDescriptor? = nil) {
        self.id = id
        self.temperature = temperature
        self.descriptor = descriptor
    }

    var name: String { descriptor?.name ?? "Unidentified sensor" }
}

struct HardwareSnapshot: Sendable {
    // Timestamp at the start of acquisition: a slow scan must not freshen old data.
    let sampledAt: Date
    let fans: [FanReading]
    let fanIssue: String?
    let temperatures: [TemperatureReading]
    let sensorIssue: String?

    var hasReadings: Bool {
        fans.contains { $0.speed.value != nil } || temperatures.contains { $0.temperature.value != nil }
    }

    var hasIssues: Bool {
        fanIssue != nil || sensorIssue != nil || fans.contains {
            $0.speed.value == nil || $0.limits == nil || $0.target.value == nil || $0.mode.value == nil
        }
            || temperatures.contains { $0.temperature.value == nil }
    }

    func isFresh(at date: Date, interval: Int) -> Bool {
        let age = date.timeIntervalSince(sampledAt)
        return age >= 0 && age <= max(5, Double(interval) * 2.5)
    }
}

protocol HardwareReading: Sendable {
    func read() async throws -> HardwareSnapshot
    func disconnect() async
}

enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius, fahrenheit

    var symbol: String { self == .celsius ? "°C" : "°F" }

    func formatted(_ celsius: Double) -> String {
        let value = self == .celsius ? celsius : celsius * 9 / 5 + 32
        return "\(value.formatted(.number.precision(.fractionLength(1)))) \(symbol)"
    }
}

func formattedRPM(_ value: Double) -> String {
    "\(value.formatted(.number.precision(.fractionLength(0)))) RPM"
}
