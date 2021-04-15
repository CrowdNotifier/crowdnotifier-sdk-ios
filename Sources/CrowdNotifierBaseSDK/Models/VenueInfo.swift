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

    public init(description: String,
                address: String,
                notificationKey: Data,
                publicKey: Data,
                nonce1: Data,
                nonce2: Data,
                validFrom: Int,
                validTo: Int,
                infoBytes: Data?,
                countryData: Data) {
        self.description = description
        self.address = address
        self.notificationKey = notificationKey
        self.publicKey = publicKey
        self.nonce1 = nonce1
        self.nonce2 = nonce2
        self.validFrom = validFrom
        self.validTo = validTo
        self.infoBytes = infoBytes
        self.countryData = countryData
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
