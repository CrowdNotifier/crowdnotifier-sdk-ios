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

public struct ProblematicEventInfo {
    public let identity: Bytes
    public let secretKeyForIdentity: Bytes
    public let day: Int
    public let encryptedAssociatedData: Bytes
    public let cipherTextNonce: Bytes

    public init(identity: Bytes,
                secretKeyForIdentity: Bytes,
                day: Int,
                encryptedAssociatedData: Bytes,
                cipherTextNonce: Bytes) {
        self.identity = identity
        self.secretKeyForIdentity = secretKeyForIdentity
        self.day = day
        self.encryptedAssociatedData = encryptedAssociatedData
        self.cipherTextNonce = cipherTextNonce
    }
}
