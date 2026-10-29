//
//  SaveStatusView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct SaveStatusView: View {
    // MARK: - Input

    let status: NoteService.SaveStatus
    let hasNote: Bool

    // MARK: - View

    var body: some View {
        switch (hasNote, status) {
        case (false, _),
             (true, .saved):
            EmptyView()
        case (true, .unsaved):
            Text(String(localized: "Edited"))
                .foregroundStyle(.secondary)
        case let (true, .failed(error)):
            Label(String(localized: "Not Saved"), systemImage: "exclamationmark.triangle")
                .foregroundStyle(AppColor.failure)
                .help(error.message)
        }
    }
}

#if DEBUG
    #Preview {
        VStack {
            SaveStatusView(status: .saved, hasNote: true)
            SaveStatusView(status: .unsaved, hasNote: true)
            SaveStatusView(status: .failed(.writeFailed(NotePath("Soil.md"))), hasNote: true)
        }
        .padding()
    }
#endif
