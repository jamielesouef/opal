//
//  TabListTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Testing
@testable import OpalCore

@Suite("TabList")
struct TabListTests {
    // MARK: - Constants

    private static let soil = NotePath("Soil.md")
    private static let peas = NotePath("Peas.md")
    private static let welcome = NotePath("Welcome.md")

    // MARK: - Tests

    @Test("each tab keeps its own history")
    func histories() {
        var tabs = TabList(paths: [Self.welcome])
        tabs.visit(Self.soil)
        tabs.add(Self.peas)
        #expect(tabs.selected.history.canGoBack == false)
        tabs.select(tabs.tabs[0].id)
        #expect(tabs.goBack() == Self.welcome)
        #expect(tabs.selected.path == Self.welcome)
    }

    @Test("a new tab opens after the selected one and is selected")
    func adds() {
        var tabs = TabList(paths: [Self.welcome, Self.soil])
        tabs.select(tabs.tabs[0].id)
        tabs.add(Self.peas)
        #expect(tabs.paths == [Self.welcome, Self.peas, Self.soil])
        #expect(tabs.selected.path == Self.peas)
    }

    @Test("closing selects a neighbour, and closing the last tab leaves one empty tab")
    func closes() {
        var tabs = TabList(paths: [Self.welcome, Self.soil, Self.peas])
        tabs.select(tabs.tabs[1].id)
        tabs.close(tabs.selectedID)
        #expect(tabs.selected.path == Self.peas)
        tabs.close(tabs.tabs[0].id)
        tabs.close(tabs.tabs[0].id)
        #expect(tabs.tabs.count == 1)
        #expect(tabs.selected.path == nil)
    }

    @Test("Control-Tab cycles, and renames and deletes follow the files")
    func cyclesAndFollows() {
        var tabs = TabList(paths: [Self.welcome, Self.soil])
        tabs.selectNeighbour(by: 1)
        #expect(tabs.selected.path == Self.soil)
        tabs.selectNeighbour(by: 1)
        #expect(tabs.selected.path == Self.welcome)
        tabs.move(from: Self.soil, to: Self.peas)
        #expect(tabs.paths == [Self.welcome, Self.peas])
        tabs.forget(Self.peas)
        #expect(tabs.paths == [Self.welcome])
    }

    @Test("a tab remembers its scroll position")
    func scroll() {
        var tabs = TabList(paths: [Self.welcome])
        tabs.setTopOffset(420)
        tabs.add(Self.soil)
        #expect(tabs.selected.topOffset == 0)
        tabs.select(tabs.tabs[0].id)
        #expect(tabs.selected.topOffset == 420)
    }
}
