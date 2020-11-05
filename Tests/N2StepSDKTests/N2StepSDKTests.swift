/*
* Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at https://mozilla.org/MPL/2.0/.
*
* SPDX-License-Identifier: MPL-2.0
*/


@testable import N2StepSDK
import Clibsodium
import Foundation
import XCTest

class N2StepSDKTests: XCTestCase {

    private let storage: CheckinStorage = .shared

    private let qrCode = "https://qr-dev.n2s.ch/#CAESZAgBEiCWQ0LXsHjbnla8aVOc6O-Knrfagwzp0Hl6dpwIVfS2dBoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogyskrsZvBYlhoGLASXeEOecXRWrzeaAp7bkHQYB2zYK4aQNuzu3wLJ8uMggO1nQ3bdwq3rlrav-V33aY-QQ3HIhZUd5K0cy9j1A3zgHNKr3b_0T34rSvemvKiBoWCvbavkA8"
    private let wrongQrCode = "https://qr-dev.n2s.ch/#CAESZAgBEiCWQ0LXsHjbnla8aVOc6O-nrfagwzp0Hl6dpwIVfS2dBoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogyskrsZvBYlhoGLASXeEOecXRWrzeaAp7bkHQYB2zYK4aQNuzu3wLJ8uMggO1nQ3bdwq3rlrav-V33aY-QQ3HIhZUd5K0cy9j1A3zgHNKr3b_0T34rSvemvKiBoWCvbavkA8"

    override class func setUp() {
        N2Step.initialize()
        N2Step.cleanUpOldData(maxDaysToKeep: 0)
    }

    func testCorrectQrCode() {
        let result = N2Step.getVenueInfo(qrCode: qrCode)

        switch result {
        case .success(let venue):
            XCTAssert(venue.name == "Homeoffice", "Wrong venue name")
            XCTAssert(venue.location == "Zuhause", "Wrong venue location")
            XCTAssert(venue.room == "Büro", "Wrong venue room")
            XCTAssert(venue.venueType == .other, "Wrong venue type")
        case .failure(_):
            XCTFail("QR Code should be correct")
        }
    }

    func testWrongQrCode() {
        let result = N2Step.getVenueInfo(qrCode: wrongQrCode)

        switch result {
        case .success(_):
            XCTFail("QR Code should not be correct")
        case .failure(let error):
            XCTAssert(error == .invalidQRCode, "Error case should be .invalidQRCode")
        }
    }

    func testAddCheckin() {
        let arrivalTime = Date()
        let result = N2Step.addCheckin(qrCode: qrCode, arrivalTime: arrivalTime, departureTime: arrivalTime.addingTimeInterval(.hour * 2))

        switch result {
        case .success(let (venue, id)):
            XCTAssert(venue.name == "Homeoffice", "Wrong venue name")
            XCTAssert(venue.location == "Zuhause", "Wrong venue location")
            XCTAssert(venue.room == "Büro", "Wrong venue room")
            XCTAssert(venue.venueType == .other, "Wrong venue type")

            XCTAssert(storage.allEntries.count == 1, "Storage should contain 1 checkin entry")

            guard let entry = storage.allEntries[id] else {
                XCTFail("Entry stored with wrong id")
                return
            }

            XCTAssert(entry.id == id, "Entry has wrong id")
            XCTAssert(entry.daysSince1970 == arrivalTime.daysSince1970, "Wrong daysSince1970 value")

        case .failure(_):
            XCTFail("Checkin with correct QR Code should succeed")
        }
    }

    func testMatching() {

    }

}
