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

    func addEncryptedVenueVisit(_ visit: EncryptedVenueVisit) {
        encryptedVenueVisits.append(visit)
    }

    func removeVisits(with id: String) {
        encryptedVenueVisits = encryptedVenueVisits.filter { $0.id != id }
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        guard maxDaysToKeep > 0 else {
            encryptedVenueVisits = []
            return
        }

        let daysLimit = Date().daysSince1970 - maxDaysToKeep

        encryptedVenueVisits = encryptedVenueVisits.filter { $0.daysSince1970 >= daysLimit }
    }

    // MARK: - Storage

    private(set) var encryptedVenueVisits: [EncryptedVenueVisit] {
        get {
            if let data = userDefaults.array(forKey: .encryptedVenueVisits) as? [Data] {
                return data.compactMap { try? JSONDecoder().decode(EncryptedVenueVisit.self, from: $0) }
            }

            return []
        }
        set {
            let data = newValue.compactMap { try? JSONEncoder().encode($0) }
            userDefaults.set(data, forKey: .encryptedVenueVisits)
        }
    }
}

private extension String {
    static let encryptedVenueVisits = "sdk.crowdnotifier.encryptedVenueVisits"
}
