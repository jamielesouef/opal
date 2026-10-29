//
//  AppColor.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit
import SwiftUI

public enum AppColor {
    public static let accent = Color.accentColor
    public static let onAccent = Color.white
    public static let editorBackground = Color(nsColor: .textBackgroundColor)
    public static let codeFill = Color(nsColor: .quaternarySystemFill)
    public static let calloutFill = accent.opacity(AppOpacity.callout)
    public static let tagFill = accent.opacity(AppOpacity.tag)
    public static let unresolvedLink = accent.opacity(AppOpacity.unresolved)
    public static let searchMatch = accent.opacity(AppOpacity.searchMatch)
    public static let highlight = Color.yellow.opacity(AppOpacity.highlight)
    public static let failure = Color.red
    public static let codeKeyword = Color.purple
    public static let codeString = Color.red
    public static let codeNumber = Color.blue
    public static let codeComment = Color.secondary
}
