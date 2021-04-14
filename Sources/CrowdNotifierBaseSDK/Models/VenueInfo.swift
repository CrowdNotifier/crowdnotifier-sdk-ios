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

public struct VenueInfo: Codable {
    public let description: String
    public let address: String

    public let notificationKey: Data
    public let publicKey: Data
    public let nonce1: Data
    public let nonce2: Data

    public let validFrom: Int
    public let validTo: Int

    public let infoBytes: Data? // if null, the data is from a CrowdNotifier V2 QR Code
    public let countryData: Data
}

public extension VenueInfo {
    public func toBytes() -> Bytes? {
        var content = QRCodeContent()
        content.name = self.name
        content.location = self.location
        content.room = self.room
        content.venueType = .fromVenueType(self.venueType)

        content.notificationKey = self.notificationKey
        content.validFrom = UInt64(self.validFrom)
        content.validTo = UInt64(self.validTo)

        return try? content.serializedData().bytes
    }
}

extension NMLocationData.VenueType {
    static func fromVenueType(_ type: VenueInfo.VenueType) -> NMLocationData.VenueType {
        switch type {
        case .other:
            return .other
        case .meetingRoom:
            return .meetingRoom
        case .cafeteria:
            return .cafeteria
        case .privateEvent:
            return .privateEvent
        case .canteen:
            return .canteen
        case .library:
            return .library
        case .lectureRoom:
            return .lectureRoom
        case .shop:
            return .shop
        case .gym:
            return gym
        case .kitchenArea:
            return .kitchenArea
        case .officeSpace:
            return .officeSpace
        }
    }
}
