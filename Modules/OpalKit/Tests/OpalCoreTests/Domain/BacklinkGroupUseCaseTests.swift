//
//  BacklinkGroupUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("BacklinkGroupUseCase", .tags(.domain))
struct BacklinkGroupUseCaseTests {
    // MARK: - Fixtures

    private static func backlink(_ source: String, line: Int, text: String = "  See [[Soil]]. ") -> Backlink {
        Backlink(
            source: NotePath(source),
            link: Link(target: "Soil", span: TextSpan(location: line * 10, length: 8), line: line, lineText: text)
        )
    }

    // MARK: - Tests

    @Test("groups Backlinks by Note and keeps their order")
    func groups() {
        let groups = BacklinkGroupUseCase.groups([
            Self.backlink("A.md", line: 1),
            Self.backlink("A.md", line: 4),
            Self.backlink("B.md", line: 2)
        ])

        #expect(groups.map(\.source.rawValue) == ["A.md", "B.md"])
        #expect(groups.first?.backlinks.map(\.link.line) == [1, 4])
    }

    @Test("shows the line without its outer spaces")
    func context() {
        #expect(BacklinkGroupUseCase.context(of: Self.backlink("A.md", line: 0)) == "See [[Soil]].")
    }
}
