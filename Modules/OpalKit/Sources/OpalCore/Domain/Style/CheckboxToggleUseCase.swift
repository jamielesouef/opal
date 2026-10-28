//
//  CheckboxToggleUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum CheckboxToggleUseCase {
    // MARK: - Toggle

    public static func toggle(onLine line: Int, in text: String) -> CheckboxToggle? {
        let starts = TextLineUseCase.lineStartOffsets(in: text)
        guard starts.indices.contains(line) else {
            return nil
        }

        let nsText = text as NSString
        let end = starts.indices.contains(line + 1) ? starts[line + 1] - 1 : nsText.length
        let lineText = nsText.substring(with: NSRange(location: starts[line], length: max(end - starts[line], 0)))
        guard let match = lineText.prefixMatch(of: /^[ \t]*(?:>[ \t]?)*(?:[-*+]|\d{1,9}[.)])[ \t]+\[([ xX])\]/) else {
            return nil
        }

        let state = lineText.utf16.distance(from: lineText.utf16.startIndex, to: match.1.startIndex.samePosition(in: lineText.utf16) ?? lineText.utf16.startIndex)
        return CheckboxToggle(span: TextSpan(location: starts[line] + state, length: 1), replacement: match.1 == " " ? "x" : " ")
    }

    public static func toggle(at offset: Int, in styles: [TextStyleRun]) -> CheckboxToggle? {
        guard let run = styles.first(where: { $0.span.contains(offset) && $0.kind.isCheckbox }),
              case let .checkbox(isDone) = run.kind,
              run.span.length == 3
        else {
            return nil
        }

        return CheckboxToggle(span: TextSpan(location: run.span.location + 1, length: 1), replacement: isDone ? " " : "x")
    }
}
