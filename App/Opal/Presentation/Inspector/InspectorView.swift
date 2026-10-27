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

    @Environment(\.noteService) private var notes
    @Environment(\.linkService) private var links
    @Environment(\.navigationService) private var navigation

    // MARK: - View

    var body: some View {
        content
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let path = notes.path {
            BacklinksView(groups: BacklinkGroupUseCase.groups(links.map.backlinks(to: path))) { backlink in
                Task { await navigation.open(backlink.source, line: backlink.link.line) }
            }
        } else {
            ContentUnavailableView(String(localized: "No Note Open"), systemImage: "text.document")
        }
    }
}
