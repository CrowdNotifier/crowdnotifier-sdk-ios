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
import XCTest

@testable import CrowdNotifierSDK
@testable import CrowdNotifierBaseSDK

class CrowdNotifierSDKTests: XCTestCase {
    private let storage: CheckinStorage = .shared

    private let baseUrl = "https://qr.notify-me.ch"

    private let qrCode = "https://qr.notify-me.ch/#CAESZAgBEiDwR2Oj0B1_XP1WeCfXRFIN0FylcYGP27HsEhANnE0KExoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogIiO_NrgF7RtaIoQqvPhCN1GoCKGK93p3XNYV7QJ7AjgaQNssfMm583dl88rNfgD8ZPMyRna_xO87g3sNp8zhYi9cbRJ1TKB_UWTBFiO5Tx9G0xbSSOx7qW54wrPwUzjDYQ4"
    private let wrongQrCode = "https://qr.notify-me.ch/#CAESZAgBEiDwR2Oj0B1_XP1WeCfRFIN0FylcYGP27HsEhANnE0KExoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogIiO_NrgF7RtaIoQqvPhCN1GoCKGK93p3XNYV7QJ7AjgaQNssfMm583dl88rNfgD8ZPMyRna_xO87g3sNp8zhYi9cbRJ1TKB_UWTBFiO5Tx9G0xbSSOx7qW54wrPwUzjDYQ4"

    private let jsonString = """
{
  "identityTestVector": [
    {
      "startOfInterval": 12,
      "infoBytes": [80,97,114,115,101,32,116,104,105,115,32,97,115,32,98,121,116,101,115],
      "identity": [73,-122,119,-119,118,-114,-27,54,-44,13,52,-32,-82,71,-92,79,-22,-94,11,-104,-46,-72,-64,-101,-30,122,-85,-106,59,-29,-86,-23]
    },
    {
      "startOfInterval": 886432,
      "infoBytes": [65,110,111,116,104,101,114,32,73,100,101,110,116,105,116,121,32,84,101,115,116],
      "identity": [-20,91,-35,-1,-107,-89,117,39,122,-14,-49,69,5,-1,-44,61,0,25,105,58,-121,113,-80,-78,22,60,-76,-73,28,-97,-112,53]
    }
  ],
  "hkdfTestVector": [
    {
      "infoBytes": [80,97,114,115,101,32,116,104,105,115,32,97,115,32,98,121,116,101,115],
      "nonce1": [78,-10,-117,-108,123,-112,-49,7,63,94,61,-14,51,-48,-73,121,-73,114,-87,-119,-71,13,-103,-107,-114,19,116,-91,-117,-2,-73,48],
      "nonce2": [-102,95,4,20,29,-19,-28,125,115,125,-86,75,112,-61,4,70,59,105,-6,119,75,-106,-36,60,118,-40,-69,-36,54,-107,122,34],
      "notificationKey": [39,98,8,-14,81,119,-77,61,85,115,-101,-69,-89,-41,-47,49,-77,-62,98,46,-121,112,60,45,-100,-69,72,-109,-38,73,-109,75]
    },
    {
      "infoBytes": [50,106,20,-96,3,122,95,-93,87,-10,100,-106,97,125,29,61,-118,92,-86,94,-124,71,-68,51,120,-126,104,-100,-62,90,16,-115,44,23,11,95,-4],
      "nonce1": [-41,2,47,124,-110,-84,-23,31,-54,-117,-34,-2,-125,75,-106,-34,-50,-72,-46,114,-86,15,-33,-63,-123,17,60,-124,-73,-66,44,3],
      "nonce2": [70,-42,-42,12,18,80,103,15,67,93,-93,36,82,-17,28,55,-113,115,-120,-26,75,40,79,74,2,-37,122,56,-57,-88,-7,-86],
      "notificationKey": [-120,127,51,35,89,-116,-93,-5,-127,44,119,-74,-108,-83,-13,60,82,-28,84,84,115,-87,-2,105,119,117,-22,102,-23,-1,-6,-10]
    }
  ]
}
"""

    override class func setUp() {
        CrowdNotifier.initialize()
        CrowdNotifier.cleanUpOldData(maxDaysToKeep: 0)
    }

    func testHours() {
        let date1 = Date(timeIntervalSince1970: 1_609_495_200) // 01.01.2021 10:00

        let date2 = date1.addingTimeInterval(.minute * 59) // 01.01.2021 10:59
        assert(date1.hoursUntil(date2) == [447_082], "Hours should be [447082]")

        let date3 = date1.addingTimeInterval(.minute * 60) // 01.01.2021 11:00
        assert(date1.hoursUntil(date3) == [447_082, 447_083], "Hours should be [447082, 447083]")

        let date4 = date1.addingTimeInterval(.minute * -1) // 01.01.2021 09:59
        assert(date1.hoursUntil(date4) == [], "Hours should be [] (validFrom > validTo")
        assert(date4.hoursUntil(date1) == [447_081, 447_082], "Hours should be [447081, 447082]")

        let date5 = date1.addingTimeInterval(.hour * 20 - .second * 1)
        assert(date1.hoursUntil(date5).count == 20, "There should be 20 hours")
    }

    func testIdentityGeneration() {
        let testVector = try! JSONDecoder().decode(TestVector.self, from: jsonString.data(using: .utf8)!)

        for test in testVector.identityTestVector {
            guard let identity = CryptoUtils.generateIdentityV3(startOfInterval: test.startOfInterval, infoBytes: test.infoBytes.bytes) else {
                XCTFail("Failed to create identity")
                return
            }

            XCTAssert(identity == test.identity.bytes, "Identity does not match")
        }
    }

    func testHKDF() {
        let testVector = try! JSONDecoder().decode(TestVector.self, from: jsonString.data(using: .utf8)!)

        for test in testVector.hkdfTestVector {
            guard let (nonce1, nonce2, notificationKey) = CryptoUtilsBase.getNoncesAndNotificationKey(infoBytes: test.infoBytes.bytes) else {
                XCTFail("Failed to create nonces and notificationKey from infoBytes")
                return
            }

            XCTAssert(nonce1 == test.nonce1.bytes, "nonce1 does not match")
            XCTAssert(nonce2 == test.nonce2.bytes, "nonce2 does not match")
            XCTAssert(notificationKey == test.notificationKey.bytes, "notificationKey does not match")
        }
    }

    func testWrongQrCode() {
        let result = CrowdNotifier.getVenueInfo(qrCode: wrongQrCode, baseUrl: baseUrl)

        switch result {
        case .success:
            XCTFail("QR Code should not be correct")
        case let .failure(error):
            XCTAssert(error == .invalidQRCode, "Error case should be .invalidQRCode")
        }
    }

}
