//
//  MarkdownTextViewCoordinator.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit

@MainActor
final class MarkdownTextViewCoordinator: NSObject, NSTextViewDelegate {
    // MARK: - Stored

    var onChange: (String) -> Void

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
}
