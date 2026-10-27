//
//  OutgoingLinksView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import SwiftUI

struct OutgoingLinksView: View {
    // MARK: - Input

    let links: [OutgoingLink]
    var onFollow: (OutgoingLink) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        if links.isEmpty {
            ContentUnavailableView(
                String(localized: "No Links"),
                systemImage: "arrow.up.right",
                description: Text(String(localized: "Type [[ in the Note to link to another Note."))
            )
        } else {
            List(links, id: \.self) { outgoing in
                Button {
                    onFollow(outgoing)
                } label: {
                    row(outgoing)
                }
                .buttonStyle(.plain)
                .help(outgoing.isResolved
                    ? String(localized: "Open \(title(of: outgoing))")
                    : String(localized: "Create \(title(of: outgoing))"))
            }
            .listStyle(.sidebar)
        }
    }

    // MARK: - Row

    private func row(_ outgoing: OutgoingLink) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text(title(of: outgoing))
                    .lineLimit(1)
                if let folder = outgoing.target?.parent, folder.isRoot == false {
                    Text(folder.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } icon: {
            Image(systemName: icon(of: outgoing))
        }
        .foregroundStyle(outgoing.isResolved ? .primary : .secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private func title(of outgoing: OutgoingLink) -> String {
        outgoing.target?.name ?? outgoing.link.target
    }

    private func icon(of outgoing: OutgoingLink) -> String {
        switch outgoing.target {
        case nil:
            "plus.circle.dashed"
        case let target? where target.isNote:
            "text.document"
        case .some:
            "paperclip"
        }
    }
}

#if DEBUG
    #Preview {
        OutgoingLinksView(links: [
            OutgoingLink(link: Link(target: "Gardening Basics", span: TextSpan(location: 0, length: 1), line: 0, lineText: ""), target: NotePath("Gardening Basics.md")),
            OutgoingLink(link: Link(target: "Projects/Opal/Opal Roadmap", span: TextSpan(location: 0, length: 1), line: 0, lineText: ""), target: NotePath("Projects/Opal/Opal Roadmap.md")),
            OutgoingLink(link: Link(target: "Ideas That Do Not Exist Yet", span: TextSpan(location: 0, length: 1), line: 0, lineText: ""), target: nil)
        ])
        .frame(width: 280, height: 300)
    }
#endif
