//
//  MarkdownTextView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore
import OpalDesign
import SwiftUI

struct MarkdownTextView: NSViewRepresentable {
    // MARK: - Input

    let text: String
    var styles: [TextStyleRun] = []
    var stylesLength: Int?
    var fold: FrontmatterFold?
    var reveal: RevealRequest?
    var insertion: TextInsertion?
    var initialTopOffset = 0
    var typeOnAppear: String?
    var takesFocusOnAppear = true
    var style = EditorStyle.defaults
    var onChange: (String) -> Void = { _ in }
    var onFollowLink: (Int) -> Void = { _ in }
    var onScroll: (Int) -> Void = { _ in }
    var linkSuggestions: (String) async -> [LinkSuggestion] = { _ in [] }
    var linkInsertion: (LinkSuggestion) -> String = { _ in "" }
    var onAttach: (Data, String?) async -> String? = { _, _ in nil }
    var onFocus: () -> Void = {}
    var onUnfold: () -> Void = {}

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> MarkdownTextViewCoordinator {
        MarkdownTextViewCoordinator(onChange: onChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = FocusingTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? FocusingTextView else {
            return scrollView
        }

        let coordinator = context.coordinator
        coordinator.style = style
        coordinator.onUnfold = onUnfold
        coordinator.apply(fold, to: textView)
        textView.editorStyle = style
        configure(textView)
        textView.takesFocusOnAppear = takesFocusOnAppear
        textView.onFocus = onFocus
        textView.string = text
        coordinator.lastText = text
        textView.delegate = coordinator
        textView.textContentStorage?.delegate = coordinator
        coordinator.enforceFold(in: textView)
        if let layoutManager = textView.textLayoutManager {
            layoutManager.delegate = coordinator
        } else {
            AppLog.error("The Editor fell back to TextKit 1; block styles are off.")
        }
        textView.isLink = { [weak coordinator] offset in
            coordinator?.isLink(at: offset) ?? false
        }
        textView.onFollowLink = { [weak coordinator] offset in
            coordinator?.onFollowLink(offset)
        }
        scrollView.contentView.postsBoundsChangedNotifications = true
        coordinator.boundsObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator, weak textView] _ in
            MainActor.assumeIsolated {
                guard let coordinator, let textView else {
                    return
                }
                coordinator.styleVisibleText(in: textView)
                coordinator.onScroll(textView.characterIndexForInsertion(at: textView.visibleRect.origin))
            }
        }
        textView.onAttach = onAttach
        textView.onToggleCheckbox = { [weak coordinator, weak textView] offset in
            guard let coordinator, let textView else {
                return false
            }
            return coordinator.toggleCheckbox(at: offset, in: textView)
        }
        textView.handleCommand = { [weak coordinator, weak textView] selector in
            guard let textView, let coordinator else {
                return false
            }
            return coordinator.handleCommand(selector, in: textView)
        }
        coordinator.onFollowLink = onFollowLink
        coordinator.onScroll = onScroll
        coordinator.linkSuggestions = linkSuggestions
        coordinator.linkInsertion = linkInsertion
        coordinator.apply(styles, forLength: stylesLength, to: textView)
        coordinator.apply(reveal, to: textView)
        coordinator.apply(insertion, to: textView)
        if initialTopOffset > 0 {
            let offset = initialTopOffset
            Task { @MainActor [weak coordinator, weak textView] in
                guard let coordinator, let textView else {
                    return
                }
                coordinator.scroll(textView, toOffset: offset)
            }
        }
        if let typeOnAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                let end = NSRange(location: (textView.string as NSString).length, length: 0)
                textView.setSelectedRange(end)
                textView.insertText(typeOnAppear, replacementRange: end)
            }
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onChange = onChange
        coordinator.onFollowLink = onFollowLink
        coordinator.onScroll = onScroll
        coordinator.onUnfold = onUnfold
        coordinator.linkSuggestions = linkSuggestions
        coordinator.linkInsertion = linkInsertion
        guard let textView = scrollView.documentView as? FocusingTextView else {
            return
        }

        coordinator.apply(fold, to: textView)

        textView.onAttach = onAttach
        textView.onFocus = onFocus

        if text != coordinator.lastText {
            coordinator.lastText = text
            if textView.string != text {
                textView.string = text
                textView.undoManager?.removeAllActions()
                coordinator.enforceFold(in: textView)
            }
        }

        coordinator.apply(styles, forLength: stylesLength, to: textView)
        coordinator.apply(reveal, to: textView)
        coordinator.apply(insertion, to: textView)
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: MarkdownTextViewCoordinator) {
        coordinator.dismantle()
        (scrollView.documentView as? NSTextView)?.delegate = nil
        (scrollView.documentView as? NSTextView)?.textLayoutManager?.delegate = nil
        (scrollView.documentView as? NSTextView)?.textContentStorage?.delegate = nil
        if let observer = coordinator.boundsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Helpers

    private func configure(_ textView: FocusingTextView) {
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isContinuousSpellCheckingEnabled = style.checksSpelling
        textView.font = style.font()
        textView.defaultParagraphStyle = style.paragraph
        textView.textColor = AppKitColor.text
        textView.backgroundColor = AppKitColor.editorBackground
        textView.textContainerInset = NSSize(width: style.horizontalInset(forWidth: textView.frame.width), height: EditorMetrics.textInset)
        textView.typingAttributes = style.baseAttributes
    }
}

#if DEBUG
    #Preview("Note") {
        let text = "# Soil\n\nSee [[Tomatoes]] and [[Nowhere]].\n"
        MarkdownTextView(
            text: text,
            styles: [
                TextStyleRun(span: TextSpan(location: 12, length: 12), kind: .link(isResolved: true)),
                TextStyleRun(span: TextSpan(location: 29, length: 11), kind: .link(isResolved: false))
            ]
        )
        .frame(width: 600, height: 300)
    }

    #Preview("Empty") {
        MarkdownTextView(text: "")
            .frame(width: 600, height: 300)
    }
#endif
