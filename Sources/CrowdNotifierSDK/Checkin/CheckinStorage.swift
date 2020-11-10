/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

class CheckinStorage {
    private let userDefaults: UserDefaults = .standard

    static let shared = CheckinStorage()

    private init() {}

    func addCheckinEntry(arrivalTime: Date, epk: Bytes, h: Bytes, ctxt: Bytes, overrideEntryWithID: String? = nil) -> String {
        if let overrideId = overrideEntryWithID {
            let e = CheckinEntry(id: overrideId, daysSince1970: arrivalTime.daysSince1970, epk: Data(epk), h: Data(h), ctxt: Data(ctxt))
            checkinEntries[overrideId] = try? JSONEncoder().encode(e)
            return overrideId
        } else {
            let id = UUID().uuidString
            let e = CheckinEntry(id: id, daysSince1970: arrivalTime.daysSince1970, epk: Data(epk), h: Data(h), ctxt: Data(ctxt))
            checkinEntries[id] = try? JSONEncoder().encode(e)
            return id
        }
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        let allIds = checkinEntries.keys

        guard maxDaysToKeep > 0 else {
            checkinEntries = [:]
            return
        }

        let daysLimit = Date().daysSince1970 - maxDaysToKeep

        for id in allIds {
            if let data = checkinEntries[id], let entry = try? JSONDecoder().decode(CheckinEntry.self, from: data), entry.daysSince1970 >= daysLimit {
                continue
            } else {
                checkinEntries[id] = nil
            }
        }
    }

    // MARK: - Storage

    private(set) var checkinEntries: [String: Data] {
        get {
            return userDefaults.dictionary(forKey: .checkinEntries) as? [String: Data] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: .checkinEntries)
        }
    }

    var allEntries: [String: CheckinEntry] {
        var result = [String: CheckinEntry]()

        for (k, v) in checkinEntries {
            result[k] = try? JSONDecoder().decode(CheckinEntry.self, from: v)
        }

        return result
    }
}

private extension String {
    static let checkinEntries = "sdk.crowdnotifier.checkinEntries"
}
