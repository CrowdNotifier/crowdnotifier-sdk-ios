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

    func addCheckinEntry(id: String, arrivalTime: Date, encryptedData: EncryptedCheckinData, overrideEntryWithID: String? = nil) {
        let entry = CheckinEntry(id: id,
                             daysSince1970: arrivalTime.daysSince1970,
                             c1: encryptedData.c2.data,
                             c2: encryptedData.c2.data,
                             c3: encryptedData.c3.data,
                             nonce: encryptedData.nonce.data)

        checkinEntries.append(entry)
    }

    func removeEntries(with id: String) {
        checkinEntries = checkinEntries.filter { $0.id != id }
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        guard maxDaysToKeep > 0 else {
            checkinEntries = []
            return
        }

        let daysLimit = Date().daysSince1970 - maxDaysToKeep

        checkinEntries = checkinEntries.filter { $0.daysSince1970 >= daysLimit }
    }

    // MARK: - Storage

    private(set) var checkinEntries: [CheckinEntry] {
        get {
            if let data = userDefaults.array(forKey: .checkinEntries) as? [Data] {
                return data.compactMap { try? JSONDecoder().decode(CheckinEntry.self, from: $0) }
            }

            return []
        }
        set {
            let data = newValue.compactMap { try? JSONEncoder().encode($0) }
            userDefaults.set(data, forKey: .checkinEntries)
        }
    }
}

private extension String {
    static let checkinEntries = "sdk.crowdnotifier.checkinEntries"
}
