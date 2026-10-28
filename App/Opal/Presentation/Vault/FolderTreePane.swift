//
//  FolderTreePane.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import SwiftUI

struct FolderTreePane: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vaultService
    @Environment(\.renameService) private var renamer
    @Environment(\.launchRequest) private var launch
    @Environment(\.noteService) private var notes

    // MARK: - Input

    @Binding var selection: NotePath?
    @Binding var expandedFolders: Set<NotePath>
    let vaultName: String

    // MARK: - State

    @State private var renaming: NotePath?
    @State private var pending: PendingRename?
    @State private var problem: String?
    @State private var moving: MoveRequest?

    // MARK: - View

    var body: some View {
        FolderTreeView(
            selection: $selection,
            expandedFolders: $expandedFolders,
            renaming: $renaming,
            vaultName: vaultName,
            tree: vaultService.tree,
            actions: FolderTreeActions(
                reveal: { VaultActions.reveal($0, vault: vaultService) },
                openInDefaultApp: { VaultActions.openInDefaultApp($0, vault: vaultService) },
                rename: rename,
                move: move,
                chooseFolder: { moving = MoveRequest(path: $0) },
                duplicate: { path in Task { await VaultActions.duplicate(path, vault: vaultService, notes: notes) } }
            )
        )
        .sheet(item: $moving) { request in
            MoveToFolderView(item: request.path, folders: folders, vaultName: vaultName) { folder in
                move(request.path, into: folder)
            }
        }
        .task {
            if let path = launch.renaming {
                try? await Task.sleep(for: .seconds(1))
                renaming = path
            }
            if let path = launch.moving {
                try? await Task.sleep(for: .seconds(1))
                moving = MoveRequest(path: path)
            }
        }
        .confirmationDialog(
            String(localized: "Update Links in \(pending?.plan.linkingNotes.count ?? 0) Notes?"),
            isPresented: Binding { pending != nil } set: { if $0 == false { pending = nil } },
            presenting: pending
        ) { pending in
            Button(String(localized: "Update Links")) {
                perform(pending, updatingLinks: true)
            }
            Button(String(localized: "Don't Update")) {
                perform(pending, updatingLinks: false)
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: { pending in
            Text(String(localized: "Other Notes link to “\(pending.path.name)”. Opal can change those Links to the new name. Nothing else in those Notes changes."))
        }
        .alert(
            String(localized: "Can't Rename"),
            isPresented: Binding { problem != nil } set: { if $0 == false { problem = nil } }
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(problem ?? "")
        }
    }

    // MARK: - Folders

    private var folders: [NotePath] {
        vaultService.entries
            .filter { $0.kind == .folder }
            .map(\.path)
            .sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
    }

    // MARK: - Intent

    private func rename(_ path: NotePath, to name: String) {
        switch renamer.plan(renaming: path, to: name) {
        case let .success(plan) where plan.linkingNotes.isEmpty:
            perform(PendingRename(path: path, plan: plan), updatingLinks: false)
        case let .success(plan):
            pending = PendingRename(path: path, plan: plan)
        case .failure(.unchanged):
            break
        case let .failure(failure):
            problem = failure.message
        }
    }

    private func move(_ path: NotePath, into folder: NotePath) {
        switch renamer.plan(moving: path, into: folder) {
        case let .success(plan) where plan.linkingNotes.isEmpty:
            perform(PendingRename(path: path, plan: plan), updatingLinks: true)
        case let .success(plan):
            pending = PendingRename(path: path, plan: plan)
        case .failure(.sameFolder), .failure(.unchanged):
            break
        case let .failure(failure):
            problem = failure.message
        }
    }

    private func perform(_ pending: PendingRename, updatingLinks: Bool) {
        Task {
            do throws(VaultError) {
                let renamed = try await renamer.perform(pending.plan, from: pending.path, updatingLinks: updatingLinks)
                expandedFolders = Set(expandedFolders.map { $0.replacingPrefix(pending.path, with: renamed) })
                if let current = selection {
                    selection = current.replacingPrefix(pending.path, with: renamed)
                }
            } catch {
                problem = error.message
            }
        }
    }
}
