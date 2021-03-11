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
            checkinStorage.removeVisits(with: existingId)
        }

        let id = checkinId ?? UUID().uuidString

        let visits = CryptoUtils.createEncryptedVenueVisits(id: id, arrivalTime: arrivalTime, departureTime: departureTime, venueInfo: venueInfo)

        visits.forEach { checkinStorage.addEncryptedVenueVisit($0) }

        return .success(id)
    }

    func benchmark() {
        cleanUpOldData(maxDaysToKeep: 0)

        let result = qrCodeParser.extractVenueInformation(from: "https://qr-dev.notify-me.ch?v=2#CAISTQoFVGl0ZWwSClVudGVydGl0ZWwaBlp1c2F0eiAFKiBiPSNR7TaJ9WWDLLKAIKR8gkmwBIo8MdhCE8rMHumafzCAm_nygS84gNOSnIIvGmCNeKNngX8ez_jL225AyPOPUa-3Zgo4gkd-z8dgL6mHuYT0aKVsVtsPBk6AWHyTLQSKfbT-Wb287xE-LIyTjdBsBje_6gbVxB7eLPSlyGFoWtmFliOR7Lk70X8P6J7SNoMiRAogylUYLr1fD2-Jqwxt4BFVoCUWWA_-Z8Li6Bsk1wKluCQSIN_YkcDN-xA5ZJhPJaNKZ7tWjJL2CRYOeiOuqlPWoLCN", baseUrl: "https://qr-dev.notify-me.ch")

        guard case .success(let venueInfo) = result else {
            print("Cannot run benchmark: Invalid QR code")
            return
        }

        let checkinTime = Date(millisecondsSince1970: 1615470240000).addingTimeInterval(.minute * -5)
        let checkoutTime = checkinTime.addingTimeInterval(.minute)

        let repetitions = 1000

        var encryptionTimestamps = [Double]()

        encryptionTimestamps.append(Date().timeIntervalSince1970)
        for i in 0..<repetitions {
            let _ = CryptoUtils.createEncryptedVenueVisits(id: "\(i)", arrivalTime: checkinTime, departureTime: checkoutTime, venueInfo: venueInfo)
            encryptionTimestamps.append(Date().timeIntervalSince1970)
        }

        let _ = addCheckin(venueInfo: venueInfo, arrivalTime: checkinTime, departureTime: checkoutTime)
        let visits = checkinStorage.encryptedVenueVisits
        let successfulSample = ProblematicEventInfo.successfulSample

        var _matches = [ExposureEvent]()
        var successfulDecryptionTimestamps = [Double]()
        successfulDecryptionTimestamps.append(Date().timeIntervalSince1970)
        for _ in 0..<repetitions {
            let matches = CryptoUtils.searchAndDecryptMatches(eventInfo: successfulSample, venueVisits: visits)
            for m in matches {
                if m.arrivalTime <= successfulSample.endTimestamp, m.departureTime >= successfulSample.startTimestamp {
                    _matches.append(m)
                }
            }
            successfulDecryptionTimestamps.append(Date().timeIntervalSince1970)
        }

        let unsuccessfulSample = ProblematicEventInfo.unsuccessfulSample

        _matches = []
        var unsuccessfulDecryptionTimestamps = [Double]()
        unsuccessfulDecryptionTimestamps.append(Date().timeIntervalSince1970)
        for _ in 0..<repetitions {
            let matches = CryptoUtils.searchAndDecryptMatches(eventInfo: unsuccessfulSample, venueVisits: visits)
            for m in matches {
                if m.arrivalTime <= unsuccessfulSample.endTimestamp, m.departureTime >= unsuccessfulSample.startTimestamp {
                    _matches.append(m)
                }
            }
            unsuccessfulDecryptionTimestamps.append(Date().timeIntervalSince1970)
        }

        printCommaSeparated(encryptionTimestamps, title: "Encryption")
        printCommaSeparated(successfulDecryptionTimestamps, title: "Successful decryption")
        printCommaSeparated(unsuccessfulDecryptionTimestamps, title: "Unsuccessful decryption")
    }

    private func printCommaSeparated(_ timestamps: [Double], title: String) {
        var str = ""
        for i in 0..<timestamps.count-1 {
            str.append("\(timestamps[i+1] - timestamps[i]),")
        }
        print(title + ":\n" + str)
    }

    func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        var allExposureEvents = ExposureStorage.shared.exposureEvents

        for eventInfo in problematicEventInfos {
            let matches = CryptoUtils.searchAndDecryptMatches(eventInfo: eventInfo, venueVisits: checkinStorage.encryptedVenueVisits)

            for match in matches {
                // Check if time of visit actually overlaps with the problematic timeslot
                if match.arrivalTime <= eventInfo.endTimestamp, match.departureTime >= eventInfo.startTimestamp {
                    // Don't add the same checkin twice
                    if !allExposureEvents.contains(match) {
                        allExposureEvents.append(match)
                    }
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

private extension ProblematicEventInfo {
    static let successfulSample = ProblematicEventInfo(identity: [164,112,208,146,178,173,158,142,57,48,169,145,163,83,77,121,84,94,238,219,167,180,128,81,160,200,120,55,109,65,67,2],
                                             secretKeyForIdentity: [163,132,118,13,64,31,154,202,122,242,237,130,0,153,204,219,187,77,129,58,26,215,25,239,53,36,168,229,170,92,236,152,224,51,30,160,49,252,172,219,156,13,114,87,153,114,174,20],
                                             startTimestamp: Date(millisecondsSince1970: 1615469400000),
                                             endTimestamp: Date(millisecondsSince1970: 1615470240000),
                                             encryptedMessage: [231,217,162,10,101,19,183,194,221,178,251,231,63,1,252,158,80,85,88,206,83,117],
                                             nonce: [161,255,93,190,83,179,121,193,171,126,148,174,103,23,97,172,91,239,63,198,226,21,141,16])

    static let unsuccessfulSample = ProblematicEventInfo(identity: [14,112,208,146,178,173,158,142,57,48,169,145,163,83,77,121,84,94,238,219,167,180,128,81,160,200,120,55,109,65,67,2],
                                             secretKeyForIdentity: [13,132,118,13,64,31,154,202,122,242,237,130,0,153,204,219,187,77,129,58,26,215,25,239,53,36,168,229,170,92,236,152,224,51,30,160,49,252,172,219,156,13,114,87,153,114,174,20],
                                             startTimestamp: Date(millisecondsSince1970: 1616469400000),
                                             endTimestamp: Date(millisecondsSince1970: 1616470240000),
                                             encryptedMessage: [231,217,162,10,101,19,183,14,221,178,251,231,63,1,252,158,80,85,88,206,83,117],
                                             nonce: [161,255,93,190,83,179,121,193,171,126,18,174,103,23,97,172,91,239,63,198,226,21,141,16])
}
