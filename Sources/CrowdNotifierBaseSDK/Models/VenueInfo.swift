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

    public let validFrom: Int // milliseconds since 1970
    public let validTo: Int // milliseconds since 1970

    public let qrCodePayload: Data? // if null, the data is from a CrowdNotifier V2 QR Code
    public let countryData: Data

    public init(description: String,
                address: String,
                notificationKey: Data,
                publicKey: Data,
                nonce1: Data,
                nonce2: Data,
                validFrom: Int,
                validTo: Int,
                qrCodePayload: Data?,
                countryData: Data)
    {
        self.description = description
        self.address = address
        self.notificationKey = notificationKey
        self.publicKey = publicKey
        self.nonce1 = nonce1
        self.nonce2 = nonce2
        self.validFrom = validFrom
        self.validTo = validTo
        self.qrCodePayload = qrCodePayload
        self.countryData = countryData
    }
}

public extension VenueInfo {
    func toBytes() -> Bytes? {
        guard let locationData = try? NotifyMeLocationData(serializedData: countryData) else {
            return nil
        }

        var content = QRCodeContent()
        content.name = description
        content.location = address
        content.room = locationData.room
        content.venueType = .fromVenueType(locationData.type)

        content.notificationKey = notificationKey
        content.validFrom = UInt64(validFrom)
        content.validTo = UInt64(validTo)

        return try? content.serializedData().bytes
    }
}
