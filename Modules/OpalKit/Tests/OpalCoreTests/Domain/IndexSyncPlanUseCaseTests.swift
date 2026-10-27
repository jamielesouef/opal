//
//  IndexSyncPlanUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("IndexSyncPlanUseCase", .tags(.domain))
struct IndexSyncPlanUseCaseTests {
    // MARK: - Fixtures

    private static func stamp(_ seconds: Double, _ size: Int = 10) -> FileStamp {
        FileStamp(modified: Date(timeIntervalSinceReferenceDate: seconds), size: size)
    }

    // MARK: - Tests

    @Test("reads new and changed Notes, removes Notes gone from disk, skips the rest")
    func plan() {
        let plan = IndexSyncPlanUseCase.plan(
            disk: [
                NotePath("Same.md"): Self.stamp(1),
                NotePath("Newer.md"): Self.stamp(5),
                NotePath("Bigger.md"): Self.stamp(1, 20),
                NotePath("New.md"): Self.stamp(1)
            ],
            indexed: [
                NotePath("Same.md"): Self.stamp(1),
                NotePath("Newer.md"): Self.stamp(4),
                NotePath("Bigger.md"): Self.stamp(1, 10),
                NotePath("Gone.md"): Self.stamp(1)
            ]
        )

        #expect(plan.toRead == [NotePath("Bigger.md"), NotePath("New.md"), NotePath("Newer.md")])
        #expect(plan.toRemove == [NotePath("Gone.md")])
    }

    @Test("an unchanged Vault needs nothing")
    func empty() {
        #expect(IndexSyncPlanUseCase.plan(disk: [NotePath("A.md"): Self.stamp(1)], indexed: [NotePath("A.md"): Self.stamp(1)]).isEmpty)
    }
}
