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

    func getVenueInfo(qrCode: String) -> Result<VenueInfo, N2StepError> {
        return qrCodeParser.extractVenueInformation(from: qrCode)
    }

    func addCheckin(qrCode: String, arrivalTime: Date, departureTime: Date) -> Result<(VenueInfo, String), N2StepError> {
        addOrUpdateCheckin(qrCode: qrCode, newArrivalTime: arrivalTime, newDepartureTime: departureTime)
    }

    func updateCheckin(checkinId: String, qrCode: String, newArrivalTime: Date, newDepartureTime: Date) -> Result<(VenueInfo, String), N2StepError> {
        addOrUpdateCheckin(qrCode: qrCode, newArrivalTime: newArrivalTime, newDepartureTime: newDepartureTime, checkinId: checkinId)
    }

    private func addOrUpdateCheckin(qrCode: String, newArrivalTime: Date, newDepartureTime: Date, checkinId: String? = nil) -> Result<(VenueInfo, String), N2StepError> {
        let result = qrCodeParser.extractVenueInformation(from: qrCode)

        switch result {
        case .success(let venueInfo):

            guard let (epk, h, ctxt) = CryptoFunctions.createCheckinEntry(venueInfo: venueInfo, arrivalTime: newArrivalTime, departureTime: newDepartureTime) else {
                return .failure(.encryptionError)
            }

            let id = checkinStorage.addCheckinEntry(arrivalTime: newArrivalTime, epk: epk, h: h, ctxt: ctxt, overrideEntryWithID: checkinId)

            return .success((venueInfo, id))

        case .failure(let error):
            return .failure(error)
        }
    }

    func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        let possibleMatches = checkinStorage.allEntries.values

        var matches = [ExposureEvent]()

        for event in publishedSKs {
            guard let sk_venue_kx = CryptoFunctions.privateKeyEd25519ToCurve25519(privateKey: event.privateKey) else {
                continue
            }

            for entry in possibleMatches {
                guard let tagPrime = CryptoFunctions.computeSharedKey(privateKey: sk_venue_kx, publicKey: entry.epk.bytes) else {
                    continue
                }

                if tagPrime == entry.h.bytes {
                    // We have a potential match!
                    if let payload = CryptoFunctions.decryptPayload(ciphertext: entry.ctxt.bytes, privateKey: sk_venue_kx) {
                        let arrival = payload.arrivalTime.millisecondsSince1970
                        let departure = payload.departureTime.millisecondsSince1970
                        // Check if times actually overlap
                        if (arrival <= event.exit.millisecondsSince1970 && departure >= event.entry.millisecondsSince1970) {
                            matches.append(ExposureEvent(checkinId: entry.id, arrivalTime: payload.arrivalTime, departureTime: payload.departureTime, message: "Match!"))
                            break
                        }
                    }
                }
            }
        }
        
        return matches
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

}
