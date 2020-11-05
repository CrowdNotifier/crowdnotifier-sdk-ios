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
import Sodium

class CheckinStorage {

    private let userDefaults: UserDefaults = .standard

    static let shared = CheckinStorage()

    private init() {}

    func addCheckinEntry(epk: Bytes, h: Bytes, ctxt: Bytes, overrideEntryWithID: String? = nil) -> String {

        if let overrideId = overrideEntryWithID {
            checkinEntries[overrideId] = CheckinEntry(id: overrideId, daysSince1970: Date().daysSince1970, epk: epk, h: h, ctxt: ctxt)
            return overrideId
        } else {
            let id = UUID().uuidString

            checkinEntries[id] = CheckinEntry(id: id, daysSince1970: Date().daysSince1970, epk: epk, h: h, ctxt: ctxt)
            return id
        }
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        let allIds = checkinEntries.keys

        let daysLimit = Date().daysSince1970 - maxDaysToKeep

        for id in allIds {
            if let entry = checkinEntries[id], entry.daysSince1970 >= daysLimit {
                continue
            } else {
                checkinEntries[id] = nil
            }
        }
    }

    // MARK: - Storage

    private(set) var checkinEntries: [String: CheckinEntry] {
        get {
            return userDefaults.dictionary(forKey: .checkinEntries) as? [String: CheckinEntry] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: .checkinEntries)
        }
    }

}

private extension String {
    static let checkinEntries = "ch.ubique.n2step.checkinEntries"
}
