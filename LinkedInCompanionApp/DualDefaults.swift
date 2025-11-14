//
//  DualDefaults.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 15/10/25.
//

import Foundation

struct DualDefaults {
    static let sharedSuiteName = "group.com.einstein.common"
    static let shared = UserDefaults(suiteName: sharedSuiteName)!
    static let standard = UserDefaults.standard

    // MARK: - Write
    static func set(_ value: Any?, forKey key: String) {
        standard.set(value, forKey: key)
        shared.set(value, forKey: key)
        standard.synchronize()
        shared.synchronize()
    }

    // MARK: - Read (priority: shared, fallback: standard)
    static func string(forKey key: String) -> String? {
        return shared.string(forKey: key) ?? standard.string(forKey: key)
    }

    static func bool(forKey key: String) -> Bool {
        if shared.object(forKey: key) != nil {
            return shared.bool(forKey: key)
        }
        return standard.bool(forKey: key)
    }

    static func integer(forKey key: String) -> Int {
        if shared.object(forKey: key) != nil {
            return shared.integer(forKey: key)
        }
        return standard.integer(forKey: key)
    }

    // MARK: - Remove
    static func remove(forKey key: String) {
        standard.removeObject(forKey: key)
        shared.removeObject(forKey: key)
        standard.synchronize()
        shared.synchronize()
    }
}
