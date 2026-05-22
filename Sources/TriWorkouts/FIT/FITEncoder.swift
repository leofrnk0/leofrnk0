import Foundation

// Low-level binary writer for the ANT+ FIT format (little-endian)
final class FITWriter {
    private(set) var bytes: [UInt8] = []

    var count: Int { bytes.count }

    func writeUInt8(_ v: UInt8)  { bytes.append(v) }
    func writeUInt8(_ v: Int)    { bytes.append(UInt8(v & 0xFF)) }

    func writeUInt16LE(_ v: UInt16) {
        bytes.append(UInt8(v & 0xFF))
        bytes.append(UInt8((v >> 8) & 0xFF))
    }

    func writeUInt32LE(_ v: UInt32) {
        bytes.append(UInt8(v & 0xFF))
        bytes.append(UInt8((v >> 8)  & 0xFF))
        bytes.append(UInt8((v >> 16) & 0xFF))
        bytes.append(UInt8((v >> 24) & 0xFF))
    }

    // Fixed-length null-padded UTF-8 string
    func writeString(_ s: String, length: Int) {
        let encoded = Array(s.utf8.prefix(length - 1))
        bytes.append(contentsOf: encoded)
        for _ in encoded.count..<length { bytes.append(0x00) }
    }

    // Overwrite 4 bytes at a given offset (used to backfill data size in header)
    func patchUInt32LE(_ v: UInt32, at offset: Int) {
        bytes[offset]     = UInt8(v & 0xFF)
        bytes[offset + 1] = UInt8((v >> 8)  & 0xFF)
        bytes[offset + 2] = UInt8((v >> 16) & 0xFF)
        bytes[offset + 3] = UInt8((v >> 24) & 0xFF)
    }

    // Overwrite 2 bytes at a given offset
    func patchUInt16LE(_ v: UInt16, at offset: Int) {
        bytes[offset]     = UInt8(v & 0xFF)
        bytes[offset + 1] = UInt8((v >> 8) & 0xFF)
    }

    func toData() -> Data { Data(bytes) }
}

// MARK: - Record builders

extension FITWriter {
    // Write a Definition Message for a given local/global message number
    func writeDefinition(local: UInt8, global: UInt16, fields: [FITFieldDef]) {
        writeUInt8(0x40 | (local & 0x0F)) // definition record header
        writeUInt8(0x00)                   // reserved
        writeUInt8(0x00)                   // architecture: little-endian
        writeUInt16LE(global)
        writeUInt8(UInt8(fields.count))
        for f in fields {
            writeUInt8(f.number)
            writeUInt8(f.size)
            writeUInt8(f.baseType.rawValue)
        }
    }

    // Write a Data Message header (local message number only; caller writes field values)
    func writeDataHeader(local: UInt8) {
        writeUInt8(local & 0x0F)
    }
}
