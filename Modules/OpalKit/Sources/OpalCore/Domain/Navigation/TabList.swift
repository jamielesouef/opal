//
//  TabList.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public struct TabList: Hashable, Sendable {
    // MARK: - Stored

    public private(set) var tabs: [NoteTab]
    public private(set) var selectedID: Int
    private var nextID: Int

    // MARK: - Init

    public init(paths: [NotePath] = []) {
        let opened = paths.isEmpty ? [nil] : paths.map(Optional.some)
        tabs = opened.enumerated().map { NoteTab(id: $0.offset, path: $0.element) }
        selectedID = 0
        nextID = opened.count
    }

    // MARK: - Derived

    public var selected: NoteTab {
        tabs.first { $0.id == selectedID } ?? tabs[0]
    }

    public var paths: [NotePath] {
        tabs.compactMap(\.path)
    }

    // MARK: - Selected tab

    public mutating func visit(_ path: NotePath) {
        update(selectedID) { tab in
            if tab.path != path {
                if let current = tab.path {
                    tab.history.visit(from: current, to: path)
                }
                tab.path = path
                tab.topOffset = 0
            }
        }
    }

    public mutating func goBack() -> NotePath? {
        var result: NotePath?
        update(selectedID) { tab in
            result = tab.history.goBack(from: tab.path)
            if let result {
                tab.path = result
            }
        }
        return result
    }

    public mutating func goForward() -> NotePath? {
        var result: NotePath?
        update(selectedID) { tab in
            result = tab.history.goForward(from: tab.path)
            if let result {
                tab.path = result
            }
        }
        return result
    }

    public mutating func setTopOffset(_ offset: Int) {
        update(selectedID) { $0.topOffset = offset }
    }

    // MARK: - Tabs

    public mutating func add(_ path: NotePath?) {
        let tab = NoteTab(id: nextID, path: path)
        nextID += 1
        let index = (tabs.firstIndex { $0.id == selectedID } ?? tabs.count - 1) + 1
        tabs.insert(tab, at: index)
        selectedID = tab.id
    }

    public mutating func select(_ id: Int) {
        if tabs.contains(where: { $0.id == id }) {
            selectedID = id
        }
    }

    public mutating func selectNeighbour(by offset: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == selectedID }), tabs.count > 1 else {
            return
        }

        selectedID = tabs[(index + offset + tabs.count) % tabs.count].id
    }

    public mutating func close(_ id: Int) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }

        guard tabs.count > 1 else {
            tabs[0] = NoteTab(id: nextID, path: nil)
            selectedID = nextID
            nextID += 1
            return
        }

        tabs.remove(at: index)
        if id == selectedID {
            selectedID = tabs[min(index, tabs.count - 1)].id
        }
    }

    // MARK: - Files

    public mutating func move(from old: NotePath, to new: NotePath) {
        for index in tabs.indices {
            if tabs[index].path == old {
                tabs[index].path = new
            }
            tabs[index].history.move(from: old, to: new)
        }
    }

    public mutating func forget(_ path: NotePath) {
        for index in tabs.indices {
            if tabs[index].path == path {
                tabs[index].path = nil
            }
            tabs[index].history.remove(path)
        }
    }

    // MARK: - Private

    private mutating func update(_ id: Int, _ change: (inout NoteTab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }

        change(&tabs[index])
    }
}
