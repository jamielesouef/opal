//
//  ServiceGraph.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

@MainActor
public final class ServiceGraph {
    // MARK: - Services

    public let vault: VaultService
    public let notes: NoteService
    public let links: LinkService
    public let index: IndexService
    public let navigation: NavigationService
    public let switcher: QuickSwitcherService
    public let search: SearchService
    public let mentions: MentionService
    public let dailyNotes: DailyNoteService
    public let templates: TemplateService
    public let renames: RenameService
    public let settings: SettingsService

    // MARK: - Init

    public init(
        vault: VaultService,
        makeIndex: @escaping @Sendable (URL) throws(IndexError) -> any IndexStoring,
        recents: any RecentNotesStoring,
        settings: SettingsService,
        clock: any Clocking,
        saveDelay: Duration = .milliseconds(800)
    ) {
        let index = IndexService(vault: vault, makeIndex: makeIndex)
        let links = LinkService(vault: vault, index: index)
        let notes = NoteService(vault: vault, links: links, index: index, clock: clock, saveDelay: saveDelay)
        let navigation = NavigationService(vault: vault, notes: notes, links: links, recents: recents)
        self.vault = vault
        self.index = index
        self.links = links
        self.notes = notes
        self.navigation = navigation
        switcher = QuickSwitcherService(vault: vault, links: links, navigation: navigation)
        search = SearchService(index: index, navigation: navigation)
        mentions = MentionService(vault: vault, index: index, links: links, notes: notes)
        dailyNotes = DailyNoteService(vault: vault, links: links, navigation: navigation, clock: clock)
        templates = TemplateService(vault: vault, notes: notes, clock: clock)
        renames = RenameService(vault: vault, links: links, notes: notes, navigation: navigation)
        self.settings = settings
        settings.attach(vault)
        vault.onExternalChange = { [index, links, notes] paths in
            await index.update(paths)
            await links.refresh(paths)
            await notes.reloadIfUnchanged(paths)
        }
    }

    // MARK: - Intent

    public func syncFollowers() async {
        await index.sync()
        await links.sync()
    }
}
