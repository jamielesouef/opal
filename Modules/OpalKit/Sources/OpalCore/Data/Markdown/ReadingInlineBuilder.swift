//
//  ReadingInlineBuilder.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

struct ReadingInlineBuilder {
    // MARK: - Stored

    let text: NSString
    let runs: [TextStyleRun]
    let links: [Link]

    // MARK: - Build

    func inlines(in range: NSRange) -> [ReadingInline] {
        let end = NSMaxRange(range)
        let inside = runs.filter { $0.span.location < end && $0.span.upperBound > range.location }
        let lineLinks = links.filter { $0.span.location >= range.location && $0.span.upperBound <= end }
        var bounds: Set<Int> = [range.location, end]
        for span in inside.map(\.span) + lineLinks.map(\.span) {
            bounds.insert(max(span.location, range.location))
            bounds.insert(min(span.upperBound, end))
        }

        var result: [ReadingInline] = []
        let sorted = bounds.sorted()
        for (start, stop) in zip(sorted, sorted.dropFirst()) where start < stop {
            if let link = lineLinks.first(where: { $0.span.location <= start && start < $0.span.upperBound }) {
                if link.span.location == start, link.isEmbed == false {
                    let resolved = inside.first { $0.span == link.span && $0.kind.isLink }.map { $0.kind == .link(isResolved: true) } ?? true
                    result.append(ReadingInline(text: Self.display(link), styles: styles(at: start, in: inside), link: link, isResolved: resolved))
                }
                continue
            }

            let covering = inside.filter { $0.span.location <= start && start < $0.span.upperBound }
            guard covering.contains(where: { [.mark, .listMarker].contains($0.kind) || $0.kind.isCheckbox }) == false else {
                continue
            }

            append(ReadingInline(text: text.substring(with: NSRange(location: start, length: stop - start)), styles: styles(at: start, in: inside)), to: &result)
        }
        return result
    }

    static func display(_ link: Link) -> String {
        if let displayText = link.displayText, displayText.isEmpty == false {
            return displayText
        }

        switch link.subpath {
        case let .heading(heading):
            return link.target.isEmpty ? heading : "\(link.target) > \(heading)"
        case let .block(block):
            return link.target.isEmpty ? "^\(block)" : "\(link.target) > ^\(block)"
        case nil:
            return link.target
        }
    }

    // MARK: - Private

    private func styles(at offset: Int, in inside: [TextStyleRun]) -> Set<ReadingInlineStyle> {
        Set(inside.filter { $0.span.location <= offset && offset < $0.span.upperBound }.compactMap { run in
            switch run.kind {
            case .bold, .calloutTitle:
                .bold
            case .italic:
                .italic
            case .strikethrough, .doneTask:
                .strikethrough
            case .highlight:
                .highlight
            case .inlineCode:
                .code
            case .tag:
                .tag
            case .link, .mark, .heading, .codeBlock, .quote, .callout, .listMarker, .checkbox, .horizontalRule, .frontmatter:
                nil
            }
        })
    }

    private func append(_ inline: ReadingInline, to result: inout [ReadingInline]) {
        guard let last = result.last, last.link == nil, last.styles == inline.styles else {
            result.append(inline)
            return
        }

        result[result.count - 1] = ReadingInline(text: last.text + inline.text, styles: last.styles)
    }
}
