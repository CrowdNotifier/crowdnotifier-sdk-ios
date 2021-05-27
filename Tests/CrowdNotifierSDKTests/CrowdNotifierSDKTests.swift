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

class CrowdNotifierSDKTests: XCTestCase {
    private let storage: CheckinStorage = .shared

    private let baseUrl = "https://qr.notify-me.ch"

    private let masterPublicKey: Bytes = [Int8]([78, -92, 88, -118, 4, -52, -23, -123, 78, -17, -11, 9, 66, -21, -73, -41, -33, 102, 70, -88, -12, 113, 36, -23, -32, 53, -62, 22, 92, 91, -49, -43, 42, 12, -70, -64, 74, -67, 59, 11, -47, -55, 85, 102, 45, -105, 79, 21, -17, 17, -124, 25, 36, -105, 89, -76, 18, 69, -12, 109, -3, -70, -86, 12, -83, 7, 65, 1, -89, 103, -11, 86, 103, 20, -24, -93, -49, 45, -58, -40, 16, -42, 40, -5, -91, -126, 112, 104, 17, -64, 24, 105, -35, 44, -128, -117]).bytes

    private let qrCode = "https://qr.notify-me.ch/#CAESZAgBEiDwR2Oj0B1_XP1WeCfXRFIN0FylcYGP27HsEhANnE0KExoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogIiO_NrgF7RtaIoQqvPhCN1GoCKGK93p3XNYV7QJ7AjgaQNssfMm583dl88rNfgD8ZPMyRna_xO87g3sNp8zhYi9cbRJ1TKB_UWTBFiO5Tx9G0xbSSOx7qW54wrPwUzjDYQ4"
    private let wrongQrCode = "https://qr.notify-me.ch/#CAESZAgBEiDwR2Oj0B1_XP1WeCfRFIN0FylcYGP27HsEhANnE0KExoKSG9tZW9mZmljZSIHWnVoYXVzZSoFQsO8cm8wADogIiO_NrgF7RtaIoQqvPhCN1GoCKGK93p3XNYV7QJ7AjgaQNssfMm583dl88rNfgD8ZPMyRna_xO87g3sNp8zhYi9cbRJ1TKB_UWTBFiO5Tx9G0xbSSOx7qW54wrPwUzjDYQ4"

    private let jsonString = """
    {
      "identityTestVector": [
        {
          "startOfInterval": 12,
          "qrCodePayload": [80,97,114,115,101,32,116,104,105,115,32,97,115,32,98,121,116,101,115],
          "identity": [22,108,58,-116,-15,-15,104,-16,102,79,23,-34,-57,-54,26,-11,55,113,-120,118,37,104,88,32,20,-92,7,100,118,-123,57,-32]
        },
        {
          "startOfInterval": 886432,
          "qrCodePayload": [65,110,111,116,104,101,114,32,73,100,101,110,116,105,116,121,32,84,101,115,116],
          "identity": [51,76,2,104,41,-119,-61,72,-103,120,-33,-1,-2,-97,55,125,103,0,15,-109,-29,-124,-56,-114,-83,0,110,-79,44,-94,-52,-24]
        }
      ],
      "hkdfTestVector": [
        {
          "qrCodePayload": [80,97,114,115,101,32,116,104,105,115,32,97,115,32,98,121,116,101,115],
          "noncePreId": [78,-10,-117,-108,123,-112,-49,7,63,94,61,-14,51,-48,-73,121,-73,114,-87,-119,-71,13,-103,-107,-114,19,116,-91,-117,-2,-73,48],
          "nonceTimekey": [-102,95,4,20,29,-19,-28,125,115,125,-86,75,112,-61,4,70,59,105,-6,119,75,-106,-36,60,118,-40,-69,-36,54,-107,122,34],
          "notificationKey": [39,98,8,-14,81,119,-77,61,85,115,-101,-69,-89,-41,-47,49,-77,-62,98,46,-121,112,60,45,-100,-69,72,-109,-38,73,-109,75]
        },
        {
          "qrCodePayload": [50,106,20,-96,3,122,95,-93,87,-10,100,-106,97,125,29,61,-118,92,-86,94,-124,71,-68,51,120,-126,104,-100,-62,90,16,-115,44,23,11,95,-4],
          "noncePreId": [-41,2,47,124,-110,-84,-23,31,-54,-117,-34,-2,-125,75,-106,-34,-50,-72,-46,114,-86,15,-33,-63,-123,17,60,-124,-73,-66,44,3],
          "nonceTimekey": [70,-42,-42,12,18,80,103,15,67,93,-93,36,82,-17,28,55,-113,115,-120,-26,75,40,79,74,2,-37,122,56,-57,-88,-7,-86],
          "notificationKey": [-120,127,51,35,89,-116,-93,-5,-127,44,119,-74,-108,-83,-13,60,82,-28,84,84,115,-87,-2,105,119,117,-22,102,-23,-1,-6,-10]
        }
      ]
    }
    """

    private let userUploadInfosTestVector = [
        UserUploadInfo(preId: [102, 168, 6, 51, 148, 105, 27, 207, 161, 224, 198, 28, 198, 237, 58, 28, 226, 147, 154, 0, 242, 43, 27, 25, 156, 86, 75, 3, 236, 153, 174, 216],
                       timeKey: [222, 216, 255, 211, 72, 243, 10, 128, 187, 60, 87, 26, 73, 11, 161, 151, 79, 117, 252, 70, 118, 208, 115, 24, 57, 96, 100, 255, 35, 27, 112, 184],
                       notificationKey: [46, 48, 221, 245, 12, 93, 245, 112, 165, 172, 103, 209, 180, 202, 168, 255, 111, 22, 118, 176, 157, 134, 162, 52, 113, 2, 14, 35, 160, 205, 177, 32],
                       intervalStartMs: 1620140045000,
                       intervalEndMs: 1620140400000),
        UserUploadInfo(preId: [102, 168, 6, 51, 148, 105, 27, 207, 161, 224, 198, 28, 198, 237, 58, 28, 226, 147, 154, 0, 242, 43, 27, 25, 156, 86, 75, 3, 236, 153, 174, 216],
                       timeKey: [202, 110, 23, 99, 202, 110, 240, 234, 251, 216, 228, 66, 167, 48, 101, 135, 103, 133, 220, 139, 162, 73, 21, 40, 162, 104, 153, 173, 195, 71, 15, 130],
                       notificationKey: [46, 48, 221, 245, 12, 93, 245, 112, 165, 172, 103, 209, 180, 202, 168, 255, 111, 22, 118, 176, 157, 134, 162, 52, 113, 2, 14, 35, 160, 205, 177, 32],
                       intervalStartMs: 1620140400000,
                       intervalEndMs: 1620144000000),
        UserUploadInfo(preId: [102, 168, 6, 51, 148, 105, 27, 207, 161, 224, 198, 28, 198, 237, 58, 28, 226, 147, 154, 0, 242, 43, 27, 25, 156, 86, 75, 3, 236, 153, 174, 216],
                       timeKey: [201, 246, 160, 59, 53, 50, 171, 191, 223, 211, 18, 41, 162, 88, 149, 141, 137, 21, 187, 18, 172, 94, 16, 30, 110, 199, 175, 113, 231, 25, 204, 102],
                       notificationKey: [46, 48, 221, 245, 12, 93, 245, 112, 165, 172, 103, 209, 180, 202, 168, 255, 111, 22, 118, 176, 157, 134, 162, 52, 113, 2, 14, 35, 160, 205, 177, 32],
                       intervalStartMs: 1620144000000,
                       intervalEndMs: 1620147245000)
    ]

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
            guard let identity = CryptoUtils.generateIdentity(startOfInterval: test.startOfInterval, qrCodePayload: test.qrCodePayload.bytes) else {
                XCTFail("Failed to create identity")
                return
            }

            XCTAssert(identity == test.identity.bytes, "Identity does not match")
        }
    }

    func testHKDF() {
        let testVector = try! JSONDecoder().decode(TestVector.self, from: jsonString.data(using: .utf8)!)

        for test in testVector.hkdfTestVector {
            guard let (noncePreId, nonceTimekey, notificationKey) = CryptoUtilsBase.getNoncesAndNotificationKey(qrCodePayload: test.qrCodePayload.bytes) else {
                XCTFail("Failed to create nonces and notificationKey from qrCodePayload")
                return
            }

            XCTAssert(noncePreId == test.noncePreId.bytes, "noncePreId does not match")
            XCTAssert(nonceTimekey == test.nonceTimekey.bytes, "nonceTimekey does not match")
            XCTAssert(notificationKey == test.notificationKey.bytes, "notificationKey does not match")
        }
    }

    func testUserUploadInfo() {
        let venueInfo = VenueInfo(description: "Description",
                                  address: "Address",
                                  notificationKey: Bytes(arrayLiteral: 46,48,221,245,12,93,245,112,165,172,103,209,180,202,168,255,111,22,118,176,157,134,162,52,113,2,14,35,160,205,177,32).data,
                                  publicKey: masterPublicKey.data,
                                  noncePreId: Bytes(arrayLiteral: 238,72,16,125,45,198,247,47,219,170,81,212,113,62,203,22,63,78,223,29,183,168,16,31,137,26,76,131,171,226,10,169).data,
                                  nonceTimekey: Bytes(arrayLiteral: 92,144,126,138,102,254,159,236,188,105,1,190,191,138,21,12,232,23,148,102,80,148,19,18,200,150,101,55,241,15,51,121).data,
                                  validFrom: 1620140045000,
                                  validTo: 1620147245000,
                                  qrCodePayload: Bytes(arrayLiteral: 8,3,18,32,8,3,18,11,68,101,115,99,114,105,112,116,105,111,110,26,7,65,100,100,114,101,115,115,32,160,156,1,40,178,184,1,26,136,1,8,3,18,96,78,164,88,138,4,204,233,133,78,239,245,9,66,235,183,215,223,102,70,168,244,113,36,233,224,53,194,22,92,91,207,213,42,12,186,192,74,189,59,11,209,201,85,102,45,151,79,21,239,17,132,25,36,151,89,180,18,69,244,109,253,186,170,12,173,7,65,1,167,103,245,86,103,20,232,163,207,45,198,216,16,214,40,251,165,130,112,104,17,192,24,105,221,44,128,139,26,32,146,63,24,140,239,195,26,46,54,235,29,220,192,95,214,42,49,219,250,187,184,153,230,100,35,169,108,205,170,228,168,44,32,1).data,
                                  countryData: Bytes().data)

        let infos = CrowdNotifier.generateUserUploadInfo(venueInfo: venueInfo, arrivalTime: Date(millisecondsSince1970: 1620140045000), departureTime: Date(millisecondsSince1970: 1620147245000))

        XCTAssert(infos == userUploadInfosTestVector, "UserUploadInfos does not match")
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
