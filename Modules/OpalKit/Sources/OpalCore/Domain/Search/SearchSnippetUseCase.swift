//
//  SearchSnippetUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum SearchSnippetUseCase {
    // MARK: - Constants

    public static let maxLines = 3
    public static let maxLineLength = 160

    private static let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    // MARK: - Result

    public static func result(for path: NotePath, text: String, query: SearchQuery) -> SearchResult {
        let terms = query.highlightTerms.filter { $0.isEmpty == false }
        let frontmatterTerms = terms + query.tags
        let rawLines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let frontmatterEnd = frontmatterLineCount(rawLines)
        var lines: [SearchLine] = []
        var count = 0
        for (index, line) in rawLines.enumerated() {
            let spans = matches(of: index < frontmatterEnd ? frontmatterTerms : terms, in: line)
            guard spans.isEmpty == false else {
                continue
            }

            count += spans.count
            if lines.count < maxLines {
                lines.append(trimmed(SearchLine(line: index, text: line, highlights: spans)))
            }
        }
        return SearchResult(path: path, lines: lines, matchCount: count)
    }

    // MARK: - Filters

    public static func passesFilters(_ path: NotePath, text: String, query: SearchQuery) -> Bool {
        let fileOK = query.files.allSatisfy { path.fileName.range(of: $0, options: options) != nil }
        let pathOK = query.paths.allSatisfy { path.rawValue.range(of: $0, options: options) != nil }
        let excludedOK = query.excluded.allSatisfy { text.range(of: $0, options: options) == nil }
        return fileOK && pathOK && excludedOK
    }

    // MARK: - Private

    private static func frontmatterLineCount(_ lines: [String]) -> Int {
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return 0
        }

        let end = lines.dropFirst().firstIndex { $0.trimmingCharacters(in: .whitespaces) == "---" }
        return end.map { $0 + 1 } ?? 0
    }

    private static func matches(of terms: [String], in line: String) -> [TextSpan] {
        let nsLine = line as NSString
        var spans: [TextSpan] = []
        for term in terms {
            var searchRange = NSRange(location: 0, length: nsLine.length)
            while searchRange.length > 0 {
                let found = nsLine.range(of: term, options: options, range: searchRange)
                guard found.location != NSNotFound else {
                    break
                }
                spans.append(TextSpan(location: found.location, length: found.length))
                let next = found.location + max(found.length, 1)
                searchRange = NSRange(location: next, length: nsLine.length - next)
            }
        }
        return spans.sorted { $0.location < $1.location }
    }

    private static func trimmed(_ line: SearchLine) -> SearchLine {
        let nsText = line.text as NSString
        guard nsText.length > maxLineLength, let first = line.highlights.first else {
            return line
        }

        let start = max(0, min(first.location - maxLineLength / 4, nsText.length - maxLineLength))
        let text = (start > 0 ? "…" : "") + nsText.substring(with: NSRange(location: start, length: maxLineLength)) + "…"
        let shift = start > 0 ? start - 1 : start
        let spans = line.highlights
            .map { TextSpan(location: $0.location - shift, length: $0.length) }
            .filter { $0.location >= 0 && $0.upperBound <= (text as NSString).length }
        return SearchLine(line: line.line, text: text, highlights: spans)
    }
}
