//
//  ReadingBlockView.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct ReadingBlockView: View {
    // MARK: - Input

    let block: ReadingBlock
    var chain: [NotePath] = []
    var onToggleCheckbox: (Int) -> Void = { _ in }

    // MARK: - View

    var body: some View {
        switch block.kind {
        case let .heading(level, text):
            Text(ReadingText.attributed(text))
                .font(.system(size: EditorMetrics.fontSize * scale(level), weight: .bold))
                .padding(.top, AppSpacing.small)
                .accessibilityAddTraits(.isHeader)
        case let .paragraph(text):
            Text(ReadingText.attributed(text))
        case let .listItem(marker, depth, checkbox, text):
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                if let checkbox {
                    Button {
                        onToggleCheckbox(block.line)
                    } label: {
                        Image(systemName: checkbox ? "checkmark.square.fill" : "square")
                            .foregroundStyle(checkbox ? AppColor.accent : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(checkbox ? String(localized: "Done") : String(localized: "To do"))
                    .help(checkbox ? String(localized: "Mark as not done") : String(localized: "Mark as done"))
                } else {
                    Text(marker)
                        .foregroundStyle(.secondary)
                }
                Text(ReadingText.attributed(text))
                    .foregroundStyle(checkbox == true ? .secondary : .primary)
            }
            .padding(.leading, CGFloat(depth) * EditorMetrics.listIndent)
        case let .quote(lines):
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Rectangle()
                    .fill(.separator)
                    .frame(width: EditorMetrics.blockBarWidth)
                lineStack(lines)
                    .foregroundStyle(.secondary)
            }
        case let .callout(type, title, lines):
            callout(type: type, title: title, lines: lines)
        case let .code(language, text):
            ScrollView(.horizontal) {
                Text(ReadingText.code(text, language: language))
                    .font(.system(size: EditorMetrics.fontSize * EditorMetrics.codeScale, design: .monospaced))
                    .padding(AppSpacing.medium)
            }
            .background(AppColor.codeFill, in: RoundedRectangle(cornerRadius: AppRadius.row))
        case let .table(header, rows):
            table(header: header, rows: rows)
        case .rule:
            Divider()
        case let .embed(link):
            EmbedView(link: link, chain: chain)
        }
    }

    // MARK: - Parts

    private func lineStack(_ lines: [[ReadingInline]]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(ReadingText.attributed(line))
            }
        }
    }

    private func callout(type: String, title: [ReadingInline], lines: [[ReadingInline]]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(AppColor.accent)
                .frame(width: EditorMetrics.blockBarWidth)
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label {
                    if title.isEmpty {
                        Text(CalloutStyle.title(for: type))
                    } else {
                        Text(ReadingText.attributed(title))
                    }
                } icon: {
                    Image(systemName: CalloutStyle.systemImage(for: type))
                }
                .font(.body.bold())
                .foregroundStyle(AppColor.accent)
                lineStack(lines)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.calloutFill)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.row))
    }

    private func table(header: [[ReadingInline]], rows: [[[ReadingInline]]]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                    Text(ReadingText.attributed(cell))
                        .bold()
                        .padding(AppSpacing.compact)
                }
            }
            Divider()
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Divider()
                }
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(ReadingText.attributed(cell))
                            .padding(AppSpacing.compact)
                    }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: AppRadius.row).stroke(.separator))
    }

    private func scale(_ level: Int) -> CGFloat {
        EditorMetrics.headingScales[min(max(level, 1), EditorMetrics.headingScales.count) - 1]
    }
}
