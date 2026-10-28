//
//  TemplateService.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class TemplateService {
    // MARK: - State

    public var isPickerShown = false
    public private(set) var insertion: TextInsertion?

    // MARK: - Private

    private let vault: VaultService
    private let notes: NoteService
    private let clock: any Clocking
    private var nextInsertionID = 0

    // MARK: - Init

    public init(vault: VaultService, notes: NoteService, clock: any Clocking) {
        self.vault = vault
        self.notes = notes
        self.clock = clock
    }

    // MARK: - Templates

    public var folder: NotePath? {
        vault.templateSettings.folderPath
    }

    public var templates: [NotePath] {
        guard let folder else {
            return []
        }

        return vault.entries
            .filter { $0.kind == .note && $0.path.ancestors.contains(folder) }
            .map(\.path)
            .sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
    }

    // MARK: - Intent

    public func showPicker() {
        guard notes.path != nil else {
            return
        }

        isPickerShown = true
    }

    public func insert(_ template: NotePath) async {
        isPickerShown = false
        guard let target = notes.path, let text = await filledText(of: template, for: target) else {
            return
        }

        nextInsertionID += 1
        insertion = TextInsertion(path: target, text: text, id: nextInsertionID)
    }

    public func filledText(of template: NotePath, for target: NotePath) async -> String? {
        guard let store = vault.store else {
            return nil
        }

        let raw: String?
        do {
            raw = try await store.readNote(at: template)
        } catch {
            AppLog.error("Reading the Template \(template) failed: \(error)")
            return nil
        }

        let settings = vault.templateSettings
        return raw.map {
            TemplateFillUseCase.fill(
                $0,
                title: target.name,
                date: clock.now,
                timeZone: clock.timeZone,
                dateFormat: settings.dateFormat,
                timeFormat: settings.timeFormat
            )
        }
    }
}
