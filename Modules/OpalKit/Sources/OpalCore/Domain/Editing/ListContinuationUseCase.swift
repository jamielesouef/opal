//
//  ListContinuationUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum ListContinuationUseCase {
    // MARK: - Newline

    public static func newline(in text: String, cursor: Int) -> TextEdit? {
        let nsText = text as NSString
        guard cursor >= 0, cursor <= nsText.length else {
            return nil
        }

        let lineRange = nsText.lineRange(for: NSRange(location: cursor, length: 0))
        var contentEnd = NSMaxRange(lineRange)
        while contentEnd > lineRange.location, [0x0A, 0x0D].contains(nsText.character(at: contentEnd - 1)) {
            contentEnd -= 1
        }
        let line = nsText.substring(with: NSRange(location: lineRange.location, length: contentEnd - lineRange.location))
        guard let match = line.wholeMatch(of: /([ \t]*(?:>[ \t]?)*)([-*+]|(\d{1,9})([.)]))([ \t]+)(\[[ xX]\][ \t]+)?(.*)/) else {
            return nil
        }

        let prefixLength = (line as NSString).length - (String(match.7) as NSString).length
        guard cursor - lineRange.location >= prefixLength else {
            return nil
        }

        if match.7.trimmingCharacters(in: .whitespaces).isEmpty, cursor == contentEnd {
            return TextEdit(span: TextSpan(location: lineRange.location, length: contentEnd - lineRange.location), replacement: "")
        }

        let marker: String
        if let number = match.3.flatMap({ Int($0) }), let delimiter = match.4 {
            marker = "\(number + 1)\(delimiter)"
        } else {
            marker = String(match.2)
        }
        let checkbox = match.6 == nil ? "" : "[ ] "
        return TextEdit(span: TextSpan(location: cursor, length: 0), replacement: "\n" + match.1 + marker + match.5 + checkbox)
    }
}
