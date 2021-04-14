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

extension NotifyMeLocationData.VenueType {
    static func fromVenueType(_ type: QRCodeContent.VenueType) -> NotifyMeLocationData.VenueType {
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
    static func fromVenueType(_ type: NotifyMeLocationData.VenueType) -> QRCodeContent.VenueType {
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
