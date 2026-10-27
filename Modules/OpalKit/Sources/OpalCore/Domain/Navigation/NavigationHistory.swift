//
//  NavigationHistory.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct NavigationHistory: Hashable, Sendable {
    // MARK: - Constants

    public static let limit = 100

    // MARK: - Stored

    public private(set) var back: [NotePath] = []
    public private(set) var forward: [NotePath] = []

    // MARK: - Init

    public init() {}

    // MARK: - Derived

    public var canGoBack: Bool {
        back.isEmpty == false
    }

    public var canGoForward: Bool {
        forward.isEmpty == false
    }

    // MARK: - Moves

    public mutating func visit(from current: NotePath?, to next: NotePath) {
        guard let current, current != next else {
            return
        }

        back.append(current)
        if back.count > Self.limit {
            back.removeFirst(back.count - Self.limit)
        }
        forward.removeAll()
    }

    public mutating func goBack(from current: NotePath?) -> NotePath? {
        guard let previous = back.popLast() else {
            return nil
        }

        if let current {
            forward.append(current)
        }
        return previous
    }

    public mutating func goForward(from current: NotePath?) -> NotePath? {
        guard let next = forward.popLast() else {
            return nil
        }

        if let current {
            back.append(current)
        }
        return next
    }

    public mutating func remove(_ path: NotePath) {
        back.removeAll { $0 == path }
        forward.removeAll { $0 == path }
    }
}
