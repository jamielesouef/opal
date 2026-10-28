//
//  MarkdownTextViewCoordinator.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore

@MainActor
final class MarkdownTextViewCoordinator: NSObject, NSTextViewDelegate, NSTextLayoutManagerDelegate {
    // MARK: - Stored

    var onChange: (String) -> Void
    var onFollowLink: (Int) -> Void = { _ in }
    var linkSuggestions: (String) -> [LinkSuggestion] = { _ in [] }
    var linkInsertion: (LinkSuggestion) -> String = { _ in "" }
    private(set) var styles: [TextStyleRun] = []
    private var lastRevealID: Int?
    private var appliedLength: Int?
    private var marks: [TextSpan] = []
    private var activeRange = NSRange(location: NSNotFound, length: 0)
    private var styledWindow = NSRange(location: NSNotFound, length: 0)
    var boundsObserver: (any NSObjectProtocol)?
    private let suggestionPanel = LinkSuggestionPanel()
    private var suggestions: [LinkSuggestion] = []
    private var selectedSuggestion = 0
    private var dismissedQuery: Int?

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
        updateSuggestions(in: textView)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }

        updateMarks(in: textView)
        if suggestionPanel.isVisible {
            updateSuggestions(in: textView)
        }
    }

    // MARK: - NSTextLayoutManagerDelegate

    nonisolated func textLayoutManager(
        _ textLayoutManager: NSTextLayoutManager,
        textLayoutFragmentFor location: any NSTextLocation,
        in textElement: NSTextElement
    ) -> NSTextLayoutFragment {
        guard let paragraph = textElement as? NSTextParagraph,
              paragraph.attributedString.length > 0,
              let value = paragraph.attributedString.attribute(MarkdownBlock.key, at: 0, effectiveRange: nil) as? String,
              let block = MarkdownBlock(rawValue: value)
        else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }

        return MarkdownBlockFragment(textElement: textElement, range: textElement.elementRange, block: block)
    }

    // MARK: - Link suggestions

    func handleCommand(_ selector: Selector, in textView: NSTextView) -> Bool {
        guard suggestionPanel.isVisible, suggestions.isEmpty == false else {
            return false
        }

        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            selectedSuggestion = min(selectedSuggestion + 1, suggestions.count - 1)
            showSuggestions(in: textView)
        case #selector(NSResponder.moveUp(_:)):
            selectedSuggestion = max(selectedSuggestion - 1, 0)
            showSuggestions(in: textView)
        case #selector(NSResponder.insertNewline(_:)),
             #selector(NSResponder.insertTab(_:)):
            acceptSuggestion(at: selectedSuggestion, in: textView)
        case #selector(NSResponder.cancelOperation(_:)):
            dismissedQuery = linkQuery(in: textView)?.bracketLocation
            hideSuggestions()
        default:
            return false
        }
        return true
    }

    func hideSuggestions() {
        suggestions = []
        suggestionPanel.hide()
    }

    private func updateSuggestions(in textView: NSTextView) {
        guard let query = linkQuery(in: textView), query.bracketLocation != dismissedQuery else {
            if linkQuery(in: textView) == nil {
                dismissedQuery = nil
            }
            hideSuggestions()
            return
        }

        let found = linkSuggestions(query.text)
        guard found.isEmpty == false else {
            hideSuggestions()
            return
        }

        if found != suggestions {
            selectedSuggestion = 0
        }
        suggestions = found
        showSuggestions(in: textView)
    }

    private func showSuggestions(in textView: NSTextView) {
        guard let window = textView.window, let query = linkQuery(in: textView) else {
            hideSuggestions()
            return
        }

        let anchor = textView.firstRect(forCharacterRange: NSRange(location: query.bracketLocation, length: 0), actualRange: nil)
        guard window.isVisible, anchor.origin != .zero else {
            hideSuggestions()
            return
        }

        suggestionPanel.show(suggestions, selectedIndex: selectedSuggestion, below: anchor, in: window) { [weak self, weak textView] index in
            guard let self, let textView else {
                return
            }
            acceptSuggestion(at: index, in: textView)
        }
    }

    private func acceptSuggestion(at index: Int, in textView: NSTextView) {
        guard suggestions.indices.contains(index), let query = linkQuery(in: textView) else {
            hideSuggestions()
            return
        }

        let suggestion = suggestions[index]
        hideSuggestions()
        let range = NSRange(location: query.bracketLocation, length: query.queryLocation + query.queryLength - query.bracketLocation)
        textView.insertText(linkInsertion(suggestion), replacementRange: range)
    }

    private func linkQuery(in textView: NSTextView) -> LinkQuery? {
        let selection = textView.selectedRange()
        guard selection.length == 0 else {
            return nil
        }

        return LinkSuggestionUseCase.openQuery(in: textView.string, cursor: selection.location)
    }

    // MARK: - Styles

    func isLink(at offset: Int) -> Bool {
        styles.contains { $0.kind.isLink && $0.span.contains(offset) }
    }

    func apply(_ newStyles: [TextStyleRun], to textView: NSTextView) {
        guard let storage = textView.textStorage, newStyles != styles || storage.length != appliedLength else {
            return
        }

        styles = newStyles
        appliedLength = storage.length
        marks = newStyles.filter { $0.kind == .mark }.map(\.span)
        activeRange = MarkdownStyler.activeRange(in: textView)
        styledWindow = NSRange(location: NSNotFound, length: 0)
        styleVisibleText(in: textView)
    }

    func toggleCheckbox(at offset: Int, in textView: NSTextView) -> Bool {
        guard textView.textStorage?.length == appliedLength,
              let toggle = CheckboxToggleUseCase.toggle(at: offset, in: styles) ?? CheckboxToggleUseCase.toggle(at: offset - 1, in: styles)
        else {
            return false
        }

        let range = NSRange(location: toggle.span.location, length: toggle.span.length)
        guard textView.shouldChangeText(in: range, replacementString: toggle.replacement) else {
            return false
        }

        textView.textStorage?.replaceCharacters(in: range, with: toggle.replacement)
        textView.didChangeText()
        textView.undoManager?.setActionName(String(localized: "Toggle Checkbox"))
        return true
    }

    func styleVisibleText(in textView: NSTextView) {
        guard let storage = textView.textStorage, storage.length == appliedLength else {
            return
        }

        let window = MarkdownStyler.window(around: textView)
        guard NSIntersectionRange(window, styledWindow) != window || styledWindow.location == NSNotFound else {
            return
        }

        styledWindow = window
        MarkdownStyler.apply(styles, to: storage, in: window, activeRange: activeRange)
    }

    private func updateMarks(in textView: NSTextView) {
        let newRange = MarkdownStyler.activeRange(in: textView)
        guard let storage = textView.textStorage, newRange != activeRange, storage.length == appliedLength else {
            return
        }

        MarkdownStyler.fadeMarks(marks, in: storage, from: activeRange, to: newRange)
        activeRange = newRange
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
