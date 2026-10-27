//
//  TextLineUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("TextLineUseCase", .tags(.domain))
struct TextLineUseCaseTests {
    @Test("finds the UTF-16 offset where a line starts", arguments: [(0, 0), (1, 5), (2, 9), (9, 11)])
    func offsets(line: Int, expected: Int) {
        #expect(TextLineUseCase.utf16Offset(ofLine: line, in: "a 🌱\nbcd\nef") == expected)
    }
}
