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

class QRCodeParser {

    func extractVenueInformation(from qrCode: String) -> VenueInfo? {
        let parts = qrCode.split(separator: ",")

        switch parts.count {
        case 4:
            return VenueInfo(pk: String(parts[0]),
                             notificationKey: String(parts[1]),
                             name: String(parts[2]),
                             location: String(parts[3]),
                             defaultDuration: nil)

        case 5:
            return VenueInfo(pk: String(parts[0]),
                             notificationKey: String(parts[1]),
                             name: String(parts[2]),
                             location: String(parts[3]),
                             defaultDuration: TimeInterval(parts[4]))

        default:
            return nil // Incorrect QR code format
        
        }
    }

}
