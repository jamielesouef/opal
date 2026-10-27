//
//  AttachmentView.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import SwiftUI

struct AttachmentView: View {
    // MARK: - Input

    let name: String
    var onOpen: () -> Void = {}

    // MARK: - View

    var body: some View {
        ContentUnavailableView {
            Label(name, systemImage: "paperclip")
        } description: {
            Text(String(localized: "Opal shows Attachments inside Notes in a later version."))
        } actions: {
            Button(String(localized: "Open in Default App"), action: onOpen)
        }
    }
}

#if DEBUG
    #Preview {
        AttachmentView(name: "seedlings.png")
    }

    #Preview("Long name") {
        AttachmentView(name: "a-very-long-attachment-file-name-from-a-scanner-2026-10-27-001.pdf")
            .frame(width: 320)
    }
#endif
