//
//  MarkdownBlockFragment.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import AppKit
import OpalDesign

final class MarkdownBlockFragment: NSTextLayoutFragment {
    // MARK: - Constants

    private enum Constants {
        static let calloutAlpha: CGFloat = 0.08
    }

    // MARK: - Stored

    private let block: MarkdownBlock

    // MARK: - Init

    init(textElement: NSTextElement, range: NSTextRange?, block: MarkdownBlock) {
        self.block = block
        super.init(textElement: textElement, range: range)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Derived

    private var blockWidth: CGFloat {
        let containerWidth = textLayoutManager?.textContainer?.size.width ?? layoutFragmentFrame.maxX
        return max(containerWidth - layoutFragmentFrame.minX, layoutFragmentFrame.width)
    }

    // MARK: - NSTextLayoutFragment

    override var renderingSurfaceBounds: CGRect {
        super.renderingSurfaceBounds.union(CGRect(x: 0, y: 0, width: blockWidth, height: layoutFragmentFrame.height))
    }

    override func draw(at point: CGPoint, in context: CGContext) {
        let frame = CGRect(x: point.x, y: point.y, width: blockWidth, height: layoutFragmentFrame.height)
        let bar = CGRect(x: frame.minX, y: frame.minY, width: EditorMetrics.blockBarWidth, height: frame.height)
        context.saveGState()
        switch block {
        case .quote:
            context.setFillColor(NSColor.separatorColor.cgColor)
            context.fill(bar)
        case .callout:
            context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(Constants.calloutAlpha).cgColor)
            context.fill(frame)
            context.setFillColor(NSColor.controlAccentColor.cgColor)
            context.fill(bar)
        case .code:
            context.setFillColor(NSColor.quaternarySystemFill.cgColor)
            context.fill(frame)
        }
        context.restoreGState()
        super.draw(at: point, in: context)
    }
}
