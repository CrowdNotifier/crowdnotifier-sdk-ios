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

class CrowdNotifierMain {
    private var qrCodeParser: QRCodeParser
    private let checkinStorage: CheckinStorage = .shared
    private let exposureStorage: ExposureStorage = .shared

    init() {
        qrCodeParser = QRCodeParser()
    }

    func getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        return qrCodeParser.extractVenueInformation(from: qrCode, baseUrl: baseUrl)
    }

    func addCheckin(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        return addOrUpdateCheckin(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    func updateCheckin(checkinId: String, venueInfo: VenueInfo, newArrivalTime: Date, newDepartureTime: Date) -> Result< String, CrowdNotifierError> {
        return addOrUpdateCheckin(checkinId: checkinId, venueInfo: venueInfo, arrivalTime: newArrivalTime, departureTime: newDepartureTime)
    }

    private func addOrUpdateCheckin(checkinId: String? = nil, venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {

        guard let (epk, h, ctxt) = CryptoFunctions.createCheckinEntry(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime) else {
            return .failure(.encryptionError)
        }

        let id = checkinStorage.addCheckinEntry(arrivalTime: arrivalTime, epk: epk, h: h, ctxt: ctxt, overrideEntryWithID: checkinId)

        return .success(id)
    }

    func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        let possibleMatches = checkinStorage.allEntries.values

        var matches = exposureStorage.exposureEvents

        for event in publishedSKs
        {
            for entry in possibleMatches
            {
                guard !matches.map({ $0.checkinId }).contains(entry.id) else {
                    continue
                }

                guard let tagPrime = CryptoFunctions.computeSharedKey(privateKey: event.privateKey, publicKey: entry.epk.bytes) else {
                    continue
                }

                // check tag prime
                if tagPrime != entry.h.bytes {
                    continue
                }
                
                // We have a potential match!
                if let payload = CryptoFunctions.decryptPayload(ciphertext: entry.ctxt.bytes, privateKey: event.privateKey, r2: event.r2) {
                    let arrival = payload.arrivalTime.millisecondsSince1970
                    let departure = payload.departureTime.millisecondsSince1970
                    // Check if times actually overlap
                    if arrival <= event.exit.millisecondsSince1970, departure >= event.entry.millisecondsSince1970 {

                        let m = CryptoFunctions.decryptMessage(message: event.message, nonce: event.nonce, key: payload.notificationKey.bytes) ?? ""

                        matches.append(ExposureEvent(checkinId: entry.id, arrivalTime: payload.arrivalTime, departureTime: payload.departureTime, message: m))
                        continue
                    }
                }
            }
        }

        exposureStorage.setExposureEvents(matches)

        return matches
    }

    func getExposureEvents() -> [ExposureEvent] {
        return exposureStorage.exposureEvents
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }
}
