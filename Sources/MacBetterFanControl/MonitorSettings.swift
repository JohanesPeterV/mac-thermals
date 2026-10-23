import Foundation
import Observation

@MainActor @Observable
final class MonitorSettings {
    private let defaults: UserDefaults

    var unit: TemperatureUnit {
        didSet { defaults.set(unit.rawValue, forKey: "temperatureUnit") }
    }
    var interval: Int {
        didSet { defaults.set(interval, forKey: "refreshInterval") }
    }
    var favoriteSensors: Set<String> {
        didSet { defaults.set(favoriteSensors.sorted(), forKey: "favoriteSensors") }
    }
    var menuSensor: String {
        didSet { defaults.set(menuSensor, forKey: "menuSensor") }
    }

    static let intervals = [1, 2, 5, 10]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        unit = TemperatureUnit(rawValue: defaults.string(forKey: "temperatureUnit") ?? "") ?? .celsius
        let savedInterval = defaults.integer(forKey: "refreshInterval")
        interval = Self.intervals.contains(savedInterval) ? savedInterval : 2
        favoriteSensors = Set((defaults.stringArray(forKey: "favoriteSensors") ?? []).prefix(512).filter(Self.validKey))
        let savedSensor = defaults.string(forKey: "menuSensor") ?? ""
        menuSensor = Self.validKey(savedSensor) || SensorGroup.allCases.contains { $0.menuID == savedSensor } ? savedSensor : ""
    }

    func toggleFavorite(_ key: String) {
        if favoriteSensors.contains(key) { favoriteSensors.remove(key) }
        else if Self.validKey(key) { favoriteSensors.insert(key) }
    }

    private static func validKey(_ key: String) -> Bool {
        key.utf8.count == 4 && key.hasPrefix("T") && key.utf8.allSatisfy { (32...126).contains($0) }
    }
}
