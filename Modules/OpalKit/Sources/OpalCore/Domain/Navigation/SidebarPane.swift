//
//  SidebarPane.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public enum SidebarPane: String, CaseIterable, Hashable, Sendable, Identifiable {
    case files
    case search
    case tags

    // MARK: - Identifiable

    public var id: Self {
        self
    }
}
