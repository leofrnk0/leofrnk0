import Foundation

// ANT+ FIT SDK message numbers and base types
enum FITMesgNum {
    static let fileId:      UInt16 = 0
    static let workout:     UInt16 = 26
    static let workoutStep: UInt16 = 27
}

enum FITBaseType: UInt8 {
    case enumType  = 0x00   // 1 byte
    case uint8     = 0x02   // 1 byte
    case uint16    = 0x84   // 2 bytes LE
    case uint32    = 0x86   // 4 bytes LE
    case string    = 0x07   // fixed-size, null-padded

    var size: Int {
        switch self {
        case .enumType, .uint8:  1
        case .uint16:            2
        case .uint32:            4
        case .string:            0   // caller specifies size
        }
    }
}

struct FITFieldDef {
    let number:   UInt8
    let size:     UInt8
    let baseType: FITBaseType
}

// MARK: - File ID fields (mesg_num = 0)

let kFileIDFields: [FITFieldDef] = [
    FITFieldDef(number: 0, size: 1, baseType: .enumType),  // type: 5 = workout
    FITFieldDef(number: 1, size: 2, baseType: .uint16),    // manufacturer: 1 = Garmin
    FITFieldDef(number: 2, size: 2, baseType: .uint16),    // product
    FITFieldDef(number: 4, size: 4, baseType: .uint32),    // time_created
]

// MARK: - Workout fields (mesg_num = 26)

let kWorkoutFields: [FITFieldDef] = [
    FITFieldDef(number: 4, size: 1,  baseType: .enumType), // sport
    FITFieldDef(number: 8, size: 16, baseType: .string),   // wkt_name (16 chars)
    FITFieldDef(number: 6, size: 2,  baseType: .uint16),   // num_valid_steps
]

// MARK: - WorkoutStep fields (mesg_num = 27)

let kWorkoutStepFields: [FITFieldDef] = [
    FITFieldDef(number: 254, size: 2,  baseType: .uint16),   // message_index
    FITFieldDef(number: 0,   size: 16, baseType: .string),   // wkt_step_name
    FITFieldDef(number: 1,   size: 1,  baseType: .enumType), // duration_type (0 = time)
    FITFieldDef(number: 2,   size: 4,  baseType: .uint32),   // duration_value (ms)
    FITFieldDef(number: 3,   size: 1,  baseType: .enumType), // target_type
    FITFieldDef(number: 4,   size: 4,  baseType: .uint32),   // target_value
    FITFieldDef(number: 7,   size: 1,  baseType: .enumType), // intensity
]
