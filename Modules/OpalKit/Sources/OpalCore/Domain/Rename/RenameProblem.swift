//
//  RenameProblem.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

public enum RenameProblem: Error, Hashable, Sendable {
    case empty
    case invalidCharacter(Character)
    case startsWithDot
    case taken(NotePath)
    case unchanged
}
