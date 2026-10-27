//
//  ObsidianAppSettingsParserTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("ObsidianAppSettingsParser", .tags(.parser))
struct ObsidianAppSettingsParserTests {
    @Test("reads the new Note location, Attachment folder and Link format")
    func parsesFields() {
        let json = #"{"newFileLocation":"folder","newFileFolderPath":"Inbox","attachmentFolderPath":"Attachments","useMarkdownLinks":true}"#

        let settings = ObsidianAppSettingsParser.parse(Data(json.utf8))

        #expect(settings == ObsidianAppSettings(
            newFileLocation: .folder,
            newFileFolderPath: "Inbox",
            attachmentFolderPath: "Attachments",
            useMarkdownLinks: true
        ))
    }

    @Test("uses Obsidian's defaults for missing keys and unknown values")
    func defaultsForMissing() {
        let settings = ObsidianAppSettingsParser.parse(Data(#"{"newFileLocation":"somewhere","theme":"obsidian"}"#.utf8))

        #expect(settings == .defaults)
    }

    @Test("uses the defaults when there is no file or it is not JSON", arguments: [nil, Data("not json".utf8)])
    func defaultsForUnreadable(data: Data?) {
        #expect(ObsidianAppSettingsParser.parse(data) == .defaults)
    }
}
