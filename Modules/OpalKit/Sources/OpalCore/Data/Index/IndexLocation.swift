//
//  IndexLocation.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import CryptoKit
import Foundation

public enum IndexLocation {
    // MARK: - Constants

    private enum Constants {
        static let idLength = 16
    }

    // MARK: - Folder

    public static func folder(forVaultAt rootURL: URL, in baseURL: URL) -> URL {
        let digest = SHA256.hash(data: Data(rootURL.standardizedFileURL.path.utf8))
        let id = digest.map { String(format: "%02x", $0) }.joined().prefix(Constants.idLength)
        return baseURL.appending(component: String(id), directoryHint: .isDirectory)
    }
}
