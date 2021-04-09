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

public struct EncryptedVenueVisit: Codable {
    public init(id: String, daysSince1970: Int, encryptedData: EncryptedData) {
        self.id = id
        self.daysSince1970 = daysSince1970
        self.encryptedData = encryptedData
    }
    
    public let id: String
    public let daysSince1970: Int
    public let encryptedData: EncryptedData
}
