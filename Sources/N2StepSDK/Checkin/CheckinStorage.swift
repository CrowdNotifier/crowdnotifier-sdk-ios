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

    func addCheckinEntry(pk: String, sharedKey: String, encryptedArrivalTimeAndNotificationKey: String, encryptedCheckoutTime: String) -> Int {
        let nextId = checkinEntries.values.map{ $0.id }.sorted().last ?? 1

        checkinEntries["\(nextId)"] = CheckinEntry(id: nextId,
                                                   daydate: Date.todayAsString,
                                                   pk: pk,
                                                   sharedKey: sharedKey,
                                                   encryptedArrivalTimeAndNotificationKey: encryptedArrivalTimeAndNotificationKey,
                                                   encryptedCheckoutTime: encryptedCheckoutTime)

        return nextId
    }

    func setCheckoutTime(id: Int, encryptedCheckoutTime: String) {
        var entry = checkinEntries["\(id)"]
        if entry != nil {
            entry?.updateCheckoutTime(encryptedCheckoutTime)
            checkinEntries["\(id)"] = entry
        }
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        let allIds = checkinEntries.keys

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for id in allIds {
            if let entry = checkinEntries[id],
               let day = formatter.date(from: entry.daydate),
               day.addingTimeInterval(.day * Double(maxDaysToKeep)) > now {
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
