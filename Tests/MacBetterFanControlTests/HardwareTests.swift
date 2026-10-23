import Foundation
import Testing
@testable import MacBetterFanControl

@Test func decodesHardwareNumbersWithoutTreatingZeroAsMissing() throws {
    #expect(try SMCDecoder.number(type: "flt ", bytes: [0, 0, 72, 66]) == 50)
    #expect(try SMCDecoder.number(type: "sp78", bytes: [0xFF, 0x80]) == -0.5)
    #expect(try SMCDecoder.number(type: "fpe2", bytes: [0x1F, 0x40]) == 2_000)
    #expect(try SMCDecoder.number(type: "ui16", bytes: [0x12, 0x34]) == 4_660)
    #expect(try SMCDecoder.number(type: "ui32", bytes: [0, 0, 1, 0]) == 256)
    #expect(try SMCDecoder.rpm(0) == 0)
    #expect(try SMCDecoder.fanCount(0) == 0)
}

@Test func rejectsMalformedAndNonFiniteHardwareValues() {
    #expect(throws: HardwareError.self) { try SMCDecoder.number(type: "flt ", bytes: [0, 0, 0xC0, 0x7F]) }
    #expect(throws: HardwareError.self) { try SMCDecoder.number(type: "flt ", bytes: [0, 0, 0x80, 0x7F]) }
    #expect(throws: HardwareError.self) { try SMCDecoder.number(type: "ui16", bytes: [1]) }
    #expect(throws: HardwareError.self) { try SMCDecoder.number(type: "????", bytes: [1, 2]) }
    #expect(throws: HardwareError.self) { try SMCDecoder.keyCode("TOOLONG") }
    #expect(throws: HardwareError.self) { try SMCDecoder.keyCode("Té0x") }
    #expect(throws: HardwareError.self) { try SMCDecoder.keyString(0) }
    #expect(throws: HardwareError.self) { try SMCDecoder.fanCount(1.5) }
    #expect(throws: HardwareError.self) { try SMCDecoder.rpm(-1) }
    #expect(throws: HardwareError.self) { try SMCDecoder.temperature(0) }
    #expect(throws: HardwareError.self) { try SMCDecoder.temperature(151) }
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["MBF_LIVE_TEST"] == "1"))
func liveHardwareRead() async throws {
    let reader = SMCReader()
    let sample = try await reader.read()
    #expect(sample.hasReadings)
    #expect(Date().timeIntervalSince(sample.sampledAt) < 10)
    print("LIVE: fans=\(sample.fans.count), fanIssue=\(sample.fanIssue ?? "none"), validTemperatures=\(sample.temperatures.filter { $0.temperature.value != nil }.count)/\(sample.temperatures.count)")
    for fan in sample.fans {
        print("LIVE: \(fan.name) RPM=\(String(describing: fan.speed.value)) limits=\(String(describing: fan.limits)) mode=\(fan.modeLabel) target=\(String(describing: fan.target.value))")
    }
    for sensor in sample.temperatures.prefix(8) {
        print("LIVE: \(sensor.id)=\(String(describing: sensor.temperature.value)) °C")
    }
    for group in TemperatureSummary.make(from: sample.temperatures) {
        print("LIVE: \(group.group.name) highest=\(String(describing: group.maximum)) °C from \(group.availableCount)/\(group.sensors.count) mapped sensors")
    }
    await reader.disconnect()
}
