//
//  NoteSaveDecisionUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("NoteSaveDecisionUseCase", .tags(.domain))
struct NoteSaveDecisionUseCaseTests {
    @Test("writes when the user edited and the file on disk is what Opal last saw")
    func write() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "ab", onDisk: "a") == .write)
    }

    @Test("does nothing when there are no edits and the file is unchanged")
    func unchanged() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "a", onDisk: "a") == .unchanged)
    }

    @Test("reports a conflict when both the draft and the file changed differently")
    func conflict() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "mine", onDisk: "theirs") == .conflict(diskText: "theirs"))
    }

    @Test("adopts the file when it changed and there are no edits, or it already holds the draft")
    func adopt() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "a", onDisk: "theirs") == .adoptDisk("theirs"))
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "same", onDisk: "same") == .adoptDisk("same"))
    }

    @Test("recreates a file deleted while open")
    func recreate() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a", draft: "a", onDisk: nil) == .recreate)
    }

    @Test("compares text exactly, so a line ending change on disk is a change")
    func exactComparison() {
        #expect(NoteSaveDecisionUseCase.decide(lastKnownDisk: "a\n", draft: "a\nb", onDisk: "a\r\n") == .conflict(diskText: "a\r\n"))
    }
}
