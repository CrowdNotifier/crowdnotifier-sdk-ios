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
    private let checkinStorage: CheckinStorage = .shared
    private let exposureStorage: ExposureStorage = .shared

    init() {
        mclBn_init(Int32(MCL_BLS12_381), MCLBN_FR_UNIT_SIZE * 10 + MCLBN_FP_UNIT_SIZE)
    }

    func getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        return CrowdNotifierBase.getVenueInfo(qrCode: qrCode, baseUrl: baseUrl)
    }

    func addCheckin(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        return addOrUpdateCheckin(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    func updateCheckin(checkinId: String, venueInfo: VenueInfo, newArrivalTime: Date, newDepartureTime: Date) -> Result<String, CrowdNotifierError> {
        return addOrUpdateCheckin(checkinId: checkinId, venueInfo: venueInfo, arrivalTime: newArrivalTime, departureTime: newDepartureTime)
    }

    func generateQRCodeString(baseUrl: String, masterPublicKey: Bytes, description: String, address: String, startTimestamp: Date, endTimestamp: Date, countryData: Data?) -> Result<(VenueInfo, String), CrowdNotifierError> {
        return CryptoUtils.generateQRCodeString(baseUrl: baseUrl, masterPublicKey: masterPublicKey, description: description, address: address, startTimestamp: startTimestamp, endTimestamp: endTimestamp, countryData: countryData)
    }

    func generateUserUploadInfo(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> [UserUploadInfo] {
        return CryptoUtils.generateUserUploadInfo(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    private func addOrUpdateCheckin(checkinId: String? = nil, venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        if let existingId = checkinId {
            checkinStorage.removeVisits(with: existingId)
        }

        let id = checkinId ?? UUID().uuidString

        let visits = CryptoUtils.createEncryptedVenueVisits(id: id, arrivalTime: arrivalTime, departureTime: departureTime, venueInfo: venueInfo)

        visits.forEach { checkinStorage.addEncryptedVenueVisit($0) }

        return .success(id)
    }

    func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        var allExposureEvents = ExposureStorage.shared.exposureEvents

        for eventInfo in problematicEventInfos {
            // Only check visits with the same day as the problematic event
            let matches = CryptoUtils.searchAndDecryptMatches(eventInfo: eventInfo, venueVisits: checkinStorage.encryptedVenueVisits.filter({ $0.daysSince1970 == eventInfo.day }))

            for match in matches {
                // Don't add the same checkin twice
                if !allExposureEvents.contains(match) {
                    allExposureEvents.append(match)
                }
            }
        }

        ExposureStorage.shared.setExposureEvents(allExposureEvents)

        return allExposureEvents
    }

    func getExposureEvents() -> [ExposureEvent] {
        return exposureStorage.exposureEvents
    }

    func removeExposure(exposure: ExposureEvent) {
        return exposureStorage.removeExposure(exposure)
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
        exposureStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }
}
