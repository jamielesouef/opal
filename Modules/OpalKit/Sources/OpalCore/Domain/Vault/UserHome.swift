//
//  UserHome.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation

public enum UserHome {
    // MARK: - Path

    public static var path: String {
        if let entry = getpwuid(getuid()), let directory = entry.pointee.pw_dir {
            return String(cString: directory)
        }

        return NSHomeDirectory()
    }
}
