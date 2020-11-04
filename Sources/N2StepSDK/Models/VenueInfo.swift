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
        case restaurant = "RESTAURANT"
    }

    public let publicKey: Data
    public let notificationKey: Data
    public let name: String
    public let location: String
    public let room: String?
    public let venueType: VenueInfo.VenueType
    public let defaultDuration: TimeInterval?
}

extension VenueInfo.VenueType {
    static func fromVenueType(_ type: QRCodeContent.VenueType) -> VenueInfo.VenueType {
        switch type {
        case .restaurant: return .restaurant
        case .other: return .other
        }
    }
}
