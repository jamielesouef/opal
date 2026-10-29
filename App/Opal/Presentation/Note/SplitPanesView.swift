//
//  SplitPanesView.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import OpalDesign
import SwiftUI

struct SplitPanesView<First: View, Second: View>: View {
    // MARK: - Environment

    @Environment(\.navigationService) private var navigation

    // MARK: - State

    @State private var dragStartShare: Double?

    // MARK: - Input

    let isSplit: Bool
    private let first: First
    private let second: Second

    // MARK: - Init

    init(isSplit: Bool, @ViewBuilder first: () -> First, @ViewBuilder second: () -> Second) {
        self.isSplit = isSplit
        self.first = first()
        self.second = second()
    }

    // MARK: - View

    var body: some View {
        GeometryReader { proxy in
            let available = max(proxy.size.width - EditorMetrics.dividerThickness, EditorMetrics.paneMinWidth * 2)
            HStack(spacing: 0) {
                first
                    .frame(width: isSplit ? navigation.panes.firstPaneWidth(availableWidth: available, minPaneWidth: EditorMetrics.paneMinWidth) : proxy.size.width)
                if isSplit {
                    divider(available: available)
                    second
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: isSplit ? available + EditorMetrics.dividerThickness : proxy.size.width, height: proxy.size.height, alignment: .leading)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .mask {
                Rectangle()
                    .ignoresSafeArea(edges: .vertical)
            }
        }
    }

    // MARK: - Divider

    private func divider(available: Double) -> some View {
        Divider()
            .overlay {
                Rectangle()
                    .fill(.clear)
                    .frame(width: EditorMetrics.dividerGrabWidth)
                    .contentShape(.rect)
                    .pointerStyle(.columnResize)
                    .gesture(drag(available: available))
                    .onTapGesture(count: 2) {
                        navigation.resetSplitShare()
                    }
            }
            .zIndex(1)
            .accessibilityElement()
            .accessibilityLabel(String(localized: "Pane divider"))
            .accessibilityHint(String(localized: "Adjust to change the width of the first pane. Double-click to make the panes equal."))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    nudge(by: EditorMetrics.dividerStep, available: available)
                case .decrement:
                    nudge(by: -EditorMetrics.dividerStep, available: available)
                @unknown default:
                    break
                }
            }
    }

    private func drag(available: Double) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let start = dragStartShare ?? shown(available: available)
                dragStartShare = start
                set(start + value.translation.width / available, available: available)
            }
            .onEnded { _ in
                dragStartShare = nil
            }
    }

    // MARK: - Share

    private func shown(available: Double) -> Double {
        EditorPanes.clampedShare(navigation.panes.splitShare, availableWidth: available, minPaneWidth: EditorMetrics.paneMinWidth)
    }

    private func nudge(by step: Double, available: Double) {
        set(shown(available: available) + step, available: available)
    }

    private func set(_ share: Double, available: Double) {
        navigation.setSplitShare(EditorPanes.clampedShare(share, availableWidth: available, minPaneWidth: EditorMetrics.paneMinWidth))
    }
}
