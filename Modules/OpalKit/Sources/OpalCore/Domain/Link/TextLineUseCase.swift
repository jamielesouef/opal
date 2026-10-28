//
//  TextLineUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum TextLineUseCase {
    // MARK: - Offsets

    public static func utf16Offset(ofLine line: Int, in text: String) -> Int {
        guard line > 0 else {
            return 0
        }

        var current = 0
        var offset = 0
        for unit in text.utf16 {
            offset += 1
            if unit == 0x0A {
                current += 1
                if current == line {
                    return offset
                }
            }
        }
        return text.utf16.count
    }

    public static func line(atOffset offset: Int, in text: String) -> Int {
        text.utf16.prefix(max(offset, 0)).reduce(0) { $0 + ($1 == 0x0A ? 1 : 0) }
    }

    public static func lineStartOffsets(in text: String) -> [Int] {
        var offsets = [0]
        var offset = 0
        for unit in text.utf16 {
            offset += 1
            if unit == 0x0A {
                offsets.append(offset)
            }
        }
        return offsets
    }
}
