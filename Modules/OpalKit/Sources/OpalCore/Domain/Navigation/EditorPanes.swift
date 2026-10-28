//
//  EditorPanes.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct EditorPanes: Hashable, Sendable {
    // MARK: - Constants

    public static let maxCount = 2

    // MARK: - Stored

    public private(set) var panes: [TabList]
    public private(set) var focusedIndex = 0

    // MARK: - Init

    public init(_ first: TabList = TabList()) {
        panes = [first]
    }

    // MARK: - Derived

    public var focused: TabList {
        get { panes[focusedIndex] }
        set { panes[focusedIndex] = newValue }
    }

    public var isSplit: Bool {
        panes.count > 1
    }

    public var focusedPath: NotePath? {
        focused.selected.path
    }

    public var otherPaths: Set<NotePath> {
        Set(panes.indices.filter { $0 != focusedIndex }.compactMap { panes[$0].selected.path })
    }

    // MARK: - Panes

    public mutating func splitRight() {
        guard panes.count < Self.maxCount else {
            return
        }

        panes.insert(TabList(paths: focused.selected.path.map { [$0] } ?? []), at: focusedIndex + 1)
        focusedIndex += 1
    }

    public mutating func focus(_ index: Int) {
        if panes.indices.contains(index) {
            focusedIndex = index
        }
    }

    public mutating func closeTab(_ id: Int, inPane index: Int) {
        guard panes.indices.contains(index) else {
            return
        }

        guard isSplit, panes[index].tabs.count == 1, panes[index].tabs[0].id == id else {
            panes[index].close(id)
            return
        }

        panes.remove(at: index)
        focusedIndex = min(focusedIndex > index ? focusedIndex - 1 : focusedIndex, panes.count - 1)
    }

    // MARK: - Files

    public mutating func move(from old: NotePath, to new: NotePath) {
        for index in panes.indices {
            panes[index].move(from: old, to: new)
        }
    }

    public mutating func forget(_ path: NotePath) {
        for index in panes.indices {
            panes[index].forget(path)
        }
    }
}
