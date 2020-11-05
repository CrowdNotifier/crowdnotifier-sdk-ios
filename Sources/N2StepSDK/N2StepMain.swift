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
        let result = qrCodeParser.extractVenueInformation(from: qrCode)

        switch result {
        case .success(let venueInfo):
            // 1. Create private key esk (randombytes_buf)
            // 2. Compute corresponding public key epk (crypto_scalarmult_ed25519_base)
            // 3. Compute shared key h = pk^esk (crypto_scalarmult_ed25519)
            let (epk, h) = CryptoFunctions.createPublicAndSharedKey()
            // 4. Construct payload to store:
            //    - arrivalTime
            //    - departureTime
            //    - notificationKey
            let m = CheckinPayload(arrivalTime: arrivalTime, departureTime: departureTime, notificationKey: venueInfo.notificationKey)
            // 5. Compute ciphertext ctxt by converting pk from ed --> curve (crypto_sign_ed25519_pk_to_curve25519),
            //    then encrypt payload with pk' (crypto_box_seal)
            guard let ctxt = CryptoFunctions.encryptVenuePayload(from: m, pk: venueInfo.publicKey.bytes) else {
                return .failure(.encryptionError)
            }
            // 6. Store day, epk, h, ctxt
            let id = checkinStorage.addCheckinEntry(arrivalTime: arrivalTime, epk: epk, h: h, ctxt: ctxt)

            return .success((venueInfo, id))
        case .failure(let error):
            return .failure(error)
        }
    }

    func updateCheckin(checkinId: String, qrCode: String, newArrivalTime: Date, newDepartureTime: Date) -> Result<(VenueInfo, String), N2StepError> {
        let result = qrCodeParser.extractVenueInformation(from: qrCode)

        switch result {
        case .success(let venueInfo):
            // 1. Create private key esk (randombytes_buf)
            // 2. Compute corresponding public key epk (crypto_scalarmult_ed25519_base)
            // 3. Compute shared key h = pk^esk (crypto_scalarmult_ed25519)
            let (epk, h) = CryptoFunctions.createPublicAndSharedKey()
            // 4. Construct payload to store:
            //    - arrivalTime
            //    - departureTime
            //    - notificationKey
            let m = CheckinPayload(arrivalTime: newArrivalTime, departureTime: newDepartureTime, notificationKey: venueInfo.notificationKey)
            // 5. Compute ciphertext ctxt by converting pk from ed --> curve (crypto_sign_ed25519_pk_to_curve25519),
            //    then encrypt payload with pk' (crypto_box_seal)
            guard let ctxt = CryptoFunctions.encryptVenuePayload(from: m, pk: venueInfo.publicKey.bytes) else {
                return .failure(.encryptionError)
            }
            // 6. Store day, epk, h, ctxt
            let id = checkinStorage.addCheckinEntry(arrivalTime: newArrivalTime, epk: epk, h: h, ctxt: ctxt, overrideEntryWithID: checkinId)

            return .success((venueInfo, id))
        case .failure(let error):
            return .failure(error)
        }
    }

    func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        let possibleMatches = checkinStorage.checkinEntries.values

        var matches = [ExposureEvent]()

        for event in publishedSKs {
            for entry in possibleMatches {
                let shared = CryptoFunctions.computeSharedKey(privateKey: event.privateKey, publicKey: entry.epk)

                if shared == entry.h {
                    // We have a potential match!
                    if let payload = CryptoFunctions.decryptPayload(ciphertext: entry.ctxt, privateKey: event.privateKey, publicKey: shared) {
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
