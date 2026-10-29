//
//  FrontmatterFoldRule.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public enum FrontmatterFoldRule: Hashable, Sendable {
    case keep
    case moveTo(Int)
    case unfold
}
