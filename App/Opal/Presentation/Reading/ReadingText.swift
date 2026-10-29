//
//  ReadingText.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

enum ReadingText {
    // MARK: - Constants

    private enum Constants {
        static let linkScheme = "opal-link"
    }

    // MARK: - Inline

    static func attributed(_ inlines: [ReadingInline]) -> AttributedString {
        inlines.reduce(into: AttributedString()) { result, inline in
            var part = AttributedString(inline.text)
            var intent: InlinePresentationIntent = []
            if inline.styles.contains(.bold) {
                intent.insert(.stronglyEmphasized)
            }
            if inline.styles.contains(.italic) {
                intent.insert(.emphasized)
            }
            if inline.styles.contains(.strikethrough) {
                intent.insert(.strikethrough)
            }
            if inline.styles.contains(.code) {
                intent.insert(.code)
            }
            part.inlinePresentationIntent = intent.isEmpty ? nil : intent
            if inline.styles.contains(.highlight) {
                part.backgroundColor = AppColor.highlight
            }
            if inline.styles.contains(.tag) {
                part.foregroundColor = AppColor.accent
                part.backgroundColor = AppColor.tagFill
            }
            if let link = inline.link {
                part.link = linkURL(link)
                part.foregroundColor = inline.isResolved ? AppColor.accent : AppColor.unresolvedLink
            }
            result += part
        }
    }

    // MARK: - Links

    static func linkURL(_ link: OpalCore.Link) -> URL? {
        URL(string: "\(Constants.linkScheme):\(link.span.location)")
    }

    static func linkOffset(of url: URL) -> Int? {
        guard url.scheme == Constants.linkScheme else {
            return nil
        }

        return Int(url.absoluteString.dropFirst(Constants.linkScheme.count + 1))
    }

    // MARK: - Code

    static func code(_ text: String, language: String?) -> AttributedString {
        var result = AttributedString(text)
        let characters = Array(text.utf16)
        for token in CodeTokenizer.tokens(in: text, language: language) {
            guard let lower = String.Index(utf16Offset: token.span.location, in: text).samePosition(in: text.unicodeScalars),
                  let upper = String.Index(utf16Offset: min(token.span.upperBound, characters.count), in: text).samePosition(in: text.unicodeScalars),
                  let start = AttributedString.Index(lower, within: result),
                  let end = AttributedString.Index(upper, within: result)
            else {
                continue
            }

            result[start ..< end].foregroundColor = color(token.kind)
        }
        return result
    }

    private static func color(_ kind: CodeTokenKind) -> Color {
        switch kind {
        case .keyword:
            AppColor.codeKeyword
        case .string:
            AppColor.codeString
        case .number:
            AppColor.codeNumber
        case .comment:
            AppColor.codeComment
        }
    }
}
