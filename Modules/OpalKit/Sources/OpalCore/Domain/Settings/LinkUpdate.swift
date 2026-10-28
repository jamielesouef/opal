//
//  LinkUpdate.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public enum LinkUpdate: String, Hashable, Sendable, Codable, CaseIterable {
    case ask
    case always
    case never
}
