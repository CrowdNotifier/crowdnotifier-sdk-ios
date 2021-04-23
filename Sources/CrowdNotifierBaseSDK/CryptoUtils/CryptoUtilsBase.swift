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
import HKDF

public final class CryptoUtilsBase {

    private static let hkdfDomainKey = "CrowdNotifier_v3"

    public static func getNoncesAndNotificationKey(qrCodePayload: Bytes) -> (nonce1: Bytes, nonce2: Bytes, notificationKey: Bytes)? {
        // Length: 32 bytes each for nonce1, nonce2 & notification_key
        let length = 32 + 32 + 32
        let hkdfKey = HKDF.deriveKey(seed: qrCodePayload.data, info: hkdfDomainKey.bytes.data, salt: Bytes().data, count: length)

        guard hkdfKey.count == length else {
            return nil
        }

        let nonce1 = Bytes(hkdfKey[0..<32])
        let nonce2 = Bytes(hkdfKey[32..<64])
        let notificationKey = Bytes(hkdfKey[64..<96])

        return (nonce1, nonce2, notificationKey)
    }
}
