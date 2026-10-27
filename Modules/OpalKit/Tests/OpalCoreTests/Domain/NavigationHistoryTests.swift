//
//  NavigationHistoryTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Testing
@testable import OpalCore

@Suite("NavigationHistory", .tags(.domain))
struct NavigationHistoryTests {
    // MARK: - Tests

    @Test("going back and forward retraces the Notes visited")
    func backAndForward() {
        var history = NavigationHistory()
        history.visit(from: NotePath("A.md"), to: NotePath("B.md"))
        history.visit(from: NotePath("B.md"), to: NotePath("C.md"))

        #expect(history.goBack(from: NotePath("C.md")) == NotePath("B.md"))
        #expect(history.goBack(from: NotePath("B.md")) == NotePath("A.md"))
        #expect(history.canGoBack == false)
        #expect(history.goForward(from: NotePath("A.md")) == NotePath("B.md"))
        #expect(history.canGoForward)
    }

    @Test("a new visit clears forward")
    func visitClearsForward() {
        var history = NavigationHistory()
        history.visit(from: NotePath("A.md"), to: NotePath("B.md"))
        _ = history.goBack(from: NotePath("B.md"))
        history.visit(from: NotePath("A.md"), to: NotePath("D.md"))

        #expect(history.canGoForward == false)
        #expect(history.back == [NotePath("A.md")])
    }

    @Test("no Note open or the same Note adds nothing")
    func ignoresNoOp() {
        var history = NavigationHistory()
        history.visit(from: nil, to: NotePath("A.md"))
        history.visit(from: NotePath("A.md"), to: NotePath("A.md"))

        #expect(history.canGoBack == false)
    }

    @Test("keeps at most the limit")
    func limit() {
        var history = NavigationHistory()
        for index in 0 ... NavigationHistory.limit + 5 {
            history.visit(from: NotePath("\(index).md"), to: NotePath("\(index + 1).md"))
        }

        #expect(history.back.count == NavigationHistory.limit)
    }
}
