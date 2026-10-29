//
//  CommandPaletteRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalDesign
import SwiftUI

struct CommandPaletteRow: View {
    // MARK: - Input

    let command: AppCommand
    let isSelected: Bool
    let isEnabled: Bool

    // MARK: - View

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(command.group)
                .font(.caption)
                .opacity(AppOpacity.subdued)
                .frame(width: EditorMetrics.shortcutGroupWidth, alignment: .leading)
            Text(command.title)
                .lineLimit(1)
            Spacer(minLength: AppSpacing.small)
            Text(command.shortcutText)
                .font(.callout.monospaced())
                .opacity(AppOpacity.subdued)
        }
        .foregroundStyle(isSelected ? AppColor.onAccent : .primary)
        .opacity(isEnabled ? 1 : AppOpacity.disabled)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.compact)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: AppRadius.row, style: .continuous)
                    .fill(AppColor.accent)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isEnabled ? "" : String(localized: "Not available now"))
    }
}
