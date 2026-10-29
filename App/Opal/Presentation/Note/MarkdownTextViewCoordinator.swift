//
//  MarkdownTextViewCoordinator.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore
import OpalDesign

@MainActor
final class MarkdownTextViewCoordinator: NSObject, NSTextViewDelegate, NSTextLayoutManagerDelegate, NSTextContentStorageDelegate {
    // MARK: - Stored

    var onChange: (String) -> Void
    var onFollowLink: (Int) -> Void = { _ in }
    var onScroll: (Int) -> Void = { _ in }
    var onUnfold: () -> Void = {}
    nonisolated(unsafe) private(set) var fold: FrontmatterFold?
    var linkSuggestions: (String) async -> [LinkSuggestion] = { _ in [] }
    private var suggestionTask: Task<Void, Never>?
    private let undo = UndoManager()
    var linkInsertion: (LinkSuggestion) -> String = { _ in "" }
    private(set) var styles: [TextStyleRun] = []
    private var lastRevealID: Int?
    private var lastInsertionID: Int?
    private var appliedLength: Int?
    var lastText: String?
    nonisolated(unsafe) var style = EditorStyle.defaults
    private var marks: [TextSpan] = []
    private var checkboxes: [TextStyleRun] = []
    private var activeRange = NSRange(location: NSNotFound, length: 0)
    private var styled = IndexSet()
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

        let text = textView.string
        lastText = text
        onChange(text)
        updateSuggestions(in: textView)
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if let fold, fold.isInside(editAt: affectedCharRange.location) {
            unfold(in: textView)
        }
        return true
    }

    func undoManager(for view: NSTextView) -> UndoManager? {
        undo
    }

    func dismantle() {
        undo.removeAllActions()
        hideSuggestions()
        fold = nil
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }

        enforceFold(in: textView)
        updateMarks(in: textView)
        if suggestionPanel.isVisible {
            updateSuggestions(in: textView)
        }
    }

    // MARK: - NSTextContentStorageDelegate

    nonisolated func textContentManager(_ textContentManager: NSTextContentManager, shouldEnumerate textElement: NSTextElement, options: NSTextContentManager.EnumerationOptions = []) -> Bool {
        guard let fold else {
            return true
        }

        let start = textContentManager.offset(from: textContentManager.documentRange.location, to: textElement.elementRange?.location ?? textContentManager.documentRange.location)
        return fold.hidden.contains(start) == false
    }

    // MARK: - NSTextLayoutManagerDelegate

    nonisolated func textLayoutManager(
        _ textLayoutManager: NSTextLayoutManager,
        textLayoutFragmentFor location: any NSTextLocation,
        in textElement: NSTextElement
    ) -> NSTextLayoutFragment {
        guard let paragraph = textElement as? NSTextParagraph, paragraph.attributedString.length > 0 else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }

        let text = paragraph.attributedString
        let block = (text.attribute(MarkdownBlock.key, at: 0, effectiveRange: nil) as? String).flatMap(MarkdownBlock.init(rawValue:))
        var hasCheckbox = false
        text.enumerateAttribute(MarkdownCheckbox.key, in: NSRange(location: 0, length: text.length)) { value, _, stop in
            hasCheckbox = value != nil
            stop.pointee = ObjCBool(hasCheckbox)
        }
        let foldLabel = foldLabel(for: textElement, in: textLayoutManager)
        guard block != nil || hasCheckbox || foldLabel != nil else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }

        return MarkdownBlockFragment(textElement: textElement, range: textElement.elementRange, block: block, foldLabel: foldLabel)
    }

    private nonisolated func foldLabel(for textElement: NSTextElement, in textLayoutManager: NSTextLayoutManager) -> NSAttributedString? {
        guard fold != nil, let start = textElement.elementRange?.location,
              start.compare(textLayoutManager.documentRange.location) == .orderedSame
        else {
            return nil
        }

        return NSAttributedString(string: String(localized: "Properties"), attributes: [.font: style.font(), .foregroundColor: AppKitColor.secondaryText])
    }

    // MARK: - Link suggestions

    func handleCommand(_ selector: Selector, in textView: NSTextView) -> Bool {
        guard suggestionPanel.isVisible, suggestions.isEmpty == false else {
            return continueList(selector, in: textView)
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

    private func continueList(_ selector: Selector, in textView: NSTextView) -> Bool {
        let selection = textView.selectedRange()
        guard selector == #selector(NSResponder.insertNewline(_:)), selection.length == 0,
              let edit = ListContinuationUseCase.newline(in: textView.string, cursor: selection.location)
        else {
            return false
        }

        textView.insertText(edit.replacement, replacementRange: NSRange(location: edit.span.location, length: edit.span.length))
        return true
    }

    func hideSuggestions() {
        suggestionTask?.cancel()
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

        suggestionTask?.cancel()
        suggestionTask = Task { [weak self, weak textView] in
            guard let self else {
                return
            }

            let found = await linkSuggestions(query.text)
            guard Task.isCancelled == false, let textView, linkQuery(in: textView) == query else {
                return
            }

            guard found.isEmpty == false else {
                suggestions = []
                suggestionPanel.hide()
                return
            }

            if found != suggestions {
                selectedSuggestion = 0
            }
            suggestions = found
            showSuggestions(in: textView)
        }
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

    // MARK: - Fold

    func apply(_ newFold: FrontmatterFold?, to textView: NSTextView) {
        guard newFold != fold else {
            return
        }

        fold = newFold
        relayout(textView)
        enforceFold(in: textView)
    }

    func enforceFold(in textView: NSTextView) {
        guard let fold else {
            return
        }

        let range = textView.selectedRange()
        switch fold.rule(forSelection: TextSpan(location: range.location, length: range.length)) {
        case .keep:
            break
        case let .moveTo(offset):
            textView.setSelectedRange(NSRange(location: min(offset, (textView.string as NSString).length), length: 0))
        case .unfold:
            unfold(in: textView)
        }
    }

    private func unfold(in textView: NSTextView) {
        fold = nil
        relayout(textView)
        onUnfold()
    }

    private func relayout(_ textView: NSTextView) {
        guard let layout = textView.textLayoutManager else {
            return
        }

        layout.invalidateLayout(for: layout.documentRange)
        textView.needsDisplay = true
    }

    // MARK: - Styles

    func isLink(at offset: Int) -> Bool {
        styles.contains { $0.kind.isLink && $0.span.contains(offset) }
    }

    func apply(_ newStyles: [TextStyleRun], forLength length: Int?, to textView: NSTextView) {
        guard let storage = textView.textStorage, length == nil || length == storage.length,
              newStyles != styles || storage.length != appliedLength
        else {
            return
        }

        styles = newStyles
        appliedLength = storage.length
        marks = newStyles.filter { $0.kind == .mark }.map(\.span)
        checkboxes = newStyles.filter { $0.kind.isCheckbox }
        activeRange = MarkdownStyler.activeRange(in: textView)
        styled = IndexSet()
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

        guard storage.editedMask.isEmpty else {
            Task { [weak self, weak textView] in
                guard let self, let textView else {
                    return
                }
                styleVisibleText(in: textView)
            }
            return
        }

        let window = MarkdownStyler.window(around: textView)
        var missing = IndexSet(integersIn: window.location ..< NSMaxRange(window))
        missing.subtract(styled)
        guard missing.isEmpty == false else {
            return
        }

        styled.formUnion(missing)
        for range in missing.rangeView {
            MarkdownStyler.apply(styles, to: storage, in: NSRange(location: range.lowerBound, length: range.count), activeRange: activeRange, style: style)
        }
    }

    private func updateMarks(in textView: NSTextView) {
        let newRange = MarkdownStyler.activeRange(in: textView)
        guard let storage = textView.textStorage, newRange != activeRange, storage.length == appliedLength, storage.editedMask.isEmpty else {
            return
        }

        MarkdownStyler.fadeMarks(marks, checkboxes: checkboxes, in: storage, from: activeRange, to: newRange)
        activeRange = newRange
    }

    // MARK: - Scroll

    func scroll(_ textView: NSTextView, toOffset offset: Int) {
        guard let layout = textView.textLayoutManager, let content = textView.textContentStorage,
              let location = content.location(content.documentRange.location, offsetBy: min(offset, (textView.string as NSString).length)),
              let range = NSTextRange(location: content.documentRange.location, end: location)
        else {
            return
        }

        layout.ensureLayout(for: range)
        guard let fragment = layout.textLayoutFragment(for: location) else {
            return
        }

        textView.scroll(NSPoint(x: 0, y: fragment.layoutFragmentFrame.minY))
        styleVisibleText(in: textView)
    }

    // MARK: - Insertion

    func apply(_ insertion: TextInsertion?, to textView: NSTextView) {
        guard let insertion, insertion.id != lastInsertionID else {
            return
        }

        lastInsertionID = insertion.id
        textView.window?.makeFirstResponder(textView)
        textView.insertText(insertion.text, replacementRange: textView.selectedRange())
    }

    // MARK: - Reveal

    func apply(_ reveal: RevealRequest?, to textView: NSTextView) {
        guard let reveal, reveal.id != lastRevealID else {
            return
        }

        lastRevealID = reveal.id
        let offset = TextLineUseCase.utf16Offset(ofLine: reveal.line, in: textView.string)
        if let fold, offset > 0, fold.isInside(editAt: offset) {
            unfold(in: textView)
        }
        let range = NSRange(location: offset, length: 0)
        textView.setSelectedRange(range)
        Task { @MainActor in
            textView.scrollRangeToVisible(range)
        }
    }
}
