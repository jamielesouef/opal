//
//  EditorPanesTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Testing
@testable import OpalCore

@Suite("EditorPanes")
struct EditorPanesTests {
    // MARK: - Constants

    private static let soil = NotePath("Soil.md")
    private static let peas = NotePath("Peas.md")

    // MARK: - Tests

    @Test("splitting opens the focused Note in a second pane, focuses it, and stops at two panes")
    func splits() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        #expect(panes.panes.map(\.paths) == [[Self.soil], [Self.soil]])
        #expect(panes.focusedIndex == 1)
        panes.splitRight()
        #expect(panes.panes.count == 2)
    }

    @Test("the other pane's Note is the one shown beside the focused Note")
    func otherPaths() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.focused.visit(Self.peas)
        #expect(panes.focusedPath == Self.peas)
        #expect(panes.otherPaths == [Self.soil])
        panes.focus(0)
        #expect(panes.otherPaths == [Self.peas])
    }

    @Test("closing the last tab of a pane closes the pane when there are two")
    func closesPane() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.focused.visit(Self.peas)
        panes.closeTab(panes.panes[0].tabs[0].id, inPane: 0)
        #expect(panes.panes.map(\.paths) == [[Self.peas]])
        #expect(panes.focusedIndex == 0)
    }

    @Test("closing the last tab of the only pane leaves an empty tab")
    func keepsOnlyPane() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.closeTab(panes.focused.tabs[0].id, inPane: 0)
        #expect(panes.panes.count == 1)
        #expect(panes.focusedPath == nil)
    }

    @Test("renames and deletes reach both panes")
    func filesReachBothPanes() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.move(from: Self.soil, to: Self.peas)
        #expect(panes.panes.map(\.paths) == [[Self.peas], [Self.peas]])
        panes.forget(Self.peas)
        #expect(panes.focusedPath == nil)
        #expect(panes.otherPaths.isEmpty)
    }
}
