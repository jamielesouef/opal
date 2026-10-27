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

    // MARK: - State

    @AppStorage("inspectorPane") private var pane = InspectorPane.backlinks

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
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let path = notes.path, let note = notes.loadState.note {
            switch pane {
            case .backlinks:
                BacklinksView(groups: BacklinkGroupUseCase.groups(links.map.backlinks(to: path))) { backlink in
                    Task { await navigation.open(backlink.source, line: backlink.link.line) }
                }
            case .outgoing:
                OutgoingLinksView(links: links.map.outgoing(from: path, in: links.parse(note.text))) { outgoing in
                    Task { await VaultActions.follow(outgoing.link, from: path, vault: vault, navigation: navigation) }
                }
            case .outline:
                OutlineView(headings: links.parse(note.text).headings) { heading in
                    Task { await navigation.open(path, line: heading.line) }
                }
            }
        } else {
            ContentUnavailableView(String(localized: "No Note Open"), systemImage: "text.document")
        }
    }
}
