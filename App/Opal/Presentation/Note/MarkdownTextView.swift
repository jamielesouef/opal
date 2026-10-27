//
//  MarkdownTextView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalDesign
import SwiftUI

struct MarkdownTextView: NSViewRepresentable {
    // MARK: - Input

    let text: String
    var onChange: (String) -> Void = { _ in }

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> MarkdownTextViewCoordinator {
        MarkdownTextViewCoordinator(onChange: onChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = FocusingTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        configure(textView)
        textView.string = text
        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onChange = onChange
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else {
            return
        }

        textView.string = text
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
    }
}

#if DEBUG
    #Preview("Note") {
        MarkdownTextView(text: "---\ntags: [garden]\n---\n# Soil\n\nSoil is a mix of sand, silt, clay and organic matter.\n")
            .frame(width: 600, height: 300)
    }

    #Preview("Empty") {
        MarkdownTextView(text: "")
            .frame(width: 600, height: 300)
    }
#endif
