//
//  FocusingTextView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore
import OpalDesign

final class FocusingTextView: NSTextView {
    // MARK: - Links

    var isLink: (Int) -> Bool = { _ in false }
    var onFollowLink: (Int) -> Void = { _ in }
    var onToggleCheckbox: (Int) -> Bool = { _ in false }
    var onAttach: (Data, String?) async -> String? = { _, _ in nil }

    // MARK: - Commands

    var handleCommand: (Selector) -> Bool = { _ in false }

    // MARK: - Focus

    var takesFocusOnAppear = true
    var editorStyle = EditorStyle.defaults
    var onFocus: () -> Void = {}

    // MARK: - NSView

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        let inset = editorStyle.horizontalInset(forWidth: newSize.width)
        if textContainerInset.width != inset {
            textContainerInset = NSSize(width: inset, height: EditorMetrics.textInset)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if takesFocusOnAppear {
            window?.makeFirstResponder(self)
        }
    }

    // MARK: - NSResponder

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted {
            onFocus()
        }
        return accepted
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), let offset = linkOffset(at: event) {
            onFollowLink(offset)
            return
        }

        let offset = characterIndexForInsertion(at: convert(event.locationInWindow, from: nil))
        if event.modifierFlags.isDisjoint(with: [.command, .shift, .option, .control]), event.clickCount == 1, onToggleCheckbox(offset) {
            return
        }

        super.mouseDown(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        guard event.modifierFlags.contains(.command), linkOffset(at: event) != nil else {
            super.mouseMoved(with: event)
            return
        }

        NSCursor.pointingHand.set()
    }

    // MARK: - Attachments

    override func paste(_ sender: Any?) {
        let board = NSPasteboard.general
        let files = imageFiles(on: board)
        if files.isEmpty == false {
            attach(files, at: selectedRange())
            return
        }

        if board.string(forType: .string) == nil, let data = pngData(on: board) {
            attach(data: [(data, nil)], at: selectedRange())
            return
        }

        super.paste(sender)
    }

    override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        super.acceptableDragTypes + [.fileURL]
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let files = imageFiles(on: sender.draggingPasteboard)
        guard files.isEmpty == false else {
            return super.performDragOperation(sender)
        }

        let offset = characterIndexForInsertion(at: convert(sender.draggingLocation, from: nil))
        attach(files, at: NSRange(location: offset, length: 0))
        return true
    }

    private func imageFiles(on board: NSPasteboard) -> [URL] {
        let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        return urls.filter { EmbedUseCase.media(of: NotePath($0.lastPathComponent)) == .image }
    }

    @concurrent
    private nonisolated static func read(_ urls: [URL]) async -> [(Data, String?)] {
        urls.compactMap { url in (try? Data(contentsOf: url)).map { ($0, url.lastPathComponent) } }
    }

    private func pngData(on board: NSPasteboard) -> Data? {
        if let png = board.data(forType: .png) {
            return png
        }

        return board.data(forType: .tiff).flatMap(NSBitmapImageRep.init(data:))?.representation(using: .png, properties: [:])
    }

    private func attach(_ urls: [URL], at range: NSRange) {
        Task {
            attach(data: await Self.read(urls), at: range)
        }
    }

    private func attach(data files: [(Data, String?)], at range: NSRange) {
        Task {
            var embeds: [String] = []
            for (data, name) in files {
                if let embed = await onAttach(data, name) {
                    embeds.append(embed)
                }
            }
            guard embeds.isEmpty == false else {
                NSSound.beep()
                return
            }

            let length = (string as NSString).length
            let location = min(range.location, length)
            insertText(embeds.joined(separator: " "), replacementRange: NSRange(location: location, length: min(range.length, length - location)))
        }
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
