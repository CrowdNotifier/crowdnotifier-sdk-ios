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

    func addCheckinEntry(pk: String, sharedKey: String, ciphertext: String) -> Int {
        var allEntries = entries
        let nextId = allEntries.map{ $0.id }.sorted().last ?? 1

        let entry = CheckinEntry(id: nextId, pk: pk, sharedKey: sharedKey, ciphertext: ciphertext)
        allEntries.append(entry)
        entries = allEntries

        return nextId
    }

    func setAdditionalInfo(id: Int, checkinDuration: TimeInterval, name: String, location: String) {
        additionalEntryInfo["\(id)"] = AdditionalEntryInfo(id: id, checkinDuration: checkinDuration, name: name, location: location)
    }

    func updateCheckinDuration(id: Int, newCheckinDuration: TimeInterval) {
        guard let info = additionalEntryInfo["\(id)"] else {
            return
        }

        additionalEntryInfo["\(id)"] = AdditionalEntryInfo(id: id, checkinDuration: newCheckinDuration, name: info.name, location: info.location)
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        // TODO
    }

    // MARK: - Storage

    private(set) var entries: [CheckinEntry] {
        get {
            return userDefaults.array(forKey: .entries) as? [CheckinEntry] ?? []
        }
        set {
            userDefaults.set(newValue, forKey: .entries)
        }
    }

    private(set) var additionalEntryInfo: [String: AdditionalEntryInfo] {
        get {
            return userDefaults.dictionary(forKey: .additionalInfo) as? [String: AdditionalEntryInfo] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: .additionalInfo)
        }
    }
}

private extension String {
    static let entries = "ch.ubique.n2step.entries"
    static let additionalInfo = "ch.ubique.n2step.additionalInfo"
}
