import Foundation

// Encodes a Workout into a valid ANT+ FIT workout file
enum WorkoutToFIT {
    static func encode(_ workout: Workout) -> Data {
        let w = FITWriter()

        // ── 1. File header placeholder (14 bytes) ────────────────────────────
        // Bytes 0-3: header size + protocol + profile
        w.writeUInt8(0x0E)               // header size = 14
        w.writeUInt8(0x10)               // protocol version 1.0
        w.writeUInt16LE(0x0800)          // profile version
        let dataSizeOffset = w.count
        w.writeUInt32LE(0x00000000)      // data size placeholder (patched later)
        w.writeUInt8(0x2E)               // '.'
        w.writeUInt8(0x46)               // 'F'
        w.writeUInt8(0x49)               // 'I'
        w.writeUInt8(0x54)               // 'T'
        let headerCRCOffset = w.count
        w.writeUInt16LE(0x0000)          // header CRC placeholder (patched later)

        let bodyStart = w.count          // = 14

        // ── 2. File ID ────────────────────────────────────────────────────────
        w.writeDefinition(local: 0, global: FITMesgNum.fileId, fields: kFileIDFields)
        w.writeDataHeader(local: 0)
        w.writeUInt8(5)                  // type = workout
        w.writeUInt16LE(1)               // manufacturer = Garmin
        w.writeUInt16LE(0)               // product
        w.writeUInt32LE(UInt32(Date().timeIntervalSince1970) + 631065600) // FIT epoch offset

        // ── 3. Workout ────────────────────────────────────────────────────────
        w.writeDefinition(local: 1, global: FITMesgNum.workout, fields: kWorkoutFields)
        w.writeDataHeader(local: 1)
        w.writeUInt8(workout.sport.fitValue)
        w.writeString(workout.name, length: 16)
        w.writeUInt16LE(UInt16(workout.steps.count))

        // ── 4. WorkoutStep definition (written once, reused for all steps) ────
        w.writeDefinition(local: 2, global: FITMesgNum.workoutStep, fields: kWorkoutStepFields)

        for (idx, step) in workout.steps.enumerated() {
            w.writeDataHeader(local: 2)
            w.writeUInt16LE(UInt16(idx))                           // message_index
            w.writeString(step.description, length: 16)            // wkt_step_name
            w.writeUInt8(0)                                        // duration_type: time
            w.writeUInt32LE(UInt32(step.durationSeconds) * 1000)  // duration_value in ms
            w.writeUInt8(step.targetType.fitValue)                 // target_type
            // target_value: zone index for power/HR, 0 for open
            let targetValue: UInt32 = {
                if let z = step.zone { return z.fitIndex }
                if let n = step.targetZoneNumber { return UInt32(n) }
                return 0
            }()
            w.writeUInt32LE(targetValue)
            w.writeUInt8(step.intensity.fitValue)                  // intensity
        }

        // ── 5. Patch data size ────────────────────────────────────────────────
        let dataSize = UInt32(w.count - bodyStart)
        w.patchUInt32LE(dataSize, at: dataSizeOffset)

        // ── 6. Patch header CRC (over bytes 0..11) ────────────────────────────
        let headerCRC = FITCRC.compute(Array(w.bytes[0..<12]))
        w.patchUInt16LE(headerCRC, at: headerCRCOffset)

        // ── 7. File CRC (over entire body) ───────────────────────────────────
        let fileCRC = FITCRC.compute(Array(w.bytes[bodyStart...]))
        w.writeUInt16LE(fileCRC)

        return w.toData()
    }
}
