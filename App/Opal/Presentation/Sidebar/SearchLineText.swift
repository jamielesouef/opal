//
//  SearchLineText.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

enum SearchLineText {
    // MARK: - Attributed

    static func attributed(_ line: SearchLine) -> AttributedString {
        var text = AttributedString(line.text)
        let utf16 = line.text.utf16
        for span in line.highlights {
            guard span.upperBound <= utf16.count,
                  let start = String.Index(utf16.index(utf16.startIndex, offsetBy: span.location), within: line.text),
                  let end = String.Index(utf16.index(utf16.startIndex, offsetBy: span.upperBound), within: line.text),
                  let lower = AttributedString.Index(start, within: text),
                  let upper = AttributedString.Index(end, within: text)
            else {
                continue
            }
            text[lower ..< upper].inlinePresentationIntent = .stronglyEmphasized
            text[lower ..< upper].backgroundColor = AppColor.searchMatch
        }
        return text
    }
}
