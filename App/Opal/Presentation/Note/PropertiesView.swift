//
//  PropertiesView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct PropertiesView: View {
    // MARK: - Environment

    @Environment(\.navigationService) private var navigation

    // MARK: - Input

    let document: NoteDocument
    let frontmatter: Frontmatter
    let pane: Int

    // MARK: - State

    @State private var newName = ""
    @State private var isAdding = false

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xsmall) {
            HStack {
                Text(String(localized: "Properties"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "Edit as YAML")) {
                    editAsYAML()
                }
                .buttonStyle(.link)
                .help(String(localized: "Show the frontmatter in the Editor"))
            }

            if frontmatter.isReadable == false {
                Text(String(localized: "Some of this frontmatter is not in a form Opal can show here. Edit it as YAML; Opal leaves it as it is."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ForEach(frontmatter.properties) { property in
                PropertyRow(document: document, property: property, type: document.type(of: property))
            }

            if isAdding {
                TextField(String(localized: "Property name"), text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)
                    .onExitCommand { isAdding = false }
            } else {
                Button {
                    isAdding = true
                } label: {
                    Label(String(localized: "Add Property"), systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, EditorMetrics.textInset)
        .padding(.vertical, AppSpacing.regular)
    }

    // MARK: - Intent

    private func add() {
        document.addProperty(named: newName)
        newName = ""
        isAdding = false
    }

    private func editAsYAML() {
        navigation.isReadingView = false
        Task {
            await navigation.focusPane(pane)
            await navigation.open(document.path, line: 1)
        }
    }
}
