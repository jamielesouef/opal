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
                .opacity(0.7)
                .frame(width: 40, alignment: .leading)
            Text(command.title)
                .lineLimit(1)
            Spacer(minLength: AppSpacing.small)
            Text(command.shortcutText)
                .font(.callout.monospaced())
                .opacity(0.7)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .opacity(isEnabled ? 1 : 0.45)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xsmall + 2)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isEnabled ? "" : String(localized: "Not available now"))
    }
}
