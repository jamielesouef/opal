//
//  NoteScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct NoteScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.noteService) private var notes
    @Environment(\.linkService) private var links
    @Environment(\.navigationService) private var navigation
    @Environment(\.quickSwitcherService) private var switcher
    @Environment(\.launchTypeText) private var launchTypeText

    // MARK: - View

    var body: some View {
        content
    }

    // MARK: - Load state

    @ViewBuilder
    private var content: some View {
        switch notes.loadState {
        case .noNote:
            ContentUnavailableView {
                Label(String(localized: "No Note Open"), systemImage: "text.document")
            } description: {
                Text(String(localized: "Choose a Note in the sidebar, or write a new one."))
            } actions: {
                Button(String(localized: "New Note")) {
                    Task { await VaultActions.createNote(vault: vault, notes: notes) }
                }
            }
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(path, error):
            ContentUnavailableView {
                Label(path.name, systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button(String(localized: "Try Again")) {
                    Task { await notes.retry() }
                }
            }
        case let .editing(note),
             let .conflict(note, _):
            editor(note)
        }
    }

    // MARK: - Editor

    private func editor(_ note: Note) -> some View {
        MarkdownTextView(
            text: note.text,
            highlights: links.openNote.flatMap { $0.path == note.path ? $0.highlights : nil } ?? [],
            reveal: navigation.reveal.flatMap { $0.path == note.path ? $0 : nil },
            typeOnAppear: launchTypeText
        ) { text in
            notes.edit(text)
        } onFollowLink: { offset in
            followLink(at: offset)
        } linkSuggestions: { query in
            switcher.linkSuggestions(for: query)
        } linkInsertion: { suggestion in
            switcher.linkInsertion(for: suggestion, from: note.path)
        }
        .id(note.path)
        .safeAreaInset(edge: .top, spacing: 0) {
            if case .conflict = notes.loadState {
                VStack(spacing: 0) {
                    ConflictBanner(noteName: note.path.name) {
                        Task { await notes.keepMyVersion() }
                    } onUseDisk: {
                        notes.useVersionOnDisk()
                    }

                    Divider()
                }
            }
        }
    }

    // MARK: - Links

    private func followLink(at offset: Int) {
        guard let path = notes.path, let text = notes.loadState.note?.text, let link = links.link(at: offset, in: text) else {
            return
        }

        Task {
            await VaultActions.follow(link, from: path, vault: vault, navigation: navigation)
        }
    }
}

#if DEBUG
    #Preview {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        NoteScreen()
            .environment(\.vaultService, graph.vaultService)
            .environment(\.noteService, graph.noteService)
            .environment(\.linkService, graph.linkService)
            .environment(\.indexService, graph.indexService)
            .environment(\.searchService, graph.searchService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
            .task {
                await graph.vaultService.start()
                await graph.noteService.open(NotePath("Welcome.md"))
            }
            .frame(width: 600, height: 400)
    }
#endif
