//
//  UnlinkedMentionsSection.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct UnlinkedMentionsSection: View {
    // MARK: - Input

    let mentions: [UnlinkedMention]
    var total = 0
    var onOpen: (UnlinkedMention) -> Void = { _ in }
    var onLink: (UnlinkedMention) -> Void = { _ in }
    var onShowMore: () -> Void = {}

    // MARK: - View

    var body: some View {
        Section {
            if mentions.isEmpty {
                Text(String(localized: "No unlinked mentions."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(mentions) { mention in
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                    Button {
                        onOpen(mention)
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.tiny) {
                            Text(mention.source.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mention.lineText.trimmingCharacters(in: .whitespaces))
                                .font(.callout)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    Button(String(localized: "Link")) {
                        onLink(mention)
                    }
                    .controlSize(.small)
                    .help(String(localized: "Turn “\(mention.matchedText)” in \(mention.source.name) into a Link"))
                }
            }
            if total > mentions.count {
                Button(String(localized: "Show More (\(total - mentions.count, format: .number) left)")) {
                    onShowMore()
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        } header: {
            HStack {
                Text(String(localized: "Unlinked mentions"))
                Spacer()
                Text(max(total, mentions.count), format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
            .padding(.trailing, AppSpacing.small)
        }
    }
}
