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

class N2StepMain {

    private var qrCodeParser: QRCodeParser
    private let checkinStorage: CheckinStorage = .shared

    init() {
        qrCodeParser = QRCodeParser()
    }

    func getVenueInfo(qrCodeData: QRCodeData) -> VenueInfo? {
        return qrCodeParser.extractVenueInformation(from: qrCodeData)
    }

    func checkin(qrCodeData: QRCodeData, arrivalTime: Date) -> (VenueInfo, Int)? {
        guard let fullInfo = qrCodeParser.extractFullInformation(from: qrCodeData) else {
            return nil
        }

        let pair = CryptoFunctions.createKeyPair()
        let shared = CryptoFunctions.createSharedKey(key1: pair.pk, key2: fullInfo.pk)

        let id = checkinStorage.addCheckinEntry(pk: pair.pk, sharedKey: shared, ciphertext: CryptoFunctions.encrypt(text: "\(arrivalTime.millisecondsSince1970)|\(fullInfo.notificationKey)", withKey: fullInfo.pk))

        checkinStorage.setAdditionalInfo(id: id, checkinDuration: fullInfo.venueInfo.defaultDuration ?? 0, name: fullInfo.venueInfo.name, location: fullInfo.venueInfo.location)

        return (fullInfo.venueInfo, id)
    }

    func changeDuration(checkinId: Int, newDuration: TimeInterval) {
        checkinStorage.updateCheckinDuration(id: checkinId, newCheckinDuration: newDuration)
    }

    func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        let possibleMatches = checkinStorage.entries

        var matches = [ExposureEvent]()

        for event in publishedSKs {
            for entry in possibleMatches {
                if CryptoFunctions.createSharedKey(key1: entry.pk, key2: event.sk) == entry.sharedKey {
                    let decryptedInfo = CryptoFunctions.decrypt(ciphertext: entry.ciphertext, withKey: event.sk)
                    let parts = decryptedInfo.split(separator: "|")
                    guard let milliseconds = Int(parts[0]) else {
                        continue
                    }

                    let additionalInfo = checkinStorage.additionalEntryInfo["\(entry.id)"]

                    let arrivalTime = Date(millisecondsSince1970: milliseconds)
                    let notificationKey = String(parts[1])
                    matches.append(ExposureEvent(checkinId: entry.id, start: arrivalTime, duration: additionalInfo?.checkinDuration ?? 0, message: CryptoFunctions.decrypt(ciphertext: event.message, withKey: notificationKey)))
                }
            }
        }
        
        return matches
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

}
