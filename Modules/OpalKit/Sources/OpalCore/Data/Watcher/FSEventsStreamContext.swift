//
//  FSEventsStreamContext.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

final class FSEventsStreamContext: Sendable {
    // MARK: - Stored

    private let rootPaths: [String]
    private let continuation: AsyncStream<Set<NotePath>>.Continuation

    // MARK: - Init

    init(rootURL: URL, continuation: AsyncStream<Set<NotePath>>.Continuation) {
        let standard = rootURL.standardizedFileURL.path
        let resolved = realpath(standard, nil).map { pointer in
            defer { free(pointer) }
            return String(cString: pointer)
        } ?? standard
        rootPaths = Array(Set([standard, resolved])).map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        self.continuation = continuation
    }

    // MARK: - Events

    func receive(_ absolutePaths: [String]) {
        let paths = Set(absolutePaths.compactMap(notePath(for:)))
        guard paths.isEmpty == false else {
            return
        }

        continuation.yield(paths)
    }

    // MARK: - Private

    private func notePath(for absolutePath: String) -> NotePath? {
        guard let root = rootPaths.first(where: { absolutePath.hasPrefix($0) }) else {
            return nil
        }

        let path = NotePath(String(absolutePath.dropFirst(root.count)))
        guard path.isRoot == false, path.isHidden == false, path.isWithinVault else {
            return nil
        }

        return path
    }
}
