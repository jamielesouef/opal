//
//  LinkSuggestionPanel.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import AppKit
import OpalCore
import OpalDesign
import SwiftUI

@MainActor
final class LinkSuggestionPanel {
    // MARK: - Stored

    private var panel: NSPanel?
    private var hostingView: NSHostingView<LinkSuggestionList>?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    // MARK: - Show and hide

    func show(
        _ suggestions: [LinkSuggestion],
        selectedIndex: Int,
        below anchor: NSRect,
        in parent: NSWindow,
        onPick: @escaping (Int) -> Void
    ) {
        let list = LinkSuggestionList(suggestions: suggestions, selectedIndex: selectedIndex, onPick: onPick)
        let height = CGFloat(min(suggestions.count, EditorMetrics.suggestionMaxRows)) * EditorMetrics.suggestionRowHeight + AppSpacing.small
        let frame = NSRect(
            x: anchor.minX,
            y: anchor.minY - height - EditorMetrics.suggestionGap,
            width: EditorMetrics.suggestionWidth,
            height: height
        )

        let panel = panel ?? makePanel(with: list)
        hostingView?.rootView = list
        panel.setFrame(frame, display: true)
        if panel.parent == nil {
            parent.addChildWindow(panel, ordered: .above)
        }
        panel.orderFront(nil)
    }

    func hide() {
        guard let panel else {
            return
        }

        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    // MARK: - Private

    private func makePanel(with list: LinkSuggestionList) -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        let hosting = NSHostingView(rootView: list)
        hosting.sizingOptions = []
        panel.contentView = hosting
        self.panel = panel
        hostingView = hosting
        return panel
    }
}
