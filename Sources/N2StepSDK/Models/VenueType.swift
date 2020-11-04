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

public enum N2StepVenueType: String, Codable {
    case other = "OTHER"
    case restaurant = "RESTAURANT"
}

extension N2StepVenueType {
    static func fromVenueType(_ type: QRCode.VenueType) -> N2StepVenueType {
        switch type {
        case .restaurant: return .restaurant
        case .other: return .other
        }
    }
}
