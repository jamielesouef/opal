//
//  FrontmatterFold.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct FrontmatterFold: Hashable, Sendable {
    // MARK: - Stored

    public let headingLength: Int
    public let end: Int

    // MARK: - Init

    public init(headingLength: Int, end: Int) {
        self.headingLength = headingLength
        self.end = end
    }

    // MARK: - Derived

    public var hidden: TextSpan {
        TextSpan(location: headingLength, length: end - headingLength)
    }

    // MARK: - Rules

    public func rule(forSelection selection: TextSpan) -> FrontmatterFoldRule {
        guard selection.location < end else {
            return .keep
        }

        guard selection.length > 0 else {
            return .moveTo(end)
        }

        return selection.location == 0 && selection.upperBound >= end ? .keep : .unfold
    }

    public func selectionAfterFolding(_ selection: TextSpan) -> TextSpan {
        selection.location < end ? TextSpan(location: end, length: 0) : selection
    }

    public func isInside(editAt location: Int) -> Bool {
        location < end
    }
}
