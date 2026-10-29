//
//  FrontmatterFoldUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public enum FrontmatterFoldUseCase {
    // MARK: - Constants

    private enum Constants {
        static let delimiter = Array("---".utf16)
        static let terminator = Array("...".utf16)
        static let scanLimit = 65536
        static let newline: UInt16 = 0x0A
        static let carriageReturn: UInt16 = 0x0D
        static let space: UInt16 = 0x20
        static let tab: UInt16 = 0x09
    }

    // MARK: - Fold

    public static func fold(in text: String) -> FrontmatterFold? {
        var line: [UInt16] = []
        var heading: Int?
        var offset = 0
        for unit in text.utf16 {
            offset += 1
            guard offset <= Constants.scanLimit else {
                return nil
            }

            guard unit == Constants.newline else {
                line.append(unit)
                continue
            }

            if let heading {
                if closes(line) {
                    return FrontmatterFold(headingLength: heading, end: offset)
                }
            } else if trimmed(line).elementsEqual(Constants.delimiter) {
                heading = offset
            } else {
                return nil
            }
            line.removeAll(keepingCapacity: true)
        }

        guard let heading, closes(line) else {
            return nil
        }

        return FrontmatterFold(headingLength: heading, end: offset)
    }

    // MARK: - Private

    private static func closes(_ line: [UInt16]) -> Bool {
        let content = trimmed(line)
        return content.elementsEqual(Constants.delimiter) || content.elementsEqual(Constants.terminator)
    }

    private static func trimmed(_ line: [UInt16]) -> ArraySlice<UInt16> {
        var content = line[...]
        if content.last == Constants.carriageReturn {
            content = content.dropLast()
        }
        while let last = content.last, last == Constants.space || last == Constants.tab {
            content = content.dropLast()
        }
        return content
    }
}
