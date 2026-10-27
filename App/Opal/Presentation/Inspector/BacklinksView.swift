//
//  BacklinksView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct BacklinksView: View {
    // MARK: - Input

    let groups: [BacklinkGroup]
    var onOpen: (Backlink) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        if groups.isEmpty {
            ContentUnavailableView(
                String(localized: "No Backlinks"),
                systemImage: "arrow.uturn.backward",
                description: Text(String(localized: "No other Note links here yet."))
            )
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.backlinks, id: \.self) { backlink in
                            Button {
                                onOpen(backlink)
                            } label: {
                                Text(BacklinkGroupUseCase.context(of: backlink))
                                    .font(.callout)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .help(String(localized: "Open \(group.source.name) at this line"))
                        }
                    } header: {
                        HStack {
                            Label(group.source.name, systemImage: "text.document")
                                .lineLimit(1)
                            Spacer()
                            Text(group.backlinks.count, format: .number)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.trailing, AppSpacing.small)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

#if DEBUG
    #Preview("Backlinks") {
        BacklinksView(groups: BacklinkGroupUseCase.groups([
            Backlink(
                source: NotePath("Gardening Basics.md"),
                link: Link(target: "Soil", span: TextSpan(location: 0, length: 8), line: 7, lineText: "Good soil comes first. Read [[Soil]] before you plant anything.")
            ),
            Backlink(
                source: NotePath("Tomatoes.md"),
                link: Link(target: "Soil", span: TextSpan(location: 0, length: 8), line: 7, lineText: "Grow them in full sun, in [[Soil|rich earth]].")
            )
        ]))
        .frame(width: 280, height: 400)
    }

    #Preview("Empty") {
        BacklinksView(groups: [])
            .frame(width: 280, height: 400)
    }
#endif
