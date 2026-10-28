//
//  NotePath.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public struct NotePath: Hashable, Sendable, Codable, CustomStringConvertible {
    // MARK: - Constants

    public static let noteExtension = "md"
    public static let root = NotePath(components: [])

    // MARK: - Stored

    public let components: [String]

    // MARK: - Init

    public init(components: [String]) {
        self.components = components
    }

    public init(_ rawValue: String) {
        components = rawValue
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
    }

    // MARK: - Derived

    public var rawValue: String {
        components.joined(separator: "/")
    }

    public var isRoot: Bool {
        components.isEmpty
    }

    public var fileName: String {
        components.last ?? ""
    }

    public var fileExtension: String {
        guard let dot = fileName.lastIndex(of: "."), dot != fileName.startIndex else {
            return ""
        }

        return String(fileName[fileName.index(after: dot)...])
    }

    public var isNote: Bool {
        fileExtension.lowercased() == Self.noteExtension
    }

    public var name: String {
        guard isNote else {
            return fileName
        }

        return String(fileName.dropLast(Self.noteExtension.count + 1))
    }

    public var parent: NotePath {
        NotePath(components: Array(components.dropLast()))
    }

    public var ancestors: [NotePath] {
        components.indices.dropLast().map { NotePath(components: Array(components[...$0])) }
    }

    public var isHidden: Bool {
        components.contains { $0.hasPrefix(".") }
    }

    public var isWithinVault: Bool {
        components.allSatisfy { $0 != "." && $0 != ".." && $0.contains("/") == false }
    }

    // MARK: - Building

    public func appending(_ component: String) -> NotePath {
        NotePath(components: components + [component])
    }

    public var appendingNoteExtension: NotePath {
        guard let last = components.last else {
            return self
        }

        return NotePath(components: components.dropLast() + ["\(last).\(Self.noteExtension)"])
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        rawValue
    }
}
