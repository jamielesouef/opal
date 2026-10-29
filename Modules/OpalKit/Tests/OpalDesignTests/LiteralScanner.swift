//
//  LiteralScanner.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

struct LiteralViolation: Equatable {
    let line: Int
    let rule: String
    let text: String
}

enum LiteralScanner {
    // MARK: - Rules

    private static let hues = "red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|white|gray|black"
    private static let number = "[0-9]*[1-9][0-9]*(\\.[0-9]+)?"

    private static let rules: [(name: String, pattern: String)] = [
        ("literal colour", "\\b(Color|NSColor)\\((red|white|hue|hex|srgbRed|calibratedRed|deviceRed)\\b"),
        ("literal colour", "\\b(Color|NSColor)\\(\\.(sRGB|displayP3)"),
        ("literal colour", "\\b(Color|NSColor)\\.(\(hues))\\b"),
        ("literal colour", "(?<![\\w)\\]])\\.(\(hues))\\b"),
        ("literal colour", "\\bNSColor\\.system(Red|Orange|Yellow|Green|Mint|Teal|Cyan|Blue|Indigo|Purple|Pink|Brown|Gray)\\b"),
        ("literal colour", "0x[0-9A-Fa-f]{6}\\b"),
        ("literal opacity", "\\.opacity\\([^)]*[0-9]\\.[0-9]"),
        ("literal opacity", "withAlphaComponent\\(\\s*[0-9]"),
        ("literal spacing", "\\.padding\\((\\.\\w+,\\s*)?\(number)\\)"),
        ("literal spacing", "\\bspacing: \(number)"),
        ("literal spacing", "AppSpacing\\.\\w+\\s*[-+*/]\\s*[0-9]"),
        ("literal radius", "\\bcornerRadius: \(number)"),
        ("literal radius", "\\.cornerRadius\\("),
        ("literal radius", "\\bradius: \(number)"),
        ("literal frame", "\\.frame\\([^)]*\\b(width|height|minWidth|maxWidth|minHeight|maxHeight|idealWidth|idealHeight): \(number)"),
        ("literal font size", "\\b(size|ofSize): \(number)"),
        ("literal metric", "\\bstatic let \\w+: (CGFloat|Double) = [0-9]"),
        ("literal metric", "\\bstatic let \\w+ = [0-9]+\\.[0-9]+\\s*$"),
        ("literal animation", "\\.(easeInOut|easeIn|easeOut|linear|spring|snappy|bouncy|smooth|interactiveSpring)\\b"),
        ("literal animation", "\\bduration: [0-9]"),
        ("literal animation", "\\.milliseconds\\(")
    ]

    // MARK: - Scan

    static func violations(in source: String) -> [LiteralViolation] {
        var found: [LiteralViolation] = []
        for (index, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let text = String(line)
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#if DEBUG") || trimmed.hasPrefix("#Preview") {
                break
            }
            if trimmed.hasPrefix("//") {
                continue
            }
            for rule in rules where text.range(of: rule.pattern, options: .regularExpression) != nil {
                found.append(LiteralViolation(line: index + 1, rule: rule.name, text: trimmed))
            }
        }
        return found
    }
}
