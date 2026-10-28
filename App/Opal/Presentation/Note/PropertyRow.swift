//
//  PropertyRow.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct PropertyRow: View {
    // MARK: - Constants

    private enum Constants {
        static let nameWidth: CGFloat = 140
        static let iconWidth: CGFloat = 18
    }

    // MARK: - Input

    let document: NoteDocument
    let property: Property
    let type: PropertyType

    // MARK: - State

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    // MARK: - View

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Image(systemName: type.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: Constants.iconWidth)
                .help(type.title)
            Text(property.key)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: Constants.nameWidth, alignment: .leading)
            editor
        }
        .contextMenu {
            Button(String(localized: "Remove Property"), role: .destructive) {
                document.removeProperty(property)
            }
        }
        .onAppear { draft = text }
        .onChange(of: property) { draft = text }
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        switch (type, property.value) {
        case let (_, .unreadable(raw)):
            Text(raw)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case (.checkbox, _):
            Toggle(property.key, isOn: Binding {
                draft.lowercased() == "true"
            } set: { isOn in
                document.setProperty(property, to: .text(isOn ? "true" : "false"))
            })
            .labelsHidden()
        case (.list, _), (.tags, _), (.aliases, _):
            field(prompt: String(localized: "Comma-separated")) {
                document.setProperty(property, to: .list(draft.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }))
            }
        case (.text, _), (.number, _), (.date, _), (.dateTime, _):
            field(prompt: type == .date ? "YYYY-MM-DD" : String(localized: "Empty")) {
                document.setProperty(property, to: .text(draft.trimmingCharacters(in: .whitespaces)))
            }
        }
    }

    private func field(prompt: String, commit: @escaping () -> Void) -> some View {
        TextField(property.key, text: $draft, prompt: Text(prompt))
            .labelsHidden()
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit {
                if draft != text {
                    commit()
                }
            }
            .onChange(of: isFocused) {
                if isFocused == false, draft != text {
                    commit()
                }
            }
    }

    private var text: String {
        switch property.value {
        case let .text(value):
            value
        case let .list(values):
            values.joined(separator: ", ")
        case let .unreadable(raw):
            raw
        }
    }
}
