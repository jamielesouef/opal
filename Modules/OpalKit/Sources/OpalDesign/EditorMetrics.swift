//
//  EditorMetrics.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public enum EditorMetrics {
    public static let fontSize: CGFloat = 15
    public static let textInset: CGFloat = 32
    public static let headingScales: [CGFloat] = [1.6, 1.4, 1.25, 1.12, 1.05, 1]
    public static let codeScale: CGFloat = 0.92
    public static let blockIndent: CGFloat = 14
    public static let blockBarWidth: CGFloat = 3
    public static let listIndent: CGFloat = 20
    public static let propertyNameWidth: CGFloat = 140
    public static let propertyIconWidth: CGFloat = 18
    public static let shortcutGroupWidth: CGFloat = 40
    public static let tabMaxWidth: CGFloat = 200
    public static let pdfEmbedHeight: CGFloat = 480
    public static let welcomeIconSize: CGFloat = 96
    public static let settingsWidth: CGFloat = 520
    public static let suggestionRowHeight: CGFloat = 40
    public static let suggestionMaxRows = 7
    public static let suggestionGap: CGFloat = 4
    public static let narrowLineWidth = 600.0
    public static let readableLineWidth = 720.0
    public static let sidebarMinWidth: CGFloat = 200
    public static let sidebarIdealWidth: CGFloat = 260
    public static let inspectorMinWidth: CGFloat = 220
    public static let inspectorIdealWidth: CGFloat = 280
    public static let inspectorMaxWidth: CGFloat = 420
    public static let paneMinWidth: CGFloat = 280
    public static let dividerThickness: CGFloat = 1
    public static let dividerGrabWidth: CGFloat = 9
    public static let dividerStep = 0.05
    public static let suggestionWidth: CGFloat = 320
    public static let switcherWidth: CGFloat = 560
    public static let switcherHeight: CGFloat = 380
    public static let welcomeWidth: CGFloat = 420
    public static let windowMinWidth: CGFloat = 640
    public static let windowMinHeight: CGFloat = 420
    public static let windowDefaultWidth: CGFloat = 1100
    public static let windowDefaultHeight: CGFloat = 720

    // MARK: - Derived

    public static func headingScale(level: Int) -> CGFloat {
        headingScales[min(max(level, 1), headingScales.count) - 1]
    }
}
