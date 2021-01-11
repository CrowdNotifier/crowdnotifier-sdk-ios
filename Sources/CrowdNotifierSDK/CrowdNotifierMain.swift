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
        if let existingId = checkinId {
            checkinStorage.removeEntries(with: existingId)
        }

        let id = checkinId ?? UUID().uuidString

        let startHour = arrivalTime.hoursSince1970
        let endHour = departureTime.hoursSince1970

        for hour in startHour...endHour {
            guard let encryptedData = CryptoUtils.createCheckinEntry(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime, hour: hour) else {
                return .failure(.encryptionError)
            }

            checkinStorage.addCheckinEntry(id: id, arrivalTime: arrivalTime, encryptedData: encryptedData, overrideEntryWithID: checkinId)
        }

        return .success(id)
    }

    func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        var newExposureEvents = [ExposureEvent]()

        for eventInfo in problematicEventInfos {
            let matches = CryptoUtils.searchAndDecryptMatches(eventInfo: eventInfo, visits: checkinStorage.checkinEntries)

            for match in matches {
                // Check if time of visit actually overlaps with the problematic timeslot
                if match.arrivalTime <= eventInfo.endTimestamp, match.departureTime >= eventInfo.startTimestamp {
                    // Don't add the same checkin twice
                    if !newExposureEvents.contains(match) {
                        newExposureEvents.append(match)
                    }
                }
            }
        }

        ExposureStorage.shared.setExposureEvents(newExposureEvents)

        return newExposureEvents
    }

    func getExposureEvents() -> [ExposureEvent] {
        return exposureStorage.exposureEvents
    }

    func cleanUpOldData(maxDaysToKeep: Int) {
        checkinStorage.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }
}
