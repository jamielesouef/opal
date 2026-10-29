//
//  WindowFrame.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public struct WindowFrame: Hashable, Sendable, Codable {
    // MARK: - Constants

    public static let minVisibleWidth = 100.0
    public static let minVisibleHeight = 60.0

    // MARK: - Stored

    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    // MARK: - Init

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    // MARK: - Derived

    private var maxX: Double {
        x + width
    }

    private var maxY: Double {
        y + height
    }

    // MARK: - Screens

    public func clamped(toScreens screens: [WindowFrame]) -> WindowFrame {
        guard let target = screens.first else {
            return self
        }

        guard screens.contains(where: isReachable(on:)) == false else {
            return self
        }

        let fitted = (width: min(width, target.width), height: min(height, target.height))
        return WindowFrame(
            x: min(max(x, target.x), target.maxX - fitted.width),
            y: min(max(y, target.y), target.maxY - fitted.height),
            width: fitted.width,
            height: fitted.height
        )
    }

    // MARK: - Private

    private func isReachable(on screen: WindowFrame) -> Bool {
        min(maxX, screen.maxX) - max(x, screen.x) >= Self.minVisibleWidth
            && min(maxY, screen.maxY) - max(y, screen.y) >= Self.minVisibleHeight
    }
}
