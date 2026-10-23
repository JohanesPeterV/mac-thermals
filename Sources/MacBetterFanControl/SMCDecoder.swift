import Foundation

enum SMCDecoder {
    static func keyCode(_ key: String) throws -> UInt32 {
        let bytes = Array(key.utf8)
        guard bytes.count == 4, bytes.allSatisfy({ (32...126).contains($0) }) else {
            throw HardwareError.invalidData("Invalid SMC key.")
        }
        return bytes.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    static func keyString(_ code: UInt32) throws -> String {
        let bytes = [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: code >> $0) }
        guard bytes.allSatisfy({ (32...126).contains($0) }) else {
            throw HardwareError.invalidData("Invalid SMC key encoding.")
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    static func number(type: String, bytes: [UInt8]) throws -> Double {
        let value: Double
        switch (type, bytes.count) {
        case ("ui8 ", 1): value = Double(bytes[0])
        case ("ui16", 2): value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        case ("ui32", 4): value = Double(bytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
        case ("flt ", 4):
            // REASON: SMC floats on Apple Silicon are little-endian IEEE 754.
            let bits = bytes.enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << ($1.offset * 8) }
            value = Double(Float(bitPattern: bits))
        case ("sp78", 2):
            value = Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
        case ("fpe2", 2): value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
        default: throw HardwareError.invalidData("Unsupported SMC encoding \(type) or payload size.")
        }
        guard value.isFinite else { throw HardwareError.invalidData("The sensor returned a non-finite value.") }
        return value
    }

    static func rpm(_ value: Double) throws -> Double {
        guard value.isFinite, (0...30_000).contains(value) else {
            throw HardwareError.invalidData("The fan returned an invalid RPM reading.")
        }
        return value
    }

    static func temperature(_ value: Double) throws -> Double {
        // Zero-valued thermal channels commonly represent inactive sensors.
        // Do not use those channels as a live temperature or control input.
        guard value.isFinite, value > 0, value <= 150 else {
            throw HardwareError.invalidData("The temperature channel is inactive or outside the valid range.")
        }
        return value
    }

    static func fanCount(_ value: Double) throws -> Int {
        guard value.isFinite, (0...10).contains(value), value.rounded() == value else {
            throw HardwareError.invalidData("The hardware returned an invalid fan count.")
        }
        return Int(value)
    }
}
