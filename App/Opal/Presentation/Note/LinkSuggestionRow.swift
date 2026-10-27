//
//  LinkSuggestionRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct LinkSuggestionRow: View {
    // MARK: - Input

    let suggestion: LinkSuggestion
    let isSelected: Bool

    // MARK: - View

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: AppSpacing.regular)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .opacity(0.75)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xsmall)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.accentColor)
            }
        }
        .contentShape(.rect)
    }

    // MARK: - Content

    private var title: String {
        suggestion.name
    }

    private var detail: String? {
        switch suggestion {
        case let .note(path, .some):
            String(localized: "Alias of \(path.name)")
        case let .note(path, nil):
            path.parent.isRoot ? nil : path.parent.rawValue
        case .unresolved:
            String(localized: "No Note yet")
        }
    }

    private var icon: String {
        switch suggestion {
        case .note(_, alias: .some):
            "arrow.turn.down.right"
        case .note:
            "text.document"
        case .unresolved:
            "plus.circle.dashed"
        }
    }
}
