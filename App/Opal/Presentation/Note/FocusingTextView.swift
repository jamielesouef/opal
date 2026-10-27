//
//  FocusingTextView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit

final class FocusingTextView: NSTextView {
    // MARK: - Links

    var isLink: (Int) -> Bool = { _ in false }
    var onFollowLink: (Int) -> Void = { _ in }

    // MARK: - Commands

    var handleCommand: (Selector) -> Bool = { _ in false }

    // MARK: - NSView

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    // MARK: - NSResponder

    override func mouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(.command), let offset = linkOffset(at: event) else {
            super.mouseDown(with: event)
            return
        }

        onFollowLink(offset)
    }

    override func mouseMoved(with event: NSEvent) {
        guard event.modifierFlags.contains(.command), linkOffset(at: event) != nil else {
            super.mouseMoved(with: event)
            return
        }

        NSCursor.pointingHand.set()
    }

    // MARK: - NSTextView

    override func doCommand(by selector: Selector) {
        guard handleCommand(selector) == false else {
            return
        }

        super.doCommand(by: selector)
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            _ = handleCommand(#selector(NSResponder.cancelOperation(_:)))
        }
        return resigned
    }

    // MARK: - Private

    private func linkOffset(at event: NSEvent) -> Int? {
        let offset = characterIndexForInsertion(at: convert(event.locationInWindow, from: nil))
        return isLink(offset) ? offset : nil
    }
}
