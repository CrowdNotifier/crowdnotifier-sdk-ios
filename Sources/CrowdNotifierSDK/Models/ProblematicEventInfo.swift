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
    public let startTimestamp: Date
    public let endTimestamp: Date
    public let nonce: Bytes
    public let encryptedMessage: Bytes

    public init(identity: Bytes, secretKeyForIdentity: Bytes, startTimestamp: Date, endTimestamp: Date, nonce: Bytes, encryptedMessage: Bytes) {
        self.identity = identity
        self.secretKeyForIdentity = secretKeyForIdentity
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.nonce = nonce
        self.encryptedMessage = encryptedMessage
    }
}
