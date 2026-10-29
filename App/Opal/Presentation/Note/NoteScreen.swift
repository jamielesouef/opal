//
//  NoteScreen.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct NoteScreen: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.noteService) private var notes
    @Environment(\.linkService) private var links
    @Environment(\.navigationService) private var navigation
    @Environment(\.quickSwitcherService) private var switcher
    @Environment(\.launchRequest) private var launch
    @Environment(\.templateService) private var templates

    // MARK: - Input

    let pane: Int

    // MARK: - State

    @AppStorage(EditorPreferences.liveMarkdownKey) private var isLiveMarkdown = true
    @AppStorage(EditorPreferences.fontDesignKey) private var fontDesign = EditorFontDesign.system
    @AppStorage(EditorPreferences.fontSizeKey) private var fontSize = Double(EditorStyle.defaults.size)
    @AppStorage(EditorPreferences.lineSpacingKey) private var lineSpacing = Double(EditorStyle.defaults.lineSpacing)
    @AppStorage(EditorPreferences.lineWidthKey) private var lineWidth = Double(EditorStyle.defaults.lineWidth)
    @AppStorage(EditorPreferences.checksSpellingKey) private var checksSpelling = EditorStyle.defaults.checksSpelling
    @State private var readingBlocks: [ReadingBlock] = []
    @State private var readingTopLine = 0

    // MARK: - Derived

    private var path: NotePath? {
        navigation.panes.panes.indices.contains(pane) ? navigation.panes.panes[pane].selected.path : nil
    }

    private var document: NoteDocument? {
        path.flatMap(notes.document(for:))
    }

    private var style: EditorStyle {
        EditorStyle(design: fontDesign, size: fontSize, lineSpacing: lineSpacing, lineWidth: lineWidth, checksSpelling: checksSpelling)
    }

    private var isFocused: Bool {
        navigation.panes.focusedIndex == pane
    }

    private var loadState: NoteService.LoadState {
        switch (path, document) {
        case (nil, _):
            .noNote
        case let (path?, nil):
            .loading(path)
        case let (_, document?):
            document.loadState
        }
    }

    // MARK: - View

    var body: some View {
        content
            .onChange(of: navigation.isReadingView) { _, isReading in
                guard isReading == false, isFocused, let path else {
                    return
                }

                Task { await navigation.open(path, line: readingTopLine) }
            }
    }

    // MARK: - Load state

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .noNote:
            ContentUnavailableView {
                Label(String(localized: "No Note Open"), systemImage: "text.document")
            } description: {
                Text(String(localized: "Choose a Note in the sidebar, or write a new one."))
            } actions: {
                Button(String(localized: "New Note")) {
                    Task {
                        await navigation.focusPane(pane)
                        await VaultActions.createNote(vault: vault, navigation: navigation)
                    }
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
                    Task { await document?.retry() }
                }
            }
        case let .editing(note),
             let .conflict(note, _):
            if let document {
                if navigation.isReadingView {
                    reading(note, document: document)
                } else {
                    editor(note, document: document)
                }
            }
        }
    }

    // MARK: - Editor

    private func editor(_ note: Note, document: NoteDocument) -> some View {
        let analysed = links.analysis(of: note.path)
        return MarkdownTextView(
            text: note.text,
            styles: analysed.map { isLiveMarkdown ? $0.styles : $0.linkStyles } ?? [],
            stylesLength: analysed?.textLength,
            fold: navigation.unfoldedFrontmatter.contains(note.path) ? nil : FrontmatterFoldUseCase.fold(in: note.text),
            reveal: isFocused ? navigation.reveal.flatMap { $0.path == note.path ? $0 : nil } : nil,
            insertion: isFocused ? templates.insertion.flatMap { $0.path == note.path ? $0 : nil } : nil,
            initialTopOffset: navigation.topOffset(inPane: pane),
            typeOnAppear: isFocused ? launch.typeText : nil,
            takesFocusOnAppear: isFocused,
            style: style
        ) { text in
            document.edit(text)
        } onFollowLink: { offset in
            followLink(at: offset, in: document)
        } onScroll: { offset in
            navigation.setTopOffset(offset, inPane: pane)
        } linkSuggestions: { query in
            await switcher.linkSuggestions(for: query)
        } linkInsertion: { suggestion in
            switcher.linkInsertion(for: suggestion, from: note.path)
        } onAttach: { data, name in
            await document.attach(data, named: name)
        } onFocus: {
            Task { await navigation.focusPane(pane) }
        } onUnfold: {
            navigation.unfoldFrontmatter(of: note.path)
        }
        .id(note.path)
        .id(style)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if case .conflict = document.loadState {
                    ConflictBanner(noteName: note.path.name) {
                        Task { await document.keepMyVersion() }
                    } onUseDisk: {
                        document.useVersionOnDisk()
                    }

                    Divider()
                }
                properties(of: document)
            }
        }
    }

    // MARK: - Properties

    @ViewBuilder
    private func properties(of document: NoteDocument) -> some View {
        if let frontmatter = document.frontmatter {
            PropertiesView(document: document, frontmatter: frontmatter, pane: pane)
                .background(AppColor.editorBackground)
            Divider()
        }
    }

    // MARK: - Reading view

    private func reading(_ note: Note, document: NoteDocument) -> some View {
        ReadingView(source: note.path, blocks: readingBlocks) {
            TextLineUseCase.line(atOffset: navigation.topOffset(inPane: pane), in: note.text)
        } onTopLine: { line in
            readingTopLine = line
        } onFollowLink: { link in
            Task {
                await navigation.focusPane(pane)
                await VaultActions.follow(link, from: note.path, vault: vault, navigation: navigation)
            }
        } onToggleCheckbox: { line in
            document.toggleCheckbox(onLine: line)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                properties(of: document)
            }
        }
        .environment(\.editorStyle, style)
        .task(id: ReadingKey(path: note.path, revision: document.revision)) {
            readingBlocks = await links.readingBlocks(of: note.path, text: note.text)
        }
    }

    // MARK: - Links

    private func followLink(at offset: Int, in document: NoteDocument) {
        guard let text = document.loadState.note?.text, let link = links.link(at: offset, in: text, of: document.path) else {
            return
        }

        Task {
            await navigation.focusPane(pane)
            await VaultActions.follow(link, from: document.path, vault: vault, navigation: navigation)
        }
    }
}

#if DEBUG
    #Preview {
        let graph = PreviewGraph.makeGraph(openingGarden: true)
        NoteScreen(pane: 0)
            .serviceGraph(graph)
            .task {
                await graph.vault.start()
                await graph.navigation.open(NotePath("Welcome.md"))
            }
            .frame(width: 600, height: 400)
    }
#endif
