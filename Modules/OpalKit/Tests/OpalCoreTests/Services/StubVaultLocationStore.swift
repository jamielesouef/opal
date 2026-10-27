//
//  StubVaultLocationStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
@testable import OpalCore

actor StubVaultLocationStore: VaultLocationStoring {
    // MARK: - Stored

    private(set) var bookmark: Data?
    private(set) var setCount = 0

    // MARK: - Init

    init(bookmark: Data? = nil) {
        self.bookmark = bookmark
    }

    // MARK: - VaultLocationStoring

    func lastVaultBookmark() -> Data? {
        bookmark
    }

    func setLastVaultBookmark(_ bookmark: Data?) {
        setCount += 1
        self.bookmark = bookmark
    }
}
