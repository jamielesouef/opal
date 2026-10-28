//
//  MarkdownReadingParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum MarkdownReadingParser {
    // MARK: - Constants

    private enum Pattern {
        static let calloutType = MarkdownNoteParser.regex(#"\[!([^\]\n]+)\]"#)
        static let tableSeparator = MarkdownNoteParser.regex(#"^[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$"#)
    }

    private enum Constants {
        static let spacesPerDepth = 2
        static let tabWidth = 4
        static let bullet = "•"
    }

    // MARK: - Blocks

    public static func blocks(in text: String, parsed: ParsedNote, styles: [TextStyleRun]) -> [ReadingBlock] {
        let nsText = text as NSString
        let lines = MarkdownNoteParser.splitLines(text)
        let runsByLine = group(styles, into: lines)
        let linksByLine = Dictionary(grouping: parsed.links, by: \.line)
        var blocks: [ReadingBlock] = []
        var index = MarkdownNoteParser.frontmatterLineCount(lines)

        func builder(_ range: Range<Int>) -> ReadingInlineBuilder {
            ReadingInlineBuilder(
                text: nsText,
                runs: range.flatMap { runsByLine[$0] ?? [] },
                links: range.flatMap { linksByLine[$0] ?? [] }
            )
        }

        while index < lines.count {
            let line = lines[index]
            let kinds = (runsByLine[index] ?? []).filter { $0.span.location == line.offset || $0.span.length == line.text.utf16.count }.map(\.kind)
            let whole = NSRange(location: line.offset, length: line.text.utf16.count)

            if kinds.contains(.codeBlock) {
                let start = index
                let language = fenceLanguage(line.text)
                var body: [String] = []
                index += 1
                while index < lines.count, (runsByLine[index] ?? []).contains(where: { $0.kind == .codeBlock }) {
                    let isClosing = (runsByLine[index] ?? []).contains { $0.kind == .mark && $0.span.length == lines[index].text.utf16.count }
                    index += 1
                    if isClosing {
                        break
                    }
                    body.append(lines[index - 1].text)
                }
                blocks.append(ReadingBlock(line: start, kind: .code(language: language, text: body.joined(separator: "\n"))))
                continue
            }

            if let level = kinds.compactMap({ if case let .heading(level) = $0 { level } else { nil } }).first {
                blocks.append(ReadingBlock(line: index, kind: .heading(level: level, text: builder(index ..< index + 1).inlines(in: whole))))
            } else if kinds.contains(.horizontalRule) {
                blocks.append(ReadingBlock(line: index, kind: .rule))
            } else if kinds.contains(.callout), let type = first(Pattern.calloutType, in: line.text) {
                let start = index
                let title = trimmed(builder(index ..< index + 1).inlines(in: whole))
                index += 1
                var body: [[ReadingInline]] = []
                while index < lines.count, isLine(index, kind: .callout, runsByLine, lines), first(Pattern.calloutType, in: lines[index].text) == nil {
                    body.append(trimmed(builder(index ..< index + 1).inlines(in: range(of: lines[index]))))
                    index += 1
                }
                blocks.append(ReadingBlock(line: start, kind: .callout(type: type.lowercased(), title: title, lines: body)))
                continue
            } else if kinds.contains(.quote) {
                let start = index
                var body: [[ReadingInline]] = []
                while index < lines.count, isLine(index, kind: .quote, runsByLine, lines) {
                    body.append(trimmed(builder(index ..< index + 1).inlines(in: range(of: lines[index]))))
                    index += 1
                }
                blocks.append(ReadingBlock(line: start, kind: .quote(lines: body)))
                continue
            } else if let marker = (runsByLine[index] ?? []).first(where: { $0.kind == .listMarker }) {
                let markerText = nsText.substring(with: NSRange(location: marker.span.location, length: marker.span.length))
                let checkbox = (runsByLine[index] ?? []).compactMap { if case let .checkbox(isDone) = $0.kind { isDone } else { nil } }.first
                blocks.append(ReadingBlock(line: index, kind: .listItem(
                    marker: markerText.first?.isNumber == true ? markerText : Constants.bullet,
                    depth: depth(of: line.text),
                    checkbox: checkbox,
                    text: trimmed(builder(index ..< index + 1).inlines(in: whole))
                )))
            } else if startsTable(at: index, lines) {
                let start = index
                let header = cells(of: line, builder(index ..< index + 1))
                index += 2
                var rows: [[[ReadingInline]]] = []
                while index < lines.count, lines[index].text.contains("|"), lines[index].text.trimmingCharacters(in: .whitespaces).isEmpty == false {
                    rows.append(cells(of: lines[index], builder(index ..< index + 1)))
                    index += 1
                }
                blocks.append(ReadingBlock(line: start, kind: .table(header: header, rows: rows)))
                continue
            } else if line.text.trimmingCharacters(in: .whitespaces).isEmpty == false {
                let start = index
                var paragraph: [ReadingInline] = []
                while index < lines.count, isParagraphLine(index, runsByLine, lines) {
                    let line = trimmed(builder(index ..< index + 1).inlines(in: range(of: lines[index])))
                    if paragraph.isEmpty == false, line.isEmpty == false {
                        paragraph.append(ReadingInline(text: "\n"))
                    }
                    paragraph += line
                    index += 1
                    if startsTable(at: index, lines) {
                        break
                    }
                }
                blocks.append(ReadingBlock(line: start, kind: .paragraph(paragraph)))
                continue
            }
            index += 1
        }
        return withEmbeds(blocks, links: parsed.links.filter(\.isEmbed), lineCount: lines.count)
    }

    // MARK: - Embeds

    private static func withEmbeds(_ blocks: [ReadingBlock], links: [Link], lineCount: Int) -> [ReadingBlock] {
        guard links.isEmpty == false else {
            return blocks
        }

        var result: [ReadingBlock] = []
        for (position, block) in blocks.enumerated() {
            let end = blocks.indices.contains(position + 1) ? blocks[position + 1].line : lineCount
            if block.kind != .paragraph([]) {
                result.append(block)
            }
            for (part, link) in links.filter({ (block.line ..< end).contains($0.line) }).enumerated() {
                result.append(ReadingBlock(line: block.line, part: part + 1, kind: .embed(link)))
            }
        }
        return result
    }

    // MARK: - Lines

    private static func group(_ styles: [TextStyleRun], into lines: [MarkdownLine]) -> [Int: [TextStyleRun]] {
        let starts = lines.map(\.offset)
        var result: [Int: [TextStyleRun]] = [:]
        for run in styles where run.kind != .frontmatter {
            var low = 0
            var high = starts.count
            while low < high {
                let middle = (low + high) / 2
                if starts[middle] <= run.span.location {
                    low = middle + 1
                } else {
                    high = middle
                }
            }
            result[max(low - 1, 0), default: []].append(run)
        }
        return result
    }

    private static func startsTable(at index: Int, _ lines: [MarkdownLine]) -> Bool {
        guard index + 1 < lines.count, lines[index].text.contains("|"), lines[index + 1].text.contains("|") else {
            return false
        }

        return first(Pattern.tableSeparator, in: lines[index + 1].text) != nil
    }

    private static func isLine(_ index: Int, kind: TextStyleKind, _ runsByLine: [Int: [TextStyleRun]], _ lines: [MarkdownLine]) -> Bool {
        (runsByLine[index] ?? []).contains { $0.kind == kind && $0.span.location == lines[index].offset }
    }

    private static func isParagraphLine(_ index: Int, _ runsByLine: [Int: [TextStyleRun]], _ lines: [MarkdownLine]) -> Bool {
        guard lines[index].text.trimmingCharacters(in: .whitespaces).isEmpty == false else {
            return false
        }

        return (runsByLine[index] ?? []).contains { run in
            switch run.kind {
            case .heading, .horizontalRule, .codeBlock, .quote, .callout, .listMarker:
                true
            case .link, .mark, .bold, .italic, .strikethrough, .highlight, .inlineCode, .calloutTitle, .checkbox, .doneTask, .tag, .frontmatter:
                false
            }
        } == false
    }

    private static func range(of line: MarkdownLine) -> NSRange {
        NSRange(location: line.offset, length: line.text.utf16.count)
    }

    private static func cells(of line: MarkdownLine, _ builder: ReadingInlineBuilder) -> [[ReadingInline]] {
        var cells: [[ReadingInline]] = []
        var start = 0
        let units = Array(line.text.utf16)
        let pipe = UInt16(UInt8(ascii: "|"))
        let backslash = UInt16(UInt8(ascii: "\\"))
        for (offset, unit) in units.enumerated() where unit == pipe && (offset == 0 || units[offset - 1] != backslash) {
            cells.append(trimmed(builder.inlines(in: NSRange(location: line.offset + start, length: offset - start))))
            start = offset + 1
        }
        cells.append(trimmed(builder.inlines(in: NSRange(location: line.offset + start, length: units.count - start))))
        if line.text.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
            cells.removeFirst()
        }
        if line.text.trimmingCharacters(in: .whitespaces).hasSuffix("|"), cells.isEmpty == false {
            cells.removeLast()
        }
        return cells
    }

    private static func trimmed(_ inlines: [ReadingInline]) -> [ReadingInline] {
        var result = inlines.filter { $0.text.isEmpty == false || $0.link != nil }
        let isBlank = { (inline: ReadingInline) in inline.link == nil && inline.text.allSatisfy { $0 == " " || $0 == "\t" } }
        while let first = result.first, isBlank(first) {
            result.removeFirst()
        }
        while let last = result.last, isBlank(last) {
            result.removeLast()
        }
        if let first = result.first, first.link == nil {
            let text = String(first.text.drop { $0 == " " || $0 == "\t" })
            result[0] = ReadingInline(text: text, styles: first.styles)
        }
        if let last = result.last, last.link == nil {
            var text = last.text
            while text.last == " " || text.last == "\t" {
                text.removeLast()
            }
            result[result.count - 1] = ReadingInline(text: text, styles: last.styles)
        }
        return result.filter { $0.text.isEmpty == false || $0.link != nil }
    }

    private static func fenceLanguage(_ line: String) -> String? {
        let info = line.trimmingCharacters(in: .whitespaces).drop { $0 == "`" || $0 == "~" }.trimmingCharacters(in: .whitespaces)
        return info.isEmpty ? nil : info.lowercased()
    }

    private static func depth(of line: String) -> Int {
        let indent = line.prefix { $0 == " " || $0 == "\t" }
        let width = indent.reduce(0) { $0 + ($1 == "\t" ? Constants.tabWidth : 1) }
        return width / Constants.spacesPerDepth
    }

    private static func first(_ regex: NSRegularExpression, in text: String) -> String? {
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) else {
            return nil
        }

        let range = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
        return (text as NSString).substring(with: range)
    }
}
