//
//  MarkdownBlockFragment.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import AppKit
import OpalDesign

final class MarkdownBlockFragment: NSTextLayoutFragment {
    // MARK: - Stored

    private let block: MarkdownBlock?

    // MARK: - Init

    init(textElement: NSTextElement, range: NSTextRange?, block: MarkdownBlock?) {
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
            context.setFillColor(AppKitColor.divider.cgColor)
            context.fill(bar)
        case .callout:
            context.setFillColor(AppKitColor.calloutFill.cgColor)
            context.fill(frame)
            context.setFillColor(AppKitColor.accent.cgColor)
            context.fill(bar)
        case .code:
            context.setFillColor(AppKitColor.codeFill.cgColor)
            context.fill(frame)
        case nil:
            break
        }
        context.restoreGState()
        super.draw(at: point, in: context)
        drawCheckboxes(at: point, in: context)
    }

    // MARK: - Checkboxes

    private func drawCheckboxes(at point: CGPoint, in context: CGContext) {
        guard let text = (textElement as? NSTextParagraph)?.attributedString else {
            return
        }

        text.enumerateAttribute(MarkdownCheckbox.key, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let isDone = value as? Bool, let line = textLineFragments.first(where: { NSLocationInRange(range.location, $0.characterRange) }) else {
                return
            }

            let font = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: NSFont.systemFontSize)
            let start = line.locationForCharacter(at: range.location)
            let end = line.locationForCharacter(at: min(NSMaxRange(range), NSMaxRange(line.characterRange)))
            let palette: [NSColor] = isDone ? [AppKitColor.editorBackground, AppKitColor.accent] : [AppKitColor.secondaryText]
            let configuration = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular).applying(NSImage.SymbolConfiguration(paletteColors: palette))
            let name = isDone ? "checkmark.square.fill" : "square"
            guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(configuration) else {
                return
            }

            let size = image.size
            let baseline = point.y + line.typographicBounds.minY + start.y
            let rect = CGRect(
                x: point.x + line.typographicBounds.minX + (start.x + end.x - size.width) / 2,
                y: baseline - (font.capHeight + size.height) / 2,
                width: size.width,
                height: size.height
            )
            context.saveGState()
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()
            context.restoreGState()
        }
    }
}
