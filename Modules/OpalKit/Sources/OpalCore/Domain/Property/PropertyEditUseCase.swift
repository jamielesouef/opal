//
//  PropertyEditUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum PropertyEditUseCase {
    // MARK: - Constants

    private enum Constants {
        static let listIndent = "  "
        static let delimiter = "---"
        static let specialStarts: Set<Character> = ["[", "]", "{", "}", "&", "*", "!", "|", ">", "'", "\"", "%", "@", "`", ",", "#", "-", "?", ":"]
        static let reserved: Set<String> = ["true", "false", "null", "yes", "no", "~"]
    }

    // MARK: - Edits

    public static func set(_ property: Property, to value: PropertyValue, type: PropertyType, in text: String) -> String {
        var lines = split(text)
        let ending = lineEnding(lines)
        lines.replaceSubrange(property.lines, with: render(key: property.key, value: value, type: type, ending: ending))
        return lines.joined()
    }

    public static func remove(_ property: Property, from text: String) -> String {
        var lines = split(text)
        lines.removeSubrange(property.lines)
        return lines.joined()
    }

    public static func add(key: String, type: PropertyType, to text: String, frontmatter: Frontmatter?) -> String {
        var lines = split(text)
        let ending = lineEnding(lines)
        let value: PropertyValue = [.list, .tags, .aliases].contains(type) ? .list([]) : .text("")
        let new = render(key: key, value: value, type: type, ending: ending)
        guard let frontmatter else {
            return ([Constants.delimiter + ending] + new + [Constants.delimiter + ending]).joined() + text
        }

        var closing = lines[frontmatter.endLine - 1]
        if closing.hasSuffix("\n") == false {
            closing += ending
            lines[frontmatter.endLine - 1] = closing
        }
        lines.insert(contentsOf: new, at: frontmatter.endLine - 1)
        return lines.joined()
    }

    // MARK: - Render

    static func render(key: String, value: PropertyValue, type: PropertyType, ending: String) -> [String] {
        switch value {
        case let .unreadable(raw):
            return ("\(key):" + (raw.hasPrefix("\n") || raw.isEmpty ? "" : " ") + raw).split(separator: "\n", omittingEmptySubsequences: false).map { $0 + ending }
        case let .list(items):
            guard items.isEmpty == false else {
                return ["\(key): []" + ending]
            }
            return ["\(key):" + ending] + items.map { Constants.listIndent + "- " + scalar($0, quoteReserved: true) + ending }
        case let .text(item):
            guard item.isEmpty == false else {
                return ["\(key):" + ending]
            }
            return ["\(key): " + scalar(item, quoteReserved: type == .text) + ending]
        }
    }

    // MARK: - Private

    private static func scalar(_ value: String, quoteReserved: Bool) -> String {
        let needsQuotes = value.first.map { Constants.specialStarts.contains($0) || $0.isWhitespace } == true
            || value.last?.isWhitespace == true
            || value.contains(": ") || value.contains(" #") || value.contains("\n")
            || (quoteReserved && (Constants.reserved.contains(value.lowercased()) || Double(value) != nil))
        guard needsQuotes else {
            return value
        }

        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private static func split(_ text: String) -> [String] {
        var lines: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "\n" || character == "\r\n" {
                lines.append(current)
                current = ""
            }
        }
        if current.isEmpty == false {
            lines.append(current)
        }
        return lines
    }

    private static func lineEnding(_ lines: [String]) -> String {
        lines.first?.hasSuffix("\r\n") == true ? "\r\n" : "\n"
    }
}
