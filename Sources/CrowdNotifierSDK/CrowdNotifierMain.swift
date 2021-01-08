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
import libmcl

class CrowdNotifierMain {
    private var qrCodeParser: QRCodeParser
    private let checkinStorage: CheckinStorage = .shared
    private let exposureStorage: ExposureStorage = .shared

    init() {
        qrCodeParser = QRCodeParser()
        mclBn_init(Int32(MCL_BLS12_381), MCLBN_FR_UNIT_SIZE * 10 + MCLBN_FP_UNIT_SIZE)
    }

    func getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        return qrCodeParser.extractVenueInformation(from: qrCode, baseUrl: baseUrl)
    }

    func addCheckin(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        return addOrUpdateCheckin(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    func updateCheckin(checkinId: String, venueInfo: VenueInfo, newArrivalTime: Date, newDepartureTime: Date) -> Result<String, CrowdNotifierError> {
        return addOrUpdateCheckin(checkinId: checkinId, venueInfo: venueInfo, arrivalTime: newArrivalTime, departureTime: newDepartureTime)
    }

    private func addOrUpdateCheckin(checkinId: String? = nil, venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        let id = UUID().uuidString

        let startHour = arrivalTime.hoursSince1970
        let endHour = departureTime.hoursSince1970

        for hour in startHour...endHour {
            guard let encryptedData = CryptoFunctions.createCheckinEntry(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime, hour: hour) else {
                return .failure(.encryptionError)
            }

            checkinStorage.addCheckinEntry(id: id, arrivalTime: arrivalTime, encryptedData: encryptedData, overrideEntryWithID: checkinId)
        }

        return .success(id)
    }

    func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        return []

        var matches = exposureStorage.exposureEvents

        for eventInfo in problematicEventInfos {
            let events = CryptoFunctions.searchAndDecryptMatches(eventInfo: eventInfo, visits: checkinStorage.checkinEntries)
            print(events)
//            for entry in possibleMatches {
//                guard !matches.map(\.checkinId).contains(entry.id) else {
//                    continue
//                }
//
//                let aux = CryptoFunctions.match(identity: eventInfo.identity, secretKey: eventInfo.secretKeyForIdentity, entry: entry)
//            }
        }

//        let possibleMatches = checkinStorage.allEntries.values
//
//        var matches = exposureStorage.exposureEvents
//
//        for event in publishedSKs
//        {
//            for entry in possibleMatches
//            {
//                guard !matches.map({ $0.checkinId }).contains(entry.id) else {
//                    continue
//                }
//
//                guard let tagPrime = CryptoFunctions.computeSharedKey(privateKey: event.privateKey, publicKey: entry.epk.bytes) else {
//                    continue
//                }
//
//                // check tag prime
//                if tagPrime != entry.h.bytes {
//                    continue
//                }
//
//                // We have a potential match!
//                if let payload = CryptoFunctions.decryptPayload(ciphertext: entry.ctxt.bytes, privateKey: event.privateKey, r2: event.r2) {
//                    let arrival = payload.arrivalTime.millisecondsSince1970
//                    let departure = payload.departureTime.millisecondsSince1970
//                    // Check if times actually overlap
//                    if arrival <= event.exit.millisecondsSince1970, departure >= event.entry.millisecondsSince1970 {
//
//                        let m = CryptoFunctions.decryptMessage(message: event.message, nonce: event.nonce, key: payload.notificationKey.bytes) ?? ""
//
//                        matches.append(ExposureEvent(checkinId: entry.id, arrivalTime: payload.arrivalTime, departureTime: payload.departureTime, message: m))
//                        continue
//                    }
//                }
//            }
//        }
//
//        exposureStorage.setExposureEvents(matches)
//
//        return matches
    }

    func getExposureEvents() -> [ExposureEvent] {
        return exposureStorage.exposureEvents
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }
}
