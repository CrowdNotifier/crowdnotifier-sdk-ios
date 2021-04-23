/*
 * Copyright (c) 2021 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

public struct VenueInfo_v2: Codable {
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
    public let venueType: VenueInfo_v2.VenueType

    public let masterPublicKey: Data
    public let nonce1: Data
    public let nonce2: Data

    public let notificationKey: Data
    public let validFrom: Int
    public let validTo: Int
}


