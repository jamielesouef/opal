//
//  VaultWatching.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public protocol VaultWatching: Sendable {
    func changes() -> AsyncStream<Set<NotePath>>
}
