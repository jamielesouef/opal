//
//  NewFileLocation.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum NewFileLocation: String, Hashable, Sendable, Codable, CaseIterable {
    case root
    case current
    case folder
}
