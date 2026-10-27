//
//  TextSpan.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

public struct TextSpan: Hashable, Sendable {
    // MARK: - Stored

    public let location: Int
    public let length: Int

    // MARK: - Init

    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }

    // MARK: - Derived

    public var upperBound: Int {
        location + length
    }

    public func contains(_ offset: Int) -> Bool {
        offset >= location && offset < upperBound
    }
}
