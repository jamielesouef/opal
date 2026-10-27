//
//  AppLog.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

import OSLog

public enum AppLog {
    // MARK: - Private

    private static let logger = Logger(subsystem: "com.jamielesouef.Opal", category: "app")

    // MARK: - Levels

    public static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    public static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}
