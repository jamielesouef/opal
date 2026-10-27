//
//  ConflictBanner.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalDesign
import SwiftUI

struct ConflictBanner: View {
    // MARK: - Input

    let noteName: String
    var onKeepMine: () -> Void = {}
    var onUseDisk: () -> Void = {}

    // MARK: - View

    var body: some View {
        HStack(spacing: AppSpacing.regular) {
            Label(
                String(localized: "“\(noteName)” was changed by another app while you were editing it."),
                systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(String(localized: "Use Version on Disk"), action: onUseDisk)

            Button(String(localized: "Keep My Version"), action: onKeepMine)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, AppSpacing.regular)
        .padding(.vertical, AppSpacing.small)
        .background(.bar)
    }
}

#if DEBUG
    #Preview {
        VStack {
            ConflictBanner(noteName: "Soil")
            ConflictBanner(noteName: "A Note With A Very Long Name That Needs Room To Wrap Across Lines")
        }
        .frame(width: 640)
    }
#endif
