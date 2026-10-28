//
//  SettingsStoring.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

public protocol SettingsStoring: Sendable {
    func settings() -> OpalSettings
    func setSettings(_ settings: OpalSettings)
}
