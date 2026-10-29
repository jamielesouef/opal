//
//  WindowReaderView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit

final class WindowReaderView: NSView {
    // MARK: - Stored

    var onWindow: @MainActor (NSWindow?) -> Void = { _ in }

    // MARK: - NSView

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Task { @MainActor [window, onWindow] in
            onWindow(window)
        }
    }
}
