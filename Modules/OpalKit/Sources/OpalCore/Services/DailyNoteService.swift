//
//  DailyNoteService.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation
import Observation

@MainActor
@Observable
public final class DailyNoteService {
    // MARK: - Private

    private let vault: VaultService
    private let links: LinkService
    private let navigation: NavigationService
    private let clock: any Clocking

    // MARK: - Init

    public init(vault: VaultService, links: LinkService, navigation: NavigationService, clock: any Clocking) {
        self.vault = vault
        self.links = links
        self.navigation = navigation
        self.clock = clock
    }

    // MARK: - Intent

    @discardableResult
    public func openToday() async -> NotePath? {

        let now = clock.now

        guard let store = vault.store,
              let path = DailyNotePlanUseCase.path(on: now, timeZone: clock.timeZone, settings: vault.dailyNoteSettings)
        else {
            return nil
        }

        if vault.kind(of: path) == nil {
            let template = await templateText(store: store)
            let text = TemplateFillUseCase.fill(template, title: path.name, date: now, timeZone: clock.timeZone)
            do {
                try await vault.createNote(at: path, text: text)
            } catch .alreadyExists {
                AppLog.info("Today's Daily Note \(path) already exists on disk")
            } catch {
                AppLog.error("Creating today's Daily Note \(path) failed: \(error)")
                return nil
            }
            await links.sync()
        }

        await navigation.open(path)
        return path
    }

    // MARK: - Private

    private func templateText(store: any VaultFileStoring) async -> String {
        guard let path = DailyNotePlanUseCase.templatePath(vault.dailyNoteSettings.template) else {
            return ""
        }

        do {
            return try await store.readNote(at: path) ?? ""
        } catch {
            AppLog.error("Reading the Daily Note Template \(path) failed: \(error)")
            return ""
        }
    }
}
