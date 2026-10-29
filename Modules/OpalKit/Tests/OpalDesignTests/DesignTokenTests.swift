//
//  DesignTokenTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalDesign
import Testing

@Suite("Design tokens")
struct DesignTokenTests {
    @Test("spacing grows with every step")
    func spacingScale() {
        let steps = [AppSpacing.tiny, AppSpacing.xsmall, AppSpacing.compact, AppSpacing.small, AppSpacing.medium, AppSpacing.regular, AppSpacing.large]
        #expect(steps == steps.sorted())
        #expect(Set(steps).count == steps.count)
    }

    @Test("radii are on the scale")
    func radii() {
        #expect(AppRadius.row < AppRadius.panel)
    }

    @Test("opacities stay between 0 and 1 and keep their order")
    func opacities() {
        let values = [AppOpacity.callout, AppOpacity.tag, AppOpacity.searchMatch, AppOpacity.highlight, AppOpacity.disabled, AppOpacity.unresolved, AppOpacity.subdued, AppOpacity.emphasized]
        #expect(values == values.sorted())
        #expect(values.allSatisfy { $0 > 0 && $0 < 1 })
    }

    @Test("motion durations are short and ordered")
    func motion() {
        #expect(AppMotion.quick < AppMotion.standard)
        #expect(AppMotion.dismissDelay < AppMotion.standard)
    }

    @Test("the pane minimum fits two panes in the default window")
    func paneMinimum() {
        #expect(EditorMetrics.paneMinWidth * 2 < EditorMetrics.windowDefaultWidth)
    }
}
