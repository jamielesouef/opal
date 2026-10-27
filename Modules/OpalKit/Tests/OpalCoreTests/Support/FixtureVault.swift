//
//  FixtureVault.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

struct FixtureVault {
    // MARK: - Constants

    private enum Constants {
        static let fixturesFolder = "Fixtures/Vaults"
    }

    // MARK: - Stored

    let rootURL: URL
    let containerURL: URL

    // MARK: - Init

    init(named name: String = "Garden") throws {
        let fileManager = FileManager()
        guard let resources = Bundle.module.resourceURL else {
            throw CocoaError(.fileNoSuchFile)
        }

        let source = resources.appending(path: Constants.fixturesFolder).appending(component: name)
        containerURL = fileManager.temporaryDirectory.appending(component: "OpalTests-\(UUID().uuidString)")
        rootURL = containerURL.appending(component: name)
        try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
        try fileManager.copyItem(at: source, to: rootURL)
    }

    static func empty() throws -> FixtureVault {
        let vault = try FixtureVault()
        let fileManager = FileManager()
        for item in try fileManager.contentsOfDirectory(at: vault.rootURL, includingPropertiesForKeys: nil) {
            try fileManager.removeItem(at: item)
        }
        return vault
    }

    // MARK: - Files

    func url(_ relativePath: String) -> URL {
        rootURL.appending(path: relativePath)
    }

    func text(_ relativePath: String) throws -> String {
        try String(contentsOf: url(relativePath), encoding: .utf8)
    }

    func write(_ text: String, to relativePath: String) throws {
        try Data(text.utf8).write(to: url(relativePath))
    }

    func remove() {
        try? FileManager().removeItem(at: containerURL)
    }
}
