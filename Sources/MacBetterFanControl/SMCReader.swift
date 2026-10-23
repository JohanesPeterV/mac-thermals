import Foundation
import OSLog
import SMCTransport

actor SMCReader: HardwareReading {
    private var connection: UInt32 = 0
    private var temperatureKeys: [String]?
    private let logger = Logger(subsystem: "local.mac-better-fan-control", category: "hardware")
    private let catalog: SensorCatalog

    init() {
        var bytes = [CChar](repeating: 0, count: 128)
        let result = MBFChipName(&bytes)
        let chip = result == 0 ? String(decoding: bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self) : ""
        catalog = SensorCatalog(chip: chip)
        if result != 0 { logger.error("Chip identification unavailable; model-specific sensor names disabled.") }
    }

    deinit {
        if connection != 0 { MBFClose(connection) }
    }

    func disconnect() {
        if connection != 0 {
            let result = MBFClose(connection)
            if result != 0 { logger.error("AppleSMC close failed: \(result)") }
        }
        connection = 0
        temperatureKeys = nil
    }

    func read() throws -> HardwareSnapshot {
        try Task.checkCancellation()
        if connection == 0 {
            let result = MBFOpen(&connection)
            guard result == 0, connection != 0 else {
                connection = 0
                throw HardwareError.unavailable("Cannot open AppleSMC (IOKit \(result)). Retry after waking or restarting your Mac.")
            }
            logger.info("Read-only AppleSMC connection opened.")
        }

        var sensorIssue: String?
        if temperatureKeys == nil {
            do {
                temperatureKeys = try discoverTemperatures()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                sensorIssue = error.localizedDescription
            }
        }
        let sampledAt = Date()
        var fans: [FanReading] = []
        var fanIssue: String?
        do {
            let count = try SMCDecoder.fanCount(number("FNum"))
            for id in 0..<count {
                try Task.checkCancellation()
                fans.append(FanReading(
                    id: id,
                    speed: Reading { try SMCDecoder.rpm(number("F\(id)Ac")) },
                    minimum: Reading { try SMCDecoder.rpm(number("F\(id)Mn")) },
                    maximum: Reading { try SMCDecoder.rpm(number("F\(id)Mx")) },
                    target: Reading { try SMCDecoder.rpm(number("F\(id)Tg")) },
                    mode: Reading { try fanMode(id) }
                ))
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            fanIssue = error.localizedDescription
        }

        var temperatures: [TemperatureReading] = []
        for key in temperatureKeys ?? [] {
            try Task.checkCancellation()
            temperatures.append(TemperatureReading(id: key, temperature: Reading {
                try SMCDecoder.temperature(number(key))
            }, descriptor: catalog.descriptor(for: key)))
        }
        return HardwareSnapshot(
            sampledAt: sampledAt, fans: fans, fanIssue: fanIssue, temperatures: temperatures,
            sensorIssue: sensorIssue ?? (temperatures.isEmpty ? "No supported temperature channels were found on this Mac." : nil)
        )
    }

    private func discoverTemperatures() throws -> [String] {
        let count = try number("#KEY")
        guard count >= 0, count <= 16_384, count.rounded() == count else {
            throw HardwareError.invalidData("Invalid SMC key count.")
        }
        var keys: Set<String> = []
        for index in 0..<Int(count) {
            try Task.checkCancellation()
            var key: UInt32 = 0
            var result: UInt8 = 0
            var status: UInt8 = 0
            let code = MBFKeyAtIndex(connection, UInt32(index), &key, &result, &status)
            try check(code: code, result: result, status: status, key: "key index")
            let name = try SMCDecoder.keyString(key)
            guard name.hasPrefix("T") else { continue }
            let payload = try readKey(name)
            // A T-prefix alone is not enough; admit only thermal number encodings.
            if payload.type == "flt " || payload.type == "sp78" { keys.insert(name) }
            guard keys.count <= 512 else {
                throw HardwareError.invalidData("Too many thermal channels were reported by AppleSMC.")
            }
        }
        logger.info("Discovered \(keys.count) temperature channels.")
        return keys.sorted()
    }

    private func fanMode(_ id: Int) throws -> Double {
        let value: Double
        do {
            value = try number("F\(id)md")
        } catch HardwareError.missingKey {
            value = try number("F\(id)Md")
        }
        guard [0, 1, 3].contains(value) else {
            throw HardwareError.invalidData("Unrecognised fan control mode.")
        }
        return value
    }

    private func number(_ key: String) throws -> Double {
        let payload = try readKey(key)
        return try SMCDecoder.number(type: payload.type, bytes: payload.bytes)
    }

    private func readKey(_ key: String) throws -> (type: String, bytes: [UInt8]) {
        var type: UInt32 = 0
        var bytes = [UInt8](repeating: 0, count: 32)
        var size: UInt32 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        let code = MBFRead(connection, try SMCDecoder.keyCode(key), &type, &bytes, &size, &result, &status)
        try check(code: code, result: result, status: status, key: key)
        guard (1...32).contains(size) else { throw HardwareError.invalidData("Invalid SMC payload size.") }
        return (try SMCDecoder.keyString(type), Array(bytes.prefix(Int(size))))
    }

    private func check(code: Int32, result: UInt8, status: UInt8, key: String) throws {
        guard code == 0 else { throw HardwareError.unavailable("AppleSMC read failed (IOKit \(code)).") }
        if result == 0x84 { throw HardwareError.missingKey(key) }
        guard result == 0, status == 0 else {
            throw HardwareError.unavailable("AppleSMC rejected a read (result \(result), status \(status)).")
        }
    }
}
