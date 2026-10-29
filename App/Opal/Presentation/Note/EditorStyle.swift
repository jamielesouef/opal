//
//  EditorStyle.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit
import OpalDesign
import SwiftUI

struct EditorStyle: Hashable {
    // MARK: - Defaults

    static let defaults = EditorStyle()

    // MARK: - Stored

    var design = EditorFontDesign.system
    var size = EditorMetrics.fontSize
    var lineSpacing: CGFloat = 1
    var lineWidth: CGFloat = 0
    var checksSpelling = true

    // MARK: - Fonts

    func font(scale: CGFloat = 1, weight: NSFont.Weight = .regular) -> NSFont {
        let base = NSFont.systemFont(ofSize: size * scale, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(design.design) else {
            return base
        }

        return NSFont(descriptor: descriptor, size: size * scale) ?? base
    }

    var codeFont: NSFont {
        .monospacedSystemFont(ofSize: size * EditorMetrics.codeScale, weight: .regular)
    }

    // MARK: - Reading view

    var readingFont: Font {
        Font(font())
    }

    var readingCodeFont: Font {
        Font(codeFont)
    }

    var lineHeight: CGFloat {
        NSLayoutManager().defaultLineHeight(for: font()) * lineSpacing
    }

    // MARK: - Paragraphs

    var paragraph: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineSpacing
        return style
    }

    var indentedParagraph: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineSpacing
        style.firstLineHeadIndent = EditorMetrics.blockIndent
        style.headIndent = EditorMetrics.blockIndent
        return style
    }

    var baseAttributes: [NSAttributedString.Key: Any] {
        [.font: font(), .foregroundColor: AppKitColor.text, .paragraphStyle: paragraph]
    }

    // MARK: - Width

    func horizontalInset(forWidth width: CGFloat) -> CGFloat {
        guard lineWidth > 0 else {
            return EditorMetrics.textInset
        }

        return max(EditorMetrics.textInset, (width - lineWidth) / 2)
    }
}
