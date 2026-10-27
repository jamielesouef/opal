//
//  LinkResolverTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("LinkResolver", .tags(.domain))
struct LinkResolverTests {
    // MARK: - Fixtures

    private static let resolver = LinkResolver(
        paths: [
            "Soil.md",
            "Tomatoes.md",
            "Welcome.md",
            "Reading/The Soil Book.md",
            "Projects/Opal/Opal Roadmap.md",
            "Projects/Opal/Notes.md",
            "Archive/Old/Notes.md",
            "Areas/Notes.md",
            "Attachments/seedlings.png",
            "Areas/Health.md"
        ].map(NotePath.init),
        aliases: [NotePath("Soil.md"): ["Dirt", "Earth"], NotePath("Welcome.md"): ["Soil Book"]]
    )

    private static func resolve(_ target: String, from source: String = "Welcome.md") -> String? {
        resolver.resolve(target, from: NotePath(source))?.rawValue
    }

    // MARK: - Tests

    @Test(
        "resolves by path, name, case and suffix",
        arguments: [
            ("Soil", "Soil.md"),
            ("soil", "Soil.md"),
            ("Soil.md", "Soil.md"),
            ("Projects/Opal/Opal Roadmap", "Projects/Opal/Opal Roadmap.md"),
            ("Opal Roadmap", "Projects/Opal/Opal Roadmap.md"),
            ("Opal/Opal Roadmap", "Projects/Opal/Opal Roadmap.md"),
            ("The Soil Book", "Reading/The Soil Book.md"),
            ("seedlings.png", "Attachments/seedlings.png"),
            ("/Soil", "Soil.md")
        ]
    )
    func resolves(target: String, expected: String) {
        #expect(Self.resolve(target) == expected)
    }

    @Test("picks the shortest path, then name order, when names clash")
    func shortestPathWins() {
        #expect(Self.resolve("Notes") == "Areas/Notes.md")
    }

    @Test("prefers a path relative to the linking Note")
    func relative() {
        #expect(Self.resolve("Notes", from: "Projects/Opal/Opal Roadmap.md") == "Projects/Opal/Notes.md")
        #expect(Self.resolve("../Soil", from: "Areas/Health.md") == "Soil.md")
    }

    @Test("resolves an Alias only when no Note has that name")
    func aliases() {
        #expect(Self.resolve("Dirt") == "Soil.md")
        #expect(Self.resolve("earth") == "Soil.md")
        #expect(Self.resolve("The Soil Book") == "Reading/The Soil Book.md")
    }

    @Test("an empty target points at the linking Note")
    func selfLink() {
        #expect(Self.resolve("", from: "Tomatoes.md") == "Tomatoes.md")
    }

    @Test("a target that matches nothing is Unresolved", arguments: ["Ideas That Do Not Exist Yet", "Nowhere/Soil", "seedlings"])
    func unresolved(target: String) {
        #expect(Self.resolve(target) == nil)
    }
}
