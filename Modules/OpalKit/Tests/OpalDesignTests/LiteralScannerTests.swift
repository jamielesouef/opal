//
//  LiteralScannerTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Testing

@Suite("Literal scanner")
struct LiteralScannerTests {
    // MARK: - Flagged

    @Test(
        "flags a literal",
        arguments: [
            "Color(red: 0.1, green: 0.2, blue: 0.3)",
            "Color(white: 0.5)",
            "NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)",
            ".foregroundStyle(.white)",
            "isSelected ? .white : .secondary",
            "let tint = Color.purple",
            "NSColor.systemYellow",
            "let value = 0xFF8800",
            ".opacity(0.5)",
            ".opacity(isEnabled ? 1 : 0.45)",
            "color.withAlphaComponent(0.3)",
            ".padding(12)",
            ".padding(.horizontal, 12)",
            "VStack(spacing: 6)",
            "AppSpacing.xsmall + 2",
            "RoundedRectangle(cornerRadius: 6)",
            ".rect(cornerRadius: 8)",
            ".cornerRadius(4)",
            ".shadow(radius: 3)",
            ".frame(width: 260, height: 300)",
            ".frame(maxWidth: .infinity, minHeight: 40)",
            ".font(.system(size: 14))",
            "NSFont.systemFont(ofSize: 13)",
            "static let gap: CGFloat = 4",
            "static let calloutOpacity = 0.08",
            "withAnimation(.easeInOut(duration: 0.2)) {",
            ".animation(.spring(), value: isOn)",
            "try await Task.sleep(for: .milliseconds(100))"
        ]
    )
    func flags(_ line: String) {
        #expect(LiteralScanner.violations(in: line).isEmpty == false)
    }

    // MARK: - Allowed

    @Test(
        "allows tokens and system colours",
        arguments: [
            "Color.accentColor",
            ".foregroundStyle(.secondary)",
            ".foregroundStyle(.separator)",
            ".foregroundStyle(isSelected ? AppColor.onAccent : .secondary)",
            ".background(.bar)",
            ".background(.regularMaterial, in: .rect(cornerRadius: AppRadius.panel))",
            ".opacity(isEnabled ? 1 : AppOpacity.disabled)",
            ".opacity(0)",
            ".padding()",
            ".padding(0)",
            ".padding(.horizontal, AppSpacing.small)",
            ".padding(EditorMetrics.textInset)",
            "VStack(spacing: 0)",
            "HStack(alignment: .top, spacing: AppSpacing.regular)",
            ".safeAreaInset(edge: .top, spacing: 0)",
            ".frame(maxWidth: .infinity, alignment: .leading)",
            ".frame(width: EditorMetrics.switcherWidth, height: EditorMetrics.switcherHeight)",
            ".frame(width: 0, height: 0)",
            ".font(.system(size: EditorMetrics.fontSize))",
            "RoundedRectangle(cornerRadius: AppRadius.row, style: .continuous)",
            "static let maximumDepth = 4",
            "static let linkScheme = \"opal-link\"",
            "try await Task.sleep(for: .seconds(1))",
            "try await Task.sleep(for: AppMotion.dismissDelay)",
            "// Color.purple at 12 points"
        ]
    )
    func allows(_ line: String) {
        #expect(LiteralScanner.violations(in: line).isEmpty)
    }

    // MARK: - Previews

    @Test("ignores everything from the first preview block")
    func ignoresPreviews() {
        let source = """
        struct Row: View {}

        #if DEBUG
            #Preview {
                Row().frame(width: 260, height: 300)
            }
        #endif
        """
        #expect(LiteralScanner.violations(in: source).isEmpty)
    }

    @Test("reports the line number")
    func reportsLine() {
        let source = "struct Row {}\n.padding(12)\n"
        #expect(LiteralScanner.violations(in: source) == [LiteralViolation(line: 2, rule: "literal spacing", text: ".padding(12)")])
    }
}
