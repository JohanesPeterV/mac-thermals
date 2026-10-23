import Foundation

enum SensorGroup: String, CaseIterable, Identifiable, Sendable {
    case cpu, gpu, memory, battery, storage, display, wireless

    var id: String { rawValue }
    var menuID: String { "group:\(rawValue)" }

    var name: String {
        switch self {
        case .cpu: "CPU"
        case .gpu: "GPU"
        case .memory: "Memory"
        case .battery: "Battery"
        case .storage: "Storage"
        case .display: "Display"
        case .wireless: "Wi-Fi"
        }
    }

    var detail: String {
        switch self {
        case .cpu: "Processor"
        case .gpu: "Graphics"
        case .memory: "Nearby temperature sensors"
        case .battery: "Battery temperature sensors"
        case .storage: "SSD temperature sensors"
        case .display: "Near the display"
        case .wireless: "Near the wireless module"
        }
    }

    var symbol: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "square.3.layers.3d"
        case .memory: "memorychip"
        case .battery: "battery.100percent"
        case .storage: "internaldrive"
        case .display: "display"
        case .wireless: "wifi"
        }
    }
}

struct SensorDescriptor: Sendable {
    let name: String
    let group: SensorGroup
}

struct TemperatureSummary: Identifiable {
    let group: SensorGroup
    let sensors: [TemperatureReading]

    var id: SensorGroup { group }
    var availableCount: Int { sensors.filter { $0.temperature.value != nil }.count }
    var maximum: Double? { sensors.compactMap(\.temperature.value).max() }

    static func make(from sensors: [TemperatureReading]) -> [Self] {
        SensorGroup.allCases.compactMap { group in
            let members = sensors.filter { $0.descriptor?.group == group }
            return members.isEmpty ? nil : Self(group: group, sensors: members)
        }
    }
}

struct SensorCatalog: Sendable {
    private var entries: [String: SensorDescriptor] = [:]

    // REASON: Key meanings change between chip generations (Tp09 is one example).
    // Use exact community-documented mappings, never a prefix-based CPU/GPU guess.
    // Adapted from Stats' MIT-licensed sensor catalogue; see THIRD_PARTY_NOTICES.md.
    init(chip: String) {
        add(["TB0T", "TB1T", "TB2T"], group: .battery, label: "Battery sensor")
        add(["TH0A", "TH0B", "TH0C"], group: .storage, label: "SSD sensor")
        add(["TL0P"], group: .display, label: "Display proximity")
        add(["TW0P"], group: .wireless, label: "Wi-Fi proximity")

        switch chip {
        case "Apple M1", "Apple M1 Pro", "Apple M1 Max", "Apple M1 Ultra":
            add(["Tp09", "Tp0T"], group: .cpu, label: "CPU efficiency sensor")
            add(["Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b"], group: .cpu, label: "CPU performance sensor")
            add(["Tg05", "Tg0D", "Tg0L", "Tg0T"], group: .gpu, label: "GPU sensor")
            add(["Tm02", "Tm06", "Tm08", "Tm09"], group: .memory, label: "Memory sensor")
        case "Apple M2", "Apple M2 Pro", "Apple M2 Max", "Apple M2 Ultra":
            add(["Tp1h", "Tp1t", "Tp1p", "Tp1l"], group: .cpu, label: "CPU efficiency sensor")
            add(["Tp01", "Tp05", "Tp09", "Tp0D", "Tp0X", "Tp0b", "Tp0f", "Tp0j"], group: .cpu, label: "CPU performance sensor")
            add(["Tg0f", "Tg0j"], group: .gpu, label: "GPU sensor")
        case "Apple M3", "Apple M3 Pro", "Apple M3 Max", "Apple M3 Ultra":
            add(["Te05", "Te0L", "Te0P", "Te0S"], group: .cpu, label: "CPU efficiency sensor")
            add(["Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E"], group: .cpu, label: "CPU performance sensor")
            add(["Tf14", "Tf18", "Tf19", "Tf1A", "Tf24", "Tf28", "Tf29", "Tf2A"], group: .gpu, label: "GPU sensor")
        case "Apple M4", "Apple M4 Pro", "Apple M4 Max":
            add(["Te05", "Te0S", "Te09", "Te0H"], group: .cpu, label: "CPU efficiency sensor")
            add(["Tp01", "Tp05", "Tp09", "Tp0D", "Tp0V", "Tp0Y", "Tp0b", "Tp0e"], group: .cpu, label: "CPU performance sensor")
            let gpuKeys = chip == "Apple M4" ? ["Tg0G", "Tg0H"] : ["Tg1U", "Tg1k"]
            add(gpuKeys + ["Tg0K", "Tg0L", "Tg0d", "Tg0e", "Tg0j", "Tg0k"], group: .gpu, label: "GPU sensor")
            add(["Tm0p", "Tm1p", "Tm2p"], group: .memory, label: "Memory proximity sensor")
        case "Apple M5", "Apple M5 Pro", "Apple M5 Max":
            add(["Tp00", "Tp04", "Tp08", "Tp0C", "Tp0G", "Tp0K"], group: .cpu, label: "CPU super core sensor")
            add(["Tp0O", "Tp0R", "Tp0U", "Tp0X", "Tp0a", "Tp0d", "Tp0g", "Tp0j", "Tp0m", "Tp0p", "Tp0u", "Tp0y"], group: .cpu, label: "CPU performance sensor")
            add(["Tg0U", "Tg0X", "Tg0d", "Tg0g", "Tg0j", "Tg1Y", "Tg1c", "Tg1g"], group: .gpu, label: "GPU sensor")
        default: break
        }
    }

    func descriptor(for key: String) -> SensorDescriptor? { entries[key] }

    private mutating func add(_ keys: [String], group: SensorGroup, label: String) {
        for (index, key) in keys.enumerated() {
            entries[key] = SensorDescriptor(name: keys.count == 1 ? label : "\(label) \(index + 1)", group: group)
        }
    }
}
