//
//  SaveStatusItem.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import SwiftUI

struct SaveStatusItem: View {
    // MARK: - Environment

    @Environment(\.noteService) private var notes

    // MARK: - View

    var body: some View {
        SaveStatusView(status: notes.saveStatus, hasNote: notes.path != nil)
    }
}
