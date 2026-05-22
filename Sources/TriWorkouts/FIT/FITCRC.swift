import Foundation

// CRC-16 as specified in the ANT+ FIT SDK
enum FITCRC {
    private static let table: [UInt16] = [
        0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
        0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400
    ]

    static func compute(_ data: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for byte in data {
            var tmp = table[Int(crc & 0x0F)]
            crc = (crc >> 4) & 0x0FFF
            crc = crc ^ tmp ^ table[Int(byte & 0x0F)]
            tmp = table[Int(crc & 0x0F)]
            crc = (crc >> 4) & 0x0FFF
            crc = crc ^ tmp ^ table[Int((byte >> 4) & 0x0F)]
        }
        return crc
    }
}
