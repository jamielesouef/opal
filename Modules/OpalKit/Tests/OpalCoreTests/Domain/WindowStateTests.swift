//
//  WindowStateTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("WindowState", .tags(.domain))
struct WindowStateTests {
    // MARK: - Constants

    private static let soil = NotePath("Soil.md")
    private static let peas = NotePath("Peas.md")
    private static let screen = WindowFrame(x: 0, y: 0, width: 1440, height: 900)
    private static let side = WindowFrame(x: 1440, y: 0, width: 1920, height: 1080)

    // MARK: - State

    @Test("both panes' tabs, the focused pane, the split share and the frame survive encoding")
    func encodes() throws {
        let state = WindowState(
            panes: [[Self.soil, Self.peas], [Self.peas]],
            focusedPane: 1,
            splitShare: 0.7,
            frame: WindowFrame(x: 10, y: 20, width: 1000, height: 700)
        )

        let decoded = try JSONDecoder().decode(WindowState.self, from: JSONEncoder().encode(state))

        #expect(decoded == state)
    }

    @Test("drops Notes that no longer exist from every pane and keeps the rest")
    func dropsMissingNotes() {
        let state = WindowState(panes: [[Self.soil, Self.peas], [Self.peas]], focusedPane: 1, splitShare: 0.6)

        let kept = state.dropping { $0 == Self.peas }

        #expect(kept.panes == [[Self.soil], []])
        #expect(kept.focusedPane == 1)
        #expect(kept.splitShare == 0.6)
    }

    @Test("restoring builds two panes with the saved focus and share, and one pane starts even")
    func restoresPanes() {
        let split = EditorPanes(restoring: WindowState(panes: [[Self.soil], [Self.peas]], focusedPane: 1, splitShare: 0.7))
        #expect(split.paths == [[Self.soil], [Self.peas]])
        #expect(split.focusedIndex == 1)
        #expect(split.splitShare == 0.7)

        let single = EditorPanes(restoring: WindowState(panes: [[Self.soil]], focusedPane: 5, splitShare: 0.7))
        #expect(single.focusedIndex == 0)
        #expect(single.splitShare == EditorPanes.evenShare)

        #expect(EditorPanes(restoring: WindowState(panes: [])).paths == [[]])
    }

    // MARK: - Frame

    @Test("a frame that is on a screen stays where it is")
    func keepsReachableFrame() {
        let frame = WindowFrame(x: 100, y: 100, width: 1100, height: 700)
        let hanging = WindowFrame(x: 1000, y: 100, width: 1100, height: 700)
        let second = WindowFrame(x: 1500, y: 100, width: 1100, height: 700)

        #expect(frame.clamped(toScreens: [Self.screen]) == frame)
        #expect(hanging.clamped(toScreens: [Self.screen]) == hanging)
        #expect(second.clamped(toScreens: [Self.screen, Self.side]) == second)
    }

    @Test("a frame that is off every screen moves onto the first screen")
    func clampsOffScreenFrame() {
        let gone = WindowFrame(x: 1800, y: 200, width: 1100, height: 700)

        #expect(gone.clamped(toScreens: [Self.screen]) == WindowFrame(x: 340, y: 200, width: 1100, height: 700))
        #expect(WindowFrame(x: -3000, y: -2000, width: 1100, height: 700).clamped(toScreens: [Self.screen]) == WindowFrame(x: 0, y: 0, width: 1100, height: 700))
    }

    @Test("a frame bigger than the screen shrinks to fit, and no screens leave it alone")
    func shrinksToFit() {
        let huge = WindowFrame(x: 5000, y: 5000, width: 3000, height: 2000)

        #expect(huge.clamped(toScreens: [Self.screen]) == Self.screen)
        #expect(huge.clamped(toScreens: []) == huge)
    }
}
