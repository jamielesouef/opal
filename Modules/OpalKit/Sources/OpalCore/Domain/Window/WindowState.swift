//
//  WindowState.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct WindowState: Hashable, Sendable, Codable {
    // MARK: - Stored

    public var panes: [[NotePath]]
    public var focusedPane: Int
    public var splitShare: Double
    public var frame: WindowFrame?

    // MARK: - Init

    public init(
        panes: [[NotePath]] = [[]],
        focusedPane: Int = 0,
        splitShare: Double = EditorPanes.evenShare,
        frame: WindowFrame? = nil
    ) {
        self.panes = panes
        self.focusedPane = focusedPane
        self.splitShare = splitShare
        self.frame = frame
    }

    // MARK: - Missing Notes

    public func dropping(where isMissing: (NotePath) -> Bool) -> WindowState {
        var kept = self
        kept.panes = panes.map { $0.filter { isMissing($0) == false } }
        return kept
    }
}
