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

public enum CryptoUtilsBase {
    private static let hkdfDomainKey = "CrowdNotifier_v3"

    public static func getNoncesAndNotificationKey(qrCodePayload: Bytes) -> (noncePreId: Bytes, nonceTimekey: Bytes, notificationKey: Bytes)? {
        // Length: 32 bytes each for noncePreId, nonceTimekey & notificationKey
        let length = 32 + 32 + 32
        let hkdfKey = HKDF.deriveKey(seed: qrCodePayload.data, info: hkdfDomainKey.bytes.data, salt: Bytes().data, count: length)

        guard hkdfKey.count == length else {
            return nil
        }

        let noncePreId = Bytes(hkdfKey[0 ..< 32])
        let nonceTimekey = Bytes(hkdfKey[32 ..< 64])
        let notificationKey = Bytes(hkdfKey[64 ..< 96])

        return (noncePreId, nonceTimekey, notificationKey)
    }
}
