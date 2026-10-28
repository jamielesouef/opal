//
//  MarkdownStyleParser.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum MarkdownStyleParser {
    // MARK: - Constants

    private enum Pattern {
        static let headingMarks = MarkdownNoteParser.regex(#"^ {0,3}(#{1,6}[ \t]+)"#)
        static let quote = MarkdownNoteParser.regex(#"^ {0,3}(>[ \t]?)"#)
        static let callout = MarkdownNoteParser.regex(#"^ {0,3}>[ \t]*(\[![^\]\n]+\][+-]?)[ \t]*(.*)$"#)
        static let listMarker = MarkdownNoteParser.regex(#"^[ \t]*(?:>[ \t]?)*([-*+]|\d{1,9}[.)])[ \t]+"#)
        static let checkbox = MarkdownNoteParser.regex(#"^[ \t]*(?:>[ \t]?)*(?:[-*+]|\d{1,9}[.)])[ \t]+(\[([ xX])\])(?=[ \t]|$)"#)
        static let horizontalRule = MarkdownNoteParser.regex(#"^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$"#)
        static let blockID = MarkdownNoteParser.regex(#"(?:^|\s)(\^[A-Za-z0-9-]+)[ \t]*$"#)
        static let emphasis: [(NSRegularExpression, Int, [TextStyleKind])] = [
            (MarkdownNoteParser.regex(#"(?<![*\\])\*\*\*(?=\S)(.+?)(?<=\S)\*\*\*(?!\*)"#), 3, [.bold, .italic]),
            (MarkdownNoteParser.regex(#"(?<![_\w\\])___(?=\S)(.+?)(?<=\S)___(?![_\w])"#), 3, [.bold, .italic]),
            (MarkdownNoteParser.regex(#"(?<![*\\])\*\*(?=\S)(.+?)(?<=\S)\*\*(?!\*)"#), 2, [.bold]),
            (MarkdownNoteParser.regex(#"(?<![_\w\\])__(?=\S)(.+?)(?<=\S)__(?![_\w])"#), 2, [.bold]),
            (MarkdownNoteParser.regex(#"(?<![*\\])\*(?=[^\s*])(.+?)(?<=[^\s*])\*(?!\*)"#), 1, [.italic]),
            (MarkdownNoteParser.regex(#"(?<![_\w\\])_(?=[^\s_])(.+?)(?<=[^\s_])_(?![_\w])"#), 1, [.italic]),
            (MarkdownNoteParser.regex(#"(?<!~)~~(?=\S)(.+?)(?<=\S)~~(?!~)"#), 2, [.strikethrough]),
            (MarkdownNoteParser.regex(#"(?<!=)==(?=\S)(.+?)(?<=\S)==(?!=)"#), 2, [.highlight])
        ]
    }

    // MARK: - Runs

    public static func runs(in text: String, parsed: ParsedNote) -> [TextStyleRun] {
        let lines = MarkdownNoteParser.splitLines(text)
        let frontmatterLength = MarkdownNoteParser.frontmatterLineCount(lines)
        var runs: [TextStyleRun] = []
        var openFence: String?
        var inCallout = false

        if frontmatterLength > 0 {
            let last = lines[frontmatterLength - 1]
            runs.append(TextStyleRun(span: TextSpan(location: 0, length: last.offset + last.text.utf16.count), kind: .frontmatter))
        }

        let linksByLine = Dictionary(grouping: parsed.links, by: \.line)
        for line in lines.dropFirst(frontmatterLength) {
            let length = line.text.utf16.count
            let whole = TextSpan(location: line.offset, length: length)
            let trimmed = String(line.text.drop { $0 == " " || $0 == "\t" })

            if let fence = openFence {
                runs.append(TextStyleRun(span: whole, kind: .codeBlock))
                if MarkdownNoteParser.closesFence(trimmed, fence: fence) {
                    runs.append(TextStyleRun(span: whole, kind: .mark))
                    openFence = nil
                }
                continue
            }

            if let fence = MarkdownNoteParser.fenceMarker(trimmed) {
                runs.append(TextStyleRun(span: whole, kind: .codeBlock))
                runs.append(TextStyleRun(span: whole, kind: .mark))
                openFence = fence
                inCallout = false
                continue
            }

            let links = linksByLine[line.index] ?? []
            runs += blockRuns(in: line, inCallout: &inCallout)
            runs += inlineRuns(in: line, links: links)
        }

        return runs.filter { $0.span.length > 0 }
    }

    // MARK: - Blocks

    private static func blockRuns(in line: MarkdownLine, inCallout: inout Bool) -> [TextStyleRun] {
        let length = line.text.utf16.count
        let whole = TextSpan(location: line.offset, length: length)
        var runs: [TextStyleRun] = []

        if let quote = first(Pattern.quote, in: line.text) {
            runs.append(run(quote.range(at: 1), in: line, kind: .mark))
            if let callout = first(Pattern.callout, in: line.text) {
                inCallout = true
                runs.append(TextStyleRun(span: whole, kind: .callout))
                runs.append(run(callout.range(at: 1), in: line, kind: .mark))
                runs.append(run(callout.range(at: 2), in: line, kind: .calloutTitle))
            } else {
                runs.append(TextStyleRun(span: whole, kind: inCallout ? .callout : .quote))
            }
        } else {
            inCallout = false
        }

        if let heading = first(MarkdownNoteParser.Pattern.heading, in: line.text), let marks = first(Pattern.headingMarks, in: line.text) {
            runs.append(TextStyleRun(span: whole, kind: .heading(level: heading.range(at: 1).length)))
            runs.append(run(marks.range(at: 1), in: line, kind: .mark))
        } else if let rule = first(Pattern.horizontalRule, in: line.text) {
            runs.append(TextStyleRun(span: whole, kind: .horizontalRule))
            runs.append(run(rule.range, in: line, kind: .mark))
        } else if let marker = first(Pattern.listMarker, in: line.text) {
            runs.append(run(marker.range(at: 1), in: line, kind: .listMarker))
            if let box = first(Pattern.checkbox, in: line.text) {
                let state = (line.text as NSString).substring(with: box.range(at: 2))
                runs.append(run(box.range(at: 1), in: line, kind: .checkbox(isDone: state != " ")))
            }
        }

        if let blockID = first(Pattern.blockID, in: line.text) {
            runs.append(run(blockID.range(at: 1), in: line, kind: .mark))
        }
        return runs
    }

    // MARK: - Inline

    private static func inlineRuns(in line: MarkdownLine, links: [Link]) -> [TextStyleRun] {
        let codeSpans = MarkdownNoteParser.inlineCodeSpans(line.text)
        var runs: [TextStyleRun] = []
        for span in codeSpans {
            let ticks = line.text.utf16.dropFirst(span.location).prefix { $0 == UInt16(UInt8(ascii: "`")) }.count
            runs.append(TextStyleRun(span: span.shifted(by: line.offset), kind: .inlineCode))
            runs.append(TextStyleRun(span: TextSpan(location: line.offset + span.location, length: ticks), kind: .mark))
            runs.append(TextStyleRun(span: TextSpan(location: line.offset + span.upperBound - ticks, length: ticks), kind: .mark))
        }

        let linkSpans = links.map { TextSpan(location: $0.span.location - line.offset, length: $0.span.length) }
        for link in links {
            runs += linkMarks(link, in: line)
        }

        var taken = codeSpans
        for (regex, width, kinds) in Pattern.emphasis {
            for match in MarkdownNoteParser.matches(of: regex, in: line.text) {
                let open = TextSpan(location: match.range.location, length: width)
                let close = TextSpan(location: match.range.location + match.range.length - width, length: width)
                guard MarkdownNoteParser.overlaps(match.range, taken) == false,
                      [open, close].allSatisfy({ inside($0, linkSpans) == false })
                else {
                    continue
                }

                taken.append(TextSpan(location: match.range.location, length: match.range.length))
                for kind in kinds {
                    runs.append(run(match.range(at: 1), in: line, kind: kind))
                }
                runs.append(TextStyleRun(span: open.shifted(by: line.offset), kind: .mark))
                runs.append(TextStyleRun(span: close.shifted(by: line.offset), kind: .mark))
            }
        }

        for match in MarkdownNoteParser.matches(of: MarkdownNoteParser.Pattern.tag, in: line.text)
            where MarkdownNoteParser.overlaps(match.range, codeSpans) == false && inside(TextSpan(location: match.range.location, length: match.range.length), linkSpans) == false {
            runs.append(run(match.range, in: line, kind: .tag))
        }
        return runs
    }

    private static func linkMarks(_ link: Link, in line: MarkdownLine) -> [TextStyleRun] {
        let start = link.span.location
        let end = link.span.upperBound
        let bang = link.isEmbed ? 1 : 0
        switch link.style {
        case .wiki:
            var marks = [
                TextSpan(location: start, length: bang + 2),
                TextSpan(location: end - 2, length: 2)
            ]
            let inner = (line.text as NSString).substring(with: NSRange(location: start - line.offset + bang + 2, length: max(link.span.length - bang - 4, 0)))
            let bar = (inner as NSString).range(of: "|").location
            if link.displayText != nil, bar != NSNotFound {
                marks.append(TextSpan(location: start + bang + 2, length: bar + 1))
            }
            return marks.map { TextStyleRun(span: $0, kind: .mark) }
        case .markdown:
            let local = (line.text as NSString).substring(with: NSRange(location: start - line.offset, length: link.span.length))
            let closeOffset = (local as NSString).range(of: "](").location
            guard closeOffset != NSNotFound else {
                return []
            }

            return [
                TextSpan(location: start, length: bang + 1),
                TextSpan(location: start + closeOffset, length: link.span.length - closeOffset)
            ].map { TextStyleRun(span: $0, kind: .mark) }
        }
    }

    // MARK: - Helpers

    private static func first(_ regex: NSRegularExpression, in text: String) -> NSTextCheckingResult? {
        regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count))
    }

    private static func run(_ range: NSRange, in line: MarkdownLine, kind: TextStyleKind) -> TextStyleRun {
        guard range.location != NSNotFound else {
            return TextStyleRun(span: TextSpan(location: line.offset, length: 0), kind: kind)
        }

        return TextStyleRun(span: TextSpan(location: line.offset + range.location, length: range.length), kind: kind)
    }

    private static func inside(_ span: TextSpan, _ spans: [TextSpan]) -> Bool {
        spans.contains { span.location < $0.upperBound && $0.location < span.upperBound }
    }
}
