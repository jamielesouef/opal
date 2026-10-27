//
//  MockVaultLocationStore.swift
//  Opal
//
//  Created by Jamie Le Souef on 27/10/2026.
//

#if DEBUG
    import Foundation
    import OpalCore

    actor MockVaultLocationStore: VaultLocationStoring {
        // MARK: - Stored

        private var bookmark: Data?

        // MARK: - VaultLocationStoring

        func lastVaultBookmark() -> Data? {
            bookmark
        }

        func setLastVaultBookmark(_ bookmark: Data?) {
            self.bookmark = bookmark
        }
    }
#endif
