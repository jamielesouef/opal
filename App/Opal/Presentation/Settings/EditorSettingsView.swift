//
//  EditorSettingsView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalDesign
import SwiftUI

struct EditorSettingsView: View {
    // MARK: - Constants

    private enum Constants {
        static let sizes = 11 ... 24
        static let spacings: [Double] = [1, 1.2, 1.4, 1.6]
    }

    // MARK: - State

    @AppStorage(EditorPreferences.fontDesignKey) private var fontDesign = EditorFontDesign.system
    @AppStorage(EditorPreferences.fontSizeKey) private var fontSize = Double(EditorStyle.defaults.size)
    @AppStorage(EditorPreferences.lineSpacingKey) private var lineSpacing = Double(EditorStyle.defaults.lineSpacing)
    @AppStorage(EditorPreferences.lineWidthKey) private var lineWidth = Double(EditorStyle.defaults.lineWidth)
    @AppStorage(EditorPreferences.checksSpellingKey) private var checksSpelling = EditorStyle.defaults.checksSpelling
    @AppStorage(EditorPreferences.liveMarkdownKey) private var isLiveMarkdown = true

    // MARK: - View

    var body: some View {
        Form {
            Picker(String(localized: "Font"), selection: $fontDesign) {
                ForEach(EditorFontDesign.allCases) { design in
                    Text(design.title).tag(design)
                }
            }
            Picker(String(localized: "Size"), selection: $fontSize) {
                ForEach(Constants.sizes, id: \.self) { size in
                    Text(String(localized: "\(size) pt")).tag(Double(size))
                }
            }
            Picker(String(localized: "Line width"), selection: $lineWidth) {
                Text(String(localized: "Narrow")).tag(EditorMetrics.narrowLineWidth)
                Text(String(localized: "Readable")).tag(EditorMetrics.readableLineWidth)
                Text(String(localized: "Fill the window")).tag(0.0)
            }
            Picker(String(localized: "Line spacing"), selection: $lineSpacing) {
                ForEach(Constants.spacings, id: \.self) { spacing in
                    Text(spacing.formatted(.number.precision(.fractionLength(1)))).tag(spacing)
                }
            }
            Toggle(String(localized: "Check spelling while typing"), isOn: $checksSpelling)
            Toggle(String(localized: "Live Markdown"), isOn: $isLiveMarkdown)
                .help(String(localized: "Style Markdown as you type and dim its marks"))
        }
        .formStyle(.grouped)
    }
}
