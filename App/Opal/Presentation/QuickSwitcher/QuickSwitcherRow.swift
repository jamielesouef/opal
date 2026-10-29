//
//  QuickSwitcherRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct QuickSwitcherRow: View {
    // MARK: - Input

    let match: SwitcherMatch
    let isSelected: Bool

    // MARK: - View

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "text.document")
                .foregroundStyle(isSelected ? AppColor.onAccent : .secondary)

            VStack(alignment: .leading, spacing: AppSpacing.tiny) {
                Text(match.path.name)
                    .lineLimit(1)
                if let alias = match.matchedAlias {
                    Label(alias, systemImage: "arrow.turn.down.right")
                        .font(.caption)
                        .opacity(AppOpacity.emphasized)
                        .lineLimit(1)
                } else if match.path.parent.isRoot == false {
                    Text(match.path.parent.rawValue)
                        .font(.caption)
                        .opacity(AppOpacity.subdued)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppSpacing.small)

            if isSelected {
                Text("↩")
                    .font(.callout)
                    .opacity(AppOpacity.emphasized)
            }
        }
        .foregroundStyle(isSelected ? AppColor.onAccent : .primary)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.compact)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.row, style: .continuous)
                    .fill(AppColor.accent)
            }
        }
        .contentShape(.rect)
    }
}

#if DEBUG
    #Preview {
        VStack(spacing: 0) {
            QuickSwitcherRow(match: SwitcherMatch(path: NotePath("Soil.md"), matchedAlias: "Dirt"), isSelected: true)
            QuickSwitcherRow(match: SwitcherMatch(path: NotePath("Reading/The Soil Book.md")), isSelected: false)
        }
        .padding()
        .frame(width: 560)
    }
#endif
