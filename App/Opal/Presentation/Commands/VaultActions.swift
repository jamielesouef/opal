//
//  VaultActions.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import Foundation
import OpalCore

@MainActor
enum VaultActions {
    // MARK: - Vault

    static func openVault(graph: ServiceGraph, windowID: UUID?, windows: WindowRegistry, openWindow: (UUID) -> Void) async {
        guard let url = VaultPanels.chooseVaultFolder() else {
            return
        }

        await open(WaitingVault(folderURL: url, isNew: false), graph: graph, windowID: windowID, windows: windows, openWindow: openWindow)
    }

    static func createVault(graph: ServiceGraph, windowID: UUID?, windows: WindowRegistry, openWindow: (UUID) -> Void) async {
        guard let url = VaultPanels.chooseNewVaultFolder() else {
            return
        }

        await open(WaitingVault(folderURL: url, isNew: true), graph: graph, windowID: windowID, windows: windows, openWindow: openWindow)
    }

    static func open(_ waiting: WaitingVault, in graph: ServiceGraph) async {
        await graph.notes.close()
        if waiting.isNew {
            await graph.vault.create(folderURL: waiting.folderURL)
        } else {
            await graph.vault.open(folderURL: waiting.folderURL)
        }
    }

    private static func open(_ waiting: WaitingVault, graph: ServiceGraph, windowID: UUID?, windows: WindowRegistry, openWindow: (UUID) -> Void) async {
        guard let windowID else {
            return
        }

        switch windows.decide(opening: waiting.folderURL, from: windowID) {
        case let .bringToFront(other):
            openWindow(other)
        case .openHere:
            await open(waiting, in: graph)
        case .openInNewWindow:
            openWindow(windows.newWindow(opening: waiting))
        }
    }

    static func reloadVault(vault: VaultService, notes: NoteService) async {
        await notes.flush()
        await vault.refresh()
    }

    // MARK: - Items

    static func createNote(vault: VaultService, navigation: NavigationService) async {
        do {
            let path = try await vault.createNote(openNote: navigation.openNote)
            await navigation.open(path)
        } catch {
            AppLog.error("Creating a Note failed: \(error)")
        }
    }

    static func createFolder(vault: VaultService, notes: NoteService) async {
        do {
            _ = try await vault.createFolder(near: notes.path)
        } catch {
            AppLog.error("Creating a Folder failed: \(error)")
        }
    }

    static func showQuickSwitcher(query: String = "", switcher: QuickSwitcherService, navigation: NavigationService) async {
        await switcher.prepare(query: query)
        navigation.isQuickSwitcherShown = true
    }

    static func duplicate(_ path: NotePath, vault: VaultService, navigation: NavigationService) async {
        do {
            let copy = try await vault.duplicate(path)
            await navigation.open(copy)
        } catch {
            AppLog.error("Duplicating \(path) failed: \(error)")
        }
    }

    static func follow(_ link: Link, from source: NotePath, vault: VaultService, navigation: NavigationService) async {
        guard case let .attachment(path) = await navigation.follow(link, from: source) else {
            return
        }

        openInDefaultApp(path, vault: vault)
    }

    static func reveal(_ path: NotePath, vault: VaultService) {
        guard let url = vault.url(for: path) else {
            return
        }

        WorkspaceActions.revealInFinder(url)
    }

    static func openInDefaultApp(_ path: NotePath, vault: VaultService) {
        guard let url = vault.url(for: path) else {
            return
        }

        WorkspaceActions.openInDefaultApp(url)
    }
}
