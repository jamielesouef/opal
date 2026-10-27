//
//  UnlinkedMentionUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum UnlinkedMentionUseCase {
    // MARK: - Find

    public static func mentions(of names: [String], in text: String, parsed: ParsedNote, source: NotePath) -> [UnlinkedMention] {
        let nsText = text as NSString
        let blocked = parsed.skippedSpans + parsed.links.map(\.span)
        let lineStarts = TextLineUseCase.lineStartOffsets(in: text)
        var found: [UnlinkedMention] = []
        var taken: [TextSpan] = []
        for name in names.filter({ $0.isEmpty == false }).sorted(by: { $0.count > $1.count }) {
            var searchRange = NSRange(location: 0, length: nsText.length)
            while searchRange.length > 0 {
                let range = nsText.range(of: name, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
                guard range.location != NSNotFound else {
                    break
                }
                searchRange = NSRange(location: range.upperBound, length: nsText.length - range.upperBound)
                let span = TextSpan(location: range.location, length: range.length)
                guard isWholeWord(range, in: nsText), overlapsAny(span, blocked + taken) == false else {
                    continue
                }

                taken.append(span)
                let line = (lineStarts.lastIndex { $0 <= range.location }) ?? 0
                let lineEnd = line + 1 < lineStarts.count ? lineStarts[line + 1] - 1 : nsText.length
                found.append(UnlinkedMention(
                    source: source,
                    span: span,
                    matchedText: nsText.substring(with: range),
                    line: line,
                    lineText: nsText.substring(with: NSRange(location: lineStarts[line], length: max(0, lineEnd - lineStarts[line])))
                ))
            }
        }
        return found.sorted { $0.span.location < $1.span.location }
    }

    // MARK: - Link

    public static func replacement(for mention: UnlinkedMention, target: String, targetName: String) -> String {
        mention.matchedText == targetName ? "[[\(target)]]" : "[[\(target)|\(mention.matchedText)]]"
    }

    public static func linking(_ mention: UnlinkedMention, in text: String, target: String, targetName: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: mention.span.location, length: mention.span.length)
        guard range.upperBound <= nsText.length, nsText.substring(with: range) == mention.matchedText else {
            return nil
        }

        return nsText.replacingCharacters(in: range, with: replacement(for: mention, target: target, targetName: targetName))
    }

    // MARK: - Private

    private static func isWholeWord(_ range: NSRange, in text: NSString) -> Bool {
        let before = range.location > 0 ? text.character(at: range.location - 1) : nil
        let after = range.upperBound < text.length ? text.character(at: range.upperBound) : nil
        return [before, after].allSatisfy { unit in
            guard let unit, let scalar = Unicode.Scalar(unit) else {
                return true
            }
            return CharacterSet.alphanumerics.contains(scalar) == false && scalar != "_"
        }
    }

    private static func overlapsAny(_ span: TextSpan, _ others: [TextSpan]) -> Bool {
        others.contains { span.location < $0.upperBound && $0.location < span.upperBound }
    }
}
