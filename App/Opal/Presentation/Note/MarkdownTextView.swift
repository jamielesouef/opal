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
    var highlights: [LinkHighlight] = []
    var reveal: RevealRequest?
    var onChange: (String) -> Void = { _ in }
    var onFollowLink: (Int) -> Void = { _ in }

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
        configure(textView)
        textView.string = text
        textView.delegate = coordinator
        textView.isLink = { [weak coordinator] offset in
            coordinator?.isLink(at: offset) ?? false
        }
        textView.onFollowLink = { [weak coordinator] offset in
            coordinator?.onFollowLink(offset)
        }
        coordinator.onFollowLink = onFollowLink
        coordinator.apply(highlights, to: textView)
        coordinator.apply(reveal, to: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onChange = onChange
        coordinator.onFollowLink = onFollowLink
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        coordinator.apply(highlights, to: textView)
        coordinator.apply(reveal, to: textView)
    }

    // MARK: - Helpers

    private func configure(_ textView: NSTextView) {
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
        textView.isContinuousSpellCheckingEnabled = true
        textView.font = .systemFont(ofSize: EditorMetrics.fontSize)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: EditorMetrics.textInset, height: EditorMetrics.textInset)
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: EditorMetrics.fontSize),
            .foregroundColor: NSColor.textColor
        ]
    }
}

#if DEBUG
    #Preview("Note") {
        let text = "# Soil\n\nSee [[Tomatoes]] and [[Nowhere]].\n"
        MarkdownTextView(
            text: text,
            highlights: [
                LinkHighlight(span: TextSpan(location: 12, length: 12), isResolved: true),
                LinkHighlight(span: TextSpan(location: 29, length: 11), isResolved: false)
            ]
        )
        .frame(width: 600, height: 300)
    }

    #Preview("Empty") {
        MarkdownTextView(text: "")
            .frame(width: 600, height: 300)
    }
#endif
