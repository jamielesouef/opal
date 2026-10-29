//
//  PropertyIndexUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Testing
@testable import OpalCore

@Suite("Property index", .tags(.domain))
struct PropertyIndexUseCaseTests {
    // MARK: - Properties

    @Test("lists each Property with its inferred type and its items")
    func properties() {
        let text = "---\ntags: [a, b]\nrating: 4\nstatus: draft\nempty:\n---\nBody"

        #expect(PropertyIndexUseCase.properties(in: text) == [
            IndexedProperty(name: "tags", type: .tags, items: ["a", "b"]),
            IndexedProperty(name: "rating", type: .number, items: ["4"]),
            IndexedProperty(name: "status", type: .text, items: ["draft"]),
            IndexedProperty(name: "empty", type: .text, items: [])
        ])
    }

    @Test("a Note without frontmatter has no Properties")
    func none() {
        #expect(PropertyIndexUseCase.properties(in: "# Title").isEmpty)
    }

    // MARK: - Vault types

    @Test("the declared type wins, then the most common, then the first type in order on a tie")
    func resolved() {
        let counts: [String: [PropertyType: Int]] = [
            "a": [.number: 3, .text: 1],
            "b": [.number: 1, .text: 1],
            "c": [.number: 5],
            "d": [:]
        ]

        let types = PropertyIndexUseCase.resolvedTypes(counts: counts, declared: ["c": .text])

        #expect(types == ["a": .number, "b": .text, "c": .text])
    }
}
