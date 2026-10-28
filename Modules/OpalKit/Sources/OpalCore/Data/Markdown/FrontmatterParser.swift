//
//  FrontmatterParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum FrontmatterParser {
    // MARK: - Constants

    private enum Pattern {
        static let key = MarkdownNoteParser.regex(#"^([^\s#:\-][^:]*?|-[^\s:][^:]*?)[ \t]*:(?:[ \t]+(.*?))?[ \t]*$"#)
    }

    private enum Constants {
        static let delimiter = "---"
        static let maximumLength = 65536
    }

    // MARK: - Parse

    public static func parse(_ text: String) -> Frontmatter? {
        guard text.hasPrefix(Constants.delimiter) else {
            return nil
        }

        let lines = MarkdownNoteParser.splitLines(String(text.prefix(Constants.maximumLength)))
        let end = MarkdownNoteParser.frontmatterLineCount(lines)
        guard end > 0 else {
            return nil
        }

        var properties: [Property] = []
        var isReadable = true
        var index = 1
        while index < end - 1 {
            let line = lines[index].text
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                index += 1
                continue
            }

            guard line.first?.isWhitespace == false, let match = Pattern.key.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) else {
                isReadable = false
                index += 1
                continue
            }

            let nsLine = line as NSString
            let key = nsLine.substring(with: match.range(at: 1))
            let rest = match.range(at: 2).location == NSNotFound ? "" : nsLine.substring(with: match.range(at: 2))
            let start = index
            index += 1
            var nested: [String] = []
            while index < end - 1, lines[index].text.first?.isWhitespace == true || lines[index].text.hasPrefix("- ") || lines[index].text == "-" {
                nested.append(lines[index].text)
                index += 1
            }
            properties.append(Property(key: key, value: value(rest, nested: nested), lines: start ..< index))
        }
        return Frontmatter(properties: properties, endLine: end, isReadable: isReadable)
    }

    // MARK: - Values

    private static func value(_ rest: String, nested: [String]) -> PropertyValue {
        let items = nested.map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
        if rest.isEmpty {
            guard items.isEmpty == false else {
                return .text("")
            }

            guard items.allSatisfy({ $0 == "-" || $0.hasPrefix("- ") }) else {
                return .unreadable(([rest] + nested).joined(separator: "\n"))
            }
            return .list(items.map { unquoted(String($0.dropFirst()).trimmingCharacters(in: .whitespaces)) }.filter { $0.isEmpty == false })
        }

        guard nested.isEmpty, rest != "|", rest != ">", rest.hasPrefix("{") == false else {
            return .unreadable(([rest] + nested).joined(separator: "\n"))
        }

        if rest.hasPrefix("["), rest.hasSuffix("]") {
            return .list(rest.dropFirst().dropLast().split(separator: ",").map { unquoted(String($0)) }.filter { $0.isEmpty == false })
        }
        return .text(unquoted(rest))
    }

    private static func unquoted(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, let first = trimmed.first, first == trimmed.last, first == "\"" || first == "'" else {
            return trimmed
        }

        let inner = String(trimmed.dropFirst().dropLast())
        return first == "\"" ? inner.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\\\", with: "\\") : inner.replacingOccurrences(of: "''", with: "'")
    }
}
