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
    public enum VenueType: String, Codable {
        case other = "OTHER"
        case meetingRoom = "MEETING_ROOM"
        case cafeteria = "CAFETERIA"
        case privateEvent = "PRIVATE_EVENT"
        case canteen = "CANTEEN"
        case library = "LIBRARY"
        case lectureRoom = "LECTURE_ROOM"
        case shop = "SHOP"
        case gym = "GYM"
        case kitchenArea = "KITCHEN_AREA"
        case officeSpace = "OFFICE_SPACE"
    }

    public let name: String
    public let location: String
    public let room: String
    public let venueType: VenueInfo.VenueType

    public let masterPublicKey: Data
    public let nonce1: Data
    public let nonce2: Data

    public let notificationKey: Data
    public let validFrom: Int
    public let validTo: Int
}

extension VenueInfo.VenueType {
    static func fromVenueType(_ type: QRCodeContent.VenueType) -> VenueInfo.VenueType {
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
            return .gym
        case .kitchenArea:
            return .kitchenArea
        case .officeSpace:
            return .officeSpace
        case .UNRECOGNIZED(_):
            return .other
        }
    }

    static func fromVenueType(_ type: NMLocationData.VenueType) -> VenueInfo.VenueType {
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
            return .gym
        case .kitchenArea:
            return .kitchenArea
        case .officeSpace:
            return .officeSpace
        case .UNRECOGNIZED(_):
            return .other
        }
    }
}

extension QRCodeContent.VenueType {
    static func fromVenueType(_ type: VenueInfo.VenueType) -> QRCodeContent.VenueType {
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
