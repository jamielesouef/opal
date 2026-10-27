//
//  LaunchArguments.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

struct LaunchArguments {
    // MARK: - Constants

    private enum Constants {
        static let vaultPath = "-OpalVaultPath"
        static let defaultsSuite = "-OpalDefaultsSuite"
    }

    // MARK: - Stored

    let vaultURL: URL?
    let defaultsSuite: String?

    // MARK: - Init

    init(_ arguments: [String]) {
        vaultURL = Self.value(after: Constants.vaultPath, in: arguments).map { URL(filePath: $0, directoryHint: .isDirectory) }
        defaultsSuite = Self.value(after: Constants.defaultsSuite, in: arguments)
    }

    // MARK: - Private

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}
