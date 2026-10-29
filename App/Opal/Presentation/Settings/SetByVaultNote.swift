//
//  SetByVaultNote.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalDesign
import SwiftUI

struct SetByVaultNote<Content: View>: View {
    // MARK: - Input

    let isSet: Bool
    @ViewBuilder let content: Content

    // MARK: - View

    var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.tiny) {
            content
                .disabled(isSet)
            if isSet {
                Text(String(localized: "Set by this Vault's Obsidian settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
