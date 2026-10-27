//
//  MarkdownNoteParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum MarkdownNoteParser {
    // MARK: - Constants

    private enum Pattern {
        static let wikiLink = regex(#"(!?)\[\[([^\[\]\n]+?)\]\]"#)
        static let markdownLink = regex(#"(!?)\[([^\[\]\n]*)\]\((<[^<>\n]+>|[^()\s]+)\)"#)
        static let heading = regex(#"^ {0,3}(#{1,6})[ \t]+(.+?)(?:[ \t]+#+)?[ \t]*$"#)
        static let block = regex(#"(?:^|\s)\^([A-Za-z0-9-]+)[ \t]*$"#)
        static let urlScheme = regex(#"^[A-Za-z][A-Za-z0-9+.-]*:"#)
        static let aliasKey = regex(#"^(?:aliases|alias)[ \t]*:[ \t]*(.*)$"#)
        static let tagKey = regex(#"^(?:tags|tag)[ \t]*:[ \t]*(.*)$"#)
        static let tag = regex(#"(?:^|(?<=[\s(,;]))#([\p{L}\p{N}_/-]*[\p{L}_/-][\p{L}\p{N}_/-]*)"#)
    }

    private enum Constants {
        static let frontmatterDelimiter = "---"
        static let frontmatterEnd = "..."
        static let fenceCharacters: Set<Character> = ["`", "~"]
        static let minimumFenceLength = 3
        static let backtick = UInt16(UInt8(ascii: "`"))
    }

    // MARK: - Parse

    public static func parse(_ text: String) -> ParsedNote {
        let lines = splitLines(text)
        let frontmatterLength = frontmatterLineCount(lines)
        let frontmatter = frontmatterLength > 0 ? lines[1 ..< frontmatterLength - 1].map(\.text) : []
        let aliases = listProperty(Pattern.aliasKey, in: frontmatter)
        var tags = listProperty(Pattern.tagKey, in: frontmatter, splitOnSpaces: true)
            .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }
            .filter { $0.isEmpty == false }

        var links: [Link] = []
        var headings: [Heading] = []
        var blocks: [Block] = []
        var openFence: String?

        for line in lines.dropFirst(frontmatterLength) {
            let trimmed = String(line.text.drop { $0 == " " || $0 == "\t" })
            if let fence = openFence {
                if closesFence(trimmed, fence: fence) {
                    openFence = nil
                }
                continue
            }

            if let fence = fenceMarker(trimmed) {
                openFence = fence
                continue
            }

            let codeSpans = inlineCodeSpans(line.text)
            links += wikiLinks(in: line, avoiding: codeSpans)
            links += markdownLinks(in: line, avoiding: codeSpans)
            tags += bodyTags(in: line, avoiding: codeSpans)

            if let heading = heading(in: line) {
                headings.append(heading)
            }

            if let block = block(in: line) {
                blocks.append(block)
            }
        }

        return ParsedNote(
            links: links.sorted { $0.span.location < $1.span.location },
            headings: headings,
            blocks: blocks,
            aliases: aliases,
            tags: uniqueIgnoringCase(tags)
        )
    }

    public static func lineStartOffsets(in text: String) -> [Int] {
        splitLines(text).map(\.offset)
    }

    // MARK: - Lines

    private static func splitLines(_ text: String) -> [MarkdownLine] {
        var lines: [MarkdownLine] = []
        var offset = 0
        for (index, raw) in text.unicodeScalars.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let content = raw.last == "\r" ? raw.dropLast() : raw
            lines.append(MarkdownLine(text: String(String.UnicodeScalarView(content)), offset: offset, index: index))
            offset += raw.reduce(0) { $0 + $1.utf16.count } + 1
        }
        return lines
    }

    private static func frontmatterLineCount(_ lines: [MarkdownLine]) -> Int {
        guard lines.first.map(\.text).map(trimmingTrailingSpace) == Constants.frontmatterDelimiter else {
            return 0
        }

        let end = lines.dropFirst().firstIndex {
            let line = trimmingTrailingSpace($0.text)
            return line == Constants.frontmatterDelimiter || line == Constants.frontmatterEnd
        }
        return end.map { $0 + 1 } ?? 0
    }

    private static func trimmingTrailingSpace(_ text: String) -> String {
        var result = text
        while result.last == " " || result.last == "\t" {
            result.removeLast()
        }
        return result
    }

    // MARK: - Code

    private static func fenceMarker(_ trimmed: String) -> String? {
        guard let first = trimmed.first, Constants.fenceCharacters.contains(first) else {
            return nil
        }

        let run = trimmed.prefix { $0 == first }
        guard run.count >= Constants.minimumFenceLength else {
            return nil
        }

        return String(run)
    }

    private static func closesFence(_ trimmed: String, fence: String) -> Bool {
        guard let character = fence.first else {
            return false
        }

        let run = trimmed.prefix { $0 == character }
        return run.count >= fence.count && trimmed.dropFirst(run.count).allSatisfy(\.isWhitespace)
    }

    private static func inlineCodeSpans(_ line: String) -> [TextSpan] {
        let units = Array(line.utf16)
        var spans: [TextSpan] = []
        var index = 0
        while index < units.count {
            guard units[index] == Constants.backtick else {
                index += 1
                continue
            }

            let start = index
            while index < units.count, units[index] == Constants.backtick {
                index += 1
            }

            let runLength = index - start
            guard let close = closingRun(in: units, from: index, length: runLength) else {
                continue
            }

            spans.append(TextSpan(location: start, length: close + runLength - start))
            index = close + runLength
        }
        return spans
    }

    private static func closingRun(in units: [UInt16], from start: Int, length: Int) -> Int? {
        var index = start
        while index < units.count {
            guard units[index] == Constants.backtick else {
                index += 1
                continue
            }

            let runStart = index
            while index < units.count, units[index] == Constants.backtick {
                index += 1
            }

            if index - runStart == length {
                return runStart
            }
        }
        return nil
    }

    private static func overlaps(_ range: NSRange, _ spans: [TextSpan]) -> Bool {
        spans.contains { range.location < $0.upperBound && $0.location < range.location + range.length }
    }

    // MARK: - Links

    private static func wikiLinks(in line: MarkdownLine, avoiding codeSpans: [TextSpan]) -> [Link] {
        let nsLine = line.text as NSString
        return matches(of: Pattern.wikiLink, in: line.text).compactMap { match in
            guard overlaps(match.range, codeSpans) == false else {
                return nil
            }

            let inner = nsLine.substring(with: match.range(at: 2))
            let (destination, display) = split(inner, at: "|")
            let (name, subpath) = splitSubpath(destination)
            return Link(
                target: name.trimmingCharacters(in: .whitespaces),
                subpath: subpath,
                displayText: display,
                isEmbed: match.range(at: 1).length > 0,
                style: .wiki,
                span: TextSpan(location: line.offset + match.range.location, length: match.range.length),
                line: line.index,
                lineText: line.text
            )
        }
    }

    private static func markdownLinks(in line: MarkdownLine, avoiding codeSpans: [TextSpan]) -> [Link] {
        let nsLine = line.text as NSString
        return matches(of: Pattern.markdownLink, in: line.text).compactMap { match in
            guard overlaps(match.range, codeSpans) == false else {
                return nil
            }

            var destination = nsLine.substring(with: match.range(at: 3))
            if destination.hasPrefix("<"), destination.hasSuffix(">") {
                destination = String(destination.dropFirst().dropLast())
            }

            guard matches(of: Pattern.urlScheme, in: destination).isEmpty else {
                return nil
            }

            let (rawName, subpath) = splitSubpath(destination)
            let name = rawName.removingPercentEncoding ?? rawName
            guard name.isEmpty == false || subpath != nil else {
                return nil
            }

            let text = nsLine.substring(with: match.range(at: 2))
            return Link(
                target: name,
                subpath: subpath,
                displayText: text.isEmpty ? nil : text,
                isEmbed: match.range(at: 1).length > 0,
                style: .markdown,
                span: TextSpan(location: line.offset + match.range.location, length: match.range.length),
                line: line.index,
                lineText: line.text
            )
        }
    }

    private static func split(_ text: String, at separator: Character) -> (String, String?) {
        guard let index = text.firstIndex(of: separator) else {
            return (text, nil)
        }

        return (String(text[..<index]), String(text[text.index(after: index)...]))
    }

    private static func splitSubpath(_ destination: String) -> (String, LinkSubpath?) {
        let (name, rawSubpath) = split(destination, at: "#")
        guard let rawSubpath else {
            return (name, nil)
        }

        let decoded = rawSubpath.removingPercentEncoding ?? rawSubpath
        guard decoded.hasPrefix("^") else {
            return (name, .heading(decoded.trimmingCharacters(in: .whitespaces)))
        }

        return (name, .block(String(decoded.dropFirst())))
    }

    // MARK: - Headings and Blocks

    private static func heading(in line: MarkdownLine) -> Heading? {
        guard let match = matches(of: Pattern.heading, in: line.text).first else {
            return nil
        }

        let nsLine = line.text as NSString
        return Heading(
            level: match.range(at: 1).length,
            text: nsLine.substring(with: match.range(at: 2)),
            line: line.index
        )
    }

    private static func block(in line: MarkdownLine) -> Block? {
        guard let match = matches(of: Pattern.block, in: line.text).first else {
            return nil
        }

        return Block(id: (line.text as NSString).substring(with: match.range(at: 1)), line: line.index)
    }

    // MARK: - Properties

    private static func listProperty(_ key: NSRegularExpression, in lines: [String], splitOnSpaces: Bool = false) -> [String] {
        guard let keyIndex = lines.firstIndex(where: { matches(of: key, in: $0).isEmpty == false }),
              let match = matches(of: key, in: lines[keyIndex]).first
        else {
            return []
        }

        let value = (lines[keyIndex] as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("[") {
            return value.dropFirst().dropLast()
                .split(separator: ",")
                .map { unquoted(String($0)) }
                .filter { $0.isEmpty == false }
        }

        if value.isEmpty == false {
            guard splitOnSpaces else {
                return [unquoted(value)]
            }
            return unquoted(value)
                .split { $0 == "," || $0 == " " }
                .map(String.init)
                .filter { $0.isEmpty == false }
        }

        var aliases: [String] = []
        for line in lines[(keyIndex + 1)...] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else {
                if trimmed.isEmpty {
                    continue
                }
                break
            }

            let alias = unquoted(String(trimmed.dropFirst()))
            if alias.isEmpty == false {
                aliases.append(alias)
            }
        }
        return aliases
    }

    // MARK: - Tags

    private static func bodyTags(in line: MarkdownLine, avoiding codeSpans: [TextSpan]) -> [String] {
        let nsLine = line.text as NSString
        return matches(of: Pattern.tag, in: line.text).compactMap { match in
            guard overlaps(match.range, codeSpans) == false else {
                return nil
            }

            let tag = nsLine.substring(with: match.range(at: 1)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return tag.isEmpty ? nil : tag
        }
    }

    private static func uniqueIgnoringCase(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { seen.insert($0.lowercased()).inserted }
    }

    private static func unquoted(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, let first = trimmed.first, first == trimmed.last, first == "\"" || first == "'" else {
            return trimmed
        }

        return String(trimmed.dropFirst().dropLast())
    }

    // MARK: - Regex

    private static func regex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        } catch {
            preconditionFailure("Invalid pattern \(pattern): \(error)")
        }
    }

    private static func matches(of regex: NSRegularExpression, in text: String) -> [NSTextCheckingResult] {
        regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
    }
}
