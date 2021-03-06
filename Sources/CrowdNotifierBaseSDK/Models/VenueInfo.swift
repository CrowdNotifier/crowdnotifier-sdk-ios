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
    public let noncePreId: Data
    public let nonceTimekey: Data

    public let validFrom: Int // milliseconds since 1970
    public let validTo: Int // milliseconds since 1970

    public let qrCodePayload: Data
    public let countryData: Data

    public init(description: String,
                address: String,
                notificationKey: Data,
                publicKey: Data,
                noncePreId: Data,
                nonceTimekey: Data,
                validFrom: Int,
                validTo: Int,
                qrCodePayload: Data,
                countryData: Data) {
        self.description = description
        self.address = address
        self.notificationKey = notificationKey
        self.publicKey = publicKey
        self.noncePreId = noncePreId
        self.nonceTimekey = nonceTimekey
        self.validFrom = validFrom
        self.validTo = validTo
        self.qrCodePayload = qrCodePayload
        self.countryData = countryData
    }
}
