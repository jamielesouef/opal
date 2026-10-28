//
//  CodeTokenizerTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("CodeTokenizer", .tags(.parser))
struct CodeTokenizerTests {
    @Test(
        "colours keywords, strings, numbers and comments",
        arguments: [
            ("swift", #"let soil = "loam" // rich"#, [("let", CodeTokenKind.keyword), (#""loam""#, .string), ("// rich", .comment)]),
            ("python", "def grow(n=3):  # seeds", [("def", .keyword), ("3", .number), ("# seeds", .comment)]),
            ("js", "const x = 'a' /* b */", [("const", .keyword), ("'a'", .string), ("/* b */", .comment)]),
            ("json", #"{"ok": true, "n": 12}"#, [(#""ok""#, .string), ("true", .keyword), (#""n""#, .string), ("12", .number)]),
            ("yaml", "tags: [a]\n# note", [("tags", .keyword), ("# note", .comment)]),
            ("sh", #"echo "hi" # say"#, [("echo", .keyword), (#""hi""#, .string), ("# say", .comment)])
        ]
    )
    func tokens(language: String, code: String, expected: [(String, CodeTokenKind)]) {
        let nsCode = code as NSString
        let found = CodeTokenizer.tokens(in: code, language: language).map {
            (nsCode.substring(with: NSRange(location: $0.span.location, length: $0.span.length)), $0.kind)
        }
        #expect(found.map(\.0) == expected.map(\.0))
        #expect(found.map(\.1) == expected.map(\.1))
    }

    @Test("leaves unknown languages plain")
    func unknown() {
        #expect(CodeTokenizer.tokens(in: "let a = 1", language: "cobol").isEmpty)
        #expect(CodeTokenizer.tokens(in: "let a = 1", language: nil).isEmpty)
    }
}
