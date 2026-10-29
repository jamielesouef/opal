//
//  IndexStatusItem.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import SwiftUI

struct IndexStatusItem: View {
    // MARK: - Environment

    @Environment(\.indexService) private var index

    // MARK: - View

    var body: some View {
        IndexStatusView(state: index.loadState)
    }
}
