//
//  SettingsService+Binding.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import OpalCore
import SwiftUI

extension SettingsService {
    // MARK: - Bindings

    func binding<Value>(_ key: WritableKeyPath<OpalSettings, Value>, vaultValue: Value? = nil) -> Binding<Value> {
        Binding {
            vaultValue ?? self.settings[keyPath: key]
        } set: { newValue in
            self.settings[keyPath: key] = newValue
        }
    }
}
