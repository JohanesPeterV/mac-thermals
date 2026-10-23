import Testing
@testable import MacBetterFanControl

@Test func sensorNamesRespectChipGenerationAndVariant() {
    let m1 = SensorCatalog(chip: "Apple M1 Max")
    let m4 = SensorCatalog(chip: "Apple M4")
    let max = SensorCatalog(chip: "Apple M4 Max")
    #expect(m1.descriptor(for: "Tp09")?.name == "CPU efficiency sensor 1")
    #expect(max.descriptor(for: "Tp09")?.name == "CPU performance sensor 3")
    #expect(m4.descriptor(for: "Tg0G")?.group == .gpu)
    #expect(max.descriptor(for: "Tg0G") == nil)
    #expect(max.descriptor(for: "Tg1U")?.group == .gpu)
    #expect(m4.descriptor(for: "Tg1U") == nil)
    #expect(max.descriptor(for: "Tm0p")?.group == .memory)
}

@Test func unknownKeysDoNotBecomeGuessedCoreTemperatures() {
    let unknown = SensorCatalog(chip: "Apple M999")
    let known = SensorCatalog(chip: "Apple M4 Max")
    #expect(unknown.descriptor(for: "Tp09") == nil)
    #expect(known.descriptor(for: "TCMx") == nil)
    #expect(known.descriptor(for: "TfZZ") == nil)
    #expect(known.descriptor(for: "TB0T")?.group == .battery)
}

@Test func overviewUsesOnlyMappedAvailableReadings() {
    let catalog = SensorCatalog(chip: "Apple M4 Max")
    let readings = [
        TemperatureReading(id: "Tp01", temperature: Reading { 60 }, descriptor: catalog.descriptor(for: "Tp01")),
        TemperatureReading(id: "Tp05", temperature: Reading { 75 }, descriptor: catalog.descriptor(for: "Tp05")),
        TemperatureReading(id: "Tp09", temperature: Reading { throw HardwareError.unavailable("Missing") }, descriptor: catalog.descriptor(for: "Tp09")),
        TemperatureReading(id: "T???", temperature: Reading { 120 }),
        TemperatureReading(id: "TB0T", temperature: Reading { 35 }, descriptor: catalog.descriptor(for: "TB0T"))
    ]
    let summary = TemperatureSummary.make(from: readings)
    #expect(summary.map(\.group) == [.cpu, .battery])
    #expect(summary.first?.maximum == 75)
    #expect(summary.first?.availableCount == 2)
    #expect(summary.first?.sensors.count == 3)
    #expect(summary.last?.maximum == 35)
}

@Test func unavailableComponentNeverDisplaysZero() {
    let reading = TemperatureReading(id: "TB0T", temperature: Reading { throw HardwareError.unavailable("Missing") },
                                     descriptor: SensorCatalog(chip: "Apple M4 Max").descriptor(for: "TB0T"))
    let summary = TemperatureSummary.make(from: [reading])
    #expect(summary.first?.maximum == nil)
    #expect(summary.first?.availableCount == 0)
}
