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

    @Test("the share is clamped so neither pane is narrower than the minimum")
    func clampsShare() {
        #expect(EditorPanes.clampedShare(0.5, availableWidth: 1000, minPaneWidth: 280) == 0.5)
        #expect(EditorPanes.clampedShare(0, availableWidth: 1000, minPaneWidth: 280) == 0.28)
        #expect(EditorPanes.clampedShare(1, availableWidth: 1000, minPaneWidth: 280) == 0.72)
        #expect(EditorPanes.clampedShare(-3, availableWidth: 1000, minPaneWidth: 280) == 0.28)
    }

    @Test("a width with no room for two minimum panes splits evenly")
    func evenWhenTight() {
        #expect(EditorPanes.clampedShare(0.9, availableWidth: 560, minPaneWidth: 280) == 0.5)
        #expect(EditorPanes.clampedShare(0.9, availableWidth: 400, minPaneWidth: 280) == 0.5)
    }

    @Test("the first pane's width follows the share and keeps both panes at the minimum after a resize")
    func firstPaneWidth() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.setSplitShare(0.9)
        #expect(panes.firstPaneWidth(availableWidth: 1000, minPaneWidth: 280) == 720)
        #expect(panes.firstPaneWidth(availableWidth: 700, minPaneWidth: 280) == 420)
        panes.setSplitShare(0.3)
        #expect(panes.firstPaneWidth(availableWidth: 1000, minPaneWidth: 280) == 300)
        #expect(panes.firstPaneWidth(availableWidth: 800, minPaneWidth: 280) == 280)
    }

    @Test("the share stays within 0 to 1 and resets to even")
    func setsAndResets() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.setSplitShare(2)
        #expect(panes.splitShare == 1)
        panes.setSplitShare(-1)
        #expect(panes.splitShare == 0)
        panes.setSplitShare(0.7)
        panes.resetSplitShare()
        #expect(panes.splitShare == EditorPanes.evenShare)
    }

    @Test("the share survives switching, adding, visiting and closing tabs and focusing panes")
    func shareSurvivesTabs() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.setSplitShare(0.65)
        panes.focused.add(Self.peas)
        panes.focused.select(panes.focused.tabs[0].id)
        panes.focused.visit(Self.peas)
        panes.focus(0)
        panes.focused.add(Self.peas)
        panes.focused.selectNeighbour(by: 1)
        panes.closeTab(panes.focused.tabs[1].id, inPane: 0)
        #expect(panes.isSplit)
        #expect(panes.splitShare == 0.65)
    }

    @Test("opening a new split or closing a pane starts even again")
    func splitStartsEven() {
        var panes = EditorPanes(TabList(paths: [Self.soil]))
        panes.splitRight()
        panes.setSplitShare(0.7)
        panes.closeTab(panes.panes[1].tabs[0].id, inPane: 1)
        #expect(panes.isSplit == false)
        #expect(panes.splitShare == EditorPanes.evenShare)
        panes.splitRight()
        #expect(panes.splitShare == EditorPanes.evenShare)
    }
}
