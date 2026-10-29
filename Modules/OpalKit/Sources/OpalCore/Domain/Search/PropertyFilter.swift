//
//  PropertyFilter.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct PropertyFilter: Hashable, Sendable {
    // MARK: - Stored

    public let name: String
    public let value: String?
    public let isExcluded: Bool

    // MARK: - Init

    public init(name: String, value: String? = nil, isExcluded: Bool = false) {
        self.name = name
        self.value = value
        self.isExcluded = isExcluded
    }
}
