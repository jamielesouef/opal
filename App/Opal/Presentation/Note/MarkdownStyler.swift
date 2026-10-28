//
//  MarkdownStyler.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import AppKit
import OpalCore
import OpalDesign

@MainActor
enum MarkdownStyler {
    // MARK: - Constants

    private enum Constants {
        static let unresolvedAlpha: CGFloat = 0.55
        static let highlightAlpha: CGFloat = 0.35
        static let tagAlpha: CGFloat = 0.12
        static let windowMargin = 3000
    }

    // MARK: - Apply

    static func apply(_ runs: [TextStyleRun], to storage: NSTextStorage, in window: NSRange, activeRange: NSRange, style editorStyle: EditorStyle) {
        let styled = NSMutableAttributedString(string: (storage.string as NSString).substring(with: window), attributes: editorStyle.baseAttributes)
        let localActive = NSRange(location: activeRange.location == NSNotFound ? NSNotFound : activeRange.location - window.location, length: activeRange.length)
        for run in slice(runs, in: window).sorted(by: { phase($0.kind) < phase($1.kind) }) where run.span.upperBound <= storage.length {
            let range = NSIntersectionRange(NSRange(location: run.span.location, length: run.span.length), window)
            let local = NSRange(location: range.location - window.location, length: range.length)
            style(run.kind, range: local, in: styled, isActive: touches(local, localActive), editorStyle: editorStyle)
        }

        storage.beginEditing()
        styled.enumerateAttributes(in: NSRange(location: 0, length: styled.length)) { wanted, local, _ in
            let target = NSRange(location: local.location + window.location, length: local.length)
            storage.enumerateAttributes(in: target) { current, part, _ in
                if NSDictionary(dictionary: current).isEqual(to: wanted) == false {
                    storage.setAttributes(wanted, range: part)
                }
            }
        }
        storage.endEditing()
    }

    static func window(around textView: NSTextView) -> NSRange {
        let text = textView.string as NSString
        let visible = textView.enclosingScrollView?.documentVisibleRect ?? textView.visibleRect
        let fallback = min(textView.selectedRange().location, text.length)
        let top = index(textView.characterIndexForInsertion(at: visible.origin), or: fallback, in: text)
        let bottom = index(textView.characterIndexForInsertion(at: NSPoint(x: visible.maxX, y: visible.maxY)), or: fallback, in: text)
        let low = min(top, bottom)
        let start = max(low - Constants.windowMargin, 0)
        let end = min(min(max(top, bottom), low + Constants.windowMargin) + Constants.windowMargin, text.length)
        return text.paragraphRange(for: NSRange(location: start, length: end - start))
    }

    static func fadeMarks(_ marks: [TextSpan], in storage: NSTextStorage, from oldRange: NSRange, to newRange: NSRange) {
        storage.beginEditing()
        for mark in marks where mark.upperBound <= storage.length {
            let range = NSRange(location: mark.location, length: mark.length)
            let wasActive = touches(range, oldRange)
            let isActive = touches(range, newRange)
            if wasActive != isActive {
                storage.addAttribute(.foregroundColor, value: markColor(isActive: isActive), range: range)
            }
        }
        storage.endEditing()
    }

    static func activeRange(in textView: NSTextView) -> NSRange {
        let text = textView.string as NSString
        let selection = textView.selectedRange()
        guard selection.location <= text.length else {
            return NSRange(location: NSNotFound, length: 0)
        }

        return text.paragraphRange(for: selection)
    }

    // MARK: - Private

    private static func index(_ value: Int, or fallback: Int, in text: NSString) -> Int {
        value == NSNotFound || value > text.length ? fallback : value
    }

    private static func slice(_ runs: [TextStyleRun], in window: NSRange) -> [TextStyleRun] {
        var low = 0
        var high = runs.count
        while low < high {
            let middle = (low + high) / 2
            if runs[middle].span.location < window.location {
                low = middle + 1
            } else {
                high = middle
            }
        }
        var start = low
        while start > 0, runs[start - 1].span.upperBound > window.location {
            start -= 1
        }
        let end = runs[low...].firstIndex { $0.span.location >= NSMaxRange(window) } ?? runs.count
        let leading = runs.first.map { $0.kind == .frontmatter && $0.span.upperBound > window.location && start > 0 } ?? false
        return leading ? [runs[0]] + runs[start ..< end] : Array(runs[start ..< end])
    }

    private static func phase(_ kind: TextStyleKind) -> Int {
        switch kind {
        case .frontmatter, .codeBlock, .heading, .inlineCode, .checkbox, .quote, .callout:
            0
        case .bold, .italic, .calloutTitle:
            1
        case .strikethrough, .highlight, .listMarker, .tag, .link, .horizontalRule, .doneTask:
            2
        case .mark:
            3
        }
    }

    private static func style(_ kind: TextStyleKind, range: NSRange, in storage: NSMutableAttributedString, isActive: Bool, editorStyle: EditorStyle) {
        switch kind {
        case let .heading(level):
            let scale = EditorMetrics.headingScales[min(max(level, 1), EditorMetrics.headingScales.count) - 1]
            storage.addAttribute(.font, value: editorStyle.font(scale: scale, weight: .bold), range: range)
        case .bold:
            addTrait(.boldFontMask, range: range, in: storage, base: editorStyle.font())
        case .italic:
            addTrait(.italicFontMask, range: range, in: storage, base: editorStyle.font())
        case .strikethrough:
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        case .highlight:
            storage.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(Constants.highlightAlpha), range: range)
        case .inlineCode:
            storage.addAttributes([.font: editorStyle.codeFont, .backgroundColor: NSColor.quaternarySystemFill], range: range)
        case .codeBlock:
            storage.addAttributes([.font: editorStyle.codeFont, MarkdownBlock.key: MarkdownBlock.code.rawValue], range: range)
        case .quote:
            storage.addAttributes([.foregroundColor: NSColor.secondaryLabelColor, .paragraphStyle: editorStyle.indentedParagraph, MarkdownBlock.key: MarkdownBlock.quote.rawValue], range: range)
        case .callout:
            storage.addAttributes([.paragraphStyle: editorStyle.indentedParagraph, MarkdownBlock.key: MarkdownBlock.callout.rawValue], range: range)
        case .calloutTitle:
            addTrait(.boldFontMask, range: range, in: storage, base: editorStyle.font())
            storage.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: range)
        case .doneTask:
            storage.addAttributes([.strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: NSColor.secondaryLabelColor], range: range)
        case .listMarker, .horizontalRule:
            storage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)
        case let .checkbox(isDone):
            storage.addAttributes([.font: editorStyle.codeFont, .foregroundColor: isDone ? NSColor.secondaryLabelColor : NSColor.controlAccentColor], range: range)
        case .tag:
            storage.addAttributes([.foregroundColor: NSColor.controlAccentColor, .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(Constants.tagAlpha)], range: range)
        case .frontmatter:
            storage.addAttributes([.font: editorStyle.codeFont, .foregroundColor: NSColor.secondaryLabelColor], range: range)
        case let .link(isResolved):
            let color = isResolved ? NSColor.controlAccentColor : NSColor.controlAccentColor.withAlphaComponent(Constants.unresolvedAlpha)
            storage.addAttribute(.foregroundColor, value: color, range: range)
        case .mark:
            storage.addAttribute(.foregroundColor, value: markColor(isActive: isActive), range: range)
        }
    }

    private static func markColor(isActive: Bool) -> NSColor {
        isActive ? .secondaryLabelColor : .quaternaryLabelColor
    }

    private static func addTrait(_ trait: NSFontTraitMask, range: NSRange, in storage: NSMutableAttributedString, base: NSFont) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? NSFont) ?? base
            storage.addAttribute(.font, value: NSFontManager.shared.convert(font, toHaveTrait: trait), range: subrange)
        }
    }

    private static func touches(_ range: NSRange, _ active: NSRange) -> Bool {
        active.location != NSNotFound && (NSIntersectionRange(range, active).length > 0 || active.contains(range.location))
    }
}
