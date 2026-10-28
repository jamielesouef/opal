//
//  DailyNoteUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("Daily Notes and Templates")
struct DailyNoteUseCaseTests {
    // MARK: - Constants

    private static let zone = TimeZone(identifier: "Australia/Sydney") ?? .gmt
    private static let date = Date(timeIntervalSince1970: 1_793_000_000)

    // MARK: - Format

    @Test(
        "formats dates with Moment tokens",
        arguments: [
            ("YYYY-MM-DD", "2026-10-26"),
            ("YY/M/D", "26/10/26"),
            ("dddd, MMMM D", "Monday, October 26"),
            ("ddd D MMM YYYY", "Mon 26 Oct 2026"),
            ("[Week of] YYYY-MM-DD", "Week of 2026-10-26"),
            ("HH:mm:ss", "18:33:20"),
            ("h:mm a", "6:33 pm")
        ]
    )
    func format(format: String, expected: String) {
        #expect(MomentFormatUseCase.string(from: Self.date, format: format, timeZone: Self.zone) == expected)
    }

    // MARK: - Plan

    @Test(
        "places today's Daily Note by Folder and format",
        arguments: [
            (DailyNoteSettings(folder: "Daily Notes", format: "YYYY-MM-DD", template: ""), "Daily Notes/2026-10-26.md"),
            (DailyNoteSettings(folder: "/Journal/", format: "YYYY/MM/YYYY-MM-DD", template: ""), "Journal/2026/10/2026-10-26.md"),
            (DailyNoteSettings(folder: "", format: "", template: ""), "2026-10-26.md")
        ]
    )
    func plan(settings: DailyNoteSettings, expected: String) {
        #expect(DailyNotePlanUseCase.path(on: Self.date, timeZone: Self.zone, settings: settings) == NotePath(expected))
    }

    @Test("finds the Template with or without .md")
    func template() {
        #expect(DailyNotePlanUseCase.templatePath("Templates/Daily") == NotePath("Templates/Daily.md"))
        #expect(DailyNotePlanUseCase.templatePath("Templates/Daily.md") == NotePath("Templates/Daily.md"))
        #expect(DailyNotePlanUseCase.templatePath("") == nil)
    }

    // MARK: - Fill

    @Test("fills date, time and title, with and without a format")
    func fill() {
        let template = "# {{date}} {{title}}\n{{time}} · {{date:dddd}} · {{ TIME:HH }} · {{other}}"
        let filled = TemplateFillUseCase.fill(template, title: "2026-10-26", date: Self.date, timeZone: Self.zone)
        #expect(filled == "# 2026-10-26 2026-10-26\n18:33 · Monday · 18 · {{other}}")
    }

    // MARK: - Settings

    @Test("reads daily-notes.json, and nothing when it is missing")
    func parse() {
        let data = Data(#"{"folder":"Daily Notes","format":"YYYY-MM-DD","template":"Templates/Daily"}"#.utf8)
        #expect(ObsidianDailyNotesParser.parse(data) == DailyNoteSettings(folder: "Daily Notes", format: "YYYY-MM-DD", template: "Templates/Daily"))
        #expect(ObsidianDailyNotesParser.parse(Data(#"{"format":""}"#.utf8)) == .defaults)
        #expect(ObsidianDailyNotesParser.parse(nil) == nil)
    }
}
