//
//  MarkdownTextViewCoordinator.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
final class MarkdownTextViewCoordinator: NSObject, NSTextViewDelegate {
    // MARK: - Constants

    private enum Constants {
        static let unresolvedAlpha: CGFloat = 0.55
    }

    // MARK: - Stored

    var onChange: (String) -> Void
    var onFollowLink: (Int) -> Void = { _ in }
    private(set) var highlights: [LinkHighlight] = []
    private var lastRevealID: Int?
    private var appliedLength: Int?

    // MARK: - Init

    init(onChange: @escaping (String) -> Void) {
        self.onChange = onChange
    }

    // MARK: - NSTextViewDelegate

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }

        onChange(textView.string)
    }

    // MARK: - Links

    func isLink(at offset: Int) -> Bool {
        highlights.contains { $0.span.contains(offset) }
    }

    func apply(_ newHighlights: [LinkHighlight], to textView: NSTextView) {
        guard let storage = textView.textStorage, newHighlights != highlights || storage.length != appliedLength else {
            return
        }

        highlights = newHighlights
        appliedLength = storage.length
        let full = NSRange(location: 0, length: storage.length)
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: full)
        for highlight in newHighlights where highlight.span.upperBound <= storage.length {
            let color = highlight.isResolved
                ? NSColor.controlAccentColor
                : NSColor.controlAccentColor.withAlphaComponent(Constants.unresolvedAlpha)
            storage.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: highlight.span.location, length: highlight.span.length)
            )
        }
        storage.endEditing()
    }

    // MARK: - Reveal

    func apply(_ reveal: RevealRequest?, to textView: NSTextView) {
        guard let reveal, reveal.id != lastRevealID else {
            return
        }

        lastRevealID = reveal.id
        let offset = TextLineUseCase.utf16Offset(ofLine: reveal.line, in: textView.string)
        let range = NSRange(location: offset, length: 0)
        textView.setSelectedRange(range)
        Task { @MainActor in
            textView.scrollRangeToVisible(range)
        }
    }
}
