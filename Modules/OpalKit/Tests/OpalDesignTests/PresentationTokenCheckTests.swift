//
//  PresentationTokenCheckTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing

@Suite("Presentation uses design tokens")
struct PresentationTokenCheckTests {
    // MARK: - Locations

    private static let presentation = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "App/Opal/Presentation", directoryHint: .isDirectory)

    // MARK: - Check

    @Test("no view in Presentation uses a literal colour, spacing, radius, size or animation")
    func noLiterals() throws {
        let enumerator = try #require(FileManager.default.enumerator(at: Self.presentation, includingPropertiesForKeys: nil))
        var files = 0
        var problems: [String] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            files += 1
            let source = try String(contentsOf: url, encoding: .utf8)
            for violation in LiteralScanner.violations(in: source) {
                problems.append("\(url.lastPathComponent):\(violation.line) \(violation.rule): \(violation.text)")
            }
        }
        #expect(files > 50)
        #expect(problems.isEmpty, "Use OpalDesign tokens (docs/design/DESIGN-SYSTEM.md):\n\(problems.joined(separator: "\n"))")
    }
}
