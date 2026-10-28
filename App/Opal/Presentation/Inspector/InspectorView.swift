//
//  InspectorView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct InspectorView: View {
    // MARK: - Environment

    @Environment(\.vaultService) private var vault
    @Environment(\.noteService) private var notes
    @Environment(\.linkService) private var links
    @Environment(\.navigationService) private var navigation
    @Environment(\.mentionService) private var mentions
    @Environment(\.indexService) private var index
    @Environment(\.searchService) private var search

    // MARK: - State

    @AppStorage("inspectorPane") private var pane = InspectorPane.backlinks
    @State private var pendingMention: UnlinkedMention?

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Show"), selection: $pane) {
                ForEach(InspectorPane.allCases) { pane in
                    Text(pane.title).tag(pane)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(AppSpacing.small)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: MentionReload(path: notes.path, revision: index.revision)) {
            await mentions.load(for: notes.path)
        }
        .confirmationDialog(
            String(localized: "Link this mention?"),
            isPresented: Binding { pendingMention != nil } set: { if $0 == false { pendingMention = nil } },
            presenting: pendingMention
        ) { mention in
            Button(String(localized: "Link")) {
                Task { _ = await mentions.link(mention) }
            }
        } message: { mention in
            Text(String(localized: "Opal will change “\(mention.matchedText)” in \(mention.source.name) into a Link to \(notes.path?.name ?? ""). Nothing else in that Note changes."))
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let path = notes.path, notes.loadState.note != nil {
            let parsed = links.openNote.flatMap { $0.path == path ? $0.parsed : nil } ?? .empty
            switch pane {
            case .backlinks:
                BacklinksView(
                    groups: BacklinkGroupUseCase.groups(links.map.backlinks(to: path)),
                    mentions: mentions.target == path ? mentions.mentions : []
                ) { backlink in
                    Task { await navigation.open(backlink.source, line: backlink.link.line) }
                } onOpenMention: { mention in
                    Task { await navigation.open(mention.source, line: mention.line) }
                } onLinkMention: { mention in
                    pendingMention = mention
                }
            case .outgoing:
                OutgoingLinksView(links: links.map.outgoing(from: path, in: parsed)) { outgoing in
                    Task { await VaultActions.follow(outgoing.link, from: path, vault: vault, navigation: navigation) }
                }
            case .outline:
                OutlineView(headings: parsed.headings) { heading in
                    Task { await navigation.open(path, line: heading.line) }
                }
            case .tags:
                NoteTagsView(tags: parsed.tags) { tag in
                    search.show(query: TagTreeUseCase.searchQuery(forTag: tag))
                }
            }
        } else {
            ContentUnavailableView(String(localized: "No Note Open"), systemImage: "text.document")
        }
    }
}
