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
    @Environment(\.launchRequest) private var launch

    // MARK: - State

    @AppStorage(EditorPreferences.liveMarkdownKey) private var isLiveMarkdown = true
    @State private var readingBlocks: [ReadingBlock] = []
    @State private var readingTopLine = 0

    // MARK: - View

    var body: some View {
        content
            .onChange(of: navigation.isReadingView) { _, isReading in
                guard isReading == false, let path = notes.path else {
                    return
                }

                Task { await navigation.open(path, line: readingTopLine) }
            }
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
            if navigation.isReadingView {
                reading(note)
            } else {
                editor(note)
            }
        }
    }

    // MARK: - Editor

    private func editor(_ note: Note) -> some View {
        MarkdownTextView(
            text: note.text,
            styles: styles(for: note),
            reveal: navigation.reveal.flatMap { $0.path == note.path ? $0 : nil },
            typeOnAppear: launch.typeText
        ) { text in
            notes.edit(text)
        } onFollowLink: { offset in
            followLink(at: offset)
        } onScroll: { offset in
            navigation.editorTopOffset = offset
        } linkSuggestions: { query in
            switcher.linkSuggestions(for: query)
        } linkInsertion: { suggestion in
            switcher.linkInsertion(for: suggestion, from: note.path)
        } onAttach: { data, name in
            await notes.attach(data, named: name)
        }
        .id(note.path)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if case .conflict = notes.loadState {
                    ConflictBanner(noteName: note.path.name) {
                        Task { await notes.keepMyVersion() }
                    } onUseDisk: {
                        notes.useVersionOnDisk()
                    }

                    Divider()
                }
                properties
            }
        }
    }

    // MARK: - Properties

    @ViewBuilder
    private var properties: some View {
        if let frontmatter = notes.frontmatter {
            PropertiesView(frontmatter: frontmatter)
                .background(Color(nsColor: .textBackgroundColor))
            Divider()
        }
    }

    // MARK: - Reading view

    private func reading(_ note: Note) -> some View {
        ReadingView(source: note.path, blocks: readingBlocks, startLine: TextLineUseCase.line(atOffset: navigation.editorTopOffset, in: note.text)) { line in
            readingTopLine = line
        } onFollowLink: { link in
            Task { await VaultActions.follow(link, from: note.path, vault: vault, navigation: navigation) }
        } onToggleCheckbox: { line in
            notes.toggleCheckbox(onLine: line)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                properties
            }
        }
        .task(id: ReadingKey(path: note.path, text: note.text.hashValue)) {
            readingBlocks = await links.readingBlocks(of: note.path, text: note.text)
        }
    }

    // MARK: - Styles

    private func styles(for note: Note) -> [TextStyleRun] {
        guard let open = links.openNote, open.path == note.path else {
            return []
        }

        return isLiveMarkdown ? open.styles : open.styles.filter(\.kind.isLink)
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
            .environment(\.mentionService, graph.mentionService)
            .environment(\.navigationService, graph.navigationService)
            .environment(\.quickSwitcherService, graph.quickSwitcherService)
            .task {
                await graph.vaultService.start()
                await graph.noteService.open(NotePath("Welcome.md"))
            }
            .frame(width: 600, height: 400)
    }
#endif
