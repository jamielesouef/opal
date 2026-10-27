//
//  VaultLocationStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation

public protocol VaultLocationStoring: Sendable {
    func lastVaultBookmark() async -> Data?
    func setLastVaultBookmark(_ bookmark: Data?) async
}
