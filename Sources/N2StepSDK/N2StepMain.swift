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

    static let defaultCheckinDuration: TimeInterval = .hour * 1

    private var qrCodeParser: QRCodeParser
    private let checkinStorage: CheckinStorage = .shared

    init() {
        qrCodeParser = QRCodeParser()
    }

    func getVenueInfo(qrCode: String) -> Result<VenueInfo, N2StepError> {
        return qrCodeParser.extractVenueInformation(from: qrCode)
    }

    func checkin(qrCode: String, arrivalTime: Date) -> Result<(VenueInfo, Int), N2StepError> {
        let result = qrCodeParser.extractVenueInformation(from: qrCode)

        switch result {
        case .success(let info):
            let pair = CryptoFunctions.createKeyPair()
            let shared = CryptoFunctions.createSharedKey(key1: pair.pk, key2: info.publicKey.base64EncodedString())
            let encryptedArrivalTimeAndNotificationKey = CryptoFunctions.encrypt(text: "\(arrivalTime.millisecondsSince1970)|\(info.notificationKey)", withKey: info.publicKey.base64EncodedString())
            let encryptedCheckoutTime = CryptoFunctions.encrypt(text: "\(info.defaultDuration ?? N2StepMain.defaultCheckinDuration)", withKey: info.publicKey.base64EncodedString())

            let id = checkinStorage.addCheckinEntry(pk: pair.pk, sharedKey: shared, encryptedArrivalTimeAndNotificationKey: encryptedArrivalTimeAndNotificationKey, encryptedCheckoutTime: encryptedCheckoutTime)

            return .success((info, id))

        case .failure(let error):
            return .failure(error)
        }
    }

    func changeDuration(checkinId: Int, pk: String, newDuration: TimeInterval) {
        checkinStorage.setCheckoutTime(id: checkinId, encryptedCheckoutTime: CryptoFunctions.encrypt(text: "\(newDuration)", withKey: pk))
    }

    func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        let possibleMatches = checkinStorage.checkinEntries.values

        var matches = [ExposureEvent]()

        for event in publishedSKs {
            for entry in possibleMatches {
                if CryptoFunctions.createSharedKey(key1: entry.pk, key2: event.sk) == entry.sharedKey {
                    let decryptedInfo = CryptoFunctions.decrypt(ciphertext: entry.encryptedArrivalTimeAndNotificationKey, withKey: event.sk)
                    let parts = decryptedInfo.split(separator: "|")
                    guard let milliseconds = Int(parts[0]) else {
                        continue
                    }

                    let arrivalTime = Date(millisecondsSince1970: milliseconds)
                    let notificationKey = String(parts[1])

                    var duration: TimeInterval = N2StepMain.defaultCheckinDuration
                    let decryptedCheckoutTime = CryptoFunctions.decrypt(ciphertext: entry.encryptedCheckoutTime, withKey: event.sk)
                    if let interval = TimeInterval(decryptedCheckoutTime) {
                        duration = interval
                    }

                    matches.append(ExposureEvent(checkinId: entry.id, start: arrivalTime, duration: duration, message: CryptoFunctions.decrypt(ciphertext: event.message, withKey: notificationKey)))
                }
            }
        }
        
        return matches
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

}
